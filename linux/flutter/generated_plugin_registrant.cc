//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <restart_app/restart_app_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) restart_app_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "RestartAppPlugin");
  restart_app_plugin_register_with_registrar(restart_app_registrar);
}
