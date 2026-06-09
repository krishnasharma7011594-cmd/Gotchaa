"use client";

import { useState, useEffect, useCallback } from "react";
import Image from "next/image";
import { Search, ShieldAlert, RotateCcw, ShieldCheck, Mail, Loader2, UserX } from "lucide-react";
import { db } from "@/lib/firebase";
import { collection, query, getDocs, doc, updateDoc, limit, orderBy, startAt, endAt } from "firebase/firestore";
import styles from "./users.module.css";

interface User {
  id: string;
  username: string;
  email: string;
  status: "verified" | "limited" | "banned";
  joinedAt: string;
  photoUrl?: string;
}

type UserUpdates = Record<string, boolean>;

type ClassValue = string | undefined | null | boolean | number;

function clsx(...args: ClassValue[]) {
  return args.filter(Boolean).join(" ");
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [processingId, setProcessingId] = useState<string | null>(null);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const usersRef = collection(db, "users");
      let q;

      if (searchTerm) {
        // Simple prefix search for username
        q = query(
          usersRef, 
          orderBy("username"),
          startAt(searchTerm),
          endAt(searchTerm + "\uf8ff"),
          limit(20)
        );
      } else {
        q = query(usersRef, orderBy("createdAt", "desc"), limit(20));
      }

      const snapshot = await getDocs(q);
      const loaded: User[] = snapshot.docs.map(docSnap => {
        const data = docSnap.data();
        let status: "verified" | "limited" | "banned" = "limited";
        if (data.isBanned) status = "banned";
        else if (data.isVerified) status = "verified";

        return {
          id: docSnap.id,
          username: data.username || "anonymous",
          email: data.email || "no-email",
          status,
          joinedAt: data.createdAt?.toDate ? data.createdAt.toDate().toLocaleDateString() : "New Member",
          photoUrl: data.photoUrl
        };
      });

      setUsers(loaded);
    } catch (error) {
      console.error("Error fetching users:", error);
    } finally {
      setLoading(false);
    }
  }, [searchTerm]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const updateStatus = async (uid: string, updates: UserUpdates) => {
    setProcessingId(uid);
    try {
      const userRef = doc(db, "users", uid);
      await updateDoc(userRef, updates);
      await fetchUsers();
    } catch (error) {
      console.error("Error updating user:", error);
    } finally {
      setProcessingId(null);
    }
  };

  return (
    <div className="animate-fade-in">
      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>User Management</h1>
          <p className={styles.subtitle}>Audit users and manage account statuses</p>
        </div>
      </header>

      <div className={styles.toolbar}>
        <div className={styles.searchBox}>
          <Search size={18} />
          <input 
            type="text" 
            placeholder="Search by username..." 
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {loading && users.length === 0 ? (
        <div className="flex justify-center items-center py-20">
          <Loader2 className="animate-spin text-primary" size={40} />
        </div>
      ) : users.length === 0 ? (
        <div className="card flex flex-col items-center py-20 text-center opacity-60">
          <UserX size={48} className="mb-4" />
          <p>No users found matching your search.</p>
        </div>
      ) : (
        <div className={styles.userGrid}>
          {users.map((user) => (
            <div key={user.id} className="card">
              <div className={styles.userHeader}>
                <div className={styles.avatar}>
                  {user.photoUrl ? (
                    <Image
                      src={user.photoUrl}
                      alt={user.username}
                      width={48}
                      height={48}
                      className="w-full h-full object-cover rounded-xl"
                    />
                  ) : (
                    user.username[0].toUpperCase()
                  )}
                </div>
                <div className={styles.userInfo}>
                  <h3 className={styles.username}>@{user.username}</h3>
                  <p className={styles.email}><Mail size={12} /> {user.email}</p>
                </div>
                <span className={clsx(styles.statusTag, styles[user.status])}>
                  {user.status}
                </span>
              </div>

              <div className={styles.userMeta}>
                <p>Joined: {user.joinedAt}</p>
                <p>UID: {user.id}</p>
              </div>

              <div className={styles.actionGrid}>
                {user.status !== "verified" ? (
                  <button 
                    className={styles.verifyBtn}
                    onClick={() => updateStatus(user.id, { isVerified: true, isLimitedUser: false })}
                    disabled={!!processingId}
                  >
                    {processingId === user.id ? <Loader2 size={16} className="animate-spin" /> : <ShieldCheck size={16} />}
                    <span>Verify</span>
                  </button>
                ) : (
                  <button 
                    className={styles.resetBtn}
                    onClick={() => updateStatus(user.id, { isVerified: false, isLimitedUser: true })}
                    disabled={!!processingId}
                  >
                    {processingId === user.id ? <Loader2 size={16} className="animate-spin" /> : <RotateCcw size={16} />}
                    <span>Revoke</span>
                  </button>
                )}
                <button 
                  className={styles.banBtn}
                  onClick={() => updateStatus(user.id, { isBanned: user.status !== "banned" })}
                  disabled={!!processingId}
                >
                  <ShieldAlert size={16} />
                  <span>{user.status === "banned" ? "Unban" : "Ban"}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
