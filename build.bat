
@if not defined VSINSTALLDIR call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

cl.exe /LD /Fe"test\libtest.dll" /Zi test\libtest.c

nasm.exe -f win64 -g -DWIN32 vm_execute.asm

cl.exe /Fe"lisp.exe" /Zi main.c vm_execute.obj Psapi.lib

