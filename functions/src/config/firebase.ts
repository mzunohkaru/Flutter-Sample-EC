import * as admin from "firebase-admin";
import { getMessaging } from "firebase-admin/messaging";

import { Env } from "../env";
import serviceAccount from "../../serviceAccountKey.json";

admin.initializeApp({
	credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
	storageBucket: Env.firebaseStorageBucket,
});

export const db = admin.firestore();
export const batch = db.batch();
export const cloudStorage = admin.storage();
export const bucket = cloudStorage.bucket();
export const messaging = getMessaging();
