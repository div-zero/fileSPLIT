:intro
@echo --- ----------------------------------
@echo --- ----------------------------------
@echo --- complete build fileSPLIT
@echo --- ----------------------------------
@echo --- ----------------------------------
pause


:settings
rem --- set app_root=trunk
        set app_root=2.02

rem --- set app_repo=file:///D:/%%23SVN-Repository/intelli-bit/fileSPLIT/%%23Src/%app_root%
        set app_repo=file:///D:/%%23SVN-Repository/intelli-bit/fileSPLIT/%%23Src/tags/%app_root%

set drive=T:
set inno="C:\Program Files (x86)\Inno Setup 6\iscc.exe"

call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"


:drive
@echo --- ----------------------------------
@echo --- create virtual drive
@echo --- (for shorter path names) ...
@echo --- ----------------------------------
subst %drive% /D
subst %drive% %CD%
%drive%

@echo --- ----------------------------------
@echo --- clean-up ...
@echo --- ----------------------------------
rd /S /Q "%app_root%"


:prepare
@echo --- ----------------------------------
@echo --- prepare directories ...
@echo --- ----------------------------------
md "\%app_root%"


:checkout
@echo --- ----------------------------------
@echo --- svn checkout ...
@echo --- ----------------------------------
cd "\%app_root%"

svn   export   "%app_repo%"                 --force    "intelli-bit\fileSPLIT\#Src"


:compile
@echo --- ----------------------------------
@echo --- compile all projects ...
@echo --- ----------------------------------
cd "\%app_root%\intelli-bit\fileSPLIT\#Src"

cd App_fileSPLIT
msbuild fileSPLIT.dproj
cd ..
if not exist ..\#Bin\fileSPLIT\fileSPLIT.exe goto err
del /S /Q ..\#Temp\*.dcu


:create_setup
@echo --- ----------------------------------
@echo --- create setup ...
@echo --- ----------------------------------
cd "\%app_root%\intelli-bit\fileSPLIT\#Src\__Setup\fileSPLIT"

%inno% /Q "fileSPLIT.iss" 
IF NOT ERRORLEVEL 0 (GOTO err)  

%inno% /Q "fileSPLIT_portable.iss" 
IF NOT ERRORLEVEL 0 (GOTO err)  


 
:cleanup
@echo --- ----------------------------------
@echo --- clean up virtual drive ...
@echo --- ----------------------------------
subst %drive% /D

goto success


:finish
exit


:success
@echo off
color 3f
@echo ********** SUCCESS!! ********** 
@echo ;-) 
pause
goto finish


:err
@echo off
color 4f
@echo ********** ERROR ********** 
@echo unexpected error; 
@echo sorry, we must quit now :-(
@echo.
@echo.
pause
goto finish


