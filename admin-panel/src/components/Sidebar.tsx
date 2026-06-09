"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { 
  LayoutDashboard, 
  KeyRound, 
  UserPlus, 
  Users, 
  ShieldAlert, 
  BarChart3, 
  Settings2,
  LogOut
} from "lucide-react";
import { clsx } from "clsx";
import styles from "./Sidebar.module.css";
import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";

const menuItems = [
  { icon: LayoutDashboard, label: "Overview", href: "/dashboard" },
  { icon: KeyRound, label: "Invite Codes", href: "/dashboard/invites" },
  { icon: UserPlus, label: "Invite Requests", href: "/dashboard/requests" },
  { icon: Users, label: "User Management", href: "/dashboard/users" },
  { icon: ShieldAlert, label: "Abuse Monitoring", href: "/dashboard/abuse" },
  { icon: BarChart3, label: "Analytics", href: "/dashboard/analytics" },
  { icon: Settings2, label: "Feature Control", href: "/dashboard/controls" },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const handleSignOut = async () => {
    try {
      await signOut(auth);
      router.push("/login");
    } catch (error) {
      console.error("Sign out error", error);
    }
  };

  return (
    <aside className={styles.sidebar}>
      <div className={styles.logo}>
        <div className={styles.logoIcon}>G</div>
        <span className={styles.logoText}>Gotcha<span>Admin</span></span>
      </div>

      <nav className={styles.nav}>
        {menuItems.map((item) => (
          <Link 
            key={item.href} 
            href={item.href}
            className={clsx(styles.navItem, pathname === item.href && styles.active)}
          >
            <item.icon size={20} />
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>

      <div className={styles.footer}>
        <button className={styles.logoutBtn} onClick={handleSignOut}>
          <LogOut size={18} />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>
  );
}
