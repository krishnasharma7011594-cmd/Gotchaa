"use client";

import { useState, useEffect } from "react";
import { Search, Filter, MoreVertical, Edit2, ShieldOff, Plus, Loader2, X, Check } from "lucide-react";
import styles from "./invites.module.css";
import { db } from "@/lib/firebase";
import { collection, getDocs, doc, setDoc, serverTimestamp, query, orderBy } from "firebase/firestore";

interface InviteData {
  id: string; // The code itself
  creator: string;
  usage: number;
  limit: number;
  status: string;
  created: string;
}

export default function InvitesPage() {
  const [invites, setInvites] = useState<InviteData[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Form State
  const [showForm, setShowForm] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [customCode, setCustomCode] = useState("");
  const [creatorName, setCreatorName] = useState("");
  const [usageLimit, setUsageLimit] = useState(10);

  useEffect(() => {
    loadInvites();
  }, []);

  const loadInvites = async () => {
    setLoading(true);
    try {
      const invitesRef = collection(db, "invite_codes");
      const q = query(invitesRef, orderBy("createdAt", "desc"));
      const snapshot = await getDocs(q);
      
      const loaded: InviteData[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        let dateStr = "Unknown";
        if (data.createdAt && data.createdAt.toDate) {
          dateStr = data.createdAt.toDate().toISOString().split("T")[0];
        } else if (data.created) {
          dateStr = data.created;
        }

        loaded.push({
          id: doc.id,
          creator: data.creatorName || data.creator || "admin",
          usage: data.uses || data.usage || 0,
          limit: data.maxUses || data.limit || 10,
          status: data.status || "active",
          created: dateStr
        });
      });
      setInvites(loaded);
    } catch (error) {
      console.error("Failed to load invites", error);
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateRandom = () => {
    setCustomCode("GOTCHA-" + Math.random().toString(36).substring(2, 8).toUpperCase());
  };

  const submitNewCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customCode.trim()) return;

    setIsGenerating(true);
    try {
      const codeToUse = customCode.trim().toUpperCase();
      const newRef = doc(db, "invite_codes", codeToUse);
      
      await setDoc(newRef, {
        creator: "admin", // system level admin
        creatorName: creatorName.trim() || "System Admin",
        usage: 0,
        uses: 0,
        limit: usageLimit,
        maxUses: usageLimit,
        status: "active",
        createdAt: serverTimestamp(),
      });
      
      // Reset form
      setCustomCode("");
      setCreatorName("");
      setUsageLimit(10);
      setShowForm(false);
      
      // Reload the list
      await loadInvites();
    } catch (error) {
      console.error("Failed to generate code:", error);
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="animate-fade-in">
      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>Invite Management</h1>
          <p className={styles.subtitle}>Monitor and control system-wide invite codes</p>
        </div>
        {!showForm && (
          <button 
            className={styles.createBtn} 
            onClick={() => {
              setShowForm(true);
              handleGenerateRandom();
            }} 
          >
            <Plus size={18} />
            <span>New Custom Code</span>
          </button>
        )}
      </header>

      {showForm && (
        <form onSubmit={submitNewCode} className="card" style={{ marginBottom: '24px', backgroundColor: 'var(--surface)' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 600, color: 'var(--text)', marginBottom: '16px' }}>
            Create Specific Invite Code
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '8px' }}>
                Invite Code
              </label>
              <div style={{ display: 'flex', gap: '8px' }}>
                <input 
                  type="text" 
                  value={customCode}
                  onChange={(e) => setCustomCode(e.target.value)}
                  placeholder="e.g. GOTCHA-VIP"
                  required
                  style={{ width: '100%', padding: '10px 12px', background: 'var(--background)', border: '1px solid var(--border)', borderRadius: '6px', color: 'var(--text)' }}
                />
                <button 
                  type="button" 
                  onClick={handleGenerateRandom}
                  style={{ padding: '0 12px', background: 'var(--background)', border: '1px solid var(--border)', borderRadius: '6px', cursor: 'pointer', color: 'var(--text-muted)' }}
                  title="Randomize"
                >
                  <Search size={16} />
                </button>
              </div>
            </div>
            
            <div>
              <label style={{ display: 'block', fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '8px' }}>
                Assigned To / Creator Name
              </label>
              <input 
                type="text" 
                value={creatorName}
                onChange={(e) => setCreatorName(e.target.value)}
                placeholder="e.g. John Doe"
                style={{ width: '100%', padding: '10px 12px', background: 'var(--background)', border: '1px solid var(--border)', borderRadius: '6px', color: 'var(--text)' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '8px' }}>
                Usage Limit
              </label>
              <input 
                type="number" 
                min="1"
                value={usageLimit}
                onChange={(e) => setUsageLimit(Number(e.target.value))}
                placeholder="10"
                required
                style={{ width: '100%', padding: '10px 12px', background: 'var(--background)', border: '1px solid var(--border)', borderRadius: '6px', color: 'var(--text)' }}
              />
            </div>
          </div>
          
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
            <button 
              type="button" 
              onClick={() => setShowForm(false)}
              style={{ padding: '8px 16px', border: '1px solid var(--border)', borderRadius: '6px', background: 'transparent', color: 'var(--text)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <X size={16} /> Cancel
            </button>
            <button 
              type="submit" 
              disabled={isGenerating}
              style={{ padding: '8px 16px', border: 'none', borderRadius: '6px', background: 'var(--primary)', color: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', opacity: isGenerating ? 0.7 : 1 }}
            >
              {isGenerating ? <Loader2 size={16} className="animate-spin" /> : <Check size={16} />}
              {isGenerating ? "Saving..." : "Save Code"}
            </button>
          </div>
        </form>
      )}

      <div className={styles.toolbar}>
        <div className={styles.searchBox}>
          <Search size={18} />
          <input type="text" placeholder="Search codes or creators..." />
        </div>
        <button className={styles.filterBtn}>
          <Filter size={18} />
          <span>Filters</span>
        </button>
      </div>

      <div className="card" style={{ padding: 0, overflow: "hidden" }}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Invite Code</th>
              <th>Assigned To</th>
              <th>Usage</th>
              <th>Status</th>
              <th>Created</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '2rem' }}>
                  <Loader2 className="animate-spin text-gray-400 mx-auto" size={24} />
                </td>
              </tr>
            ) : invites.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '2rem', color: '#888' }}>
                  No invite codes found. 
                </td>
              </tr>
            ) : invites.map((invite) => (
              <tr key={invite.id}>
                <td><span className={styles.codeBadge}>{invite.id}</span></td>
                <td>{invite.creator}</td>
                <td>
                  <div className={styles.usageContainer}>
                    <span>{invite.usage} / {invite.limit}</span>
                    <div className={styles.usageBar}>
                      <div 
                        className={styles.usageFill} 
                        style={{ width: `${Math.min(100, (invite.usage / Math.max(1, invite.limit)) * 100)}%` }}
                      ></div>
                    </div>
                  </div>
                </td>
                <td>
                  <span className={clsx(styles.status, styles[invite.status])}>
                    {invite.status}
                  </span>
                </td>
                <td>{invite.created}</td>
                <td>
                  <div className={styles.actions}>
                    <button title="Edit Limit"><Edit2 size={16} /></button>
                    <button title="Disable" className={styles.danger}><ShieldOff size={16} /></button>
                    <button><MoreVertical size={16} /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

type ClassValue = string | undefined | null | boolean | number;

function clsx(...args: ClassValue[]) {
  return args.filter(Boolean).join(" ");
}

