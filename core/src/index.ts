import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createInterface } from "node:readline";
import { loginWithAuthToken, loginWithQR, type Client } from "@evex/linejs";
import { FileStorage } from "@evex/linejs/storage";

const DATA_DIR = join(process.env.XDG_DATA_HOME ?? `${process.env.HOME}/.local/share`, "line-kde");
const SESSION = join(DATA_DIR, "session.json");
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
const chatCache = new Map<string, Awaited<ReturnType<Client["fetchJoinedChats"]>>[number]>();

const profile = async () => {
	const me = await client!.getMyProfile();
	selfMid = me.mid;
	return { name: me.displayName, mid: me.mid };
};

const auth = async () => {
	if (client) return profile();
	const saved = await storage.get(TOKEN_KEY);
	if (typeof saved === "string" && saved) {
		try {
			client = await loginWithAuthToken(saved, init);
			return profile();
		} catch {
			// an expired token falls through to the QR login
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
	return profile();
};

const methods: Record<string, (params?: Record<string, unknown>) => Promise<unknown>> = {
	"auth.start": auth,
	"chats.list": async () => {
		if (!client) throw new Error("not signed in");
		const chats = await client.fetchJoinedChats();
		chatCache.clear();
		for (const chat of chats) chatCache.set(chat.mid, chat);
		return chats.map((chat) => ({ mid: chat.mid, name: chat.name, type: String(chat.raw?.type ?? "") }));
	},
	"chat.messages": async (params) => {
		if (!client) throw new Error("not signed in");
		const mid = String(params?.mid);
		const chat = chatCache.get(mid) ?? (await client.getChat(mid));
		const messages = await chat.fetchMessages(30);
		return messages.map((message) => ({
			id: String(message.raw.id),
			text: message.raw.text ?? "",
			from: message.from?.id ?? "",
			mine: (message.from?.id ?? "") === selfMid,
		}));
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
