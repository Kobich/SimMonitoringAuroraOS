#include <cstdlib>

#include "generated_plugin_registrant.h"

int main(int argc, char* argv[]) {
  aurora::FlutterApp app(argc, argv);
  if (std::getenv("AURORA_TASK_ID") != nullptr) {
    return app.exec("backgroundMain", kFA_GuiType_Disabled);
  }

  return app.exec();
