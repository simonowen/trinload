@echo off
if not exist code.bin pyz80.py --obj=code.bin -o nul code.asm
trinload.py code.bin
