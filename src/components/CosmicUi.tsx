import React, { useEffect, useRef, useState } from "react";
import QRCode from "qrcode";
import { Loader2, X } from "lucide-react";

export type AccentTone = "cyan" | "emerald" | "amber" | "crimson" | "gold" | "purple" | "blue" | "slate";

const TONE_MAP: Record<AccentTone, { border: string; text: string; bg: string; hex: string; glow: string }> = {
  cyan: {
    border: "border-[#38BDF8]/28",
    text: "text-[#38BDF8]",
    bg: "bg-[#38BDF8]/12",
    hex: "#38BDF8",
    glow: "hover:border-[#38BDF8]/55 hover:shadow-[0_14px_38px_-14px_rgba(56,189,248,0.28)]",
  },
  emerald: {
    border: "border-[#34D399]/28",
    text: "text-[#34D399]",
    bg: "bg-[#34D399]/12",
    hex: "#34D399",
    glow: "hover:border-[#34D399]/55 hover:shadow-[0_14px_38px_-14px_rgba(52,211,153,0.26)]",
  },
  amber: {
    border: "border-[#FBBF24]/30",
    text: "text-[#FBBF24]",
    bg: "bg-[#FBBF24]/12",
    hex: "#FBBF24",
    glow: "hover:border-[#FBBF24]/55 hover:shadow-[0_14px_38px_-14px_rgba(251,191,36,0.26)]",
  },
  crimson: {
    border: "border-[#F87171]/30",
    text: "text-[#F87171]",
    bg: "bg-[#F87171]/12",
    hex: "#F87171",
    glow: "hover:border-[#F87171]/55 hover:shadow-[0_14px_38px_-14px_rgba(248,113,113,0.26)]",
  },
  gold: {
    border: "border-[#EAB308]/30",
    text: "text-[#EAB308]",
    bg: "bg-[#EAB308]/12",
    hex: "#EAB308",
    glow: "hover:border-[#EAB308]/55 hover:shadow-[0_14px_38px_-14px_rgba(234,179,8,0.26)]",
  },
  purple: {
    border: "border-[#A78BFA]/28",
    text: "text-[#A78BFA]",
    bg: "bg-[#A78BFA]/12",
    hex: "#A78BFA",
    glow: "hover:border-[#A78BFA]/55 hover:shadow-[0_14px_38px_-14px_rgba(167,139,250,0.28)]",
  },
  blue: {
    border: "border-[#60A5FA]/28",
    text: "text-[#60A5FA]",
    bg: "bg-[#60A5FA]/12",
    hex: "#60A5FA",
    glow: "hover:border-[#60A5FA]/55 hover:shadow-[0_14px_38px_-14px_rgba(96,165,250,0.26)]",
  },
  slate: {
    border: "border-white/12",
    text: "text-[#94A3B8]",
    bg: "bg-white/5",
    hex: "#94A3B8",
    glow: "hover:border-white/25",
  },
};

export const CosmicCard: React.FC<{
  children: React.ReactNode;
  tone?: AccentTone;
  className?: string;
  onClick?: () => void;
  floatIndex?: number;
  tiltEnabled?: boolean;
}> = ({ children, tone = "cyan", className = "", onClick, floatIndex, tiltEnabled = Boolean(onClick) }) => {
  const t = TONE_MAP[tone];
  const cardRef = useRef<HTMLDivElement | null>(null);
  const [tiltStyle, setTiltStyle] = useState<React.CSSProperties>({});

  const floatStyle: React.CSSProperties | undefined =
    typeof floatIndex === "number"
      ? ({
          "--float-delay": `${((floatIndex % 5) * -1.15).toFixed(2)}s`,
          "--float-duration": `${(5.8 + (floatIndex % 3) * 0.8).toFixed(2)}s`,
        } as React.CSSProperties)
      : undefined;

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!tiltEnabled || !cardRef.current) return;
    const rect = cardRef.current.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0) return;
    const nx = (e.clientX - rect.left) / rect.width - 0.5;
    const ny = (e.clientY - rect.top) / rect.height - 0.5;
    setTiltStyle({
      transform: `perspective(900px) rotateX(${(-ny * 4.5).toFixed(2)}deg) rotateY(${(nx * 4.5).toFixed(2)}deg) translate3d(0, -2px, 0)`,
    });
  };

  const resetTilt = () => {
    if (tiltEnabled) setTiltStyle({});
  };

  return (
    <div
      ref={cardRef}
      onClick={() => {
        if (onClick) {
          try {
            navigator.vibrate?.(6);
          } catch {
            // Haptics unsupported on desktop
          }
          onClick();
        }
      }}
      onPointerMove={handlePointerMove}
      onPointerLeave={resetTilt}
      style={{ ...floatStyle, ...tiltStyle }}
      className={`rounded-2xl kashkool-space-glass border ${t.border} p-4 transition-[transform,border-color,box-shadow] duration-200 ease-out ${
        typeof floatIndex === "number" ? "kashkool-zero-g" : ""
      } ${onClick ? `cursor-pointer ${t.glow}` : ""} ${className}`}
    >
      {children}
    </div>
  );
};

