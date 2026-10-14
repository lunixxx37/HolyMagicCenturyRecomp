// Settings menus. Adapted from HarvestMoon64Recomp (GPL-3.0).

#include "hmc_config.h"
#include "recompui/recompui.h"
#include "recompui/config.h"
#include "recompinput/recompinput.h"
#include "ultramodern/config.hpp"
#include "librecomp/files.hpp"
#include "librecomp/config.hpp"
#include "util/file.h"
#include <filesystem>

static void set_control_descriptions() {
    using recompinput::GameInput;
    recompinput::set_game_input_description(GameInput::Y_AXIS_POS, "Move Down / Menu Down");
    recompinput::set_game_input_description(GameInput::Y_AXIS_NEG, "Move Up / Menu Up");
    recompinput::set_game_input_description(GameInput::X_AXIS_NEG, "Move Left / Menu Left");
    recompinput::set_game_input_description(GameInput::X_AXIS_POS, "Move Right / Menu Right");
    recompinput::set_game_input_description(GameInput::A, "Confirm / Talk / Act");
    recompinput::set_game_input_description(GameInput::B, "Cancel");
    recompinput::set_game_input_description(GameInput::START, "Open Menu");
}

void hmc::init_config() {
    std::filesystem::path recomp_dir = recompui::file::get_app_folder_path();

    if (!recomp_dir.empty()) {
        std::filesystem::create_directories(recomp_dir);
    }

    recompui::config::GeneralTabOptions general_options{};
    general_options.has_rumble_strength = true;
    general_options.has_gyro_sensitivity = false;
    general_options.has_mouse_sensitivity = false;
    recompui::config::create_general_tab(general_options);

    recompui::config::create_graphics_tab();

    set_control_descriptions();
    recompui::config::create_controls_tab();

    recompui::config::create_sound_tab();

    recompui::config::create_mods_tab();

    recompui::config::finalize();
}
