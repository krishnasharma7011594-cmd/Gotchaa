"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LogIn, Loader2 } from "lucide-react";
import styles from "./login.module.css";
import { auth } from "@/lib/firebase";
import { signInWithPopup, GoogleAuthProvider, signOut } from "firebase/auth";

const ALLOWED_ADMINS = ["krishnasharma7011594@gmail.com"];

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleGoogleLogin = async () => {
    setLoading(true);
    setError("");
    
    try {
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      
      if (result.user && result.user.email) {
        if (ALLOWED_ADMINS.includes(result.user.email.toLowerCase())) {
          router.push("/dashboard");
        } else {
          // Unauthorized email
          await signOut(auth);
          setError(`Access denied. The email ${result.user.email} is not authorized for the admin panel.`);
          setLoading(false);
        }
      }
    } catch (err: any) {
      console.error(err);
      setError(err.message || "Authentication failed. Please try again.");
      setLoading(false);
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.loginCard}>
        <div className={styles.logo}>
          <div className={styles.logoIcon}>G</div>
          <h1>Gotcha Admin</h1>
        </div>
        
        {error && <div style={{ color: '#ff4c4c', background: '#301010', padding: '10px', borderRadius: '4px', marginBottom: '16px', fontSize: '14px', textAlign: 'center' }}>{error}</div>}

        <div className={styles.form}>
          <button 
            type="button" 
            className={styles.loginBtn} 
            disabled={loading} 
            onClick={handleGoogleLogin}
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}
          >
            {loading ? <Loader2 size={18} className="animate-spin" /> : <LogIn size={18} />}
            {loading ? "Authenticating..." : "Sign In with Google"}
          </button>
        </div>

        <p className={styles.footer}>
          Secure terminal for authorized personnel only.
        </p>
      </div>
    </div>
  );
}

