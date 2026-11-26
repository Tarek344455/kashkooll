import React, { useMemo, useState } from "react";
import {
  Banknote,
  Camera,
  CheckCircle2,
  Copy,
  MessageSquare,
  Printer,
  QrCode,
  Search,
  ShieldAlert,
  ShieldCheck,
  UserPlus,
  Zap,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { EgyptValidators } from "../core/utils/egyptValidators";
import { copyToClipboard } from "../core/utils/browserUtils";
import { AppLanguage, LedgerKind, QrVerifyStatus, StudentEntity, StudentRiskTier, UserRole } from "../types/kashkool";
import { CosmicButton, CosmicCard, DynamicQrCode, EmptyState, ModalDialog, StatusBadge } from "../components/CosmicUi";
import { SecretaryNoticeModal } from "../components/AiToolkitCards";
import { QrScannerModal } from "../components/QrScannerModal";
import { CommunicationHubPanel } from "../components/AcademicHubPanels";
import { AegisSecurityPanel } from "../components/AegisSecurityPanel";

export const SecretaryDeskScreen: React.FC = () => {
  const {
    language,
    groups,
    students,
    qrToken,
    qrSecondsRemaining,
    rushModeEnabled,
    scannerScanCount,
    lastScanFeedback,
    qrVerificationBanner,
    shiftReconciliation,
    operatingReport,
    generatedQrCode,
    generatedQrStudentName,
    toggleRushMode,
    verifyGateQrToken,
    checkInStudent,
    discreetAllowWithParentNotice,
    recordCashDeskEntry,
    addWalkInStudent,
    toggleStudentBlocked,
    generateQrForStudent,
    dismissGeneratedQr,
    composeSecretaryNotice,
    buildThermalReceipt,
    showSnackbar,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const [search, setSearch] = useState("");
  const [verifyInput, setVerifyInput] = useState("");
  const [scannerOpen, setScannerOpen] = useState(false);

  // Dialog states
  const [walkInOpen, setWalkInOpen] = useState(false);
  const [walkInName, setWalkInName] = useState("");
  const [walkInPhone, setWalkInPhone] = useState("");
  const [walkInGroupId, setWalkInGroupId] = useState(groups[0]?.id ?? "");
  const [walkInTopUp, setWalkInTopUp] = useState("");
  const [walkInError, setWalkInError] = useState<string | null>(null);

  const [collectTarget, setCollectTarget] = useState<StudentEntity | null>(null);
  const [collectKind, setCollectKind] = useState<LedgerKind>(LedgerKind.CASH_TOPUP);
  const [collectAmount, setCollectAmount] = useState("");
  const [collectNote, setCollectNote] = useState("");
  const [collectError, setCollectError] = useState<string | null>(null);

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [receiptOpen, setReceiptOpen] = useState(false);

  const sortedStudents = useMemo(() => {
    const order = operatingReport.priorityStudentIds;
    const query = search.trim().toLowerCase();
    return [...students]
      .sort((a, b) => {
        const ia = order.indexOf(a.id);
        const ib = order.indexOf(b.id);
        return (ia === -1 ? 999 : ia) - (ib === -1 ? 999 : ib);
      })
      .filter((s) => {
        if (!query) return true;
        return (
          s.nameAr.toLowerCase().includes(query) ||
          s.nameEn.toLowerCase().includes(query) ||
          s.phone.toLowerCase().includes(query)
        );
      });
  }, [students, operatingReport.priorityStudentIds, search]);

  const queue = operatingReport.queueDispatch;
  const thermalText = useMemo(() => buildThermalReceipt(), [buildThermalReceipt]);

  return (
    <div className="space-y-4">
      {/* Top Rush & Queue Dispatch Card */}
      <CosmicCard tone={rushModeEnabled ? "amber" : "emerald"} className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-[#EAB308]" />
              <h2 className="text-base font-extrabold text-[#F1F5F9]">{tr("open_desk")}</h2>
            </div>
            <p className="text-xs text-[#94A3B8]">
              {tr("rush_counter_label")}:{" "}
              <span className="font-bold text-[#34D399] tabular-nums">{scannerScanCount}</span> ·{" "}
              {isAr ? "متوسط الانتظار:" : "Est. Wait:"}{" "}
              <span className="font-bold text-[#38BDF8] tabular-nums">{queue.expectedWaitSeconds}s</span>
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <CosmicButton
              type="button"
              tone={rushModeEnabled ? "amber" : "slate"}
              variant={rushModeEnabled ? "solid" : "outline"}
              onClick={toggleRushMode}
              className="text-xs"
            >
              {tr("rush_mode_toggle")}
            </CosmicButton>
            <CosmicButton
              type="button"
              tone="cyan"
              icon={<Camera className="w-4 h-4" />}
              onClick={() => setScannerOpen(true)}
            >
              {tr("open_qr_scanner_cta")}
            </CosmicButton>
          </div>
        </div>

        {/* Last Scan Feedback */}
        {lastScanFeedback && (
          <div
            className={`rounded-xl border px-3.5 py-2.5 flex items-center justify-between gap-2 ${
              lastScanFeedback.status === "valid"
                ? "bg-[#34D399]/14 border-[#34D399]/40 text-[#34D399]"
                : lastScanFeedback.status === "due"
                  ? "bg-[#FBBF24]/14 border-[#FBBF24]/40 text-[#FBBF24]"
                  : "bg-[#F87171]/14 border-[#F87171]/40 text-[#F87171]"
            }`}
          >
            <div className="text-xs sm:text-sm font-bold truncate">
              {lastScanFeedback.studentName}
              {lastScanFeedback.detail ? ` · ${lastScanFeedback.detail}` : ""}
            </div>
            <StatusBadge
              tone={
                lastScanFeedback.status === "valid"
                  ? "emerald"
                  : lastScanFeedback.status === "due"
                    ? "amber"
                    : "crimson"
              }
              label={
                lastScanFeedback.status === "valid"
                  ? tr("scan_valid")
                  : lastScanFeedback.status === "due"
                    ? tr("scan_due")
                    : tr("scan_blocked")
              }
            />
          </div>
        )}
      </CosmicCard>

      {/* Dynamic Session Gate QR + Verifier */}
      <CosmicCard tone="cyan" className="space-y-3">
        <div className="flex flex-col sm:flex-row items-center gap-4">
          <DynamicQrCode payload={qrToken} size={118} />
          <div className="flex-1 w-full space-y-2.5">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <p className="text-sm font-bold text-[#F1F5F9]">{tr("dynamic_qr_title")}</p>
              <span className="text-xs font-bold text-[#38BDF8] tabular-nums">
                {tr("rotates_in")} {qrSecondsRemaining}s
              </span>
            </div>
            <p className="text-xs font-mono-tabular text-[#94A3B8] break-all bg-[#0A0F1C]/70 rounded-lg px-2.5 py-1.5 border border-white/10" dir="ltr">
              {qrToken}
            </p>
            <div className="flex flex-wrap gap-2">
              <input
                type="text"
                value={verifyInput}
                onChange={(e) => setVerifyInput(e.target.value)}
                placeholder={tr("verify_qr_hint")}
                dir="ltr"
                className="flex-1 min-w-[180px] rounded-xl bg-[#0A0F1C]/80 border border-white/15 px-3 py-2 text-xs font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
              />
              <CosmicButton
                type="button"
                tone="cyan"
                variant="outline"
                className="text-xs"
                onClick={() => {
                  verifyGateQrToken(verifyInput);
                  setVerifyInput("");
                }}
              >
                {tr("verify_qr_cta")}
              </CosmicButton>
              <CosmicButton
                type="button"
                tone="gold"
                variant="subtle"
                className="text-xs"
                onClick={() => verifyGateQrToken(qrToken)}
              >
                {tr("verify_qr_use_live")}
              </CosmicButton>
            </div>
            {qrVerificationBanner && (
              <div
                className={`text-xs font-semibold rounded-lg px-3 py-1.5 border ${
                  qrVerificationBanner.status === QrVerifyStatus.VALID
                    ? "bg-[#34D399]/12 border-[#34D399]/35 text-[#34D399]"
                    : qrVerificationBanner.status === QrVerifyStatus.EXPIRED
                      ? "bg-[#FBBF24]/12 border-[#FBBF24]/35 text-[#FBBF24]"
                      : "bg-[#F87171]/12 border-[#F87171]/35 text-[#F87171]"
                }`}
              >
                {qrVerificationBanner.status === QrVerifyStatus.VALID
                  ? tr("qr_result_valid")
                  : qrVerificationBanner.status === QrVerifyStatus.EXPIRED
                    ? tr("qr_result_expired")
                    : tr("qr_result_invalid")}
              </div>
            )}
          </div>
        </div>
      </CosmicCard>

      {/* Action Buttons Row + Search */}
      <div className="flex flex-wrap items-center gap-2">
        <CosmicButton
          type="button"
          tone="emerald"
          icon={<UserPlus className="w-4 h-4" />}
          onClick={() => {
            setWalkInGroupId(operatingReport.groupAllocation.optimalWalkInGroupId ?? groups[0]?.id ?? "");
            setWalkInError(null);
            setWalkInOpen(true);
          }}
        >
          {tr("add_walkin_cta")}
        </CosmicButton>
        <CosmicButton
          type="button"
          tone="gold"
          variant="outline"
          icon={<Banknote className="w-4 h-4" />}
          onClick={() => setDrawerOpen(true)}
        >
          {tr("drawer_reconcile_cta")}
        </CosmicButton>
        <CosmicButton
          type="button"
          tone="cyan"
          variant="outline"
          icon={<Printer className="w-4 h-4" />}
          onClick={() => setReceiptOpen(true)}
        >
          {tr("print_batch_receipt")}
        </CosmicButton>
      </div>

      <div className="relative">
        <Search className="w-4 h-4 text-[#94A3B8] absolute top-1/2 -translate-y-1/2 start-3.5" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={tr("search_student")}
          className="w-full rounded-xl bg-[#141D2F] border border-white/15 ps-10 pe-4 py-2.5 text-sm text-[#F1F5F9] placeholder-[#94A3B8]/60 focus:outline-none focus:border-[#38BDF8]"
        />
      </div>

      {/* Students List */}
      {sortedStudents.length === 0 ? (
        <EmptyState icon={<Search className="w-8 h-8" />} message={tr("empty_students")} />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
          {sortedStudents.map((st) => {
            const name = isAr ? st.nameAr : st.nameEn;
            const profile = operatingReport.studentProfiles[st.id];
            const statusTone = st.isBlocked ? "crimson" : st.dueBalancePiasters > 0 ? "amber" : "emerald";
            const statusLabel = st.isBlocked
              ? tr("scan_blocked")
              : st.dueBalancePiasters > 0
                ? tr("scan_due")
                : tr("scan_valid");

            return (
              <CosmicCard key={st.id} tone={statusTone} className="space-y-3">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="text-sm font-bold text-[#F1F5F9]">{name}</h3>
                      {profile && (
                        <StatusBadge
                          tone={
                            profile.riskTier === StudentRiskTier.CRITICAL
                              ? "crimson"
                              : profile.riskTier === StudentRiskTier.WATCH
                                ? "amber"
                                : "emerald"
                          }
                          label={
                            profile.riskTier === StudentRiskTier.CRITICAL
                              ? tr("or_risk_critical")
                              : profile.riskTier === StudentRiskTier.WATCH
                                ? tr("or_risk_watch")
                                : tr("or_risk_healthy")
                          }
                        />
                      )}
                    </div>
                    <p className="text-xs text-[#94A3B8] font-mono-tabular mt-0.5" dir="ltr">
                      {st.phone}
                    </p>
                  </div>
                  <StatusBadge tone={statusTone} label={statusLabel} />
                </div>

                <div className="grid grid-cols-2 gap-2 text-xs">
                  <div className="rounded-lg bg-[#0A0F1C]/60 px-2.5 py-1.5">
                    <span className="text-[#94A3B8]">{tr("wallet_balance")}: </span>
                    <span className="font-bold text-[#34D399] tabular-nums">
                      {EgyptValidators.formatPiasters(st.walletBalancePiasters, language)}
                    </span>
                  </div>
                  <div className="rounded-lg bg-[#0A0F1C]/60 px-2.5 py-1.5">
                    <span className="text-[#94A3B8]">{tr("due_balance")}: </span>
                    <span
                      className={`font-bold tabular-nums ${
                        st.dueBalancePiasters > 0 ? "text-[#FBBF24]" : "text-[#94A3B8]"
                      }`}
                    >
                      {EgyptValidators.formatPiasters(st.dueBalancePiasters, language)}
                    </span>
                  </div>
                </div>

                <div className="flex flex-wrap gap-2">
                  <CosmicButton
                    type="button"
                    tone="emerald"
                    className="text-xs py-1.5 px-3"
                    icon={<CheckCircle2 className="w-3.5 h-3.5" />}
                    onClick={() => checkInStudent(st)}
                  >
                    {tr("tap_to_checkin")}
                  </CosmicButton>

                  <CosmicButton
                    type="button"
                    tone="cyan"
                    variant="outline"
                    className="text-xs py-1.5 px-3"
                    icon={<Banknote className="w-3.5 h-3.5" />}
                    onClick={() => {
                      setCollectTarget(st);
                      setCollectKind(
                        st.dueBalancePiasters > 0 ? LedgerKind.PARTIAL_INSTALLMENT : LedgerKind.CASH_TOPUP
                      );
                      setCollectAmount("");
                      setCollectNote("");
                      setCollectError(null);
                    }}
                  >
                    {tr("collect_cash")}
                  </CosmicButton>

                  {st.dueBalancePiasters > 0 && !st.isBlocked && (
                    <CosmicButton
                      type="button"
                      tone="amber"
                      variant="subtle"
                      className="text-xs py-1.5 px-2.5"
                      onClick={() => discreetAllowWithParentNotice(st)}
                    >
                      {tr("discreet_due_allow")}
                    </CosmicButton>
                  )}

                  <CosmicButton
                    type="button"
                    tone="slate"
                    variant="subtle"
                    className="text-xs py-1.5 px-2.5"
                    icon={<QrCode className="w-3.5 h-3.5" />}
                    onClick={() => generateQrForStudent(st)}
                  >
                    {tr("generate_qr")}
                  </CosmicButton>

                  <CosmicButton
                    type="button"
                    tone="purple"
                    variant="subtle"
                    className="text-xs py-1.5 px-2.5"
                    icon={<MessageSquare className="w-3.5 h-3.5" />}
                    onClick={() => void composeSecretaryNotice(st)}
                  >
                    {tr("draft_notice_cta")}
                  </CosmicButton>

                  <CosmicButton
                    type="button"
                    tone={st.isBlocked ? "emerald" : "crimson"}
                    variant="outline"
                    className="text-xs py-1.5 px-2.5"
                    icon={st.isBlocked ? <ShieldCheck className="w-3.5 h-3.5" /> : <ShieldAlert className="w-3.5 h-3.5" />}
                    onClick={() => toggleStudentBlocked(st)}
                  >
                    {st.isBlocked ? tr("unblock_student") : tr("block_student")}
                  </CosmicButton>
                </div>
              </CosmicCard>
            );
          })}
        </div>
      )}

      {/* Makeups, Announcements, Tickets & Security Feed */}
      <AegisSecurityPanel role={UserRole.SECRETARY} />
      <CommunicationHubPanel role={UserRole.SECRETARY} />

      {/* QR Camera Scanner Modal */}
      <QrScannerModal open={scannerOpen} onClose={() => setScannerOpen(false)} />

      {/* Secretary Notice Modal */}
      <SecretaryNoticeModal />

      {/* Walk-In Student Modal */}
      <ModalDialog open={walkInOpen} title={tr("walkin_dialog_title")} onClose={() => setWalkInOpen(false)}>
        <div className="space-y-3">
          {walkInError && (
            <div className="rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
              {walkInError}
            </div>
          )}
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("walkin_name")}</label>
            <input
              type="text"
              value={walkInName}
              onChange={(e) => setWalkInName(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("phone_label")}</label>
            <input
              type="tel"
              value={walkInPhone}
              onChange={(e) => setWalkInPhone(e.target.value)}
              placeholder="+2010..."
              dir="ltr"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">
              {tr("groups_title")} ({tr("or_best_fit_group")})
            </label>
            <select
              value={walkInGroupId}
              onChange={(e) => setWalkInGroupId(e.target.value)}
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
            >
              {groups.map((g) => (
                <option key={g.id} value={g.id}>
                  {isAr ? g.nameAr : g.nameEn} ({g.enrolled}/{g.capacity})
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("walkin_topup")}</label>
            <input
              type="number"
              value={walkInTopUp}
              onChange={(e) => setWalkInTopUp(e.target.value)}
              dir="ltr"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <CosmicButton
            type="button"
            tone="emerald"
            className="w-full"
            onClick={() => {
              if (!walkInName.trim() || !EgyptValidators.normalizeEgyptianPhone(walkInPhone)) {
                setWalkInError(tr("err_invalid_phone"));
                return;
              }
              addWalkInStudent(walkInName, walkInPhone, walkInGroupId, walkInTopUp);
              setWalkInError(null);
              setWalkInName("");
              setWalkInPhone("");
              setWalkInTopUp("");
              setWalkInOpen(false);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Collect Payment Modal */}
      <ModalDialog
        open={Boolean(collectTarget)}
        title={collectTarget ? `${tr("collect_cash")} · ${isAr ? collectTarget.nameAr : collectTarget.nameEn}` : ""}
        onClose={() => setCollectTarget(null)}
      >
        {collectTarget && (
          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-2">
              {[
                { kind: LedgerKind.CASH_TOPUP, labelKey: "cash_topup" },
                { kind: LedgerKind.PARTIAL_INSTALLMENT, labelKey: "partial_installment" },
                { kind: LedgerKind.BOOK_RESERVATION, labelKey: "book_reservation" },
                { kind: LedgerKind.DISCOUNT, labelKey: "teacher_discount" },
              ].map((opt) => (
                <button
                  key={opt.kind}
                  type="button"
                  onClick={() => setCollectKind(opt.kind)}
                  className={`rounded-xl border px-3 py-2 text-xs font-bold cursor-pointer ${
                    collectKind === opt.kind
                      ? "bg-[#38BDF8]/18 border-[#38BDF8]/60 text-[#38BDF8]"
                      : "bg-[#0A0F1C] border-white/10 text-[#94A3B8]"
                  }`}
                >
                  {tr(opt.labelKey)}
                </button>
              ))}
            </div>

            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="text-xs text-[#94A3B8]">{tr("amount_egp")}</label>
                {operatingReport.studentProfiles[collectTarget.id]?.recommendedInstallmentPiasters ? (
                  <button
                    type="button"
                    onClick={() =>
                      setCollectAmount(
                        String(
                          Math.round(
                            operatingReport.studentProfiles[collectTarget.id].recommendedInstallmentPiasters / 100
                          )
                        )
                      )
                    }
                    className="text-xs font-semibold text-[#38BDF8] hover:underline cursor-pointer"
                  >
                    {tr("or_fill_suggested_amount")}
                  </button>
                ) : null}
              </div>
              <input
                type="number"
                value={collectAmount}
                onChange={(e) => setCollectAmount(e.target.value)}
                dir="ltr"
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
              />
            </div>

            <div>
              <label className="block text-xs text-[#94A3B8] mb-1">{tr("note_label")}</label>
              <input
                type="text"
                value={collectNote}
                onChange={(e) => setCollectNote(e.target.value)}
                className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
              />
            </div>

            {collectError && (
              <div className="rounded-xl bg-[#F87171]/15 border border-[#F87171]/40 px-3 py-2 text-xs text-[#F87171]">
                {collectError}
              </div>
            )}

            <CosmicButton
              type="button"
              tone="emerald"
              className="w-full"
              onClick={() => {
                if (!EgyptValidators.egpStringToPiasters(collectAmount)) {
                  setCollectError(tr("validation_required"));
                  return;
                }
                recordCashDeskEntry(collectTarget, collectKind, collectAmount, collectNote);
                setCollectError(null);
                setCollectTarget(null);
              }}
            >
              {tr("submit")}
            </CosmicButton>
          </div>
        )}
      </ModalDialog>

      {/* Drawer Reconciliation Modal */}
      <ModalDialog open={drawerOpen} title={tr("drawer_reconcile_title")} onClose={() => setDrawerOpen(false)}>
        <div className="space-y-2.5 text-sm">
          <div className="flex justify-between rounded-xl bg-[#0A0F1C] p-3">
            <span className="text-[#94A3B8]">{tr("drawer_cash_total")}</span>
            <span className="font-bold text-[#34D399] tabular-nums">
              {EgyptValidators.formatPiasters(shiftReconciliation.cashCollectedPiasters, language)}
            </span>
          </div>
          <div className="flex justify-between rounded-xl bg-[#0A0F1C] p-3">
            <span className="text-[#94A3B8]">{tr("drawer_electronic_total")}</span>
            <span className="font-bold text-[#38BDF8] tabular-nums">
              {EgyptValidators.formatPiasters(shiftReconciliation.electronicTransfersPiasters, language)}
            </span>
          </div>
          <div className="flex justify-between rounded-xl bg-[#0A0F1C] p-3">
            <span className="text-[#94A3B8]">{tr("drawer_void_total")}</span>
            <span className="font-bold text-[#F87171] tabular-nums">
              {EgyptValidators.formatPiasters(shiftReconciliation.voidedTotalPiasters, language)}
            </span>
          </div>
          <div className="flex justify-between rounded-xl bg-[#EAB308]/12 border border-[#EAB308]/35 p-3">
            <span className="font-bold text-[#F1F5F9]">{tr("drawer_net_total")}</span>
            <span className="font-extrabold text-[#EAB308] tabular-nums">
              {EgyptValidators.formatPiasters(shiftReconciliation.netDrawerCashPiasters, language)}
            </span>
          </div>
        </div>
      </ModalDialog>

      {/* Thermal Shift Receipt Modal */}
      <ModalDialog open={receiptOpen} title={tr("batch_receipt_title")} onClose={() => setReceiptOpen(false)}>
        <div className="space-y-3">
          <pre className="rounded-xl bg-[#0A0F1C] border border-white/10 p-3.5 text-xs font-mono-tabular text-[#F1F5F9] whitespace-pre-wrap overflow-x-auto">
            {thermalText}
          </pre>
          <CosmicButton
            type="button"
            tone="cyan"
            className="w-full"
            icon={<Copy className="w-4 h-4" />}
            onClick={async () => {
              await copyToClipboard(thermalText);
              showSnackbar(isAr ? "تم نسخ إيصال الوردية" : "Shift receipt copied");
            }}
          >
            {tr("copy_receipt")}
          </CosmicButton>
        </div>
      </ModalDialog>

      {/* Generated Student Activation QR Modal */}
      <ModalDialog
        open={Boolean(generatedQrCode)}
        title={tr("qr_generated_title")}
        onClose={dismissGeneratedQr}
      >
        {generatedQrCode && (
          <div className="flex flex-col items-center gap-4 text-center py-2">
            {generatedQrStudentName && (
              <p className="text-base font-bold text-[#F1F5F9]">{generatedQrStudentName}</p>
            )}
            <DynamicQrCode payload={generatedQrCode} size={200} />
            <p className="text-base font-extrabold font-mono-tabular text-[#38BDF8]" dir="ltr">
              {generatedQrCode}
            </p>
            <p className="text-xs text-[#94A3B8]">{tr("qr_generated_hint")}</p>
            <CosmicButton
              type="button"
              tone="cyan"
              variant="outline"
              icon={<Copy className="w-4 h-4" />}
              onClick={async () => {
                await copyToClipboard(generatedQrCode);
                showSnackbar(tr("student_qr_copied"));
              }}
            >
              {tr("copy_text")}
            </CosmicButton>
          </div>
        )}
      </ModalDialog>
    </div>
  );
};
