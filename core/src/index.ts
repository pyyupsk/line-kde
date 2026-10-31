import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { loginWithAuthToken, loginWithQR, type Client } from "@evex/linejs";
import { FileStorage } from "@evex/linejs/storage";

const DATA_DIR = join(process.env.XDG_DATA_HOME ?? `${process.env.HOME}/.local/share`, "line-kde");
const SESSION = process.env.LINE_KDE_SESSION ?? join(DATA_DIR, "session.json");
const TOKEN_KEY = "authToken";

mkdirSync(DATA_DIR, { recursive: true, mode: 0o700 });
if (!existsSync(SESSION)) writeFileSync(SESSION, "{}", { mode: 0o600 });
chmodSync(SESSION, 0o600);

const send = (message: unknown) => process.stdout.write(`${JSON.stringify(message)}\n`);

// stdout carries JSON-RPC only; library logs go to stderr
for (const level of ["log", "info", "warn", "debug"] as const) console[level] = console.error;

// Qt has no QR encoder
const qrPng = (url: string) =>
	spawnSync("qrencode", ["-t", "PNG", "-m", "2", "-s", "6", "-o", "-", url]).stdout.toString("base64");

const storage = new FileStorage(SESSION);
const init = { device: "DESKTOPMAC" as const, storage };

let client: Client | null = null;
let selfMid = "";
let selfName = "";
const people = new Map<string, { name: string; picture: string }>();
const chatCache = new Map<string, Awaited<ReturnType<Client["fetchJoinedChats"]>>[number]>();

let tokenSaverAttached = false;

const keepTokenFresh = () => {
	if (!client || tokenSaverAttached) return;
	tokenSaverAttached = true;
	client.base.on("update:authtoken", (token: string) => {
		if (token) void storage.set(TOKEN_KEY, token).then(() => send({ method: "session.saved" }));
	});
};

const profile = async () => {
	const me = await client!.getMyProfile();
	selfMid = me.mid;
	selfName = me.displayName;
	people.set(selfMid, { name: selfName, picture: "" });
	return { name: me.displayName, mid: me.mid };
};

const auth = async () => {
	if (client) return profile();
	const saved = await storage.get(TOKEN_KEY);
	const expiresAt = Number(await storage.get("expire")) * 1000;
	const tokenUsable = typeof saved === "string" && saved.length > 0 && (!expiresAt || Date.now() < expiresAt);
	if (typeof saved === "string" && saved && !tokenUsable) {
		await storage.delete(TOKEN_KEY);
		send({ method: "session.saved" });
	}
	if (tokenUsable) {
		try {
			client = await loginWithAuthToken(saved as string, init);
			keepTokenFresh();
			return profile();
		} catch {
			// an expired token falls through to the QR login
			await storage.delete(TOKEN_KEY);
			send({ method: "session.saved" });
		}
	}
	client = await loginWithQR(
		{
			onReceiveQRUrl(url) {
				send({ method: "auth.qr", params: { png: qrPng(url) } });
			},
			onPincodeRequest(pin) {
				send({ method: "auth.pincode", params: { pin } });
			},
		},
		init,
	);
	await storage.set(TOKEN_KEY, client.authToken);
	send({ method: "session.saved" });
	keepTokenFresh();
	return profile();
};

const methods: Record<string, (params?: Record<string, unknown>) => Promise<unknown>> = {
	"auth.start": auth,
	"auth.logout": async () => {
		client = null;
		tokenSaverAttached = false;
		selfMid = "";
		selfName = "";
		people.clear();
		chatCache.clear();
		if (existsSync(SESSION)) unlinkSync(SESSION);
		return { ok: true };
	},
	"chats.list": async () => {
		if (!client) throw new Error("not signed in");
		const chats = await client.fetchJoinedChats();
		chatCache.clear();
		for (const chat of chats) chatCache.set(chat.mid, chat);

		const boxes = await client.base.talk.getMessageBoxes({ messageBoxListRequest: {} });
		const unread = new Map(boxes.messageBoxes.map((box) => [box.id, Number(box.unreadCount ?? 0)]));

		const items = await Promise.all(
			chats.map(async (chat) => {
				let lastText = "";
				let lastTime = 0;
				try {
					const last = (await chat.fetchMessages(1)).at(-1);
					if (last) {
						lastText = last.raw.text ?? "";
						lastTime = Number(last.raw.createdTime ?? 0);
					}
				} catch {
					// chats without a message box have no preview
				}
				return {
					mid: chat.mid,
					name: chat.name,
					type: String(chat.raw?.type ?? ""),
					lastText,
					lastTime,
					unread: unread.get(chat.mid) ?? 0,
				};
			}),
		);
		return items.sort((a, b) => b.lastTime - a.lastTime);
	},
	"chat.send": async (params) => {
		if (!client) throw new Error("not signed in");
		const mid = String(params?.mid);
		const text = String(params?.text ?? "");
		const attempt = (e2ee: boolean) => client!.base.talk.sendMessage({ to: mid, text, e2ee });
		let sent;
		try {
			sent = await attempt(true);
		} catch (error) {
			// OA, old accounts and OpenChat reject Letter Sealing
			const rejection = error as { type?: string; data?: { code?: string } };
			const unsupported = rejection?.type === "Not support E2EE" || rejection?.data?.code === "E2EE_RECREATE_GROUP_KEY";
			if (!unsupported) throw error;
			sent = await attempt(false);
		}
		const time = Number(sent.createdTime ?? Date.now());
		return {
			id: String(sent.id),
			text,
			from: selfMid,
			mine: true,
			fromName: selfName,
			picture: "",
			time,
			day: new Date(time).toLocaleDateString("sv-SE"),
		};
	},
	"chat.messages": async (params) => {
		const person = async (mid: string) => {
			const known = people.get(mid);
			if (known) return known;
			const entry = { name: "", picture: "" };
			if (mid.startsWith("u")) {
				try {
					const detail = (await client!.getUser(mid)).raw.targetProfileDetail;
					entry.name = detail.profileName;
					entry.picture = detail.picturePath;
				} catch {
					// unknown contact: the UI falls back to the raw mid
				}
			}
			people.set(mid, entry);
			return entry;
		};

		if (!client) throw new Error("not signed in");
		const mid = String(params?.mid);
		const chat = chatCache.get(mid) ?? (await client.getChat(mid));
		const messages = await chat.fetchMessages(30);
		return Promise.all(
			messages.map(async (message) => {
				const from = message.from?.id ?? "";
				const who = await person(from);
				return {
					id: String(message.raw.id),
					text: message.raw.text ?? "",
					from,
					mine: from === selfMid,
					fromName: who.name || (from === selfMid ? selfName : from.slice(0, 8)),
					picture: who.picture,
					time: Number(message.raw.createdTime ?? 0),
					day: new Date(Number(message.raw.createdTime ?? 0)).toLocaleDateString("sv-SE"),
				};
			}),
		);
	},
};

for await (const line of createInterface({ input: process.stdin })) {
	if (!line.trim()) continue;
	const request = JSON.parse(line) as { id?: number; method?: string; params?: Record<string, unknown> };
	const handler = request.method ? methods[request.method] : undefined;
	try {
		if (!handler) throw new Error(`unknown method: ${request.method}`);
		send({ id: request.id, result: await handler(request.params) });
	} catch (error) {
		send({ id: request.id, error: { message: String((error as Error)?.message ?? error) } });
	}
}
