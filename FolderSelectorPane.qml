import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import QtQml.Models 2.2

//Page {
Pane {
    id: folderSelectorPane

    // ---------------------------------------------------------------
    // Data
    // ---------------------------------------------------------------

    // Settings
    property alias filterText: filterTextField.text

    // ---------------------------------------------------------------
    // Logic
    // ---------------------------------------------------------------
    function focusFileFilter() {
        filterTextField.forceActiveFocus()
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
        qmlRecursiveCall(listView.contentItem, "collapse")
    }

    function unfoldAll() {
        qmlRecursiveCall(listView.contentItem, "expand")
    }

    // ---------------------------------------------------------------
    // View
    // ---------------------------------------------------------------
    width: parent.width * 1 / 4
    Material.theme: Material.Dark
    Material.elevation: 10
    z: contentPage.z + 10
    padding: 0

    focus: state == "open"

    Keys.onUpPressed: {
        print("Up pressed")
        listView.decrementCurrentIndex()
    }
    Keys.onDownPressed: {
        print("Down pressed")
        listView.incrementCurrentIndex()
    }

    Pane {
        id: folderSectionTitlePane

        width: parent.width
        height: optionsPane.height

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

                //                width: parent.width
                //                Layout.alignment: Qt.AlignVCenter //| Qt.AlignBaseline
                //                Layout.fillWidth: true
                width: parent.width - otherActionsRow.width - searchIcon.width
                //                height: parent.height
                //                anchors.baseline: searchIcon.bottom
                anchors.baseline: searchIcon.bottom
                anchors.baselineOffset: -searchIcon.height / 4

                placeholderText: "Filter files..."

                Timer {
                    id: inputTimer
                    interval: 500
                    onTriggered: {
                        appControl.folderModel.setFilterText(filterTextField.text)
                        if (filterTextField.text.length > 0)
                            folderSelectorPane.unfoldAll()
                    }
                }

                selectByMouse: true
                onTextChanged: {
                    if (!inputTimer.running)
                        inputTimer.start()
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

                    text: "-"
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

                    text: "+"
                    ToolTip.text: "Unfold all"

                    onClicked: {
                        folderSelectorPane.unfoldAll()
                    }

                    flat: true
                }
            }
        }
    }


    ListView {
        id: listView

        width: parent.width
        height: parent.height - folderSectionTitlePane.height
        anchors {
            top: folderSectionTitlePane.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        interactive: false
        clip: true

        model: appControl.folderModel
        delegate: Item {
            width: parent.width
            height: childrenRect.height

            DelegateModel {
                id: visualModel
                model: entries
                delegate: FsEntryDelegate {
                    property var fsProxy: entries
                    modelIndex: visualModel.modelIndex(index)
                    parentIndex: visualModel.parentModelIndex()
                }
            }

            ListView {
                width: parent.width
                height: childrenRect.height
                interactive: false

                model: visualModel
            }
        }
    } // ListView

    RoundButton {
        id: addFolderButton
        width: 60
        height: width
        anchors.bottom: parent.bottom
        anchors.right: parent.right

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

    states: [
        State {
            name: "open"
        },
        State {
            name: "closed"
            PropertyChanges {
                target: folderSelectorPane
                x: -folderSelectorPane.width
            }
            AnchorChanges {
                target: folderSelectorPane
                anchors.left: undefined //remove myItem's left anchor
            }
        }
    ]
    state: "open"

    transitions: Transition {
        from: "open"
        to: "closed"
        reversible: true

        NumberAnimation {
            properties: "x"
            easing.type: Easing.InOutQuad
        }
    }

    function toggle() {
        state = (state == "open" ? "closed" : "open")
    }
}
