import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import QtQml.Models 2.2

//Page {
Loader {
  id: folderSelectorPane

  // ---------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------

  // Settings
  property string filterText;
  Binding on filterText {
    when: typeof(folderSelectorPane.item.filterItem) !== "undefined"
    value: folderSelectorPane.item.filterItem.text
  }

  property bool loading: status === Loader.Loading

  // ---------------------------------------------------------------
  // Logic
  // ---------------------------------------------------------------

  onLoaded: {
    folderSelectorPane.item.filterItem.text = filterText
  }

  function focusFileFilter() {
    folderSelectorPane.item.filterItem.forceActiveFocus()
    //        filterTextField.forceActiveFocus()
  }

  function qmlRecursiveCall(pRootItempFunctionName) {
    if (typeof (pRootItem) === "undefined")
      return

    //        print("try to call " + pFunctionName + " on " + pRootItem)
    if (typeof (pRootItem[pFunctionName]) === "function") {
      //            print("\tcalling " + pFunctionName + " on " + pRootItem)
      pRootItem[pFunctionName]()
    }

    for (; i < pRootItem.children.length; ++i) {
      var child = pRootItem.children[i]
      if (typeof (child) === "undefined")
        continue

      qmlRecursiveCall(child, pFunctionName)
    }
  }

  function foldAll() {
    //        qmlRecursiveCall(listView.contentItem, "collapse")
    appControl.folderModel.collapseAll();
  }

  function unfoldAll() {
    //        qmlRecursiveCall(listView.contentItem, "expand")
    appControl.folderModel.expandAll();
  }

  // ---------------------------------------------------------------
  // View
  // ---------------------------------------------------------------
  Material.theme: Material.Dark
  Material.elevation: 10
  z: contentPage.z + 10
  asynchronous: true

  focus: state == "open"

  Keys.onUpPressed: {
    print("Up pressed")
    listView.decrementCurrentIndex()
  }
  Keys.onDownPressed: {
    print("Down pressed")
    listView.incrementCurrentIndex()
  }

  sourceComponent: Page {
    width: parent.width

    property Item filterItem: filterTextField
    padding: 0

    header: Pane {
      id: folderSectionTitlePane

      width: parent.width
      //      height: optionsPane.height
      height: 74 * dp

      Material.elevation: parent.Material.elevation + 1

      background: Rectangle {
        color: Qt.darker(Material.background, 1.25)
      }
      topPadding: 0
      bottomPadding: 0

      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
      }

      Label {
        id: activeFoldersLabel
        anchors.top: parent.top
        topPadding: 10

        text: appControl.folderList.length
              > 0 ? appControl.folderList.length + " Active Folders" : "No active folders"
        verticalAlignment: Label.AlignVCenter
        font.family: "Montserrat, Segoe UI"
        color: "lightgrey"
        font.capitalization: Font.AllUppercase
      }

      Row {
        anchors.top: activeFoldersLabel.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: spacing
        anchors.rightMargin: spacing
        spacing: 5

        Icon {
          id: searchIcon
          height: filterTextField.height * 0.4
          //                margins: 5
          anchors.verticalCenter: parent.verticalCenter
          //                Layout.alignment: Qt.AlignVCenter
          source: "img/search.svg"
          color: filterTextField.text.length > 0 ? "white" : "#60605F"
        }

        TextField {
          id: filterTextField

          width: parent.width - otherActionsRow.width - searchIcon.width
          anchors.baselineOffset: -searchIcon.height / 4

          placeholderText: "Filter files..."

          selectByMouse: true
          onTextChanged: {
            if (text.length !== 0)
              folderSelectorPane.unfoldAll()
            appControl.folderModel.setFilterText("" + text)
          }
          onAccepted: {
            focus = false
          }
        }

        Row {
          id: otherActionsRow
          height: parent.height
          spacing: 0

          IconButton {
            id: foldAllBtn
            height: folderSectionTitlePane.height * 0.5
            width: height

            anchors.verticalCenter: parent.verticalCenter

            //            text: "-"
            imageSource: "qrc:///img/collapse.svg"
            ToolTip.text: "Fold all"

            onClicked: {
              folderSelectorPane.foldAll()
            }

            flat: true
          }
          IconButton {
            id: unfoldAllBtn
            height: folderSectionTitlePane.height * 0.5
            width: height
            anchors.verticalCenter: parent.verticalCenter

            imageSource: "qrc:///img/expand.svg"
            //            text: "+"
            ToolTip.text: "Unfold all"

            onClicked: {
              folderSelectorPane.unfoldAll()
            }

            flat: true
          }
        }
      }
    }

    ScrollView {
      id: listView

      anchors.fill: parent
      clip: true

      Column {
        id: rootCol
        width: parent.width

        //                onHeightChanged: {
        //                    print("\nroot col height is now " + height + " crh is " + childrenRect.height)
        //                }

        Repeater {

          //                    onHeightChanged: {
          //                        print("\nroot loader height is now " + height)
          //                    }

          Binding on model {
            value: appControl.folderModel
            //                        value: appControl.folderList.length
          }

          delegate: Column {
            id: colgate
            width: listView.width

            //                        onHeightChanged: {
            //                            print("\ncolgate %1 height is now ".arg(index) + height + " crh is now " + childrenRect.height)
            //                        }

            property var modelIndex: appControl.folderModel.index(index,0)
            property int rowCount: appControl.folderModel.rowCount(modelIndex)

            property var theEntries;
            property var rootIndex;
            property var rootEntry;

            onModelIndexChanged: {
//              print(this + "model index changed")
              theEntries = appControl.folderModel.data(modelIndex, appControl.folderModel.roleFromString("entries"))
              rootIndex = theEntries.index(0,0)
              rootEntry = theEntries.data(rootIndex, theEntries.roleFromString("entry"))
            }

            //                        onRowCountChanged: {
            //                            print(this + "rowCount changed")
            //                        }
            //                        onEntriesChanged: {
            //                            print(this + "entries Changed")
            //                        }
            //                        onRootIndexChanged: {
            //                            print(this + "rootIndex changed")
            //                        }
            //                        onRootEntryChanged: {
            //                            print(this + "rootEntry changed")
            //                        }

            Loader {
              id: loader
              width: parent.width
              height: item ? item.height : 0
              sourceComponent: FsEntryDelegate2 {}
              //                            asynchronous: true

              Binding {
                target: loader.item
                when: loader.item
                property: "itemData"
                value: colgate.rootEntry
              }

            } // Loader
          } // delegate: Column
        } // Repeater
      } // Column

    } // ListView

    IconButton {
      id: addFolderButton
      width: 60
      height: width
      anchors.bottom: parent.bottom
      anchors.right: parent.right

      backgroundColor: Qt.rgba(0,0,0,0.8)
      ToolTip.visible: false

      //        text: checked ? "x" : "+"
      Image {
        id: addFolderButtonImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: "qrc:///img/plus.svg"
        anchors.margins: 15
        rotation: addFolderButton.checked ? -45 - 90 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: 200
          }
        }
      }

      checkable: true
      checked: false
    }
    Column {
      id: contextualFloatingActionColumn

      anchors.horizontalCenter: addFolderButton.horizontalCenter
      anchors.bottom: addFolderButton.top
      visible: addFolderButton.checked

      Behavior on visible {

        NumberAnimation {
          target: contextualFloatingActionColumn
          property: "opacity"
          from: 0
          to: 1
          duration: 200
          easing.type: Easing.InOutQuad
        }
      }

      IconButton {
        id: createNewFolderButton

        backgroundColor: Qt.rgba(0,0,0,0.8)
        ToolTip.visible: false
        imageSource: "qrc:///img/newFolder.svg"

        onClicked: {
          addFolderButton.checked = false
          folderCreationPopup.open()
        }

        Pane {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.left

          background: Rectangle {
            color: Qt.rgba(0, 0, 0, .6)
          }

          Label {
            anchors.centerIn: parent
            text: "Create new folder"
          }
        }
        //            onHoveredChanged: {
        //                if (hovered)
        //                    focusTimer.restart()
        //            }
      }
      IconButton {
        id: watchAnotherFolderButton
        ToolTip.visible: false
        imageSource: "qrc:///img/eye.svg"

        backgroundColor: Qt.rgba(0,0,0,0.8)

        onClicked: {
          addFolderButton.checked = false
          folderDialog.open()
        }

        Pane {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.left

          background: Rectangle {
            color: Qt.rgba(0, 0, 0, .6)
          }

          Label {
            anchors.centerIn: parent
            text: "Add existing folder"
          }
        }
        //            onHoveredChanged: {
        //                if (hovered)
        //                    focusTimer.restart()
        //            }
      }
    }
  }

  // ---------------------------------------------------------------
  // States & Transitions
  // ---------------------------------------------------------------
  states: [
    State {
      name: "open"
    },
    State {
      name: "closed"
      PropertyChanges {
        target: folderSelectorPane
        visible: false
      }
    }
  ]
  state: "open"

  //    transitions: Transition {
  //        from: "open"
  //        to: "closed"
  //        reversible: true

  //        SmoothedAnimation {
  //            properties: "x"
  ////            easing.type: Easing.InOutQuad
  //            easing.type: Easing.Linear
  //            duration: 350
  //            reversingMode: SmoothedAnimation.Immediate
  //        }
  //    }

  function toggle() {
    state = (state == "open" ? "closed" : "open")
  }
}
