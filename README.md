This is an implementation of the PDP-11/40 for the Terasic Cyclone V GX Starter Kit.

Features:

- Connected to PiDP-11 panel
- CPU has KJ11, KT11 and KT11-E options
- KL11 and DL11 (for TU58)
- KW11-L
- M9312 console emulator and boot ROMs
- It passes all basic and 11/40 diagnostics
- It can boot XXDP from TU58
- It can boot RT-11 from TU58 (tested 5.3 and 5.7)
- VT52-like terminal built in (see [fpga-vt](https://github.com/aap/fpga-vt))

Issues:

- the PiDP-11 cabling is a mess and not even described here yet

To-do:

- implement a disk with the SD card (RK05, RP03 would be nice)
- ...
