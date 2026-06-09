import { initializeApp, getApps, getApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getAnalytics, isSupported } from "firebase/analytics";

const firebaseConfig = {
  apiKey: "AIzaSyBKndoRyI3OLgSb3lF25k1aDmmJbrWebcE",
  authDomain: "studio-1284397718-50704.firebaseapp.com",
  projectId: "studio-1284397718-50704",
  storageBucket: "studio-1284397718-50704.firebasestorage.app",
  messagingSenderId: "389547380059",
  appId: "1:389547380059:web:3edfc86da709b0b7ccde7e"
};

const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const db = getFirestore(app);
const auth = getAuth(app);

export const analytics = typeof window !== "undefined" ? isSupported().then(yes => yes ? getAnalytics(app) : null) : null;

export { app, db, auth };
