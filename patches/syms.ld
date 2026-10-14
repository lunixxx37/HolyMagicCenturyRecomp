__start = 0x80000000;

/* Dummy addresses that get recompiled into calls to the host functions in src/game/recomp_api.cpp */
recomp_puts = 0x8F000000;
recomp_exit = 0x8F000004;
recomp_error = 0x8F000008;
recomp_get_target_aspect_ratio = 0x8F00001C;
recomp_get_target_framerate = 0x8F000028;
recomp_time_us = 0x8F000050;
recomp_load_overlays = 0x8F000090;
recomp_high_precision_fb_enabled = 0x8F0000A8;
recomp_get_resolution_scale = 0x8F0000AC;
recomp_get_window_resolution = 0x8F0000B0;
recomp_update_inputs = 0x8F0000B4;
