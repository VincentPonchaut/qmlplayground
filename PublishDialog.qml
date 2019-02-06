import QtQuick 2.12
import QtQuick.Controls 2.4
import Qt.labs.platform 1.1

Item {

    property alias qtBinPath: qtBinPathEditor.text
    property alias msvcCmdPath: msvcCmdPathEditor.text
    property alias publishDir: publishtDirTextField.text

    Column {
        width: parent.width
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        FormField {
            label: "Project Name:"

            TextField {
                id: projectNameTextField

                width: parent.remainingWidth
                anchors.verticalCenter: parent.verticalCenter

                placeholderText: "Enter project name"
                selectByMouse: true
            }
        }
        FormField {
            label: "Publish directory:"

            DirectorySelector {
                id: publishtDirTextField

                width: parent.remainingWidth
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Select publish directory..."
            }
        }
        FormField {
            label: "Main file:"

            ComboBox {
                id: mainFileComboBox
                width: parent.remainingWidth

                property var files: appControl.listFiles(get_folder(appControl.currentFile))
                model: files

                onVisibleChanged: {
                    if (!visible)
                        return;

                    // set main if found
                    for (var i = 0; i < files.length; ++i) {
                        if (files[i] == "main.qml") {
                            currentIndex = i
                            break;
                        }
                    }
                }
            }
        }
        FormField {
            label: "App icon:"

            RoundButton {
                id: appIconSelector

                property string selectedFile: appIconPreview.source

                onClicked: fileDialog.open()

                Image {
                    id: appIconPreview
                    anchors.fill: parent
                    anchors.margins: 1
                    fillMode: Image.PreserveAspectFit
                    source: fileDialog.currentFile

                }

                FileDialog {
                    id: fileDialog
                    acceptLabel: "*.png"
                    folder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
                }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: fileDialog.currentFile
            }
        }

        FormField {
            label: "Window title:"

            CheckBox {
                id: windowTitleCheckbox
                text: "Use project name"
                checked: true
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: projectNameTextField.text
                font.italic: true
                visible: windowTitleCheckbox.checked
            }

            TextField {
                id: windowTitleTextField
                visible: !windowTitleCheckbox.checked

                width: parent.width * 1/3
                anchors.verticalCenter: parent.verticalCenter

                placeholderText: "Enter Window title"
                selectByMouse: true
            }
        }
        FormField {
            label: "Window size:"

            Row {
                id: windowSizeEditor
                width: parent.width * 2 / 3
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                property string mode: "presets"

                TextField {
                    id: widthTextField
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Width..."
                    visible: parent.mode !== "presets"
                }

                TextField {
                    id: heightTextField
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Height..."
                    visible: parent.mode !== "presets"
                }
                ComboBox {
                    id: windowSizeComboBox
                    width: widthTextField.width + heightTextField.width + parent.spacing
                    visible: parent.mode == "presets"
                    model: [
                        "Full HD (1920x1080)",
                        "HD (1280x720)",
                        "SD (640x480)"
                    ]
                }
                Button {
                    id: presetCombobox
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.mode == "presets" ? "Manual" : "Presets"
                    onClicked: parent.mode = parent.mode == "presets" ? "nopresets" : "presets"
                }

            }
        }
        FormField {
            label: "Mode: "

            ComboBox {
                width: parent.width / 2
                model: ["Qt 5.12.0 (MSVC 2017 64bits)"]
            }
        }
        FormField {
            label: "Qt path: "

            DirectorySelector {
                id: qtBinPathEditor
                width: parent.remainingWidth
                anchors.verticalCenter: parent.verticalCenter
//                text: "C:/Qt/5.12.0/msvc2017_64/bin"
            }
        }
        FormField {
            label: "MSVC Build tools path: "

            DirectorySelector {
                id: msvcCmdPathEditor
                width: parent.remainingWidth
                anchors.verticalCenter: parent.verticalCenter
//                text: "C:/Program Files (x86)/Microsoft Visual Studio/2017/"
            }
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Publish"
            enabled: is_publishable()

            onClicked: publish()
        }
    }


    function is_publishable() {
        var vSuccess = true;

        // Project name should not be empty
        vSuccess &= (projectNameTextField.text.length > 0)

        // Publish dir should not be empty
        vSuccess &= (publishtDirTextField.text.length > 0)

        // Window title should be valid if specified
        vSuccess &= (windowTitleCheckbox.checked || windowTitleTextField.text.length > 0)

        // Build tools directories must exist
        vSuccess &= (appControl.exists(msvcCmdPathEditor.text) && appControl.exists(qtBinPathEditor.text))

        return vSuccess
    }

    function get_folder(pFile) {
        return pFile.substring(pFile.lastIndexOf("/"), -1) + "/"
    }

    function windowSize() {

        var width = 0
        var height = 0

        if (windowSizeEditor.mode == "presets") {
            // deduce variables from index
            switch (windowSizeComboBox.currentIndex) {
                case 0: // Full HD
                {
                    width = 1920
                    height = 1080
                    break;
                }
                case 1: // HD
                {
                    width = 1280
                    height = 720
                    break;
                }
                case 2: // SD
                {
                    width = 640
                    height = 480
                    break;
                }
            }
        }
        else {
            width = parseInt(widthTextField.text)
            height = parseInt(heightTextField.text)
        }

        return Qt.point(width, height)
    }

    onVisibleChanged: {

        // We only initialize if we are displayed
        if (!visible)
            return;

        // Initialize project name
        var vFolder = get_folder(appControl.currentFile)
        vFolder = chopped(vFolder,1)
        var vProjectName = vFolder.substring(vFolder.lastIndexOf("/") + 1)
        projectNameTextField.text = vProjectName
    }

    function publish() {
        // Nom du projet
        // Qt dir
        // Msvc 2017 64bits dir
        // Titre de la fenetre
        // Taille de la fenetre
        var vProjectName = projectNameTextField.text
        var vPublishDir = publishtDirTextField.text // C:\\Users\\vincent.ponchaut\\Desktop\\TestPublish
        var vWindowTitle = windowTitleCheckbox.checked ? vProjectName : windowTitleTextField.text
        var vWindowWidth = windowSize().x
        var vWindowHeight = windowSize().y

        var vFolder = get_folder(currentFile)
        print("publish start in " + vFolder)

        // List all QML files
        var fileList = appControl.listFiles(vFolder, [
                                                        "*.qml",
                                                        "*.png",
                                                        "*.jpg",
                                                        "*.jpeg",
                                                        "*.gif",
                                                        "*.mp3",
                                                        "*.mp4",
                                                        "*.avi"
                                                     ])
        print(fileList)

        // -----------------------------------------------------------------------------
        // Generate <file>filename</file>
        // -----------------------------------------------------------------------------
        // to be inserted in
        // <RCC>
        //     <qresource prefix="/">
        //         <file>main.qml</file>
        //     </qresource>
        // </RCC>
        var vFileList = "";
        for (var i = 0; i < fileList.length; ++i) {
            vFileList += "\t\t<file>%1</file>\n".arg(fileList[i])
        }
        vFileList += "\t\t<file>qmlplayground_generated_main.qml</file>\n"
        print("fileList:", vFileList)
        print("qrcfile:", qrc_file)

        // -----------------------------------------------------------------------------
        // Generate files
        // -----------------------------------------------------------------------------
        appControl.createFolder(vPublishDir, vProjectName)
        var vTargetFolder = vPublishDir + "/" + vProjectName

        appControl.createFile(vTargetFolder, vProjectName + ".pro")
        appControl.createFile(vTargetFolder, "qml.qrc")
        appControl.createFile(vTargetFolder, "main.cpp")
        appControl.createFile(vTargetFolder, "qmlplayground_generated_main.qml")
        appControl.createFile(vTargetFolder, "build_and_deploy.bat")
        appControl.createFile(vTargetFolder, "qtquickcontrols2.conf")

        appControl.writeFileContents("%1/%2.pro".arg(vTargetFolder).arg(vProjectName), pro_file)
        appControl.writeFileContents("%1/qml.qrc".arg(vTargetFolder), qrc_file.arg(vFileList))
        appControl.writeFileContents("%1/main.cpp".arg(vTargetFolder), main_cpp_file.arg(vProjectName))
        appControl.writeFileContents("%1/qtquickcontrols2.conf".arg(vTargetFolder), qtquickcontrols2_conf) // TODO input args

        // %1 is Window title
        // %2 is Window width
        // %3 is Window height
        // %4 is main file name
        appControl.writeFileContents("%1/qmlplayground_generated_main.qml".arg(vTargetFolder), main_qml_file.arg(vWindowTitle)
                                                                                                            .arg(vWindowWidth)
                                                                                                            .arg(vWindowHeight)
                                                                                                            .arg(mainFileComboBox.currentText))

        // %1 is folder
        // %2 is project name
        // %3 is Qt dir
//        var vQtDir = "C:\\Qt\\5.12.0\\msvc2017_64\\bin"
        var vQtDir = qtBinPathEditor.text
        var vMsvcDir = msvcCmdPathEditor.text
        appControl.writeFileContents("%1/build_and_deploy.bat".arg(vTargetFolder), build_script_bat.arg(vPublishDir)
                                                                                                   .arg(vProjectName)
                                                                                                   .arg(vQtDir)
                                                                                                   .arg(vMsvcDir))
        // -----------------------------------------------------------------------------
        // Prepare command args
        // -----------------------------------------------------------------------------
        vFolder = vFolder.replace("file:///", "")
        vFolder = replaceAll(vFolder, "/", "\\")
        if (vFolder.endsWith("\\")) {
            vFolder = vFolder.substring(0, vFolder.length - 1)
        }

        // -----------------------------------------------------------------------------
        // Copy appIcon to destination
        // -----------------------------------------------------------------------------
        var vSelectedFile = replaceAll(appIconSelector.selectedFile, "file:///", "")
        vSelectedFile = replaceAll(vSelectedFile, "/", "\\")

        appControl.runCommand("cmd /c copy /y \"%1\" \"%2\\appIcon.png\""
                                .arg(replaceAll(vSelectedFile, "/", "\\"))
                                .arg(replaceAll(vTargetFolder, "/", "\\")))

        Qt.openUrlExternally(vTargetFolder)

        // -----------------------------------------------------------------------------
        // Call command
        // -----------------------------------------------------------------------------
        appControl.runCommand("xcopy /y /s %1 %2".arg(vFolder)
                                                 .arg(replaceAll(vTargetFolder, "/", "\\")))


        // -----------------------------------------------------------------------------
        // Build & Deploy
        // -----------------------------------------------------------------------------
        appControl.runAsyncCommand("%1\\build_and_deploy.bat".arg(replaceAll(vTargetFolder, "/", "\\")))

        print("publish end")
        publishDialog.close()
    }

    /*

    property string pro_file: "QT += \\ " + "\n" +
                              "    core gui qml quick \\ " + "\n" +
                              "    quickcontrols2 \\ " + "\n" +
                              "    widgets \\ " + "\n" +
                              "    multimedia sql \\ " + "\n" +
                              "    network websockets \\ " + "\n" +
                              "    xml xmlpatterns svg \\ " + "\n" +
                              "    sensors bluetooth nfc \\ " + "\n" +
                              "    positioning location \\ " + "\n" +
                              "    3dcore 3drender 3dinput 3dquick \\ " + "\n" +
                              "    webview \\ " + "\n" +
                              "    charts "
                              + "\n" +
                              "CONFIG += c++11 "
                              + "\n" +
                              "# The following define makes your compiler emit warnings if you use " + "\n" +
                              "# any Qt feature that has been marked deprecated (the exact warnings " + "\n" +
                              "# depend on your compiler). Refer to the documentation for the " + "\n" +
                              "# deprecated API to know how to port your code away from it. " + "\n" +
                              "DEFINES += QT_DEPRECATED_WARNINGS"
                              + "\n" +
                              "# You can also make your code fail to compile if it uses deprecated APIs. " + "\n" +
                              "# In order to do so, uncomment the following line. " + "\n" +
                              "# You can also select to disable deprecated APIs only up to a certain version of Qt. " + "\n" +
                              "#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0" + "\n" +
                              "SOURCES += \\ " + "\n" +
                              "        main.cpp" + "\n" +
                              "RESOURCES += qml.qrc"
                              + "\n" +
                              "DISTFILES += \\"
                              + "%1" // TODO: add for hot reload /!\ The cpp must not load using qrc:/// for that to work
                              + "\n" +
                              "" + "\n" +
                              "# Copy qml files post build" + "\n" +
                              "win32 {" + "\n" +
                              "    DESTDIR_WIN = $${OUT_PWD}" + "\n" +
                              "    DESTDIR_WIN ~= s,/,\\\\,g" + "\n" +
                              "    PWD_WIN = $${PWD}" + "\n" +
                              "    PWD_WIN ~= s,/,\\\\,g" + "\n" +
                              "    for(FILE, DISTFILES){" + "\n" +
                              "        FILE ~= s,/,\\\\,g" + "\n" +
                              "        QMAKE_POST_LINK += $$quote(cmd /c echo F | xcopy /y /s $$quote($${PWD_WIN}\\\\$${FILE}) $$quote($${DESTDIR_WIN}\\\\$${FILE}$$escape_expand(\\\\n\\\\t)))" + "\n" +
                              "    }" + "\n" +
                              "}"
                              + "\n" +
                              "# Additional import path used to resolve QML modules in Qt Creator's code model " + "\n" +
                              "QML_IMPORT_PATH =" + "\n" +
                              "# Additional import path used to resolve QML modules just for Qt Quick Designer " + "\n" +
                              "QML_DESIGNER_IMPORT_PATH =" + "\n" +
                              "# Default rules for deployment. " + "\n" +
                              "qnx: target.path = /tmp/$${TARGET}/bin " + "\n" +
                              "else: unix:!android: target.path = /opt/$${TARGET}/bin " + "\n" +
                              "!isEmpty(target.path): INSTALLS += target "


    property string qrc_file: "<RCC>\n" +
                              "    <qresource prefix=\"/\">\n" +
                                       "%1" +
                              "        <file>qtquickcontrols2.conf</file>\n" +
                              "        <file>appIcon.png</file>\n" +
                              "    </qresource>\n" +
                              "</RCC>\n"

    property string main_cpp_file: "#include <QGuiApplication>\n" +
                                   "#include <QQmlApplicationEngine>\n" +
                                   "#include <QIcon>\n" +
                                   "\n" +
                                   "int main(int argc, char *argv[])\n" +
                                   "{\n" +
                                   "    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);\n" +
                                   "\n" +
                                   "    QGuiApplication app(argc, argv);\n" +
                                   "    app.setWindowIcon(QIcon(\":/appIcon.png\"));" +
                                   "\n" +
                                   "    QQmlApplicationEngine engine;\n" +
                                   "    engine.load(QUrl(QStringLiteral(\"qrc:/qmlplayground_generated_main.qml\")));\n" +
                                   "    if (engine.rootObjects().isEmpty())\n" +
                                   "        return -1;\n" +
                                   "\n" +
                                   "    return app.exec();\n" +
                                   "}\n"

    property string main_qml_file: "import QtQuick 2.12\n" +
                                   "import QtQuick.Window 2.2\n" +
                                   "\n" +
                                   "Window {\n" +
                                   "    visible: true\n" +
                                   "    width: %2\n" +
                                   "    height: %3\n" +
                                   "    title: qsTr(\"%1\")\n" +
                                   "\n" +
                                   "    Loader {\n" +
                                   "        anchors.fill: parent\n" +
                                   "        asynchronous: true; \n" +
                                   "        source: \"qrc:///%4\"\n" +
                                   "    }\n" +
                                   "}\n"

    // TODO
    property string build_script_bat: "CALL \"C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat\" x64" + "\n" +
                                      "set PATH=%PATH%;%3;" + "\n" +
                                      "\n" +
                                      "taskkill /F /IM %2.exe" + "\n" +
                                      "\n" +
                                      "cd \"%1\\%2\"" + "\n" +
                                      "qmake %2.pro" + "\n" +
                                      "qmake" + "\n" +
                                      "nmake" + "\n" +
                                      "\n" +
                                      "REM Deploy" + "\n" +
                                      "windeployqt --qmldir . release/%2.exe" + "\n" +
                                      "start release/%2.exe"

    // TODO
    property string qtquickcontrols2_conf: "[Controls]" + "\n" +
                                           "Style=Material" + "\n" +
                                           "[Universal]" + "\n" +
                                           "Theme=System" + "\n" +
                                           "Accent=Red" + "\n" +
                                           "[Material]" + "\n" +
                                           "Theme=Dark" + "\n" +
                                           "Accent=Teal" + "\n" +
                                           "Primary=BlueGrey"
    */
    property string pro_file: appControl.readFileContents(":/publishing/template.pro")
    property string qrc_file: appControl.readFileContents(":/publishing/qml.rc")
    property string main_cpp_file: appControl.readFileContents(":/publishing/main.cpp")
    property string main_qml_file: appControl.readFileContents(":/publishing/main.qml")
    property string qtquickcontrols2_conf: appControl.readFileContents(":/publishing/qtquickcontrols2.conf")
    property string build_script_bat: appControl.readFileContents(":/publishing/build_and_deploy.bat")


    function writeFile(fileUrl, text, callback) {
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);

        request.onreadystatechange = function(event) {
            if (request.readyState == XMLHttpRequest.DONE) { // @disable-check M126
                callback.call(fileUrl)
            }
        }

        request.send(text);
        return request.status;
    }

    function escapeRegExp(str) {
        return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
    }
    function replaceAll(str, find, replace) {
        return str.replace(new RegExp(escapeRegExp(find), 'g'), replace);
    }
    function chopped(str, val) {
        if (typeof(val) == "undefined")
            val = 1
        return str.substring(0, str.length - val)
    }

}
