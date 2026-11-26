import React, { useEffect, useRef, useState } from "react";
import { AppLanguage } from "../types/kashkool";

interface StarParticle {
  x: number;
  y: number;
  z: number; // 1 = far, 2 = mid, 3 = near
  radius: number;
  alpha: number;
  twinkleSpeed: number;
  phase: number;
}

/**
 * Lightweight 60-FPS 3-depth parallax starfield & nebula canvas.
 * Automatically freezes during active exams (`examModeActive`) and throttles
 * particle count if frame time exceeds 16.6ms.
 */
export const CosmicParallaxCanvas: React.FC<{ examModeActive?: boolean }> = ({
  examModeActive = false,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d", { alpha: true });
    if (!ctx) return;

    const prefersReduced =
      typeof window !== "undefined" &&
      window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;

    let width = window.innerWidth;
    let height = window.innerHeight;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const resize = () => {
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = Math.floor(width * dpr);
      canvas.height = Math.floor(height * dpr);
      canvas.style.width = `${width}px`;
      canvas.style.height = `${height}px`;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    resize();

    let particleCount = width < 640 ? 48 : 84;
    const buildStars = (count: number): StarParticle[] =>
      Array.from({ length: count }, (_, i) => {
        const z = (i % 3) + 1;
        return {
          x: Math.random() * width,
          y: Math.random() * height,
          z,
          radius: z === 3 ? 1.55 : z === 2 ? 1.1 : 0.75,
          alpha: 0.25 + z * 0.2,
          twinkleSpeed: 0.0008 + Math.random() * 0.0014,
          phase: Math.random() * Math.PI * 2,
        };
      });

    let stars = buildStars(particleCount);
    let tiltX = 0;
    let tiltY = 0;
    let scrollOffset = 0;

    const onPointerMove = (e: PointerEvent) => {
      if (examModeActive || prefersReduced) return;
      tiltX = (e.clientX / Math.max(1, width) - 0.5) * 16;
      tiltY = (e.clientY / Math.max(1, height) - 0.5) * 16;
    };

    const onScroll = () => {
      scrollOffset = window.scrollY * 0.06;
    };

    const onOrientation = (e: DeviceOrientationEvent) => {
      if (examModeActive || prefersReduced) return;
      if (typeof e.gamma === "number" && typeof e.beta === "number") {
        tiltX = Math.max(-18, Math.min(18, e.gamma * 0.4));
        tiltY = Math.max(-18, Math.min(18, (e.beta - 35) * 0.3));
      }
    };

    window.addEventListener("resize", resize);
    window.addEventListener("pointermove", onPointerMove, { passive: true });
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("deviceorientation", onOrientation, { passive: true });

    let rafId = 0;
    let lastTime = performance.now();
    let slowFrames = 0;

    const drawFrame = (now: number) => {
      const dt = now - lastTime;
      lastTime = now;

      if (dt > 24 && particleCount > 28) {
        slowFrames += 1;
        if (slowFrames >= 6) {
          particleCount = Math.max(28, Math.floor(particleCount * 0.7));
          stars = stars.slice(0, particleCount);
          slowFrames = 0;
        }
      } else {
        slowFrames = 0;
      }

      ctx.clearRect(0, 0, width, height);

      for (let i = 0; i < stars.length; i += 1) {
        const s = stars[i];
        const twinkle =
          examModeActive || prefersReduced
            ? s.alpha
            : s.alpha * (0.6 + 0.4 * Math.sin(now * s.twinkleSpeed + s.phase));

        const px = (s.x + tiltX * s.z * 0.45 + width) % width;
        const py = (s.y - scrollOffset * s.z * 0.35 + tiltY * s.z * 0.45 + height * 4) % height;

        ctx.beginPath();
        ctx.arc(px, py, s.radius, 0, Math.PI * 2);
        ctx.fillStyle =
          s.z === 3
            ? `rgba(56, 189, 248, ${twinkle.toFixed(2)})`
            : s.z === 2
              ? `rgba(167, 139, 250, ${twinkle.toFixed(2)})`
              : `rgba(241, 245, 249, ${twinkle.toFixed(2)})`;
        ctx.fill();
      }

      if (!examModeActive && !prefersReduced) {
        rafId = window.requestAnimationFrame(drawFrame);
      }
    };

    if (examModeActive || prefersReduced) {
      drawFrame(performance.now());
    } else {
      rafId = window.requestAnimationFrame(drawFrame);
    }

    return () => {
      if (rafId) window.cancelAnimationFrame(rafId);
      window.removeEventListener("resize", resize);
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("deviceorientation", onOrientation);
    };
  }, [examModeActive]);

  return (
    <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden" aria-hidden="true">
      <div className="absolute -top-36 start-1/2 -translate-x-1/2 w-[780px] h-[420px] rounded-full bg-[radial-gradient(circle,rgba(56,189,248,0.14)_0%,rgba(167,139,250,0.06)_45%,transparent_72%)]" />
      <div className="absolute -bottom-44 -end-24 w-[520px] h-[420px] rounded-full bg-[radial-gradient(circle,rgba(167,139,250,0.11)_0%,transparent_70%)]" />
      <canvas ref={canvasRef} className="block w-full h-full opacity-85" />
    </div>
  );
};

