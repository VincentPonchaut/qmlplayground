import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
Pane {
    id: folderSelectorPane

    // Settings
    property alias filterText: filterTextField.text

    function focusFileFilter() {
        filterTextField.forceActiveFocus()
    }

    width: parent.width * 1/4
    Material.theme: Material.Dark
    Material.elevation: 15
    z: contentPage.z + 10
    padding: 0

    focus: state == "open"

    Keys.onUpPressed: {
        print("Up pressed")
        listView.decrementCurrentIndex()
    }
    Keys.onDownPressed:  {
        print("Down pressed")
        listView.incrementCurrentIndex()
    }

    Pane {
        id: folderSectionTitlePane

        width: parent.width
        height: optionsPane.height
        
        Material.elevation: 10
        
        background: Rectangle { color: Qt.darker(Material.background, 1.25) }
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        
        Row {
            id: titleRow

            anchors.centerIn: parent
            height: parent.height
            
            Image {
                height: parent.height
                anchors.margins: 5
                fillMode: Image.PreserveAspectFit
                source: "qrc:///img/folder.svg"
            }
            
            Label {
                text: "Active Folders"
                anchors.verticalCenter: parent.verticalCenter
                color: Material.accent
            }


        }
        SoftIconButton {
            id: filterToggleButton

            height: parent.height * 0.8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: filterPane.visible
            visible: checked || folderSectionTitlePane.hovered

            imageSource: "qrc:///img/search.svg"
            margins: 10
            ToolTip.text: "%1 search field".arg(filterPane.visible ? "Hide" :
                                                                     "Show")

            onClicked: filterPane.toggle()
        }
    }
    
    Pane {
        id: filterPane
        width: parent.width
        height: optionsPane.height

        anchors {
            top: folderSectionTitlePane.bottom
            left: parent.left
            right: parent.right
        }

        function toggle() {
            state = state == "open" ? "closed" : "open"
            if (state == "open")
                filterTextField.forceActiveFocus()
        }

        TextField {
            id: filterTextField
            width: parent.width * 0.77
            anchors.centerIn: parent
            placeholderText: "Filter files..."
            selectByMouse: true
//            onAccepted: {
//                if (quickEditor.state == "open")
//                    quickEditor.focus()
//            }
            onTextChanged: {
                appControl.folderModel.setFilterText(text)
            }
        }

        states: [
            State {
                name: "open"
                PropertyChanges {
                    target: filterPane
                    height: optionsPane.height
                    visible: true
                }
            },
            State {
                name: "closed"
                PropertyChanges {
                    target: filterPane
                    height: 0
                    visible: false
                }
            }
        ]
        state: "closed"
    }

    ListView {
        id: listView
        
        width: parent.width
        height: parent.height - folderSectionTitlePane.height - filterPane.height
        anchors {
            top: filterPane.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        model: appControl.folderModel
        clip: true

        delegate: VisualItemDelegate {
            width: parent.width

            textRole: "name"
            childModel: entries
            childCount: entries.rowCount();
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
            source: "qrc:///img/plus.svg";
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

                background: Rectangle { color: Qt.rgba(0,0,0,.6) }

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

                background: Rectangle { color: Qt.rgba(0,0,0,.6) }

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
            properties: "x";
            easing.type: Easing.InOutQuad
        }
    }

    function toggle() {
        state = (state == "open" ? "closed" : "open");
    }
}
