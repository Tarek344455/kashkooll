import React, { useState } from "react";
import { Brain, Check, HeartHandshake, RotateCcw, Sparkles, SlidersHorizontal, X } from "lucide-react";
import { useKashkool } from "../context/KashkoolContext";
import { AppLanguage, CognitiveMeta, EmotionalPulse, StudentAiMemory } from "../types/kashkool";
import { CosmicButton, CosmicCard } from "./CosmicUi";

export const MoodCheckInBar: React.FC = () => {
  const { selectedMood, setSelectedMood, tr } = useKashkool();

  const moods: Array<{ id: EmotionalPulse; labelKey: string }> = [
    { id: "CALM", labelKey: "mood_calm" },
    { id: "EXAM_ANXIETY", labelKey: "mood_anxiety" },
    { id: "FRUSTRATION", labelKey: "mood_frustration" },
    { id: "BURNOUT", labelKey: "mood_burnout" },
    { id: "CURIOSITY", labelKey: "mood_curiosity" },
  ];

  return (
    <div className="rounded-xl bg-[#0F172A]/85 border border-white/10 px-3 py-2 flex flex-wrap items-center gap-2 shrink-0">
      <div className="flex items-center gap-1.5 text-xs font-semibold text-[#94A3B8]">
        <HeartHandshake className="w-3.5 h-3.5 text-[#38BDF8] shrink-0" />
        <span>{tr("mood_checkin_label")}</span>
      </div>
      <div className="flex flex-wrap gap-1.5">
        {moods.map((m) => {
          const active = selectedMood === m.id;
          return (
            <button
              key={m.id}
              type="button"
              onClick={() => setSelectedMood(active ? null : m.id)}
              className={`rounded-lg px-2.5 py-1 text-xs font-semibold border transition cursor-pointer ${
                active
                  ? "bg-[#38BDF8]/20 border-[#38BDF8] text-[#F1F5F9]"
                  : "bg-[#141D2F] border-white/10 text-[#94A3B8] hover:text-[#F1F5F9] hover:border-white/25"
              }`}
            >
              {tr(m.labelKey)}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export const CognitiveReplyBadge: React.FC<{ meta: CognitiveMeta; language: AppLanguage }> = ({ meta, language }) => {
  const isAr = language === AppLanguage.AR;
  const label = isAr ? meta.strategyAr : meta.strategyEn;

  return (
    <div className="mb-2 flex flex-wrap items-center gap-2 text-[11px] font-semibold text-[#38BDF8]/90">
      <span className="inline-flex items-center gap-1 rounded-md bg-[#38BDF8]/12 border border-[#38BDF8]/25 px-2 py-0.5">
        <Sparkles className="w-3 h-3 shrink-0" />
        <span>{label}</span>
      </span>
      {meta.memoryApplied && (
        <span className="inline-flex items-center gap-1 rounded-md bg-[#34D399]/10 border border-[#34D399]/25 px-2 py-0.5 text-[#34D399]">
          <Brain className="w-3 h-3 shrink-0" />
          <span>{isAr ? "مخصّص لأسلوبك" : "Tailored to you"}</span>
        </span>
      )}
    </div>
  );
};

export const StudentMemoryPanel: React.FC<{ open: boolean; onClose: () => void }> = ({ open, onClose }) => {
  const { language, studentMemory, memoryBusy, updateStudentMemoryPrefs, resetStudentMemoryPrefs, tr } = useKashkool();
  const isAr = language === AppLanguage.AR;
  const [newTopic, setNewTopic] = useState("");

  if (!open) return null;

  const paceOptions: Array<{ id: StudentAiMemory["learningPace"]; labelKey: string }> = [
    { id: "gentle", labelKey: "memory_pace_gentle" },
    { id: "balanced", labelKey: "memory_pace_balanced" },
    { id: "intensive", labelKey: "memory_pace_intensive" },
  ];

  const styleOptions: Array<{ id: StudentAiMemory["preferredStyle"]; labelKey: string }> = [
    { id: "step_by_step", labelKey: "memory_style_step" },
    { id: "visual_examples", labelKey: "memory_style_visual" },
    { id: "socratic", labelKey: "memory_style_socratic" },
    { id: "concise_summary", labelKey: "memory_style_concise" },
  ];

  const toneOptions: Array<{ id: StudentAiMemory["tonePreference"]; labelKey: string }> = [
    { id: "warm_egyptian", labelKey: "memory_tone_warm" },
    { id: "calm_academic", labelKey: "memory_tone_academic" },
    { id: "encouraging_coach", labelKey: "memory_tone_coach" },
  ];

  const handleAddTopic = () => {
    const clean = newTopic.trim();
    if (!clean) return;
    if (!studentMemory.weakTopics.includes(clean)) {
      void updateStudentMemoryPrefs({ weakTopics: [clean, ...studentMemory.weakTopics].slice(0, 10) });
    }
    setNewTopic("");
  };

  const handleRemoveTopic = (topic: string) => {
    void updateStudentMemoryPrefs({
      weakTopics: studentMemory.weakTopics.filter((t) => t !== topic),
    });
  };

  return (
    <CosmicCard tone="cyan" className="space-y-3 shrink-0">
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2">
          <SlidersHorizontal className="w-4 h-4 text-[#38BDF8] shrink-0" />
          <div>
            <h3 className="text-sm font-extrabold text-[#F1F5F9]">{tr("memory_panel_title")}</h3>
            <p className="text-xs text-[#94A3B8]">{tr("memory_panel_subtitle")}</p>
          </div>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="rounded-lg p-1 text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-white/10 cursor-pointer"
          aria-label={tr("close")}
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Pace */}
      <div className="space-y-1.5">
        <p className="text-xs font-bold text-[#94A3B8]">{tr("memory_pace_label")}</p>
        <div className="grid grid-cols-3 gap-2">
          {paceOptions.map((opt) => {
            const active = studentMemory.learningPace === opt.id;
            return (
              <button
                key={opt.id}
                type="button"
                disabled={memoryBusy}
                onClick={() => void updateStudentMemoryPrefs({ learningPace: opt.id })}
                className={`rounded-xl px-2.5 py-2 text-xs font-bold border transition cursor-pointer flex items-center justify-center gap-1 ${
                  active
                    ? "bg-[#38BDF8]/20 border-[#38BDF8] text-[#F1F5F9]"
                    : "bg-[#0A0F1C] border-white/10 text-[#94A3B8] hover:text-[#F1F5F9]"
                }`}
              >
                {active && <Check className="w-3.5 h-3.5 text-[#38BDF8] shrink-0" />}
                <span>{tr(opt.labelKey)}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Style */}
      <div className="space-y-1.5">
        <p className="text-xs font-bold text-[#94A3B8]">{tr("memory_style_label")}</p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
          {styleOptions.map((opt) => {
            const active = studentMemory.preferredStyle === opt.id;
            return (
              <button
                key={opt.id}
                type="button"
                disabled={memoryBusy}
                onClick={() => void updateStudentMemoryPrefs({ preferredStyle: opt.id })}
                className={`rounded-xl px-2.5 py-2 text-xs font-bold border transition cursor-pointer flex items-center justify-center gap-1 ${
                  active
                    ? "bg-[#34D399]/18 border-[#34D399] text-[#F1F5F9]"
                    : "bg-[#0A0F1C] border-white/10 text-[#94A3B8] hover:text-[#F1F5F9]"
                }`}
              >
                {active && <Check className="w-3.5 h-3.5 text-[#34D399] shrink-0" />}
                <span>{tr(opt.labelKey)}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Tone */}
      <div className="space-y-1.5">
        <p className="text-xs font-bold text-[#94A3B8]">{tr("memory_tone_label")}</p>
        <div className="grid grid-cols-3 gap-2">
          {toneOptions.map((opt) => {
            const active = studentMemory.tonePreference === opt.id;
            return (
              <button
                key={opt.id}
                type="button"
                disabled={memoryBusy}
                onClick={() => void updateStudentMemoryPrefs({ tonePreference: opt.id })}
                className={`rounded-xl px-2.5 py-2 text-xs font-bold border transition cursor-pointer flex items-center justify-center gap-1 ${
                  active
                    ? "bg-[#FBBF24]/18 border-[#FBBF24] text-[#F1F5F9]"
                    : "bg-[#0A0F1C] border-white/10 text-[#94A3B8] hover:text-[#F1F5F9]"
                }`}
              >
                {active && <Check className="w-3.5 h-3.5 text-[#FBBF24] shrink-0" />}
                <span>{tr(opt.labelKey)}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Weak Topics */}
      <div className="space-y-1.5">
        <p className="text-xs font-bold text-[#94A3B8]">{tr("memory_weak_topics")}</p>
        <div className="flex flex-wrap gap-1.5">
          {studentMemory.weakTopics.map((topic) => (
            <span
              key={topic}
              className="inline-flex items-center gap-1.5 rounded-lg bg-[#0A0F1C] border border-white/15 px-2.5 py-1 text-xs text-[#F1F5F9]"
            >
              <span>{topic}</span>
              <button
                type="button"
                onClick={() => handleRemoveTopic(topic)}
                className="text-[#94A3B8] hover:text-[#F87171] cursor-pointer"
              >
                <X className="w-3 h-3" />
              </button>
            </span>
          ))}
        </div>
        <div className="flex items-center gap-2 pt-1">
          <input
            type="text"
            value={newTopic}
            onChange={(e) => setNewTopic(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                handleAddTopic();
              }
            }}
            placeholder={isAr ? "أضف درساً أو فكرة للتركيز عليها..." : "Add a focus topic..."}
            className="flex-1 rounded-xl bg-[#0A0F1C] border border-white/15 px-3 py-1.5 text-xs text-[#F1F5F9] placeholder-[#94A3B8]/55 focus:outline-none focus:border-[#38BDF8]"
          />
          <CosmicButton
            type="button"
            tone="cyan"
            variant="outline"
            className="px-3 py-1.5 text-xs"
            onClick={handleAddTopic}
          >
            {isAr ? "إضافة" : "Add"}
          </CosmicButton>
        </div>
      </div>

      <div className="flex justify-end pt-1 border-t border-white/10">
        <CosmicButton
          type="button"
          tone="slate"
          variant="outline"
          className="px-3 py-1.5 text-xs"
          loading={memoryBusy}
          icon={<RotateCcw className="w-3.5 h-3.5" />}
          onClick={() => void resetStudentMemoryPrefs()}
        >
          {tr("memory_reset_cta")}
        </CosmicButton>
      </div>
    </CosmicCard>
  );
};
