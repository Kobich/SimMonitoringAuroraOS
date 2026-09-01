#include <QDebug>
#include <QString>

#include <RuntimeManager/RuntimeDispatcher>
#include <RuntimeManager/Task>
#include <flutter/flutter_compatibility_qt.h>

#include "generated_plugin_registrant.h"

namespace {

constexpr auto kMonitorTaskId = "SimMonitorPeriodic";
constexpr auto kBackgroundEntrypoint = "backgroundMain";
constexpr int kMinimumTaskIntervalSeconds = 15 * 60;
constexpr int kTaskMaximumRunningTimeSeconds = 60;

}  // namespace

int main(int argc, char* argv[]) {
  aurora::FlutterApp app(argc, argv);
  aurora::EnableQtCompatibility();

  const auto taskId = qEnvironmentVariable("AURORA_TASK_ID");
  if (taskId == QLatin1String(kMonitorTaskId)) {
    return app.exec(kBackgroundEntrypoint, kFA_GuiType_Disabled);
  }

  auto* dispatcher = RuntimeManager::RuntimeDispatcher::instance();
  dispatcher->onApplicationStarted([] {
    RuntimeManager::Task task(QStringLiteral(kMonitorTaskId));
    task.withInterval(kMinimumTaskIntervalSeconds)
        .withMaximumRunningTime(kTaskMaximumRunningTimeSeconds)
        .withAutostart(true)
        .start();
  });

  return app.exec();
}
