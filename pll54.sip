set_global_assignment -entity "pll54" -library "lib_pll54" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll54" -library "lib_pll54" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "pll54" -library "lib_pll54" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll54" -name SPD_FILE [file join $::quartus(sip_path) "pll54.spd"]

set_global_assignment -library "lib_pll54" -name MISC_FILE [file join $::quartus(sip_path) "pll54_sim/pll54.vo"]
