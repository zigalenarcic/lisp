@echo off

lisp test\test_basic.lisp
if %ERRORLEVEL% NEQ 0 goto ERROR

lisp test\test_dynamic_library.lisp
if %ERRORLEVEL% NEQ 0 goto ERROR
echo:
echo Tests SUCCESSFUL!
echo:
exit /b 0

:ERROR
echo:
echo Test FAILED!
echo:
exit /b 1
