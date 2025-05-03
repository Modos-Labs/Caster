call C:\Xilinx\14.7\ISE_DS\settings64.bat

call clean.bat

mkdir "../synth/__projnav" > ise_flow_results.txt
mkdir "../synth/xst" >> ise_flow_results.txt
mkdir "../synth/xst/work" >> ise_flow_results.txt

echo Running Synthesis
xst -ifn ise_run.txt -ofn top.syr -intstyle ise >> ise_flow_results.txt

echo Running Translate
ngdbuild -intstyle ise -dd ../synth/_ngo -sd ../ipcore_dir -uc ../constraint.ucf -p xc6slx16-ftg256-3 top.ngc top.ngd >> ise_flow_results.txt

echo Running Map
map -intstyle ise -p xc6slx16-ftg256-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o top_map.ncd top.ngd top.pcf >> ise_flow_results.txt

echo Running Place and Route
par -w -intstyle ise -ol high -mt off top_map.ncd top.ncd top.pcf >> ise_flow_results.txt

echo Running Post PAR Static Timing
trce -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml top.twx top.ncd -o top.twr top.pcf -ucf ../constraint.ucf >> ise_flow_results.txt

echo Running Bitstream Generation
bitgen -intstyle ise -f ise_bitgen.txt top.ncd >> ise_flow_results.txt

echo Done!
