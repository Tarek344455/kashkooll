import React, { useEffect, useState } from "react";
import { KashkoolProvider, useKashkool } from "./context/KashkoolContext";
import { AppDestination, AppLanguage } from "./types/kashkool";
import { isDestinationAllowed, resolveSafeDestination } from "./core/security/roleAccessGuard";
import { CosmicParallaxCanvas, OrbitalIgnitionSplash } from "./components/SpaceGlassEngine";
import { LoginScreen } from "./screens/LoginScreen";
import { WorkspaceShell } from "./screens/WorkspaceShell";
import { DashboardHomeScreen } from "./screens/DashboardHomeScreen";
import { SecretaryDeskScreen } from "./screens/SecretaryDeskScreen";
import { AttendanceDashboardScreen } from "./screens/AttendanceDashboardScreen";
import { TeacherOpsScreen } from "./screens/TeacherOpsScreen";
import { CoursesAndQuizScreen } from "./screens/CoursesAndQuizScreen";
import { WalletAndPaymentsScreen } from "./screens/WalletAndPaymentsScreen";
import { StudyAssistantScreen } from "./screens/StudyAssistantScreen";
import { ParentPortalScreen } from "./screens/ParentPortalScreen";

const KashkoolRouter: React.FC = () => {
  const { signedIn, activeRole, language, showSnackbar } = useKashkool();
  const [destination, setDestination] = useState<AppDestination>("home");
  const [quizTabRequested, setQuizTabRequested] = useState(false);
  const [assistantInitialPrompt, setAssistantInitialPrompt] = useState<string | null>(null);
  const [assistantInitialSubject, setAssistantInitialSubject] = useState<string | null>(null);
  const [bootComplete, setBootComplete] = useState(false);
  const [examModeActive, setExamModeActive] = useState(false);

  // Listen for Exam-Mode Focus Override events from ExamFortressView
  useEffect(() => {
    const onExamFocus = (e: Event) => {
      const active = Boolean((e as CustomEvent<{ active?: boolean }>).detail?.active);
      setExamModeActive(active);
    };
    window.addEventListener("kashkool-exam-focus", onExamFocus);
    return () => window.removeEventListener("kashkool-exam-focus", onExamFocus);
  }, []);

  // Enforce RoleAccessGuard whenever activeRole changes
  useEffect(() => {
    if (!isDestinationAllowed(activeRole, destination)) {
      setDestination(resolveSafeDestination(activeRole, destination));
    }
  }, [activeRole, destination]);

  const navigate = (
    dest: AppDestination,
    opts?: { openQuizTab?: boolean; prompt?: string; subject?: string }
  ) => {
    if (!isDestinationAllowed(activeRole, dest)) {
      showSnackbar(
        language === AppLanguage.AR
          ? "القسم ده مش متاح لحسابك الحالي — تم توجيهك للرئيسية."
          : "This section is not available for your current role."
      );
      setDestination("home");
      return;
    }
    setQuizTabRequested(Boolean(opts?.openQuizTab));
    if (opts?.prompt) setAssistantInitialPrompt(opts.prompt);
    if (opts?.subject) setAssistantInitialSubject(opts.subject);
    setDestination(dest);
  };

  const safeDest = resolveSafeDestination(activeRole, destination);

  return (
    <div data-exam-freeze={examModeActive ? "true" : "false"} className="relative min-h-screen bg-[#070B19]">
      <CosmicParallaxCanvas examModeActive={examModeActive} />
      {!bootComplete && (
        <OrbitalIgnitionSplash language={language} onComplete={() => setBootComplete(true)} />
      )}

      <div className="relative z-10">
        {!signedIn ? (
          <LoginScreen />
        ) : (
          <WorkspaceShell destination={safeDest} onNavigate={(d) => navigate(d)}>
            <div key={safeDest} className="kashkool-warp-enter">
              {safeDest === "home" && <DashboardHomeScreen onNavigate={navigate} />}
              {safeDest === "desk" && <SecretaryDeskScreen />}
              {safeDest === "analytics" && <AttendanceDashboardScreen />}
              {safeDest === "teacher" && <TeacherOpsScreen onNavigate={(d) => navigate(d)} />}
              {safeDest === "courses" && (
                <CoursesAndQuizScreen
                  initialTab={quizTabRequested ? "quiz" : "courses"}
                  onAskAssistant={(prompt, subject) => navigate("assistant", { prompt, subject })}
                />
              )}
              {safeDest === "wallet" && <WalletAndPaymentsScreen />}
              {safeDest === "assistant" && (
                <StudyAssistantScreen
                  initialPrompt={assistantInitialPrompt}
                  initialSubject={assistantInitialSubject}
                  onClearInitialPrompt={() => setAssistantInitialPrompt(null)}
                />
              )}
              {safeDest === "parent" && <ParentPortalScreen onNavigate={(d) => navigate(d)} />}
            </div>
          </WorkspaceShell>
        )}
      </div>
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <KashkoolProvider>
      <KashkoolRouter />
    </KashkoolProvider>
  );
};

export default App;
