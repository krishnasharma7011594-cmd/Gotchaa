"use client";

import { useState } from "react";
import { 
  UserPlus, 
  Wallet, 
  Smartphone, 
  Video,
  AlertTriangle,
  Info
} from "lucide-react";
import styles from "./controls.module.css";

const initialFeatures = [
  { id: "invite_only", label: "Invite Lock System", desc: "Require invite codes for full app access", icon: UserPlus, enabled: true },
  { id: "wallet_system", label: "Wallet & Karma", desc: "Enable token transactions and rewards", icon: Wallet, enabled: true },
  { id: "mini_apps", label: "Mini Apps Tab", desc: "Display the exploration tab with partner apps", icon: Smartphone, enabled: true },
  { id: "vybz_posting", label: "Vybz Feed & Posting", desc: "Allow users to upload short videos", icon: Video, enabled: true },
];

export default function ControlsPage() {
  const [features, setFeatures] = useState(initialFeatures);

  const toggleFeature = (id: string) => {
    setFeatures(features.map(f => f.id === id ? { ...f, enabled: !f.enabled } : f));
  };

  return (
    <div className="animate-fade-in">
      <header className={styles.header}>
        <div>
          <h1 className={styles.title}>System Control</h1>
          <p className={styles.subtitle}>Toggle core platform features in real-time</p>
        </div>
      </header>

      <div className={styles.warningBox}>
        <AlertTriangle size={20} />
        <p>Changes here apply instantly to all app instances. Use with caution.</p>
      </div>

      <div className={styles.featureGrid}>
        {features.map((feature) => (
          <div key={feature.id} className={clsx(styles.featureCard, "card")}>
            <div className={styles.featureHeader}>
              <div className={styles.iconBox}>
                <feature.icon size={24} />
              </div>
              <div className={styles.switchBox}>
                <label className={styles.switch}>
                  <input 
                    type="checkbox" 
                    checked={feature.enabled} 
                    onChange={() => toggleFeature(feature.id)}
                  />
                  <span className={styles.slider}></span>
                </label>
              </div>
            </div>
            <div className={styles.featureInfo}>
              <h3 className={styles.featureLabel}>{feature.label}</h3>
              <p className={styles.featureDesc}>{feature.desc}</p>
            </div>
            <div className={styles.featureStatus}>
              <div className={clsx(styles.indicator, feature.enabled ? styles.on : styles.off)}></div>
              <span>{feature.enabled ? "Live" : "Disabled"}</span>
            </div>
          </div>
        ))}
      </div>

      <section className={styles.emergencyStats}>
        <div className="card">
          <div className={styles.infoRow}>
            <Info size={16} />
            <span>Last change by @admin (5 mins ago)</span>
          </div>
        </div>
      </section>
    </div>
  );
}

function clsx(...args: any[]) {
  return args.filter(Boolean).join(" ");
}
