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

const profile = async () => {
	const me = await client!.getMyProfile();
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

const methods: Record<string, () => Promise<unknown>> = {
	"auth.start": auth,
	"chats.list": async () => {
		if (!client) throw new Error("not signed in");
		const chats = await client.fetchJoinedChats();
		return chats.map((chat) => ({ mid: chat.mid, name: chat.name, type: String(chat.raw?.type ?? "") }));
	},
};

for await (const line of createInterface({ input: process.stdin })) {
	if (!line.trim()) continue;
	const request = JSON.parse(line) as { id?: number; method?: string };
	const handler = request.method ? methods[request.method] : undefined;
	try {
		if (!handler) throw new Error(`unknown method: ${request.method}`);
		send({ id: request.id, result: await handler() });
	} catch (error) {
		send({ id: request.id, error: { message: String((error as Error)?.message ?? error) } });
	}
}
