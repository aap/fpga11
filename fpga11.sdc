
create_clock -period 8.000ns [get_ports {CLOCK_125_p}]
create_clock -period 20.000ns [get_ports {CLOCK_50_B5B}]
create_clock -period 20.000ns [get_ports {CLOCK_50_B6A}]
create_clock -period 20.000ns [get_ports {CLOCK_50_B7A}]
create_clock -period 20.000ns [get_ports {CLOCK_50_B8A}]
create_clock -period 50000.000ns [get_pins {vt|I2C_HDMI_Config|mI2C_CTRL_CLK|q}]

set_false_path -from [get_keepers {vt|uart1402|tro}] -to [get_keepers {pdp11|kl11|rxsyn|syn}]
set_false_path -from [get_keepers {pdp11|kl11|uart1402|tro}] -to [get_keepers {vt|rxsyn|syn}]
set_false_path -from [get_keepers {pdp11|kl11|break}] -to [get_keepers {vt|rxsyn|syn}]

derive_pll_clocks
derive_clock_uncertainty