export const ZeroGravityCard = CosmicCard;

export const CosmicButton: React.FC<
  React.ButtonHTMLAttributes<HTMLButtonElement> & {
    tone?: AccentTone;
    variant?: "solid" | "outline" | "subtle";
    loading?: boolean;
    icon?: React.ReactNode;
  }
> = ({
  children,
  tone = "cyan",
  variant = "solid",
  loading = false,
  icon,
  className = "",
  disabled,
  onClick,
  ...rest
}) => {
  const [internalBusy, setInternalBusy] = useState(false);
  const busy = loading || internalBusy;

  const handleClick = async (e: React.MouseEvent<HTMLButtonElement>) => {
    if (busy || disabled) return;
    try {
      navigator.vibrate?.(8);
    } catch {
      // Haptics unsupported
    }
    if (!onClick) return;
    const maybePromise = onClick(e) as unknown;
    if (
      maybePromise &&
      typeof (maybePromise as PromiseLike<unknown>).then === "function"
    ) {
      setInternalBusy(true);
      try {
        await maybePromise;
      } finally {
        setInternalBusy(false);
      }
    }
  };

  const toneStyles: Record<AccentTone, { solid: string; outline: string; subtle: string }> = {
    cyan: {
      solid: "bg-[#38BDF8] text-[#0A0F1C] hover:bg-[#5ccbfa] border-transparent",
      outline: "border-[#38BDF8]/45 text-[#38BDF8] hover:bg-[#38BDF8]/10 bg-transparent",
      subtle: "bg-[#38BDF8]/14 text-[#38BDF8] hover:bg-[#38BDF8]/22 border-transparent",
    },
    emerald: {
      solid: "bg-[#34D399] text-[#0A0F1C] hover:bg-[#4ee0ab] border-transparent",
      outline: "border-[#34D399]/45 text-[#34D399] hover:bg-[#34D399]/10 bg-transparent",
      subtle: "bg-[#34D399]/14 text-[#34D399] hover:bg-[#34D399]/22 border-transparent",
    },
    amber: {
      solid: "bg-[#FBBF24] text-[#0A0F1C] hover:bg-[#fcd056] border-transparent",
      outline: "border-[#FBBF24]/45 text-[#FBBF24] hover:bg-[#FBBF24]/10 bg-transparent",
      subtle: "bg-[#FBBF24]/14 text-[#FBBF24] hover:bg-[#FBBF24]/22 border-transparent",
    },
    crimson: {
      solid: "bg-[#F87171] text-[#0A0F1C] hover:bg-[#fa8c8c] border-transparent",
      outline: "border-[#F87171]/45 text-[#F87171] hover:bg-[#F87171]/10 bg-transparent",
      subtle: "bg-[#F87171]/14 text-[#F87171] hover:bg-[#F87171]/22 border-transparent",
    },
    gold: {
      solid: "bg-[#EAB308] text-[#0A0F1C] hover:bg-[#f1c42e] border-transparent",
      outline: "border-[#EAB308]/45 text-[#EAB308] hover:bg-[#EAB308]/10 bg-transparent",
      subtle: "bg-[#EAB308]/14 text-[#EAB308] hover:bg-[#EAB308]/22 border-transparent",
    },
    purple: {
      solid: "bg-[#A78BFA] text-[#0A0F1C] hover:bg-[#b8a1fb] border-transparent",
      outline: "border-[#A78BFA]/45 text-[#A78BFA] hover:bg-[#A78BFA]/10 bg-transparent",
      subtle: "bg-[#A78BFA]/14 text-[#A78BFA] hover:bg-[#A78BFA]/22 border-transparent",
    },
    blue: {
      solid: "bg-[#60A5FA] text-[#0A0F1C] hover:bg-[#7cb5fb] border-transparent",
      outline: "border-[#60A5FA]/45 text-[#60A5FA] hover:bg-[#60A5FA]/10 bg-transparent",
      subtle: "bg-[#60A5FA]/14 text-[#60A5FA] hover:bg-[#60A5FA]/22 border-transparent",
    },
    slate: {
      solid: "bg-[#1B263B] text-[#F1F5F9] hover:bg-[#24324c] border-white/10",
      outline: "border-white/15 text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-white/5 bg-transparent",
      subtle: "bg-white/6 text-[#94A3B8] hover:text-[#F1F5F9] border-transparent",
    },
  };

  return (
    <button
      disabled={disabled || busy}
      onClick={(e) => void handleClick(e)}
      className={`inline-flex items-center justify-center gap-2 rounded-xl border px-3.5 py-2.5 text-sm font-semibold whitespace-nowrap shrink-0 transition-all active:scale-[0.98] disabled:opacity-45 disabled:pointer-events-none cursor-pointer ${toneStyles[tone][variant]} ${className}`}
      {...rest}
    >
      {busy ? <Loader2 className="w-4 h-4 animate-spin shrink-0" /> : icon}
      <span>{children}</span>
    </button>
  );
};

