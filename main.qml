import QtQuick 2.6
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import Qt.labs.lottieqt 1.0
import Qt.labs.settings 1.0
import Qt.labs.platform 1.1 as Labs

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
    property alias showContentBorder: optionsPane.showBorder
    property bool applyContentRatio: aspectRatioIndex > 0
    property alias aspectRatioIndex: optionsPane.aspectRatioIndex
    property alias selectedAspectRatio: optionsPane.selectedAspectRatio
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
    property alias windowState: root.visibility

    // Publish dialog
    property alias qtBinPath: publishDialogItem.qtBinPath
    property alias msvcCmdPath: publishDialogItem.msvcCmdPath
    property alias publishDir: publishDialogItem.publishDir

    // Split view
    property var splitViewState
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

  Labs.SystemTrayIcon {
    visible: true
    iconSource: "qrc:///img/console.svg"
    menu: Labs.Menu {
      Labs.MenuItem {
          text: qsTr("Center window")
          onTriggered: {
            root.x = 0
            root.y = 0
            root.showMaximized()
          }
      }
  }
  QtObject {
    id: executionData
    property var expandedState: ({});
  }

  // ------------------------------------------------------------------
  // Behavior
  // ------------------------------------------------------------------

  Component.onCompleted: {
    splitView.restoreState() // TODO
  }
  Component.onDestruction: {
    settings.splitViewState = splitView.saveState()
  }

  // -----------------------------------------------------------------------------
  // View
  // -----------------------------------------------------------------------------
  header: MainToolBar {
    id: mainToolBar
  }

  SplitView {
    id: splitView
    anchors.fill: parent

    handle: Rectangle {
             implicitWidth: 4
             implicitHeight: 4
             color: SplitHandle.pressed ? "black"
                 : (SplitHandle.hovered ? "black" : "#303030")
         }

    FolderSelectorPane {
      id: folderSelectorPane

      //            implicitWidth: parent.width * 1 / 4
      SplitView.minimumWidth: parent.width * 0.2
      SplitView.maximumWidth: parent.width * 0.5
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

      //            implicitWidth: parent.width - folderSelectorPane.implicitWidth
//      SplitView.minimumWidth: parent.width * 0.2
//      SplitView.maximumWidth: parent.width
      SplitView.fillWidth: true
      height: parent.height

      //            anchors {
      //                left: folderSelectorPane.right
      //                right: parent.right
      //                top: parent.top
      //                bottom: parent.bottom
      //            }

      padding: 0

      OptionsPane {
        id: optionsPane

        width: parent.width

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        Material.theme: Material.Dark
      }

      Item {
        id: contentRow

        width: parent.width
        height: (parent.height - optionsPane.height)

        anchors.top: optionsPane.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Column {
          width: parent.width
          height: parent.height
          spacing: 0

          ContentPage {
            id: contentPage
            width: parent.width
            height: theConsole.state == "open" ? parent.height - theConsole.height : parent.height
          }

          Console {
            id: theConsole
            width: parent.width
            height: parent.height * 0.33
          }
        }
      } // end contentRow
    } // end Pane

    QuickEditor {
      id: quickEditor

//      SplitView.minimumWidth: parent.width * 0.2
      SplitView.preferredWidth: parent.width * 0.2
//      SplitView.maximumWidth: parent.width * 0.5
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
  }  // end Main Split View
  // -----------------------------------------------------------------------------
  // Other Views
  // -----------------------------------------------------------------------------

  LoadingOverlay {
    id: loadingOverlay
    anchors.fill: parent
    z: 99999

    loading: folderSelectorPane.loading
    minTimeMs: 1000
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

    function onReloadRequest() {
      handleExternalChanges()
    }

    function onCurrentFileChanged(pFilePath) {
      print("current file changed " + appControl.currentFile)
      root.currentFileContents = readFileContents(appControl.currentFile)
      contentPage.load()
    }

    function onCurrentFolderChanged() {
      print("current folder changed " + appControl.currentFolder)
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
