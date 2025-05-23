import * as dotenv from "dotenv";

dotenv.config();

export const Env = {
	openaiApiKey: process.env.OPENAI_API_KEY || "",
	firebaseStorageBucket: process.env.STORAGE_BUCKET || "",
} as const;
