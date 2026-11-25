import React, { useState } from "react";
import { ChevronDown, ChevronUp, Globe, KeyRound, Mail, Phone, QrCode, ShieldCheck, Users } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage, AuthMode, UserRole } from "../types/kashkool";
import { CosmicButton, CosmicCard, StatusBadge } from "../components/CosmicUi";

export const LoginScreen: React.FC = () => {
  const {
    language,
    auth,
    supabaseConfigured,
    toggleLanguage,
    setAuthMode,
    requestOtp,
    verifyOtp,
    activateWithQr,
    enterOfflineWorkspace,
    tr,
  } = useKashkool();

  const [inputValue, setInputValue] = useState("");
  const [otpValue, setOtpValue] = useState("");
  const [previewExpanded, setPreviewExpanded] = useState(true);

  const modes: Array<{ mode: AuthMode; labelKey: string; icon: React.ReactNode }> = [
    { mode: AuthMode.QR, labelKey: "mode_qr", icon: <QrCode className="w-4 h-4" /> },
    { mode: AuthMode.EMAIL, labelKey: "mode_email", icon: <Mail className="w-4 h-4" /> },
    { mode: AuthMode.PHONE, labelKey: "mode_phone", icon: <Phone className="w-4 h-4" /> },
  ];

  const handleModeChange = (mode: AuthMode) => {
    setAuthMode(mode);
    setInputValue("");
    setOtpValue("");
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (auth.mode === AuthMode.QR) {
      activateWithQr(inputValue);
    } else if (auth.awaitingOtp) {
      verifyOtp(otpValue);
    } else {
      requestOtp(inputValue);
    }
  };

  return (
    <div className="min-h-screen bg-[#0A0F1C] text-[#F1F5F9] flex flex-col justify-between p-4 sm:p-6">
      {/* Subtle Top Cosmic Ambient Glow */}
      <div className="pointer-events-none fixed inset-x-0 top-0 h-72 bg-[radial-gradient(ellipse_at_top,rgba(56,189,248,0.14),transparent_70%)]" />

      <div className="relative z-10 w-full max-w-xl mx-auto flex-1 flex flex-col justify-center space-y-5 py-6">
        {/* Header Bar */}
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-[#38BDF8] to-[#0284C7] flex items-center justify-center text-[#0A0F1C] font-extrabold text-xl shadow-[0_0_24px_rgba(56,189,248,0.35)]">
              ك
            </div>
            <div>
              <h1 className="text-xl font-extrabold tracking-tight text-[#F1F5F9]">{tr("app_title")}</h1>
              <p className="text-xs text-[#94A3B8]">{tr("zero_cost_badge")}</p>
            </div>
          </div>

          <CosmicButton
            type="button"
            variant="outline"
            tone="cyan"
            onClick={toggleLanguage}
            icon={<Globe className="w-4 h-4" />}
            className="text-xs py-2 px-3"
          >
            {language === AppLanguage.AR ? "English" : "العربية"}
          </CosmicButton>
        </div>

        {/* Hero Title */}
        <div className="space-y-2">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge
              tone="emerald"
              label={supabaseConfigured ? tr("backend_ready") : tr("backend_offline")}
            />
          </div>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-[#F1F5F9]">{tr("welcome")}</h2>
          <p className="text-sm text-[#94A3B8]">{tr("subtitle_cosmic")}</p>
        </div>

        {/* Main Auth Card */}
        <CosmicCard tone="cyan" className="space-y-4 p-5">
          {/* Mode Tabs */}
          <div className="grid grid-cols-3 gap-2">
            {modes.map((m) => {
              const active = auth.mode === m.mode;
              return (
                <button
                  key={m.mode}
                  type="button"
                  onClick={() => handleModeChange(m.mode)}
                  className={`flex items-center justify-center gap-1.5 rounded-xl border px-2.5 py-2.5 text-xs font-bold transition-all cursor-pointer ${
                    active
                      ? "bg-[#38BDF8]/18 border-[#38BDF8]/60 text-[#38BDF8]"
                      : "bg-[#1B263B]/70 border-white/10 text-[#94A3B8] hover:text-[#F1F5F9]"
                  }`}
                >
                  {m.icon}
                  <span className="truncate">{tr(m.labelKey)}</span>
                </button>
              );
            })}
          </div>

          <form onSubmit={handleSubmit} className="space-y-3.5">
            {auth.mode === AuthMode.QR ? (
              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-[#94A3B8]">{tr("qr_code_label")}</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    placeholder={tr("qr_code_hint")}
                    dir="ltr"
                    className="flex-1 rounded-xl bg-[#0A0F1C]/90 border border-white/15 px-3.5 py-2.5 text-sm font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
                  />
                  <CosmicButton
                    type="button"
                    variant="subtle"
                    tone="gold"
                    className="text-xs px-3"
                    onClick={() => setInputValue("KSH2026A")}
                  >
                    KSH2026A
                  </CosmicButton>
                </div>
              </div>
            ) : !auth.awaitingOtp ? (
              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-[#94A3B8]">
                  {auth.mode === AuthMode.EMAIL ? tr("email_label") : tr("phone_label")}
                </label>
                <input
                  type={auth.mode === AuthMode.EMAIL ? "email" : "tel"}
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  placeholder={auth.mode === AuthMode.EMAIL ? tr("email_hint") : tr("phone_hint")}
                  dir="ltr"
                  className="w-full rounded-xl bg-[#0A0F1C]/90 border border-white/15 px-3.5 py-2.5 text-sm font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
                />
              </div>
            ) : (
              <div className="space-y-2">
                <div className="flex items-center justify-between gap-2 text-xs text-[#94A3B8]">
                  <span className="font-mono-tabular" dir="ltr">
                    {auth.identifier}
                  </span>
                  <button
                    type="button"
                    onClick={() => setAuthMode(auth.mode)}
                    className="text-[#38BDF8] font-semibold hover:underline cursor-pointer"
                  >
                    {tr("change_input")}
                  </button>
                </div>
                <label className="block text-xs font-semibold text-[#94A3B8]">{tr("otp_label")}</label>
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  value={otpValue}
                  onChange={(e) => setOtpValue(e.target.value.replace(/\D/g, "").slice(0, 6))}
                  placeholder="123456"
                  dir="ltr"
                  className="w-full rounded-xl bg-[#0A0F1C]/90 border border-white/15 px-3.5 py-2.5 text-center text-lg tracking-[0.4em] font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/45 focus:outline-none focus:border-[#38BDF8]"
                />
              </div>
            )}

            {auth.errorMessage && (
              <div className="rounded-xl bg-[#F87171]/12 border border-[#F87171]/35 px-3 py-2 text-xs font-medium text-[#F87171]">
                {auth.errorMessage}
              </div>
            )}

            <CosmicButton
              type="submit"
              tone="cyan"
              className="w-full py-3"
              icon={<KeyRound className="w-4 h-4" />}
            >
              {auth.mode === AuthMode.QR
                ? tr("activate_qr")
                : auth.awaitingOtp
                  ? tr("verify_code")
                  : tr("send_code")}
            </CosmicButton>
          </form>
        </CosmicCard>

        {/* Role Preview Card */}
        <CosmicCard tone="slate" className="space-y-3">
          <button
            type="button"
            onClick={() => setPreviewExpanded((v) => !v)}
            className="w-full flex items-center justify-between gap-2 text-start cursor-pointer"
          >
            <div className="flex items-center gap-2">
              <Users className="w-4 h-4 text-[#EAB308]" />
              <span className="text-sm font-bold text-[#F1F5F9]">{tr("login_preview_toggle")}</span>
            </div>
            {previewExpanded ? (
              <ChevronUp className="w-4 h-4 text-[#94A3B8]" />
            ) : (
              <ChevronDown className="w-4 h-4 text-[#94A3B8]" />
            )}
          </button>

          {previewExpanded && (
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 pt-1">
              {(
                [
                  { role: UserRole.STUDENT, key: "role_student", tone: "cyan" },
                  { role: UserRole.SECRETARY, key: "role_secretary", tone: "emerald" },
                  { role: UserRole.TEACHER, key: "role_teacher", tone: "gold" },
                  { role: UserRole.PARENT, key: "role_parent", tone: "purple" },
                ] as const
              ).map((item) => (
                <CosmicButton
                  key={item.role}
                  type="button"
                  tone={item.tone}
                  variant="subtle"
                  onClick={() => enterOfflineWorkspace(item.role)}
                  className="py-2.5 text-xs"
                >
                  {tr(item.key)}
                </CosmicButton>
              ))}
            </div>
          )}
        </CosmicCard>

        <div className="flex items-center justify-center gap-2 text-xs text-[#94A3B8]">
          <ShieldCheck className="w-4 h-4 text-[#34D399]" />
          <span>{tr("flag_secure_active")}</span>
        </div>
      </div>
    </div>
  );
};
