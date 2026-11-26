import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  AlertTriangle,
  CalendarClock,
  CheckCircle2,
  Laptop,
  Plus,
  RefreshCw,
  Shield,
  ShieldAlert,
  Trash2,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { formatShortTime } from "../core/utils/browserUtils";
import { AppLanguage, AuditLogEntryDto, DeviceBindingDto, UserRole } from "../types/kashkool";
import { CosmicButton, CosmicCard, ModalDialog, StatusBadge } from "./CosmicUi";

export const AegisSecurityPanel: React.FC<{ role: UserRole }> = ({ role }) => {
  const {
    language,
    students,
    groups,
    makeupSessions,
    userLabel,
    issueMakeupSession,
    redeemMakeupSession,
    showSnackbar,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const isStaff = role === UserRole.TEACHER || role === UserRole.SECRETARY;
  const authHeaders = useMemo(
    () => ({
      "Content-Type": "application/json",
      "x-kashkool-role": role,
      "x-kashkool-actor": userLabel || "teacher-1",
    }),
    [role, userLabel]
  );

  const [auditLogs, setAuditLogs] = useState<AuditLogEntryDto[]>([]);
  const [devices, setDevices] = useState<DeviceBindingDto[]>([]);
  const [loadingSecurity, setLoadingSecurity] = useState(false);

  // Makeup session modal
  const [makeupOpen, setMakeupOpen] = useState(false);
  const [mkStudentId, setMkStudentId] = useState(students[0]?.id ?? "");
  const [mkGroupId, setMkGroupId] = useState(groups[1]?.id ?? groups[0]?.id ?? "");
  const [mkDateLabel, setMkDateLabel] = useState("");
  const [mkNote, setMkNote] = useState("");
  const [mkError, setMkError] = useState<string | null>(null);

  const loadSecurityFeed = useCallback(async () => {
    if (!isStaff) return;
    setLoadingSecurity(true);
    try {
      const [audRes, devRes] = await Promise.all([
        fetch("/api/security/audit-logs?limit=25", { headers: authHeaders }),
        fetch("/api/security/devices", { headers: authHeaders }),
      ]);
      if (audRes.ok) {
        const audData = (await audRes.json()) as { logs?: AuditLogEntryDto[] };
        setAuditLogs(audData.logs ?? []);
      }
      if (devRes.ok) {
        const devData = (await devRes.json()) as { devices?: DeviceBindingDto[] };
        setDevices(devData.devices ?? []);
      }
    } finally {
      setLoadingSecurity(false);
    }
  }, [authHeaders, isStaff]);

  useEffect(() => {
    void loadSecurityFeed();
  }, [loadSecurityFeed]);

  const handleRevokeDevice = async (deviceId: string) => {
    try {
      const res = await fetch("/api/security/device/revoke", {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify({ deviceId }),
      });
      if (!res.ok) throw new Error("Revoke failed");
      showSnackbar(isAr ? "تم إيقاف الجلسة عن بُعد" : "Device session revoked");
      void loadSecurityFeed();
    } catch (err) {
      showSnackbar(err instanceof Error ? err.message : "Error revoking device");
    }
  };

  return (
    <div className="space-y-4">
      {/* Makeup Sessions (حصة تعويضية) */}
      <CosmicCard tone="amber" className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <CalendarClock className="w-4 h-4 text-[#FBBF24]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("makeup_title")}</h3>
          </div>
          {isStaff && (
            <CosmicButton
              type="button"
              tone="amber"
              variant="subtle"
              className="text-xs py-1 px-2.5"
              icon={<Plus className="w-3.5 h-3.5" />}
              onClick={() => {
                setMkError(null);
                setMakeupOpen(true);
              }}
            >
              {tr("makeup_issue_cta")}
            </CosmicButton>
          )}
        </div>

        <div className="space-y-2">
          {makeupSessions.map((mk) => {
            const targetGrp = groups.find((g) => g.id === mk.toGroupId);
            return (
              <div
                key={mk.id}
                className="rounded-xl bg-[#0A0F1C]/70 border border-white/10 p-3 flex flex-wrap items-center justify-between gap-2 text-xs"
              >
                <div className="space-y-0.5">
                  <p className="font-bold text-[#F1F5F9]">
                    {isAr ? mk.studentNameAr : mk.studentNameEn} →{" "}
                    {targetGrp ? (isAr ? targetGrp.nameAr : targetGrp.nameEn) : mk.toGroupId}
                  </p>
                  <p className="text-[#94A3B8]">
                    {mk.scheduledDateLabel} · {mk.note}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <StatusBadge
                    tone={mk.status === "redeemed" ? "emerald" : "amber"}
                    label={
                      mk.status === "redeemed"
                        ? isAr
                          ? "تم الحضور"
                          : "Redeemed"
                        : isAr
                          ? "مجدولة"
                          : "Scheduled"
                    }
                  />
                  {mk.status === "scheduled" && isStaff && (
                    <CosmicButton
                      type="button"
                      tone="emerald"
                      variant="outline"
                      className="text-xs py-1 px-2.5"
                      icon={<CheckCircle2 className="w-3.5 h-3.5" />}
                      onClick={() => redeemMakeupSession(mk.id)}
                    >
                      {tr("makeup_redeem_cta")}
                    </CosmicButton>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </CosmicCard>

      {/* Aegis Security Ledger & Device Bindings (Staff Only) */}
      {isStaff && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Device Bindings */}
          <CosmicCard tone="cyan" className="space-y-3">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Laptop className="w-4 h-4 text-[#38BDF8]" />
                <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("aegis_devices_title")}</h3>
              </div>
              <CosmicButton
                type="button"
                tone="slate"
                variant="subtle"
                loading={loadingSecurity}
                className="text-xs py-1 px-2"
                icon={<RefreshCw className="w-3.5 h-3.5" />}
                onClick={() => void loadSecurityFeed()}
              >
                {isAr ? "تحديث" : "Refresh"}
              </CosmicButton>
            </div>

            {devices.length === 0 ? (
              <p className="text-xs text-[#94A3B8]">
                {isAr
                  ? "تظهر الأجهزة الموثقة هنا تلقائياً عند دخول الطلاب لقاعة الامتحان أو المحاضرات."
                  : "Bound student devices appear here automatically upon session check-in."}
              </p>
            ) : (
              <div className="space-y-2 max-h-72 overflow-y-auto">
                {devices.map((dev) => (
                  <div
                    key={dev.id}
                    className="rounded-xl bg-[#0A0F1C]/75 border border-white/10 p-2.5 flex flex-wrap items-center justify-between gap-2 text-xs"
                  >
                    <div className="space-y-0.5 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span className="font-bold text-[#F1F5F9]">{dev.actorId}</span>
                        {dev.suspiciousVelocity && (
                          <StatusBadge
                            tone="crimson"
                            label={isAr ? "تعدد أجهزة" : "Velocity Alert"}
                          />
                        )}
                        {dev.isRevoked && (
                          <StatusBadge tone="slate" label={isAr ? "موقوف" : "Revoked"} />
                        )}
                      </div>
                      <p dir="ltr" className="text-[11px] font-mono-tabular text-[#94A3B8] truncate">
                        {dev.deviceLabel} · {dev.deviceFingerprint}
                      </p>
                    </div>
                    {!dev.isRevoked && (
                      <CosmicButton
                        type="button"
                        tone="crimson"
                        variant="outline"
                        className="text-xs py-1 px-2"
                        icon={<Trash2 className="w-3 h-3" />}
                        onClick={() => void handleRevokeDevice(dev.id)}
                      >
                        {tr("aegis_revoke_cta")}
                      </CosmicButton>
                    )}
                  </div>
                ))}
              </div>
            )}
          </CosmicCard>

          {/* Immutable Security Audit Ledger */}
          <CosmicCard tone="purple" className="space-y-3">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <Shield className="w-4 h-4 text-[#A78BFA]" />
                <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("aegis_audit_title")}</h3>
              </div>
              <StatusBadge tone="emerald" label="APPEND-ONLY" />
            </div>

            <div className="space-y-2 max-h-72 overflow-y-auto">
              {auditLogs.map((log) => {
                const isAlert =
                  log.action.includes("REPLAY") ||
                  log.action.includes("VIOLATION") ||
                  log.action.includes("LOCKED") ||
                  log.action.includes("VELOCITY");
                return (
                  <div
                    key={log.id}
                    className={`rounded-xl border p-2.5 text-xs space-y-1 ${
                      isAlert
                        ? "bg-[#F87171]/10 border-[#F87171]/35"
                        : "bg-[#0A0F1C]/75 border-white/10"
                    }`}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-mono-tabular font-bold text-[#38BDF8] flex items-center gap-1">
                        {isAlert && <ShieldAlert className="w-3.5 h-3.5 text-[#F87171]" />}
                        {log.action}
                      </span>
                      <span className="text-[11px] text-[#94A3B8] tabular-nums">
                        {formatShortTime(log.createdAtMillis, language)}
                      </span>
                    </div>
                    <p className="text-[#94A3B8]">{log.detail}</p>
                  </div>
                );
              })}
            </div>
          </CosmicCard>
        </div>
      )}

      {/* Issue Makeup Pass Modal */}
      <ModalDialog open={makeupOpen} title={tr("makeup_issue_cta")} onClose={() => setMakeupOpen(false)}>
        <div className="space-y-3">
          {mkError && (
            <div className="flex items-center gap-2 rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
              <AlertTriangle className="w-4 h-4" />
              <span>{mkError}</span>
            </div>
          )}
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">
              {isAr ? "الطالب" : "Student"}
            </label>
            <select
              value={mkStudentId}
              onChange={(e) => setMkStudentId(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            >
              {students.map((st) => (
                <option key={st.id} value={st.id}>
                  {isAr ? st.nameAr : st.nameEn}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">
              {isAr ? "المجموعة التعويضية المستضيفة" : "Target Makeup Group"}
            </label>
            <select
              value={mkGroupId}
              onChange={(e) => setMkGroupId(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            >
              {groups.map((g) => (
                <option key={g.id} value={g.id}>
                  {isAr ? g.nameAr : g.nameEn} ({isAr ? g.scheduleAr : g.scheduleEn})
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">
              {isAr ? "موعد الحضور التعويضي" : "Scheduled Date / Slot"}
            </label>
            <input
              type="text"
              value={mkDateLabel}
              onChange={(e) => setMkDateLabel(e.target.value)}
              placeholder={isAr ? "غداً ٦:٠٠ م" : "Tomorrow 6:00 PM"}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("note_label")}</label>
            <input
              type="text"
              value={mkNote}
              onChange={(e) => setMkNote(e.target.value)}
              placeholder={isAr ? "تعويض غياب بعذر" : "Excused absence makeup"}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <CosmicButton
            type="button"
            tone="amber"
            className="w-full"
            onClick={() => {
              const targetStu = students.find((s) => s.id === mkStudentId);
              if (!targetStu || !mkGroupId || !mkDateLabel.trim()) {
                setMkError(tr("validation_required"));
                return;
              }
              issueMakeupSession(targetStu, mkGroupId, mkDateLabel, mkNote);
              setMkDateLabel("");
              setMkNote("");
              setMakeupOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>
    </div>
  );
};
