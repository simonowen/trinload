@echo off
setlocal
set NAME=trinload

if "%1"=="clean" goto clean

pyz80.py -s length -I samdos2 --mapfile=%NAME%.map %NAME%.asm
if errorlevel 1 goto end
if "%1"=="run" start %NAME%.dsk
goto end

:clean
if exist %NAME%.dsk del %NAME%.dsk %NAME%.map

:end
endlocal