/**
 * Orbital Ignition Launch Transition:
 * Hands off seamlessly from the pre-hydration HTML boot shell into the interactive portal.
 */
export const OrbitalIgnitionSplash: React.FC<{
  language: AppLanguage;
  onComplete: () => void;
}> = ({ language, onComplete }) => {
  const [fadingOut, setFadingOut] = useState(false);
  const onCompleteRef = useRef(onComplete);
  onCompleteRef.current = onComplete;

  useEffect(() => {
    const prefersReduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
    const holdMs = prefersReduced ? 120 : 620;
    const fadeMs = prefersReduced ? 80 : 280;

    const t1 = window.setTimeout(() => setFadingOut(true), holdMs);
    const t2 = window.setTimeout(() => onCompleteRef.current(), holdMs + fadeMs);
    return () => {
      window.clearTimeout(t1);
      window.clearTimeout(t2);
    };
  }, []);

  const isAr = language === AppLanguage.AR;

  return (
    <div
      className={`fixed inset-0 z-[9998] flex flex-col items-center justify-center bg-[#070B19] transition-all duration-300 ${
        fadingOut ? "opacity-0 scale-105 pointer-events-none" : "opacity-100 scale-100"
      }`}
    >
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_50%_42%,rgba(56,189,248,0.18),rgba(167,139,250,0.07)_35%,#070B19_70%)]" />

      <div className="relative flex items-center justify-center w-32 h-32">
        <div
          className="absolute inset-0 rounded-full border-[1.5px] border-[#38BDF8]/30 border-t-[#38BDF8]"
          style={{ animation: "kashkoolOrbitSpin 2.2s linear infinite" }}
        />
        <div
          className="absolute inset-3 rounded-full border border-dashed border-[#A78BFA]/40 border-b-[#A78BFA]"
          style={{ animation: "kashkoolOrbitSpin 3.4s linear infinite reverse" }}
        />
        <div
          className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#38BDF8] to-[#0284C7] flex items-center justify-center text-[#070B19] font-extrabold text-3xl shadow-[0_0_40px_rgba(56,189,248,0.5)]"
          style={{ animation: "kashkoolNebulaPulse 1.6s ease-in-out infinite" }}
        >
          ك
        </div>
      </div>

      <p className="relative mt-5 text-lg font-extrabold text-[#F1F5F9]">
        {isAr ? "كشكول" : "Kashkool"}
      </p>
      <p className="relative mt-1 text-xs font-medium text-[#94A3B8]">
        {isAr ? "جاري تجهيز مساحتك التعليمية..." : "Preparing your learning space..."}
      </p>
    </div>
  );
};
