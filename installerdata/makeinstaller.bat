set PATH=%PATH%;C:\Qt\5.13.0\msvc2017_64\bin;C:\Qt\Tools\QtInstallerFramework\3.1\bin
cd %~dp0
cd ..

rem copy release folder contents to installerdata/packages/com.vpo.qmlplayground/data
set source=.\release
set destination=.\installerdata\packages\com.vpo.qmlplayground\data
mkdir %destination%\bin
xcopy %source% %destination%\bin /O /X /E /H /K

rem windeployqt
windeployqt --no-translations --no-angle --no-webkit2 --release --qmldir . %destination%\bin\qmlplayground.exe

rem Zipping data
archivegen %destination%\qmlplayground.7z %destination%\bin

rem Delete unzipped data
del /q /f %destination%\bin
rmdir /q /s %destination%\bin

rem create the installer
binarycreator.exe --offline-only -f -p .\installerdata\packages -c .\installerdata\config\config.xml .\installerdata\QmlPlaygroundSetup.exe

rem delete zipped data
del /q /f %destination%\qmlplayground.7z

explorer installerdata\