export const StatusBadge: React.FC<{
  label: string;
  tone?: AccentTone;
  className?: string;
}> = ({ label, tone = "cyan", className = "" }) => {
  const t = TONE_MAP[tone];
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-lg border ${t.border} ${t.bg} ${t.text} px-2 py-0.5 text-xs font-semibold whitespace-nowrap shrink-0 ${className}`}
    >
      {label}
    </span>
  );
};

export const DynamicQrCode: React.FC<{
  payload: string;
  size?: number;
  className?: string;
}> = ({ payload, size = 160, className = "" }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const safe = payload.trim() || "KSH|empty";
    QRCode.toCanvas(
      canvas,
      safe,
      {
        width: size,
        margin: 1,
        errorCorrectionLevel: "M",
        color: {
          dark: "#0A0F1C",
          light: "#FFFFFF",
        },
      },
      () => {
        // Rendered cleanly onto canvas
      }
    );
  }, [payload, size]);

  return (
    <div
      className={`inline-flex items-center justify-center rounded-xl bg-white p-2 shadow-inner ${className}`}
    >
      <canvas ref={canvasRef} width={size} height={size} className="block rounded" />
    </div>
  );
};

export const ModalDialog: React.FC<{
  open: boolean;
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  maxWidthClass?: string;
}> = ({ open, title, onClose, children, maxWidthClass = "max-w-lg" }) => {
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4"
      onClick={onClose}
    >
      <div
        className={`w-full ${maxWidthClass} max-h-[90vh] overflow-y-auto rounded-2xl bg-[#141D2F] border border-[#38BDF8]/30 p-5 shadow-2xl`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between gap-3 mb-4 pb-3 border-b border-white/10">
          <h3 className="text-base font-bold text-[#F1F5F9]">{title}</h3>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="rounded-lg p-1.5 text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-white/10 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
};

export const ShimmerCard: React.FC<{ lines?: number; className?: string }> = ({
  lines = 3,
  className = "",
}) => (
  <div className={`rounded-2xl bg-[#141D2F]/90 border border-white/10 p-4 space-y-2.5 ${className}`}>
    {Array.from({ length: lines }).map((_, i) => (
      <div
        key={i}
        className={`h-3.5 rounded-lg kashkool-shimmer ${i === 0 ? "w-2/3" : i === lines - 1 ? "w-1/2" : "w-full"}`}
      />
    ))}
  </div>
);

export const EmptyState: React.FC<{
  icon: React.ReactNode;
  message: string;
  action?: React.ReactNode;
}> = ({ icon, message, action }) => (
  <CosmicCard tone="slate" className="text-center py-8 flex flex-col items-center gap-3">
    <div className="text-[#94A3B8] opacity-80">{icon}</div>
    <p className="text-sm text-[#94A3B8] max-w-md">{message}</p>
    {action}
  </CosmicCard>
);
