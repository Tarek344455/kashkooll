import React, { useState } from "react";
import { KashkoolProvider, useKashkool } from "./context/KashkoolContext";
import { AppDestination } from "./types/kashkool";
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
  const { signedIn } = useKashkool();
  const [destination, setDestination] = useState<AppDestination>("home");
  const [quizTabRequested, setQuizTabRequested] = useState(false);
  const [assistantInitialPrompt, setAssistantInitialPrompt] = useState<string | null>(null);
  const [assistantInitialSubject, setAssistantInitialSubject] = useState<string | null>(null);

  if (!signedIn) {
    return <LoginScreen />;
  }

  const navigate = (
    dest: AppDestination,
    opts?: { openQuizTab?: boolean; prompt?: string; subject?: string }
  ) => {
    setQuizTabRequested(Boolean(opts?.openQuizTab));
    if (opts?.prompt) setAssistantInitialPrompt(opts.prompt);
    if (opts?.subject) setAssistantInitialSubject(opts.subject);
    setDestination(dest);
  };

  return (
    <WorkspaceShell destination={destination} onNavigate={(d) => navigate(d)}>
      {destination === "home" && <DashboardHomeScreen onNavigate={navigate} />}
      {destination === "desk" && <SecretaryDeskScreen />}
      {destination === "analytics" && <AttendanceDashboardScreen />}
      {destination === "teacher" && <TeacherOpsScreen onNavigate={(d) => navigate(d)} />}
      {destination === "courses" && (
        <CoursesAndQuizScreen
          initialTab={quizTabRequested ? "quiz" : "courses"}
          onAskAssistant={(prompt, subject) => navigate("assistant", { prompt, subject })}
        />
      )}
      {destination === "wallet" && <WalletAndPaymentsScreen />}
      {destination === "assistant" && (
        <StudyAssistantScreen
          initialPrompt={assistantInitialPrompt}
          initialSubject={assistantInitialSubject}
          onClearInitialPrompt={() => setAssistantInitialPrompt(null)}
        />
      )}
      {destination === "parent" && <ParentPortalScreen onNavigate={(d) => navigate(d)} />}
    </WorkspaceShell>
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
