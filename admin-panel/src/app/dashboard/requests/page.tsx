"use client";

import { useState, useEffect } from "react";
import { Check, X, Loader2, Mail } from "lucide-react";
import styles from "./requests.module.css";
import { db } from "@/lib/firebase";
import { collection, getDocs, doc, setDoc, updateDoc, serverTimestamp, query, orderBy } from "firebase/firestore";

interface InviteRequest {
  id: string; // The uid of the user who requested
  email: string;
  status: string;
  requestedAt: string;
  issuedCode?: string;
}

export default function RequestsPage() {
  const [requests, setRequests] = useState<InviteRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    loadRequests();
  }, []);

  const loadRequests = async () => {
    setLoading(true);
    try {
      const requestsRef = collection(db, "inviteRequests");
      const q = query(requestsRef, orderBy("requestedAt", "desc"));
      const snapshot = await getDocs(q);
      
      const loaded: InviteRequest[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        let dateStr = "Unknown Date";
        if (data.requestedAt && data.requestedAt.toDate) {
          dateStr = data.requestedAt.toDate().toLocaleString();
        }

        loaded.push({
          id: doc.id,
          email: data.email || "Unknown Email",
          status: data.status || "pending",
          requestedAt: dateStr,
          issuedCode: data.issuedCode,
        });
      });
      setRequests(loaded);
    } catch (error) {
      console.error("Failed to load requests", error);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (request: InviteRequest) => {
    setProcessingId(request.id);
    try {
      // 1. Generate a new custom code tailored for this user (e.g. VIP-...)
      const shortId = request.email.split('@')[0].toUpperCase().substring(0, 5).replace(/[^A-Z0-9]/g, '');
      
      // Use a character set that avoids ambiguous characters like 0, O, 1, I
      const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
      let uniqueSuffix = "";
      for (let i = 0; i < 4; i++) {
        uniqueSuffix += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      
      const newCode = `GOTCHA-${shortId}${uniqueSuffix}`;

      // 2. Save code to system invite_codes
      const newCodeRef = doc(db, "invite_codes", newCode);
      await setDoc(newCodeRef, {
        creator: "admin",
        creatorName: "Approved Request",
        usage: 0,
        uses: 0,
        limit: 1, // Usually only 1 usage for a requested individual
        maxUses: 1,
        status: "active",
        createdAt: serverTimestamp(),
        assignedUserEmail: request.email,
        assignedUserUid: request.id
      });

      // 3. Mark request as approved with the generated code
      const requestRef = doc(db, "inviteRequests", request.id);
      await updateDoc(requestRef, {
        status: "approved",
        issuedCode: newCode,
        processedAt: serverTimestamp()
      });

      // Reload
      await loadRequests();
    } catch (error) {
      console.error("Failed to approve request", error);
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (requestId: string) => {
    setProcessingId(requestId);
    try {
      const requestRef = doc(db, "inviteRequests", requestId);
      await updateDoc(requestRef, {
        status: "rejected",
        processedAt: serverTimestamp()
      });
      await loadRequests();
    } catch (error) {
      console.error("Failed to reject request", error);
    } finally {
      setProcessingId(null);
    }
  };

  return (
    <div className="animate-fade-in">
      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>Invite Requests</h1>
          <p className={styles.subtitle}>Manage pending requests from users asking to join the private beta.</p>
        </div>
      </header>

      <div className="card" style={{ padding: 0, overflow: "hidden" }}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Email</th>
              <th>Requested At</th>
              <th>Status</th>
              <th>Issued Code</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: '2rem' }}>
                  <Loader2 className="animate-spin text-gray-400 mx-auto" size={24} />
                </td>
              </tr>
            ) : requests.length === 0 ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: '2rem', color: '#888' }}>
                  No pending requests found. 
                </td>
              </tr>
            ) : requests.map((req) => (
              <tr key={req.id}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Mail size={16} color="var(--text-muted)" />
                    {req.email}
                  </div>
                </td>
                <td>{req.requestedAt}</td>
                <td>
                  <span className={`${styles.status} ${styles[req.status] || styles.pending}`}>
                    {req.status}
                  </span>
                </td>
                <td>
                  {req.issuedCode ? (
                    <span style={{ fontFamily: 'monospace', background: 'var(--background)', padding: '4px 8px', borderRadius: '4px', letterSpacing: '1px', fontSize: '12px' }}>
                      {req.issuedCode}
                    </span>
                  ) : (
                    <span style={{ color: 'var(--text-muted)', fontSize: '13px' }}>-</span>
                  )}
                </td>
                <td>
                  {req.status === "pending" ? (
                    <div className={styles.actions}>
                      <button 
                        className={styles.approveBtn}
                        onClick={() => handleApprove(req)}
                        disabled={processingId === req.id}
                      >
                        {processingId === req.id ? <Loader2 size={14} className="animate-spin" /> : <Check size={14} />}
                        Approve
                      </button>
                      <button 
                        className={styles.rejectBtn}
                        onClick={() => handleReject(req.id)}
                        disabled={processingId === req.id}
                      >
                        <X size={14} />
                        Reject
                      </button>
                    </div>
                  ) : (
                    <span style={{ color: 'var(--text-muted)', fontSize: '13px' }}>Processed</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

