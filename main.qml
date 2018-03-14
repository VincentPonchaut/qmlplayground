import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
ApplicationWindow { visible: true
    id: root
    width: 1200
    height: 800

    // -----------------------------------------------------------------------------
    // Data
    // -----------------------------------------------------------------------------

    property var folderList: []
    Binding { target: appControl; property: "folderList"; value: root.folderList; }
    Connections { target: appControl; onFolderListChanged: root.folderList = appControl.folderList; }

    property string currentFolder;
    Binding { target: appControl; property: "currentFolder"; value: root.currentFolder }
    Connections { target: appControl; onCurrentFolderChanged: root.currentFolder = appControl.currentFolder; }

    property string currentFile;
    Binding { target: appControl; property: "currentFile"; value: root.currentFile }
    Connections { target: appControl; onCurrentFileChanged: root.currentFile = appControl.currentFile; }

    Settings {
        id: settings

        // Logic state
        property alias folderList: root.folderList
        property alias currentFolder: root.currentFolder
        property alias currentFile: root.currentFile

        // Options
        property alias showContentBackground: optionsPane.showBackground
        property alias contentXRatio: optionsPane.xRatio //xRatioSlider.value
        property alias contentYRatio: optionsPane.yRatio //yRatioSlider.value

        // Visual states
        property alias folderSelectorPaneState: folderSelectorPane.state
        property alias folderSelectorPaneFilterText: folderSelectorPane.filterText
        property alias optionsPaneState: optionsPane.state
        property alias quickEditorState: quickEditor.state
    }

    // -----------------------------------------------------------------------------
    // View
    // -----------------------------------------------------------------------------

    header: MainToolBar {}

    FolderSelectorPane {
        id: folderSelectorPane

        folders: root.folderList

        height: parent.height

        anchors {
            bottom: parent.bottom
            left: parent.left
            top: parent.top
        }
    }

    Pane {
        width: parent.width - folderSelectorPane.width
        height: parent.height

        anchors {
            left: folderSelectorPane.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        padding: 0

        OptionsPane {
            id: optionsPane

            width: parent.width

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            Material.theme: Material.Dark
        }

//        Pane {
//            id: optionsPane
//            width: parent.width

//            anchors.top: parent.top
//            anchors.left: parent.left
//            anchors.right: parent.right

//            Material.theme: Material.Dark
//            background: Rectangle { color: "#1d1d1d" }

//            Row {
//                id: contentPageHeader
//                spacing: 20

//                width: parent.width * 0.85
//                anchors.horizontalCenter: parent.horizontalCenter

//                Label {
//                    id: filterFilesLabel
//                    text: "Filter files: "
//                    anchors.verticalCenter: parent.verticalCenter
//                }
//                TextField {
//                    id: fileFilterTextField
//                    anchors.baseline: filterFilesLabel.baseline
//                    placeholderText: "Enter search text..."
//                    selectByMouse: true
//                }

//                CheckBox {
//                    id: showContentBackgroundCheckBox
//                    text: "Background"
//                }

//                Column {
//                    id: sizeRatioColumn
//                    height: parent.height

//                    Row {
//                        height: parent.height * 0.5
//                        Label {
//                            text: "Width "
//                            anchors.verticalCenter: parent.verticalCenter
//                        }
//                        Slider {
//                            id: xRatioSlider
//                            anchors.verticalCenter: parent.verticalCenter
//                            from: 0
//                            to: 100
//                            stepSize: 5
//                        }
//                        Label {
//                            anchors.verticalCenter: parent.verticalCenter
//                            text: "%1\%".arg(Math.floor(xRatioSlider.value))
//                        }
//                    }
//                    Row {
//                        height: parent.height * 0.5
//                        Label {
//                            text: "Height"
//                            anchors.verticalCenter: parent.verticalCenter
//                        }
//                        Slider {
//                            id: yRatioSlider
//                            anchors.verticalCenter: parent.verticalCenter
//                            from: 0
//                            to: 100
//                            stepSize: 5
//                        }
//                        Label {
//                            anchors.verticalCenter: parent.verticalCenter
//                            text: "%1\%".arg(Math.floor(yRatioSlider.value))
//                        }
//                    }
//                }
//            } // end contentPageHeader

//            states: [
//                State {
//                    name: "open"
//                    PropertyChanges {
//                        target: optionsPane
//                        y: 0
//                    }
//                },
//                State {
//                    name: "closed"

//                    PropertyChanges {
//                        target: optionsPane
//                        y: -optionsPane.height
//                    }
//                    AnchorChanges {
//                        target: optionsPane
//                        anchors.top: undefined //remove myItem's left anchor
//                    }
//                }
//            ]
//            state: "closed"

//            transitions: Transition {
//                from: "open"
//                to: "closed"
//                reversible: true

//                NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad }
//            }

//            function toggle() {
//                state = (state == "open" ? "closed" : "open");
//            }
//        }

        Row {
            id: contentRow

            width: parent.width
            height: (parent.height - optionsPane.height)

            anchors.top: optionsPane.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            ContentPage {
                id: contentPage
                width: parent.width - quickEditor.width
                height: parent.height
            }

            QuickEditor {
                id: quickEditor
                height: parent.height
                Behavior on width {
                    NumberAnimation { duration: 500 }
                }
            }
        }

        RoundButton {
            id: optionsPaneToggleButton

            anchors.top: parent.top
            anchors.topMargin: optionsPane.height / 2 - height / 2
            anchors.right: parent.right
            anchors.rightMargin: width / 2

            Material.theme: Material.Dark

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                anchors.margins: 5
                source: "qrc:///img/gear.png"
                mipmap: true
            }

            onClicked: optionsPane.toggle()

            ToolTip.visible: hovered
            ToolTip.text: optionsPane.state == "open" ? "Hide options":
                                                        "Show options"
        }
        RoundButton {
            id: helpButton

            width: optionsPaneToggleButton.width
            height: optionsPaneToggleButton.height

            anchors.top: optionsPaneToggleButton.bottom
            anchors.right: parent.right
            anchors.rightMargin: width / 2

            Material.theme: Material.Dark

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                anchors.margins: 5
                source: "qrc:///img/help.svg"
                mipmap: true
            }

            ToolTip.visible: hovered
            ToolTip.text: "\n"
                + "Filter files"         + ": %1 \n".arg(shortcutFileFilter.sequence)
                + "Quick file switch"    + ": %1 \n".arg(shortcutFileSwitcher.sequence)
                + "Toggle folder panel"  + ": %1 \n".arg(shortcutFolderSelectorPane.sequence)
                + "Toggle options panel" + ": %1 \n".arg(shortcutOptionsPane.sequence)
            ;
        }
    }

    // -----------------------------------------------------------------------------
    // Other Views
    // -----------------------------------------------------------------------------

    Labs.FolderDialog {
        id: folderDialog
        folder: root.currentFolder
        onAccepted: addToFolderList(folder)
    }

    Popup {
        id: folderCreationPopup

        width: parent.width * 0.8
        height: parent.height * 0.33
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2

        clip: true

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        Labs.FolderDialog {
            id: folderCreationDialog
            folder: root.currentFolder
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            spacing: 20

            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                Material.elevation: 1

                onClicked: folderCreationDialog.open()

                Image {
                    source: "qrc:///img/folder.svg"
                    anchors.margins: 5
                }
            }

            Label {
                id: baseFolderLabel
                anchors.verticalCenter: parent.verticalCenter
                text: String(folderCreationDialog.folder).replace("file:///","") + "/"
                font.pointSize: 11
            }
            TextField {
                id: newFolderNameTextField
                anchors.baseline: baseFolderLabel.baseline
                placeholderText: "Enter folder name"
                font.pointSize: baseFolderLabel.font.pointSize
                selectByMouse: true
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 10

            // TODO: checkbox "Create main.qml file" ou mieux : une liste editable de fichiers à génerer

            Button {
                text: "Create"
                onClicked: {
                    var success = appControl.createFolder(folderCreationDialog.folder, newFolderNameTextField.text);
                    if (success)
                    {
                        addToFolderList(folderCreationDialog.folder + "/" + newFolderNameTextField.text)
                    }
                    folderCreationPopup.close()
                }
            }
            Button {
                text: "Cancel"
                onClicked: folderCreationPopup.close()
            }
        }
    }

    Popup {
        id: fileCreationPopup

        width: parent.width * 0.8
        height: parent.height * 0.33
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2

        clip: true

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        property string folder;

        function openForFolder(pFolderPath) {
            folder = pFolderPath;
            open();
        }

        Row {
            anchors.centerIn:  parent
            spacing: 20

            Label {
                id: baseFolderForFileCreationLabel
                anchors.baseline: baseFolderLabel.baseline
                text: fileCreationPopup.folder.replace("file:///","") + "/"
                font.pointSize: 11
            }
            TextField {
                id: newFileNameTextField
                anchors.baseline: baseFolderForFileCreationLabel.baseline
                placeholderText: "Enter file name"
                text: "main"
                font.pointSize: baseFolderForFileCreationLabel.font.pointSize
                selectByMouse: true
            }
            Label {
                anchors.baseline: baseFolderForFileCreationLabel.baseline
                text: ".qml"
                font.pointSize: 11
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 10

            Button {
                text: "Create"
                onClicked: {
                    var folder = baseFolderForFileCreationLabel.text
                    var file = newFileNameTextField.text + ".qml"

                    var success = appControl.createFile(folder, file);
                    if (success)
                    {
                        root.currentFile = "file:///" + folder + file
                        editCurrentFileExternally()
                    }
                    fileCreationPopup.close()
                }
            }
            Button {
                text: "Cancel"
                onClicked: fileCreationPopup.close()
            }
        }
    }

    // -----------------------------------------------------------------------------
    // Logic
    // -----------------------------------------------------------------------------

    Shortcut {
        id: shortcutFolderSelectorPane
        sequence: "Tab"
        context: Qt.ApplicationShortcut
        onActivated: folderSelectorPane.toggle()
    }
    Shortcut {
        id: shortcutFileSwitcher
        sequence: "Ctrl+Space"
        context: Qt.ApplicationShortcut
        onActivated: {
            fileComboBox.forceActiveFocus()
            fileComboBox.popup.open()
        }
    }
    Shortcut {
        id: shortcutOptionsPane
        sequence: "F1"
        context: Qt.ApplicationShortcut
        onActivated: optionsPane.toggle()
    }
    Shortcut {
        id: shortcutFileFilter
        sequence: "Ctrl+K"
        context: Qt.ApplicationShortcut
        onActivated: {
            folderSelectorPane.focusFileFilter()
        }
    }
    Shortcut {
        id: quickEditorToggleShortcut
        sequence: "Shift+Tab"
        context: Qt.ApplicationShortcut
        onActivated: {
            quickEditor.toggle()
        }
    }

    Connections {
        target: appControl
        onFileChanged: contentPage.reload();
        onDirectoryChanged: contentPage.reload();
    }

    function refreshFileComboBox(pFileList)
    {
        fileComboBox.mutable = true;
        fileComboBox.fileList = pFileList
        fileComboBox.mutable = false;
    }

    onCurrentFileChanged: {
        print("current file changed " + root.currentFile)
        contentPage.reload();

        quickEditor.blockUpdates = true
        quickEditor.text = readFileContent(root.currentFile)
        quickEditor.blockUpdates = false
    }

    function targetFile() {
        return root.currentFile.length > 0 ? root.currentFile : "";
    }

    function removeFromFolderList(pFolderIndex)
    {
        print("removing folder ", root.folderList[pFolderIndex])

        var copy = root.folderList.slice()
        copy.splice(pFolderIndex,1)
        root.folderList = copy
    }
    function addToFolderList(pFolder)
    {
        print("adding folder ", pFolder)

        var copy = root.folderList.slice()
        copy.push("" + pFolder)
        root.folderList = copy
    }

    function editCurrentFileExternally()
    {
        var vUrl = root.currentFile.replace("file:///", "");
        Qt.openUrlExternally(vUrl);
    }

    function readFileContent(pPath)
    {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "" + appControl.currentFile, false);
        xhr.send(null);

        return xhr.responseText;
    }

    function saveFile(fileUrl, text) {
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);
        request.send(text);
        return request.status;
    }

    function editFileContent(pFile) {
        // ensure we do not edit anything that is not current
        appControl.currentFile = pFile

        // ...
        var vFileContent = readFileContent(pFile)
        quickEditor.text = vFileContent

        quickEditor.show()
    }
}
