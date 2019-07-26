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
    property string currentFileContents

    Settings {
        id: settings

        // Logic state
        //        property alias folderList: root.folderList
        //        property string folderList//: JSON.stringify(appControl.folderList);

        // Options
        property alias showContentBackground: optionsPane.showBackground
        property alias contentXRatio: optionsPane.xRatio //xRatioSlider.value
        property alias contentYRatio: optionsPane.yRatio //yRatioSlider.value
        property alias clearConsoleOnReload: optionsPane.clearConsoleOnReload

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

        // Publish dialog
        property alias qtBinPath: publishDialogItem.qtBinPath
        property alias msvcCmdPath: publishDialogItem.msvcCmdPath
        property alias publishDir: publishDialogItem.publishDir
    }

    DataManager {
        id: dataManager
    }

    QtObject {
        id: ui

        property string defaultFont: productSans.name
        property FontLoader productSans: FontLoader {
            source: "qrc:/fonts/product-sans/Product Sans Regular.ttf"
        }
    }

    // -----------------------------------------------------------------------------
    // View
    // -----------------------------------------------------------------------------
    header: MainToolBar {
        id: mainToolBar
    }

    FolderSelectorPane {
        id: folderSelectorPane

        height: parent.height

        anchors {
            bottom: parent.bottom
            left: parent.left
            top: parent.top
        }

        Label {
            anchors.fill: parent

            visible: appControl.folderList.length === 0

            text: "There are no active folders.\nCreate a new one or add an existing one to start."
            wrapMode: Text.Wrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 40
            font.italic: true
            color: "white"
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

            Column {
                width: parent.width - quickEditor.width
                height: parent.height
                spacing: 0

                ContentPage {
                    id: contentPage
                    width: parent.width
                    height: theConsole.state == "open" ? parent.height * 0.66 : parent.height
                }

                Console {
                    id: theConsole
                    width: parent.width
                    height: parent.height * 0.33
                }
            }

            QuickEditor {
                id: quickEditor

                height: parent.height

                text: root.currentFileContents
                onRequestFileSave: {
                    print("quick editor requested file save")
                    root.quickEditor_save()
                    print("quick editor requested file save end")
                }
                //                Pane {
                //                    width: quickEditor.width
                //                    height: quickEditor.height

                //                    background: Rectangle {
                //                        color: "black"
                //                    }

                //                    Text {
                //                        id: consoleText
                //                        anchors.fill: parent
                //                        font.family: "Consolas"
                //                        color: "white"
                //                    }
                //                }
            }
        } // end contentRow
    } // end Pane

    // -----------------------------------------------------------------------------
    // Other Views
    // -----------------------------------------------------------------------------

    Pane {
        id: loadingOverlay

        anchors.fill: parent
        visible: folderSelectorPane.loading

        Material.theme: Material.Dark
        background: Rectangle { color: Qt.rgba(0,0,0, 1.0) }
        z: 999999999

        BusyIndicator {
            id: busyIndicator
            anchors.centerIn: parent
            width: 100
            height: 100
            running: visible
        }

        Label {
            anchors.top: busyIndicator.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: "QmlPlayground is loading..."
            font.pointSize: 18
        }
    }

    Labs.FolderDialog {
        id: folderDialog
        folder: appControl.currentFolder
        onAccepted: {
            if (appControl.isAlreadyWatched(currentFolder)) {
                // TODO: Send warning
                print("warning: %1 is already being watched.".arg(
                          currentFolder))
            } else {
                appControl.addToFolderList(currentFolder)
            }
        }
    }

    FolderCreationPopup {
        id: folderCreationPopup
    }

    FileCreationPopup {
        id: fileCreationPopup
    }

    // Publish Dialog
    Popup {
        id: publishDialog

        width: parent.width * 0.66
        height: parent.height * 0.66
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2

        clip: true
        padding: 0

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        PublishDialog {
            id: publishDialogItem

            width: publishDialog.width * 0.9
            height: publishDialog.height * 0.9
            anchors.centerIn: parent
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

        //        onFileChanged: handleExternalChanges()
        //        onDirectoryChanged: handleExternalChanges()
        ///onLogMessage: consoleText.text += "\n" + message
        onReloadRequest: {
            //            contentPage.load()
            handleExternalChanges()
        }

        onCurrentFileChanged: {
            print("current file changed " + appControl.currentFile)
            root.currentFileContents = readFileContents(appControl.currentFile)
            contentPage.load()

            //            appControl.sendFolderToClients("");
        }

        onCurrentFolderChanged: {
            print("current folder changed " + appControl.currentFolder)

            //            appControl.sendZippedFolderToClients(appControl.currentFolder)
        }
    }
    onCurrentFileContentsChanged: {

        //        appControl.sendFolderToClients("");
    }

    function handleExternalChanges() {
        print("handleExternalChanges")
        root.currentFileContents = readFileContents(appControl.currentFile)
        contentPage.load()
    }

    function refreshActiveFolders() {//folderSelectorPane.refresh();
    }

    function targetFile() {
        //return root.currentFile.length > 0 ? root.currentFile : "";
        return appControl.currentFile.length > 0 ? appControl.currentFile : ""
    }

    //    function removeFromFolderList(pFolderIndex)
    //    {
    //        print("removing folder ", root.folderList[pFolderIndex])

    //        var copy = root.folderList.slice()
    //        copy.splice(pFolderIndex,1)
    //        root.folderList = copy
    //        root.folderListChanged();
    //    }
    //    function addToFolderList(pFolder)
    //    {
    //        print("adding folder ", pFolder)

    //        var copy = root.folderList.slice()
    //        copy.push("" + pFolder)
    //        root.folderList = copy
    //        root.folderListChanged();
    //    }
    function editCurrentFileExternally() {
        var vUrl = appControl.currentFile.replace("file:///", "")
        Qt.openUrlExternally(vUrl)
    }

    function editFileLocally(pFile) {
        // ensure we do not edit anything that is not current
        appControl.currentFile = pFile

        // ...
        //var vFileContent = readFileContents(pFile) // TODO remove
        //quickEditor.text = vFileContent
        quickEditor.show()
    }

    function editCurrentFileLocally() {
        editFileLocally(appControl.currentFile)
    }

    function quickEditor_save() {
        if (!quickEditor.visible)
            return
        if (!quickEditor.text.length > 0)
            return

        writeFileContents(appControl.currentFile, quickEditor.text,
                          notifyFileChanged) // emit signal when writing is done
        //        appControl.fileChanged(appControl.currentFile)
        //        contentPage.load() // TODO: should we reload everything instead ?
    }
    function notifyFileChanged(pFileUrl) {
        appControl.fileChanged(pFileUrl)
        //        root.currentFileChanged()
    }

    function readFileContents(pPath) {
        return appControl.readFileContents(pPath) // make it synchronous


        /*
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "" + appControl.currentFile, false);
        xhr.send(null);

        return xhr.responseText;
        */
    }

    function writeFileContents(fileUrl, text, callback) {
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
