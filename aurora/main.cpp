#include <flutter/flutter_compatibility_qt.h>

#include "generated_plugin_registrant.h"

int main(int argc, char *argv[]) {
  aurora::EnableQtCompatibility();
  aurora::FlutterApp app(argc, argv);
  return app.exec();
}
