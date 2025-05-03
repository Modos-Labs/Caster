@echo off

call clean.bat

echo Building bitstream
call ise_flow.bat
copy top.bit fpga.bit || exit /b
call clean.bat

pause

@echo on