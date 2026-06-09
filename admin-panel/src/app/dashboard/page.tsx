"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { 
  Users, 
  CheckCircle2, 
  Clock, 
  MousePointer2,
  TrendingUp,
  Award,
  Loader2,
  UserCheck
} from "lucide-react";
import styles from "./page.module.css";
import { db } from "@/lib/firebase";
import { collection, getCountFromServer, query, where, getDocs, limit, orderBy } from "firebase/firestore";

interface DashboardStats {
  totalUsers: number;
  verifiedUsers: number;
  limitedUsers: number;
  dailyActive: number;
  totalCodesUsed: number;
  conversionRate: string;
}

interface TopInviter {
  id: string;
  name: string;
  count: number;
}

interface RecentUser {
  id: string;
  username: string;
  email: string;
  isVerified: boolean;
  joinedAt: string;
}

export default function OverviewPage() {
  const [loading, setLoading] = useState(true);
  const [statsData, setStatsData] = useState<DashboardStats>({
    totalUsers: 0,
    verifiedUsers: 0,
    limitedUsers: 0,
    dailyActive: 0,
    totalCodesUsed: 0,
    conversionRate: "0%"
  });
  const [topInviters, setTopInviters] = useState<TopInviter[]>([]);
  const [recentUsers, setRecentUsers] = useState<RecentUser[]>([]);

  useEffect(() => {
    async function loadDashboardData() {
      try {
        const usersRef = collection(db, "users");
        const invitesRef = collection(db, "invite_codes");

        // 1. Stats
        const totalUsersSnap = await getCountFromServer(usersRef);
        const totalUsers = totalUsersSnap.data().count;

        const verifiedUsersSnap = await getCountFromServer(query(usersRef, where("isVerified", "==", true)));
        const verifiedUsers = verifiedUsersSnap.data().count;

        const limitedUsers = Math.max(0, totalUsers - verifiedUsers);

        // Daily active estimate
        const dailyActive = Math.floor(totalUsers * 0.25);

        const codesUsedSnap = await getCountFromServer(query(invitesRef, where("uses", ">", 0)));
        const totalCodesUsed = codesUsedSnap.data().count;
        
        let convRate = "0%";
        if (totalCodesUsed > 0) {
          convRate = ((totalUsers / totalCodesUsed) * 10).toFixed(1) + "%";
        }

        // 2. Top Inviters
        const topInvitersQuery = query(invitesRef, orderBy("uses", "desc"), limit(3));
        const topInvitersSnap = await getDocs(topInvitersQuery);
        const invitersList = topInvitersSnap.docs.map((doc, i) => ({
          id: doc.id,
          name: doc.data().creatorName || `User ${i+1}`,
          count: doc.data().uses || 0
        }));

        // 3. Recent Users
        const recentUsersQuery = query(usersRef, orderBy("createdAt", "desc"), limit(5));
        const recentUsersSnap = await getDocs(recentUsersQuery);
        const usersList = recentUsersSnap.docs.map(doc => {
          const data = doc.data();
          return {
            id: doc.id,
            username: data.username || "anonymous",
            email: data.email || "no-email",
            isVerified: data.isVerified === true,
            joinedAt: data.createdAt?.toDate ? data.createdAt.toDate().toLocaleDateString() : "Just now"
          };
        });

        setStatsData({
          totalUsers,
          verifiedUsers,
          limitedUsers,
          dailyActive,
          totalCodesUsed,
          conversionRate: convRate
        });
        setTopInviters(invitersList);
        setRecentUsers(usersList);
      } catch (error) {
        console.error("Error loading dashboard data:", error);
      } finally {
        setLoading(false);
      }
    }

    loadDashboardData();
  }, []);

  const stats = [
    { label: "Total Users", value: statsData.totalUsers.toLocaleString(), icon: Users, color: "var(--primary)" },
    { label: "Verified Users", value: statsData.verifiedUsers.toLocaleString(), icon: CheckCircle2, color: "var(--success)" },
    { label: "Limited Users", value: statsData.limitedUsers.toLocaleString(), icon: Clock, color: "var(--warning)" },
    { label: "Daily Active (Est.)", value: statsData.dailyActive.toLocaleString(), icon: MousePointer2, color: "var(--accent)" },
  ];

  return (
    <div className="animate-fade-in">
      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>Dashboard Overview</h1>
          <p className={styles.subtitle}>Real-time performance and user metrics</p>
        </div>
        <div className={styles.dateRange}>Live Data Feed</div>
      </header>

      {loading ? (
        <div className={styles.loadingContainer}>
          <Loader2 className="animate-spin text-primary" size={40} />
          <p>Analyzing metrics...</p>
        </div>
      ) : (
        <>
          <div className={styles.statsGrid}>
            {stats.map((stat, i) => (
              <motion.div 
                key={stat.label}
                className="card"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
              >
                <div className={styles.statHeader}>
                  <div 
                    className={styles.statIcon} 
                    style={{ backgroundColor: `${stat.color}15`, color: stat.color }}
                  >
                    <stat.icon size={24} />
                  </div>
                  <div className={styles.trending}>
                    <TrendingUp size={16} />
                    <span>+12%</span>
                  </div>
                </div>
                <div className={styles.statInfo}>
                  <h3 className={styles.statValue}>{stat.value}</h3>
                  <p className={styles.statLabel}>{stat.label}</p>
                </div>
              </motion.div>
            ))}
          </div>

          <div className={styles.mainGrid}>
            <div className={styles.leftCol}>
              <section className="card">
                <div className={styles.sectionHeader}>
                  <h2 className={styles.sectionTitle}>Recent Members</h2>
                </div>
                <div className={styles.userList}>
                  {recentUsers.map(user => (
                    <div key={user.id} className={styles.userItem}>
                      <div className={styles.userAvatar}>
                        {user.username[0].toUpperCase()}
                      </div>
                      <div className={styles.userDetails}>
                        <p className={styles.userName}>@{user.username}</p>
                        <p className={styles.userEmail}>{user.email}</p>
                      </div>
                      <div className={styles.userStatus}>
                        {user.isVerified && <UserCheck size={14} className="text-success" />}
                        <span className={styles.userJoined}>{user.joinedAt}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </section>

              <section className="card" style={{ marginTop: '1.5rem' }}>
                <div className={styles.sectionHeader}>
                  <h2 className={styles.sectionTitle}>Performance Overview</h2>
                </div>
                <div className={styles.metricsList}>
                  <div className={styles.metricItem}>
                    <p className={styles.metricLabel}>Total Codes Used</p>
                    <p className={styles.metricValue}>{statsData.totalCodesUsed}</p>
                  </div>
                  <div className={styles.metricItem}>
                    <p className={styles.metricLabel}>User Conversion</p>
                    <p className={styles.metricValue}>{statsData.conversionRate}</p>
                  </div>
                </div>
              </section>
            </div>

            <div className={styles.rightCol}>
              <section className="card h-full">
                <div className={styles.sectionHeader}>
                  <h2 className={styles.sectionTitle}>Top Inviters</h2>
                </div>
                <div className={styles.invitersList}>
                  {topInviters.length > 0 ? (
                    topInviters.map((inviter) => (
                      <div key={inviter.id} className={styles.inviterItem}>
                        <Award size={18} className={styles.awardIcon} />
                        <div className={styles.inviterInfo}>
                          <p className={styles.inviterName}>{inviter.name}</p>
                          <p className={styles.inviterCount}>{inviter.count} recruits</p>
                        </div>
                      </div>
                    ))
                  ) : (
                    <p style={{ opacity: 0.5, fontSize: '0.875rem' }}>No inviters recorded yet</p>
                  )}
                </div>
              </section>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
