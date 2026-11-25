import React, { useEffect, useRef, useState } from "react";
import { Camera, ImagePlus, QrCode, ScanLine } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage } from "../types/kashkool";
import { CosmicButton, CosmicCard, ModalDialog, StatusBadge } from "./CosmicUi";

interface BarcodeDetectorLike {
  detect: (source: ImageBitmapSource) => Promise<Array<{ rawValue?: string }>>;
}

export const QrScannerModal: React.FC<{
  open: boolean;
  onClose: () => void;
}> = ({ open, onClose }) => {
  const {
    language,
    students,
    lastScanFeedback,
    scannerScanCount,
    activeStudentQrToken,
    scanQrForAttendance,
    tr,
  } = useKashkool();

  const videoRef = useRef<HTMLVideoElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [cameraActive, setCameraActive] = useState(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [manualPayload, setManualPayload] = useState("");
  const lastDecodedRef = useRef<{ value: string; at: number }>({ value: "", at: 0 });

  useEffect(() => {
    if (!open) {
      setCameraActive(false);
      setCameraError(null);
      return;
    }

    let stream: MediaStream | null = null;
    let rafId = 0;
    let cancelled = false;

    const startCamera = async () => {
      if (!navigator.mediaDevices?.getUserMedia) {
        setCameraError(tr("qr_camera_perm_needed"));
        return;
      }
      try {
        stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "environment" },
        });
        if (cancelled) {
          stream.getTracks().forEach((track) => track.stop());
          return;
        }
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          await videoRef.current.play();
        }
        setCameraActive(true);
        setCameraError(null);

        const DetectorCtor = (window as unknown as {
          BarcodeDetector?: new (opts: { formats: string[] }) => BarcodeDetectorLike;
        }).BarcodeDetector;
        if (DetectorCtor && videoRef.current) {
          const detector = new DetectorCtor({ formats: ["qr_code"] });
          const scanFrame = async () => {
            if (cancelled || !videoRef.current) return;
            try {
              if (videoRef.current.readyState >= 2) {
                const codes = await detector.detect(videoRef.current);
                const raw = codes[0]?.rawValue?.trim();
                const now = Date.now();
                if (
                  raw &&
                  !(raw === lastDecodedRef.current.value && now - lastDecodedRef.current.at < 3500)
                ) {
                  lastDecodedRef.current = { value: raw, at: now };
                  scanQrForAttendance(raw);
                }
              }
            } catch {
              // Ignore single-frame detection errors
            }
            rafId = window.setTimeout(() => void scanFrame(), 350);
          };
          void scanFrame();
        }
      } catch {
        setCameraError(tr("qr_camera_perm_needed"));
        setCameraActive(false);
      }
    };

    void startCamera();

    return () => {
      cancelled = true;
      window.clearTimeout(rafId);
      if (stream) stream.getTracks().forEach((t) => t.stop());
    };
  }, [open, scanQrForAttendance, tr]);

  const handlePhotoPick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const DetectorCtor = (window as unknown as {
      BarcodeDetector?: new (opts: { formats: string[] }) => BarcodeDetectorLike;
    }).BarcodeDetector;
    if (!DetectorCtor) {
      setCameraError(
        language === AppLanguage.AR
          ? "المتصفح لا يدعم قراءة QR من الصور مباشرة — يمكنك لصق الكود بالأسفل."
          : "Photo QR decoding is unavailable in this browser — paste code below."
      );
      return;
    }
    try {
      const bitmap = await createImageBitmap(file);
      const detector = new DetectorCtor({ formats: ["qr_code"] });
      const codes = await detector.detect(bitmap);
      bitmap.close();
      const raw = codes[0]?.rawValue?.trim();
      if (raw) {
        scanQrForAttendance(raw);
      } else {
        setCameraError(tr("qr_result_invalid"));
      }
    } catch {
      setCameraError(tr("qr_result_invalid"));
    }
  };

  const feedbackTone =
    lastScanFeedback?.status === "valid"
      ? "emerald"
      : lastScanFeedback?.status === "due"
        ? "amber"
        : lastScanFeedback?.status === "already"
          ? "cyan"
          : "crimson";

  const feedbackBadge =
    lastScanFeedback?.status === "valid"
      ? "scan_valid"
      : lastScanFeedback?.status === "due"
        ? "scan_due"
        : lastScanFeedback?.status === "already"
          ? "qr_already_checked_in"
          : "scan_blocked";

  return (
    <ModalDialog open={open} title={tr("qr_scanner_title")} onClose={onClose} maxWidthClass="max-w-xl">
      <div className="space-y-4">
        <div className="flex items-center justify-between gap-2 text-xs">
          <span className="text-[#94A3B8]">{tr("qr_scanner_subtitle")}</span>
          <span className="font-bold text-[#34D399] tabular-nums shrink-0">
            {tr("qr_scanned_count")}: {scannerScanCount}
          </span>
        </div>

        <div className="relative rounded-2xl overflow-hidden bg-[#0A0F1C] border border-[#38BDF8]/40 h-56 flex items-center justify-center">
          <video
            ref={videoRef}
            playsInline
            muted
            className={`w-full h-full object-cover ${cameraActive ? "block" : "hidden"}`}
          />
          {cameraActive && (
            <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
              <div className="w-40 h-40 rounded-2xl border-2 border-[#34D399]/80 shadow-[0_0_24px_rgba(52,211,153,0.3)]" />
            </div>
          )}
          {!cameraActive && (
            <div className="p-4 text-center space-y-2">
              <Camera className="w-9 h-9 text-[#FBBF24] mx-auto" />
              <p className="text-xs text-[#94A3B8] max-w-xs">{cameraError ?? tr("qr_camera_perm_needed")}</p>
            </div>
          )}
        </div>

        {lastScanFeedback && (
          <CosmicCard tone={feedbackTone}>
            <div className="flex items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="text-sm font-bold text-[#F1F5F9] truncate">{lastScanFeedback.studentName}</p>
                {lastScanFeedback.detail && (
                  <p className="text-xs text-[#94A3B8] truncate">{lastScanFeedback.detail}</p>
                )}
              </div>
              <StatusBadge tone={feedbackTone} label={tr(feedbackBadge)} />
            </div>
          </CosmicCard>
        )}

        <div className="space-y-2">
          <div className="flex gap-2">
            <input
              type="text"
              value={manualPayload}
              onChange={(e) => setManualPayload(e.target.value)}
              placeholder="KSHS|stu-1|... or KSH2026A"
              dir="ltr"
              className="flex-1 rounded-xl bg-[#0A0F1C]/80 border border-white/15 px-3 py-2 text-xs font-mono-tabular text-[#F1F5F9] placeholder-[#94A3B8]/60 focus:outline-none focus:border-[#38BDF8]"
            />
            <CosmicButton
              type="button"
              tone="cyan"
              icon={<ScanLine className="w-4 h-4" />}
              onClick={() => {
                if (!manualPayload.trim()) return;
                scanQrForAttendance(manualPayload);
                setManualPayload("");
              }}
            >
              {tr("tap_to_checkin")}
            </CosmicButton>
          </div>

          <div className="flex flex-wrap items-center gap-2 pt-1">
            {activeStudentQrToken && (
              <CosmicButton
                type="button"
                variant="subtle"
                tone="emerald"
                className="text-xs py-1.5 px-2.5"
                icon={<QrCode className="w-3.5 h-3.5" />}
                onClick={() => scanQrForAttendance(activeStudentQrToken)}
              >
                {language === AppLanguage.AR ? "اختبار بطاقة أحمد (حي)" : "Test Ahmed Live Pass"}
              </CosmicButton>
            )}
            {students[1]?.qrActivationCode && (
              <CosmicButton
                type="button"
                variant="subtle"
                tone="amber"
                className="text-xs py-1.5 px-2.5"
                onClick={() => scanQrForAttendance(students[1].qrActivationCode ?? "")}
              >
                {language === AppLanguage.AR ? "اختبار بطاقة سارة (مستحقات)" : "Test Sara Card (Due)"}
              </CosmicButton>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => void handlePhotoPick(e)}
            />
            <CosmicButton
              type="button"
              variant="outline"
              tone="cyan"
              className="text-xs py-1.5 px-2.5"
              icon={<ImagePlus className="w-3.5 h-3.5" />}
              onClick={() => fileInputRef.current?.click()}
            >
              {tr("qr_scan_from_photo_cta")}
            </CosmicButton>
          </div>
        </div>
      </div>
    </ModalDialog>
  );
};
