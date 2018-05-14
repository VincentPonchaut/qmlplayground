import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    visible: true

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

    property string currentFileContents;

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

        // Window position and size
        property alias windowX: root.x
        property alias windowY: root.y
        property alias windowWidth: root.width
        property alias windowHeight: root.height
    }

    // -----------------------------------------------------------------------------
    // View
    // -----------------------------------------------------------------------------

    header: MainToolBar {
        id: mainToolBar
    }

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

                //sourceFilePath: root.currentFile
            }

            QuickEditor {
                id: quickEditor

                height: parent.height
                Behavior on width {
                    NumberAnimation { easing.type: Easing.OutCubic; duration: 500 }
                }

                text: root.currentFileContents
                onRequestFileSave: {
                    print("quick editor requested file save");
                    root.quickEditor_save();
                    print("quick editor requested file save end");
                }
            }
        } // end contentRow
    } // end Pane

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

        width: parent.width * 0.33
        height: parent.height * 0.33
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2

        clip: true

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        function validate() {
            var success = appControl.createFolder(folderCreationDialog.folder, newFolderNameTextField.text);
            if (success)
            {
                var vFolder = folderCreationDialog.folder + "/" + newFolderNameTextField.text
                if (createMainQmlFileWithFolderCheckbox.checked)
                {
                    appControl.createFile(vFolder, 'main.qml');
                    refreshActiveFolders()
                    appControl.currentFile = vFolder + "/main.qml";
                    refreshActiveFolders()
                    // TODO: Scroll to current File
                }
                addToFolderList(vFolder);
            }
            folderCreationPopup.close()
        }

        Labs.FolderDialog {
            id: folderCreationDialog
            folder: root.currentFolder
        }

        padding: 0

        Page {
            anchors.fill: parent
            padding: 0

            Component.onCompleted: newFolderNameTextField.forceActiveFocus()

            header: Pane {
                Material.theme: Material.Dark

                Label {
                    anchors.centerIn: parent
                    text: "Create a new folder"
                    font.pointSize: 16
                }
            }
            Pane {
                width: parent.width
                height: folderCreationPopup.height

                Row {
                    id: newFolderRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Label {
                        id: baseFolderLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(folderCreationDialog.folder).substring(String(folderCreationDialog.folder).lastIndexOf("/") + 1) + "/"
                        font.pointSize: 11

                        property bool hovered: baseFolderLabelMouseArea.containsMouse

                        color: hovered ? Material.accent: Material.foreground

                        ToolTip.visible: hovered
                        ToolTip.text: "%1\nClick to change".arg(String(folderCreationDialog.folder).replace("file:///",""))

                        MouseArea {
                            id: baseFolderLabelMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: folderCreationDialog.open()
                        }
                    }
                    TextField {
                        id: newFolderNameTextField
                        anchors.baseline: baseFolderLabel.baseline
                        placeholderText: "Enter folder name"
                        font.pointSize: baseFolderLabel.font.pointSize
                        selectByMouse: true
                        focus: true

                        onAccepted: folderCreationPopup.validate()
                    }
                }

                CheckBox {
                    id: createMainQmlFileWithFolderCheckbox

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: newFolderRow.bottom
                    anchors.topMargin: 0

                    text: "Create a 'main.qml' file"
                    checked: true
                }
            }

            footer: Pane {
                Row {
                    id: folderCreationPopupValidationButtonsRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: 10

                    // TODO: checkbox "Create main.qml file" ou mieux : une liste editable de fichiers à génerer

                    Button {
                        text: "Create"
                        onClicked: folderCreationPopup.validate()
                    }
                    Button {
                        text: "Cancel"
                        onClicked: folderCreationPopup.close()
                    }
                }
            }
        } //  end page


    }

    Popup {
        id: fileCreationPopup

        width: parent.width * 0.33
        height: parent.height * 0.33
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2

        clip: true
        padding: 0

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        property string folder;

        function openForFolder(pFolderPath) {
            folder = pFolderPath;
            open();
        }

        function validate() {
            var folder = fileCreationPopup.folder.replace("file:///","") + "/"
            var file = newFileNameTextField.text + ".qml"

            var success = appControl.createFile(folder, file);
            if (success)
            {
                // Refresh active folders
                appControl.currentFile = "file:///" + folder + file;
                refreshActiveFolders();

            }
            fileCreationPopup.close()
        }

        Page {
            anchors.fill: parent
            padding: 0

            Component.onCompleted: newFileNameTextField.forceActiveFocus()

            header: Pane {
                Material.theme: Material.Dark

                Label {
                    anchors.centerIn: parent
                    font.pointSize: 16
                    text: "Create a new file"
                }
            }

            Row {
                anchors.centerIn:  parent
                spacing: 20

                Label {
                    id: baseFolderForFileCreationLabel
                    text: fileCreationPopup.folder.substring(fileCreationPopup.folder.lastIndexOf("/") + 1) + "/";
                    font.pointSize: 11

                    MouseArea {
                        id: baseFolderForFileCreationLabelMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                    property bool hovered: baseFolderForFileCreationLabelMouseArea.containsMouse

                    ToolTip.visible: hovered
                    ToolTip.text: fileCreationPopup.folder.replace("file:///","")
                }
                TextField {
                    id: newFileNameTextField
                    anchors.baseline: baseFolderForFileCreationLabel.baseline
                    placeholderText: "Enter file name"
                    text: "main"
                    font.pointSize: baseFolderForFileCreationLabel.font.pointSize
                    selectByMouse: true

                    onAccepted: fileCreationPopup.validate()
                }
                Label {
                    anchors.baseline: baseFolderForFileCreationLabel.baseline
                    text: ".qml"
                    font.pointSize: 11
                }
            }

            footer: Pane {
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: 10

                    Button {
                        text: "Create"
                        onClicked: fileCreationPopup.validate()
                    }
                    Button {
                        text: "Cancel"
                        onClicked: fileCreationPopup.close()
                    }
                }
            }
        }


    }

    // -----------------------------------------------------------------------------
    // Logic
    // -----------------------------------------------------------------------------

    Shortcut {
        id: shortcutFolderSelectorPane
        sequence: "Ctrl+Tab"
        context: Qt.ApplicationShortcut
        onActivated: folderSelectorPane.toggle()
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
            if (folderSelectorPane.state !== "open")
                folderSelectorPane.toggle()
            folderSelectorPane.focusFileFilter()
        }
    }
    Shortcut {
        id: quickEditorToggleShortcut
        sequence: "Ctrl+E"
        context: Qt.ApplicationShortcut
        onActivated: {
            quickEditor.toggle()
        }
    }

    Connections {
        target: appControl
        onFileChanged: handleExternalChanges()
        onDirectoryChanged: handleExternalChanges()
    }

    function handleExternalChanges() {
        root.currentFileChanged();
    }

    function refreshActiveFolders() {
        folderSelectorPane.refresh();
    }

    onCurrentFileChanged: {
        print("current file changed " + root.currentFile)
        root.currentFileContents = readFileContents(root.currentFile)
        contentPage.load();

        if (serverControl.available)
            serverControl.sendToClients(root.currentFileContents);
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

    function editFileLocally(pFile)
    {
        // ensure we do not edit anything that is not current
        appControl.currentFile = pFile

        // ...
        //var vFileContent = readFileContents(pFile) // TODO remove
        //quickEditor.text = vFileContent

        quickEditor.show()
    }

    function editCurrentFileLocally()
    {
        editFileLocally(root.currentFile);
    }

    function quickEditor_save()
    {
        if (!quickEditor.visible)
            return;
        if (!quickEditor.text.length > 0)
            return;

        writeFileContents(appControl.currentFile,
                          quickEditor.text,
                          notifyFileChanged); // emit signal when writing is done
//        appControl.fileChanged(appControl.currentFile)
//        contentPage.load() // TODO: should we reload everything instead ?
    }
    function notifyFileChanged(pFileUrl) {
        appControl.fileChanged(pFileUrl)
        root.currentFileChanged()
    }

    function readFileContents(pPath)
    {
        return appControl.readFileContents(pPath); // make it synchronous
        /*
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "" + appControl.currentFile, false);
        xhr.send(null);

        return xhr.responseText;
        */
    }

    function writeFileContents(fileUrl, text, callback)
    {
        if (appControl.writeFileContents(fileUrl, text))
            callback.call(fileUrl)
        else
            print("Could not write to " + fileUrl)

        // Until I know how to write it synchronously
        /*
        var request = new XMLHttpRequest();
        request.open("PUT", fileUrl, false);

        request.onreadystatechange = function(event) {
            if (request.readyState == XMLHttpRequest.DONE) { // @disable-check M126
                callback.call(fileUrl)
            }
        }

        request.send(text);
        return request.status;
        */
    }
}
