CALL "%4\vcvarsall.bat" x64
set PATH=%PATH%;%3;

taskkill /F /IM %2.exe

cd "%1\%2"
qmake %2.pro
qmake
nmake


REM Deploy
windeployqt --qmldir . release/%2.exe
start release/%2.exe"