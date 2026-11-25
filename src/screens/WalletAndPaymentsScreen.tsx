import React, { useRef, useState } from "react";
import {
  Ban,
  CheckCircle2,
  Copy,
  ImagePlus,
  Receipt,
  ScanLine,
  Send,
  ShieldCheck,
  Wallet,
} from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { EgyptValidators } from "../core/utils/egyptValidators";
import { copyToClipboard } from "../core/utils/browserUtils";
import { ledgerKindLabel } from "../core/l10n/appStrings";
import { AppLanguage, LedgerKind, SubmissionStatus } from "../types/kashkool";
import { CosmicButton, CosmicCard, ModalDialog, StatusBadge } from "../components/CosmicUi";

export const WalletAndPaymentsScreen: React.FC = () => {
  const {
    language,
    activeStudent,
    channels,
    submissions,
    ledger,
    operatingReport,
    compressedReceipt,
    receiptCompressing,
    receiptScanState,
    compressAndAttachReceipt,
    clearCompressedReceipt,
    scanAttachedReceipt,
    submitPaymentReceipt,
    voidLedgerEntry,
    showSnackbar,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const bestChannelId = operatingReport.channelOptimization?.optimalChannelId ?? channels[0]?.id ?? "";
  const [selectedChannelId, setSelectedChannelId] = useState(bestChannelId);
  const [amountEgp, setAmountEgp] = useState("");
  const [senderRef, setSenderRef] = useState("");

  const [voidTargetId, setVoidTargetId] = useState<string | null>(null);
  const [voidReason, setVoidReason] = useState("");

  const selectedChannel = channels.find((c) => c.id === selectedChannelId) ?? channels[0];

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    await compressAndAttachReceipt(file);
  };

  const handleAutoReadReceipt = async () => {
    await scanAttachedReceipt();
  };

  // Fill fields whenever receiptScanState succeeds
  React.useEffect(() => {
    if (receiptScanState.status === "success") {
      if (receiptScanState.data.amountEgp) setAmountEgp(receiptScanState.data.amountEgp);
      if (receiptScanState.data.referenceNumber) setSenderRef(receiptScanState.data.referenceNumber);
    }
  }, [receiptScanState]);

  return (
    <div className="space-y-5">
      {/* Balance Summary */}
      {activeStudent && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <CosmicCard tone="emerald" className="space-y-1">
            <div className="flex items-center gap-2 text-xs text-[#94A3B8]">
              <Wallet className="w-4 h-4 text-[#34D399]" />
              <span>{tr("wallet_balance")}</span>
            </div>
            <p className="text-2xl font-extrabold text-[#34D399] tabular-nums">
              {EgyptValidators.formatPiasters(activeStudent.walletBalancePiasters, language)}
            </p>
          </CosmicCard>
          <CosmicCard tone={activeStudent.dueBalancePiasters > 0 ? "amber" : "slate"} className="space-y-1">
            <p className="text-xs text-[#94A3B8]">{tr("due_balance")}</p>
            <p
              className={`text-2xl font-extrabold tabular-nums ${
                activeStudent.dueBalancePiasters > 0 ? "text-[#FBBF24]" : "text-[#94A3B8]"
              }`}
            >
              {EgyptValidators.formatPiasters(activeStudent.dueBalancePiasters, language)}
            </p>
          </CosmicCard>
        </div>
      )}

      {/* Payment Channels & Receipt Submission */}
      <CosmicCard tone="cyan" className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("select_channel")}</h3>
          {operatingReport.channelOptimization && (
            <span className="text-xs text-[#34D399]">
              {isAr
                ? operatingReport.channelOptimization.reasonAr
                : operatingReport.channelOptimization.reasonEn}
            </span>
          )}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
          {channels.map((ch) => {
            const active = selectedChannel?.id === ch.id;
            const isBest = operatingReport.channelOptimization?.optimalChannelId === ch.id;
            return (
              <div
                key={ch.id}
                onClick={() => setSelectedChannelId(ch.id)}
                className={`rounded-xl border p-3 space-y-1.5 cursor-pointer transition-colors ${
                  active
                    ? "bg-[#38BDF8]/16 border-[#38BDF8]/60"
                    : "bg-[#0A0F1C]/65 border-white/10 hover:border-white/25"
                }`}
              >
                <div className="flex items-center justify-between gap-1">
                  <span className="text-xs font-bold text-[#F1F5F9]">
                    {isAr ? ch.nameAr : ch.nameEn}
                  </span>
                  {isBest && <StatusBadge tone="emerald" label={tr("or_lowest_fee_pill")} />}
                </div>
                <div className="flex items-center justify-between gap-2">
                  <span className="text-xs font-mono-tabular text-[#38BDF8] truncate" dir="ltr">
                    {ch.accountRef}
                  </span>
                  <button
                    type="button"
                    aria-label="Copy account"
                    onClick={async (e) => {
                      e.stopPropagation();
                      await copyToClipboard(ch.accountRef);
                      showSnackbar(isAr ? "تم نسخ رقم الحساب" : "Account reference copied");
                    }}
                    className="text-[#94A3B8] hover:text-[#F1F5F9] cursor-pointer"
                  >
                    <Copy className="w-3.5 h-3.5" />
                  </button>
                </div>
                <p className="text-[11px] text-[#94A3B8]">
                  {ch.feePiasters === 0
                    ? tr("zero_fee")
                    : EgyptValidators.formatPiasters(ch.feePiasters, language)}
                </p>
              </div>
            );
          })}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="text-xs text-[#94A3B8]">{tr("amount_egp")}</label>
              {operatingReport.channelOptimization?.recommendedAmountPiasters ? (
                <button
                  type="button"
                  onClick={() =>
                    setAmountEgp(
                      String(
                        Math.round(
                          (operatingReport.channelOptimization?.recommendedAmountPiasters ?? 8500) / 100
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
              value={amountEgp}
              onChange={(e) => setAmountEgp(e.target.value)}
              dir="ltr"
              placeholder="250"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
          <div>
            <label className="block text-xs text-[#94A3B8] mb-1">{tr("sender_ref")}</label>
            <input
              type="text"
              value={senderRef}
              onChange={(e) => setSenderRef(e.target.value)}
              dir="ltr"
              placeholder="TRX-884210"
              className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm font-mono-tabular text-[#F1F5F9]"
            />
          </div>
        </div>

        {/* Receipt Photo Upload & Auto-Read */}
        <div className="space-y-2.5">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => void handleFileChange(e)}
          />
          <div className="flex flex-wrap items-center gap-2">
            <CosmicButton
              type="button"
              tone="cyan"
              variant="outline"
              loading={receiptCompressing}
              icon={<ImagePlus className="w-4 h-4" />}
              onClick={() => fileInputRef.current?.click()}
            >
              {tr("attach_receipt")}
            </CosmicButton>

            {compressedReceipt && (
              <CosmicButton
                type="button"
                tone="gold"
                variant="subtle"
                loading={receiptScanState.status === "loading"}
                icon={<ScanLine className="w-4 h-4" />}
                onClick={() => void handleAutoReadReceipt()}
              >
                {tr("scan_receipt_cta")}
              </CosmicButton>
            )}
          </div>

          {compressedReceipt && (
            <div className="flex items-center gap-3 rounded-xl bg-[#0A0F1C]/70 border border-[#34D399]/35 p-2.5">
              <img
                src={compressedReceipt.dataUrl}
                alt="Receipt preview"
                className="w-16 h-16 rounded-lg object-cover border border-white/15"
              />
              <div className="flex-1 min-w-0 text-xs space-y-0.5">
                <p className="font-bold text-[#34D399] flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  {tr("compressed_badge")} (-{compressedReceipt.savingsPercent}%)
                </p>
                <p className="text-[#94A3B8] tabular-nums">
                  {Math.round(compressedReceipt.compressedBytes / 1024)} KB
                </p>
              </div>
              <button
                type="button"
                onClick={clearCompressedReceipt}
                className="text-xs text-[#F87171] hover:underline cursor-pointer"
              >
                {tr("close")}
              </button>
            </div>
          )}

          {receiptScanState.status === "loading" && (
            <p className="text-xs text-[#EAB308]">{tr("scan_receipt_loading")}</p>
          )}
          {receiptScanState.status === "error" && (
            <p className="text-xs text-[#F87171]">
              {tr("scan_receipt_error")} ({receiptScanState.message})
            </p>
          )}
          {receiptScanState.status === "success" && (
            <div className="rounded-xl bg-[#34D399]/10 border border-[#34D399]/35 px-3 py-2 text-xs text-[#34D399]">
              {tr("scan_receipt_verified")} · {receiptScanState.data.verificationNote}
            </div>
          )}
        </div>

        <CosmicButton
          type="button"
          tone="emerald"
          className="w-full"
          disabled={!selectedChannel || !amountEgp.trim() || !senderRef.trim()}
          icon={<Send className="w-4 h-4" />}
          onClick={() => {
            if (!selectedChannel) return;
            submitPaymentReceipt(selectedChannel, amountEgp, senderRef);
            setAmountEgp("");
            setSenderRef("");
          }}
        >
          {tr("submit_receipt")}
        </CosmicButton>
      </CosmicCard>

      {/* Sent Receipts History */}
      <CosmicCard tone="slate" className="space-y-3">
        <div className="flex items-center gap-2">
          <Receipt className="w-4 h-4 text-[#38BDF8]" />
          <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("submissions_history")}</h3>
        </div>
        {submissions.length === 0 ? (
          <p className="text-xs text-[#94A3B8]">{tr("no_pending_receipts")}</p>
        ) : (
          <div className="space-y-2">
            {submissions.map((sub) => {
              const tone =
                sub.status === SubmissionStatus.APPROVED
                  ? "emerald"
                  : sub.status === SubmissionStatus.REJECTED
                    ? "crimson"
                    : "amber";
              const statusKey =
                sub.status === SubmissionStatus.APPROVED
                  ? "status_approved"
                  : sub.status === SubmissionStatus.REJECTED
                    ? "status_rejected"
                    : "status_pending";
              return (
                <div
                  key={sub.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 text-xs"
                >
                  <div>
                    <p className="font-bold text-[#F1F5F9]">
                      {sub.channelName} · <span className="font-mono-tabular">{sub.senderReference}</span>
                    </p>
                    {sub.rejectionReason && (
                      <p className="text-[#F87171] mt-0.5">{sub.rejectionReason}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-[#34D399] tabular-nums">
                      {EgyptValidators.formatPiasters(sub.amountPiasters, language)}
                    </span>
                    <StatusBadge tone={tone} label={tr(statusKey)} />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CosmicCard>

      {/* Immutable Ledger */}
      <CosmicCard tone="slate" className="space-y-3">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-[#34D399]" />
            <h3 className="text-sm font-bold text-[#F1F5F9]">{tr("immutable_ledger")}</h3>
          </div>
          <StatusBadge tone="emerald" label={tr("os_or_verified_badge")} />
        </div>

        <div className="space-y-2">
          {ledger.map((entry) => {
            const isVoided =
              entry.kind === LedgerKind.VOID_ENTRY ||
              ledger.some((other) => other.voidedEntryId === entry.id);
            return (
              <div
                key={entry.id}
                className="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-[#0A0F1C]/65 border border-white/10 p-3 text-xs"
              >
                <div className="min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-bold text-[#F1F5F9]">
                      {isAr ? entry.studentNameAr : entry.studentNameEn}
                    </span>
                    <StatusBadge
                      tone={entry.kind === LedgerKind.VOID_ENTRY ? "crimson" : "cyan"}
                      label={ledgerKindLabel(entry.kind, language)}
                    />
                  </div>
                  {entry.note && <p className="text-[#94A3B8] mt-0.5">{entry.note}</p>}
                </div>

                <div className="flex items-center gap-2">
                  <span
                    className={`font-extrabold tabular-nums ${
                      entry.amountPiasters < 0 ? "text-[#F87171]" : "text-[#34D399]"
                    }`}
                  >
                    {EgyptValidators.formatPiasters(entry.amountPiasters, language)}
                  </span>
                  {!isVoided && (
                    <button
                      type="button"
                      onClick={() => {
                        setVoidTargetId(entry.id);
                        setVoidReason("");
                      }}
                      className="inline-flex items-center gap-1 rounded-lg border border-[#F87171]/35 px-2 py-1 text-[11px] font-semibold text-[#F87171] hover:bg-[#F87171]/10 cursor-pointer"
                    >
                      <Ban className="w-3 h-3" />
                      {tr("void_entry")}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </CosmicCard>

      {/* Void Entry Modal */}
      <ModalDialog
        open={Boolean(voidTargetId)}
        title={tr("void_entry")}
        onClose={() => setVoidTargetId(null)}
      >
        <div className="space-y-3">
          <input
            type="text"
            value={voidReason}
            onChange={(e) => setVoidReason(e.target.value)}
            placeholder={tr("void_reason")}
            className="w-full rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-2 text-sm text-[#F1F5F9]"
          />
          <CosmicButton
            type="button"
            tone="crimson"
            className="w-full"
            disabled={!voidReason.trim()}
            onClick={() => {
              if (voidTargetId) voidLedgerEntry(voidTargetId, voidReason);
              setVoidTargetId(null);
            }}
          >
            {tr("submit")}
          </CosmicButton>
        </div>
      </ModalDialog>
    </div>
  );
};
