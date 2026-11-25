import React from "react";
import {
  BarChart3,
  BookOpen,
  Briefcase,
  CheckCircle2,
  Globe,
  HelpCircle,
  Home,
  LogOut,
  RefreshCw,
  ScanLine,
  Shield,
  Wallet,
  X,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppDestination, AppLanguage, UserRole } from "../types/kashkool";
import { CosmicButton, StatusBadge } from "../components/CosmicUi";

interface NavItem {
  dest: AppDestination;
  labelKey: string;
  icon: React.ReactNode;
}

export function destinationsForRole(role: UserRole): AppDestination[] {
  switch (role) {
    case UserRole.STUDENT:
      return ["home", "courses", "assistant", "wallet"];
    case UserRole.SECRETARY:
      return ["home", "desk", "analytics", "teacher", "wallet"];
    case UserRole.TEACHER:
      return ["home", "teacher", "courses", "assistant", "desk"];
    case UserRole.PARENT:
      return ["home", "parent", "wallet", "courses"];
  }
}

export const WorkspaceShell: React.FC<{
  destination: AppDestination;
  onNavigate: (dest: AppDestination) => void;
  children: React.ReactNode;
}> = ({ destination, onNavigate, children }) => {
  const {
    language,
    activeRole,
    userLabel,
    pendingSyncCount,
    syncBusy,
    snackbarMessage,
    clearSnackbar,
    toggleLanguage,
    switchRole,
    signOut,
    syncNow,
    tr,
  } = useKashkool();

  const navConfig: Record<AppDestination, NavItem> = {
    home: { dest: "home", labelKey: "nav_home", icon: <Home className="w-4 h-4" /> },
    desk: { dest: "desk", labelKey: "nav_desk", icon: <ScanLine className="w-4 h-4" /> },
    analytics: { dest: "analytics", labelKey: "nav_analytics", icon: <BarChart3 className="w-4 h-4" /> },
    teacher: { dest: "teacher", labelKey: "nav_teacher", icon: <Briefcase className="w-4 h-4" /> },
    courses: { dest: "courses", labelKey: "nav_courses", icon: <BookOpen className="w-4 h-4" /> },
    wallet: { dest: "wallet", labelKey: "nav_wallet", icon: <Wallet className="w-4 h-4" /> },
    assistant: { dest: "assistant", labelKey: "nav_assistant", icon: <HelpCircle className="w-4 h-4" /> },
    parent: { dest: "parent", labelKey: "nav_parent", icon: <Shield className="w-4 h-4" /> },
  };

  const roleTabs = destinationsForRole(activeRole).map((d) => navConfig[d]);

  const roleLabels: Record<UserRole, string> = {
    [UserRole.STUDENT]: tr("role_student"),
    [UserRole.SECRETARY]: tr("role_secretary"),
    [UserRole.TEACHER]: tr("role_teacher"),
    [UserRole.PARENT]: tr("role_parent"),
  };

  const handleRoleSwitch = (nextRole: UserRole) => {
    switchRole(nextRole);
    const allowed = destinationsForRole(nextRole);
    if (!allowed.includes(destination)) {
      onNavigate("home");
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0F1C] text-[#F1F5F9] flex flex-col">
      {/* Top Bar */}
      <header className="sticky top-0 z-30 bg-[#0E1525]/95 backdrop-blur-md border-b border-white/10">
        <div className="max-w-7xl mx-auto px-3 sm:px-6 h-16 flex items-center justify-between gap-2">
          <div className="flex items-center gap-2.5 min-w-0">
            <button
              type="button"
              onClick={() => onNavigate("home")}
              className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#38BDF8] to-[#0284C7] flex items-center justify-center text-[#0A0F1C] font-extrabold text-base shrink-0 cursor-pointer"
            >
              ك
            </button>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span className="text-base font-extrabold text-[#F1F5F9] truncate">{tr("app_title")}</span>
                <StatusBadge tone="cyan" label={roleLabels[activeRole]} className="hidden xs:inline-flex" />
              </div>
              <p className="text-[11px] text-[#94A3B8] truncate">{userLabel}</p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
            {/* Sync Chip */}
            <button
              type="button"
              onClick={syncNow}
              disabled={syncBusy}
              className={`hidden sm:inline-flex items-center gap-1.5 rounded-xl border px-2.5 py-1.5 text-xs font-semibold cursor-pointer transition-colors whitespace-nowrap shrink-0 ${
                pendingSyncCount > 0
                  ? "bg-[#FBBF24]/15 border-[#FBBF24]/40 text-[#FBBF24]"
                  : "bg-[#34D399]/12 border-[#34D399]/30 text-[#34D399]"
              }`}
            >
              <RefreshCw className={`w-3.5 h-3.5 ${syncBusy ? "animate-spin" : ""}`} />
              <span>
                {pendingSyncCount > 0
                  ? `${pendingSyncCount} ${tr("pending_sync")}`
                  : tr("synced_all")}
              </span>
            </button>

            {/* Quick Role Switcher */}
            <select
              aria-label="Switch Role"
              value={activeRole}
              onChange={(e) => handleRoleSwitch(e.target.value as UserRole)}
              className="rounded-xl bg-[#141D2F] border border-white/15 px-2.5 py-1.5 text-xs font-semibold text-[#F1F5F9] focus:outline-none focus:border-[#38BDF8] cursor-pointer"
            >
              <option value={UserRole.STUDENT}>{tr("role_student")}</option>
              <option value={UserRole.SECRETARY}>{tr("role_secretary")}</option>
              <option value={UserRole.TEACHER}>{tr("role_teacher")}</option>
              <option value={UserRole.PARENT}>{tr("role_parent")}</option>
            </select>

            <CosmicButton
              type="button"
              variant="outline"
              tone="slate"
              onClick={toggleLanguage}
              className="text-xs px-2.5 py-1.5"
              icon={<Globe className="w-3.5 h-3.5" />}
            >
              <span className="hidden md:inline">
                {language === AppLanguage.AR ? "EN" : "AR"}
              </span>
            </CosmicButton>

            <CosmicButton
              type="button"
              variant="subtle"
              tone="crimson"
              onClick={signOut}
              className="text-xs px-2.5 py-1.5"
              icon={<LogOut className="w-3.5 h-3.5" />}
              aria-label={tr("sign_out")}
            >
              <span className="hidden lg:inline">{tr("sign_out")}</span>
            </CosmicButton>
          </div>
        </div>
      </header>

      {/* Main Content Area with Desktop Rail + Mobile Bottom Bar */}
      <div className="flex-1 max-w-7xl w-full mx-auto flex">
        {/* Desktop Navigation Rail */}
        <aside className="hidden md:flex flex-col w-56 shrink-0 border-e border-white/10 p-3 gap-1.5 bg-[#0E1525]/55">
          {roleTabs.map((item) => {
            const active = destination === item.dest;
            return (
              <button
                key={item.dest}
                type="button"
                onClick={() => onNavigate(item.dest)}
                className={`flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-semibold transition-all cursor-pointer ${
                  active
                    ? "bg-[#38BDF8]/18 border border-[#38BDF8]/45 text-[#38BDF8]"
                    : "border border-transparent text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-white/5"
                }`}
              >
                {item.icon}
                <span>{tr(item.labelKey)}</span>
              </button>
            );
          })}

          {activeRole === UserRole.TEACHER && (
            <button
              type="button"
              onClick={() => onNavigate("analytics")}
              className={`flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-semibold transition-all cursor-pointer ${
                destination === "analytics"
                  ? "bg-[#38BDF8]/18 border border-[#38BDF8]/45 text-[#38BDF8]"
                  : "border border-transparent text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-white/5"
              }`}
            >
              <BarChart3 className="w-4 h-4" />
              <span>{tr("nav_analytics")}</span>
            </button>
          )}
        </aside>

        {/* Screen Body */}
        <main className="flex-1 min-w-0 p-3 sm:p-6 pb-24 md:pb-8">{children}</main>
      </div>

      {/* Mobile Bottom Navigation Bar */}
      <nav className="md:hidden fixed inset-x-0 bottom-0 z-30 bg-[#0E1525]/96 backdrop-blur-md border-t border-white/10 px-2 py-1.5">
        <div className="flex items-center justify-around gap-1">
          {roleTabs.map((item) => {
            const active = destination === item.dest;
            return (
              <button
                key={item.dest}
                type="button"
                onClick={() => onNavigate(item.dest)}
                className={`flex-1 flex flex-col items-center justify-center gap-0.5 rounded-xl py-1.5 px-1 text-[11px] font-semibold transition-colors cursor-pointer ${
                  active ? "text-[#38BDF8] bg-[#38BDF8]/12" : "text-[#94A3B8]"
                }`}
              >
                {item.icon}
                <span className="truncate max-w-full">{tr(item.labelKey)}</span>
              </button>
            );
          })}
        </div>
      </nav>

      {/* Snackbar Toast */}
      {snackbarMessage && (
        <div className="fixed bottom-20 md:bottom-6 inset-x-4 sm:inset-x-auto sm:end-6 z-50 flex items-center justify-between gap-3 rounded-xl bg-[#141D2F] border border-[#34D399]/50 px-4 py-3 shadow-2xl max-w-md ms-auto">
          <div className="flex items-center gap-2 text-xs sm:text-sm font-semibold text-[#F1F5F9]">
            <CheckCircle2 className="w-4 h-4 text-[#34D399] shrink-0" />
            <span>{snackbarMessage}</span>
          </div>
          <button
            type="button"
            onClick={clearSnackbar}
            aria-label="Dismiss"
            className="text-[#94A3B8] hover:text-[#F1F5F9] cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
};
