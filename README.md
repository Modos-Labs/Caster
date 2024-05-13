# Caster

The Caster is a open-source FPGA-based low-latency electrophoretics display controller (EPDC) design that can be embedded into multiple different classes of devices.

This project is the base of the [Glider open source Eink monitor](https://gitlab.com/zephray/Glider). Details of this project are also documented in the Glider documentation.

## License

The design, unless otherwise specified, is released under the CERN Open Source Hardware License version 2 permissive variant, CERN-OHL-P. A copy of the license is provided in the source repository. Additionally, user guide of the license is provided on ohwr.org. Specifically, the core design (caster.v as top level) is entirely licensed under CERN-OHL-P.

Certain target specific IP cores including DDR memory controller, asynchronous FIFO, and PLL are provided by Xilinx and licensed sepearately with use of Xilinx tools. They are not covered under the CERN-OHL-P license.

Simulation code are licensed under MIT.

Provided blue noise texture is converted from http://momentsingraphics.de/BlueNoise.html, which is released in public domain.
