import React, { useEffect, useRef, useState } from "react";
import { BookOpen, ImagePlus, RefreshCw, Send, Square, Volume2, X } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { compressImageFile } from "../core/utils/browserUtils";
import { AppLanguage } from "../types/kashkool";
import { CosmicButton, CosmicCard, ShimmerCard } from "../components/CosmicUi";

export const StudyAssistantScreen: React.FC<{
  initialPrompt?: string | null;
  initialSubject?: string | null;
  onClearInitialPrompt?: () => void;
}> = ({ initialPrompt, initialSubject, onClearInitialPrompt }) => {
  const {
    language,
    assistantMessages,
    assistantBusy,
    assistantError,
    askStudyAssistant,
    tr,
  } = useKashkool();

  const isAr = language === AppLanguage.AR;
  const [prompt, setPrompt] = useState("");
  const [attachedPhoto, setAttachedPhoto] = useState<string | null>(null);
  const [speakingId, setSpeakingId] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const endRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (initialPrompt) {
      setPrompt(initialPrompt);
      onClearInitialPrompt?.();
    }
  }, [initialPrompt, onClearInitialPrompt]);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [assistantMessages, assistantBusy]);

  useEffect(() => {
    return () => {
      if ("speechSynthesis" in window) {
        window.speechSynthesis.cancel();
      }
    };
  }, []);

  const toggleSpeak = (msgId: string, text: string) => {
    if (!("speechSynthesis" in window)) return;
    if (speakingId === msgId) {
      window.speechSynthesis.cancel();
      setSpeakingId(null);
      return;
    }
    window.speechSynthesis.cancel();
    const utter = new SpeechSynthesisUtterance(text);
    utter.lang = isAr ? "ar-EG" : "en-US";
    utter.onend = () => setSpeakingId(null);
    utter.onerror = () => setSpeakingId(null);
    setSpeakingId(msgId);
    window.speechSynthesis.speak(utter);
  };

  const handlePhotoPick = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const res = await compressImageFile(file);
      setAttachedPhoto(res.dataUrl);
    } catch {
      // Ignore invalid image
    }
  };

  const handleSend = async (customText?: string) => {
    const textToSend = (customText ?? prompt).trim();
    if (!textToSend && !attachedPhoto) return;
    const photo = attachedPhoto;
    if (!customText) setPrompt("");
    setAttachedPhoto(null);
    await askStudyAssistant(textToSend, initialSubject ?? "الرياضيات والفيزياء", photo);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-11rem)] md:h-[calc(100vh-7.5rem)] space-y-3">
      {/* Header */}
      <CosmicCard tone="cyan" className="py-3 px-4 shrink-0">
        <div className="flex items-center gap-2.5">
          <BookOpen className="w-5 h-5 text-[#38BDF8] shrink-0" />
          <div>
            <h2 className="text-sm sm:text-base font-extrabold text-[#F1F5F9]">
              {tr("assistant_title")}
            </h2>
            <p className="text-xs text-[#94A3B8]">{tr("assistant_subtitle")}</p>
          </div>
        </div>
      </CosmicCard>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto space-y-3 pe-1">
        {assistantMessages.map((msg) => (
          <div
            key={msg.id}
            className={`flex flex-col ${msg.fromUser ? "items-end" : "items-start"} space-y-1.5`}
          >
            <div
              className={`max-w-[90%] sm:max-w-[78%] rounded-2xl px-4 py-3 text-sm leading-relaxed border ${
                msg.fromUser
                  ? "bg-[#38BDF8]/18 border-[#38BDF8]/40 text-[#F1F5F9]"
                  : "bg-[#141D2F] border-white/12 text-[#F1F5F9]"
              }`}
            >
              {msg.attachedPhotoDataUrl && (
                <img
                  src={msg.attachedPhotoDataUrl}
                  alt="Problem"
                  className="max-h-48 rounded-xl mb-2 border border-white/15 object-contain"
                />
              )}
              <p className="whitespace-pre-wrap">{msg.text}</p>

              {!msg.fromUser && "speechSynthesis" in window && (
                <div className="mt-2 pt-2 border-t border-white/8 flex items-center justify-between gap-2">
                  <button
                    type="button"
                    onClick={() => toggleSpeak(msg.id, msg.text)}
                    className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#38BDF8] hover:underline cursor-pointer"
                  >
                    {speakingId === msg.id ? (
                      <>
                        <Square className="w-3 h-3 fill-current" />
                        <span>{tr("assistant_stop_reading")}</span>
                      </>
                    ) : (
                      <>
                        <Volume2 className="w-3.5 h-3.5" />
                        <span>{tr("assistant_read_aloud")}</span>
                      </>
                    )}
                  </button>
                </div>
              )}
            </div>

            {!msg.fromUser && msg.suggestions.length > 0 && (
              <div className="flex flex-wrap gap-1.5 max-w-[90%]">
                {msg.suggestions.map((sug, i) => (
                  <button
                    key={i}
                    type="button"
                    disabled={assistantBusy}
                    onClick={() => void handleSend(sug)}
                    className="rounded-xl bg-[#1B263B]/80 border border-[#38BDF8]/30 px-3 py-1.5 text-xs font-semibold text-[#38BDF8] hover:bg-[#38BDF8]/15 cursor-pointer disabled:opacity-45"
                  >
                    {sug}
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}

        {assistantBusy && (
          <div className="max-w-sm">
            <ShimmerCard lines={3} />
          </div>
        )}

        {assistantError && (
          <CosmicCard tone="crimson" className="space-y-2">
            <p className="text-xs text-[#F87171]">{assistantError}</p>
            <CosmicButton
              type="button"
              tone="crimson"
              variant="outline"
              className="text-xs py-1.5 px-3"
              icon={<RefreshCw className="w-3.5 h-3.5" />}
              onClick={() => {
                const lastUser = [...assistantMessages].reverse().find((m) => m.fromUser);
                if (lastUser) void askStudyAssistant(lastUser.text);
              }}
            >
              {tr("os_ai_retry")}
            </CosmicButton>
          </CosmicCard>
        )}

        <div ref={endRef} />
      </div>

      {/* Input Composer */}
      <CosmicCard tone="slate" className="p-3 space-y-2 shrink-0">
        {attachedPhoto && (
          <div className="flex items-center gap-2 rounded-xl bg-[#0A0F1C] p-2 border border-[#38BDF8]/30">
            <img src={attachedPhoto} alt="Attached" className="w-12 h-12 rounded-lg object-cover" />
            <span className="text-xs text-[#34D399] flex-1">{tr("assistant_photo_attached")}</span>
            <button
              type="button"
              onClick={() => setAttachedPhoto(null)}
              className="text-[#94A3B8] hover:text-[#F87171] cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        <div className="flex items-center gap-2">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => void handlePhotoPick(e)}
          />
          <CosmicButton
            type="button"
            tone="slate"
            variant="outline"
            className="px-3 py-2.5"
            aria-label={tr("assistant_attach_photo")}
            onClick={() => fileInputRef.current?.click()}
            icon={<ImagePlus className="w-4 h-4" />}
          >
            <span className="hidden sm:inline text-xs">{tr("assistant_attach_photo")}</span>
          </CosmicButton>

          <input
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                void handleSend();
              }
            }}
            placeholder={attachedPhoto ? tr("assistant_photo_hint") : tr("assistant_hint")}
            className="flex-1 rounded-xl bg-[#0A0F1C] border border-white/15 px-3.5 py-2.5 text-sm text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
          />

          <CosmicButton
            type="button"
            tone="cyan"
            loading={assistantBusy}
            disabled={!prompt.trim() && !attachedPhoto}
            icon={<Send className="w-4 h-4" />}
            onClick={() => void handleSend()}
          >
            {tr("send")}
          </CosmicButton>
        </div>
      </CosmicCard>
    </div>
  );
};
