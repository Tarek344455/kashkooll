import React, { useState } from "react";
import { Eye, EyeOff, Globe, KeyRound, Lock, Mail, Phone, QrCode, ShieldCheck } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage, AuthMode } from "../types/kashkool";
import { CosmicButton, CosmicCard, StatusBadge } from "../components/CosmicUi";

export const LoginScreen: React.FC = () => {
  const {
    language,
    auth,
    supabaseConfigured,
    toggleLanguage,
    setAuthMode,
    signInWithPassword,
    requestOtp,
    verifyOtp,
    activateWithQr,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const [inputValue, setInputValue] = useState("");
  const [passwordValue, setPasswordValue] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [otpValue, setOtpValue] = useState("");

  const modes: Array<{ mode: AuthMode; labelKey: string; icon: React.ReactNode }> = [
    { mode: AuthMode.EMAIL, labelKey: "mode_email", icon: <Mail className="w-4 h-4" /> },
    { mode: AuthMode.PHONE, labelKey: "mode_phone", icon: <Phone className="w-4 h-4" /> },
    { mode: AuthMode.QR, labelKey: "mode_qr", icon: <QrCode className="w-4 h-4" /> },
  ];

  const handleModeChange = (mode: AuthMode) => {
    setAuthMode(mode);
    setInputValue("");
    setPasswordValue("");
    setOtpValue("");
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (auth.mode === AuthMode.QR) {
      activateWithQr(inputValue);
    } else if (auth.mode === AuthMode.EMAIL) {
      signInWithPassword(inputValue, passwordValue);
    } else if (auth.awaitingOtp) {
      verifyOtp(otpValue);
    } else {
      requestOtp(inputValue);
    }
  };

  return (
    <div className="min-h-screen text-[#F1F5F9] flex flex-col justify-between p-4 sm:p-6">
      <div className="relative z-10 w-full max-w-lg mx-auto flex-1 flex flex-col justify-center space-y-5 py-6">
        {/* Header Bar */}
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-[#38BDF8] to-[#0284C7] flex items-center justify-center text-[#070B19] font-extrabold text-xl shadow-[0_0_24px_rgba(56,189,248,0.38)]">
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
        <CosmicCard tone="cyan" floatIndex={0} className="space-y-4 p-5">
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
                <input
                  type="text"
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  placeholder={tr("qr_code_hint")}
                  dir="ltr"
                  className="w-full rounded-xl bg-[#0A0F1C]/90 border border-white/15 px-3.5 py-2.5 text-sm font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
                />
              </div>
            ) : auth.mode === AuthMode.EMAIL ? (
              <div className="space-y-3">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold text-[#94A3B8]">{tr("email_label")}</label>
                  <input
                    type="email"
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    placeholder={tr("email_hint")}
                    dir="ltr"
                    className="w-full rounded-xl bg-[#0A0F1C]/90 border border-white/15 px-3.5 py-2.5 text-sm font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold text-[#94A3B8]">
                    {isAr ? "كلمة المرور" : "Password"}
                  </label>
                  <div className="relative">
                    <input
                      type={showPassword ? "text" : "password"}
                      value={passwordValue}
                      onChange={(e) => setPasswordValue(e.target.value)}
                      placeholder="••••••••"
                      dir="ltr"
                      className="w-full rounded-xl bg-[#0A0F1C]/90 border border-white/15 px-3.5 py-2.5 pe-10 text-sm font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((v) => !v)}
                      aria-label={isAr ? "إظهار كلمة المرور" : "Toggle password"}
                      className="absolute inset-y-0 end-2.5 flex items-center text-[#94A3B8] hover:text-[#F1F5F9] cursor-pointer"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
              </div>
            ) : !auth.awaitingOtp ? (
              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-[#94A3B8]">{tr("phone_label")}</label>
                <input
                  type="tel"
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  placeholder={tr("phone_hint")}
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
                  placeholder="000000"
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
              loading={auth.busy}
              className="w-full py-3"
              icon={auth.mode === AuthMode.EMAIL ? <Lock className="w-4 h-4" /> : <KeyRound className="w-4 h-4" />}
            >
              {auth.mode === AuthMode.QR
                ? tr("activate_qr")
                : auth.mode === AuthMode.EMAIL
                  ? isAr
                    ? "تسجيل الدخول"
                    : "Sign In"
                  : auth.awaitingOtp
                    ? tr("verify_code")
                    : tr("send_code")}
            </CosmicButton>
          </form>
        </CosmicCard>

        <div className="flex items-center justify-center gap-2 text-xs text-[#94A3B8]">
          <ShieldCheck className="w-4 h-4 text-[#34D399]" />
          <span>{tr("flag_secure_active")}</span>
        </div>
      </div>
    </div>
  );
};
