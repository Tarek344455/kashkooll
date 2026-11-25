import { CompressedReceiptResult } from "../../types/kashkool";
import { EgyptValidators } from "./egyptValidators";

export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {
    // Fallback below
  }
  try {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    const ok = document.execCommand("copy");
    document.body.removeChild(ta);
    return ok;
  } catch {
    return false;
  }
}

export async function shareOrCopyText(title: string, text: string): Promise<"shared" | "copied"> {
  if (typeof navigator !== "undefined" && typeof navigator.share === "function") {
    try {
      await navigator.share({ title, text });
      return "shared";
    } catch {
      // User cancelled or share unsupported in iframe -> fall back to clipboard copy
    }
  }
  await copyToClipboard(text);
  return "copied";
}

/**
 * Low-data client-side image compression using Canvas (targets <= 150KB JPEG for rural mobile savings).
 */
export async function compressImageFile(
  file: File,
  maxDimension = 1280,
  targetBytes = 150_000
): Promise<CompressedReceiptResult> {
  const originalBytes = file.size;
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxDimension / Math.max(bitmap.width, bitmap.height));
  const width = Math.max(1, Math.round(bitmap.width * scale));
  const height = Math.max(1, Math.round(bitmap.height * scale));

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas unavailable");
  ctx.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  let quality = 0.82;
  let dataUrl = canvas.toDataURL("image/jpeg", quality);
  while (dataUrl.length * 0.75 > targetBytes && quality > 0.32) {
    quality -= 0.12;
    dataUrl = canvas.toDataURL("image/jpeg", quality);
  }
  const compressedBytes = Math.round((dataUrl.length - "data:image/jpeg;base64,".length) * 0.75);
  return {
    dataUrl,
    originalBytes,
    compressedBytes,
    savingsPercent: EgyptValidators.dataSavingsPercent(originalBytes, compressedBytes),
  };
}

export function formatShortTime(millis: number, lang: "ar" | "en"): string {
  try {
    return new Date(millis).toLocaleTimeString(lang === "ar" ? "ar-EG" : "en-US", {
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "--:--";
  }
}
