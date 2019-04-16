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

    // Data
    property var folders;
    property ListModel qmlFiles: ListModel {}

    function refresh() {
//        print("refreshing FolderSelectorPane")
        qmlFiles.clear();

        folders.forEach(function(folder) {
            var files = appControl.listFiles(folder);

            files.forEach(function(file)
            {
                if (!String(file).toLowerCase().includes(folderSelectorPane.filterText.toLowerCase()))
                    return;

                qmlFiles.append({
                                    "file" : file,
                                    "folder" : folder
                                });
            })
        });

        var newCurrentIndex = 0;
        for (var i = 0; i < qmlFiles.count; ++i) {
            var qmlFile = qmlFiles.get(i);
            if (qmlFile.file == appControl.currentFile) {
                newCurrentIndex = i
                break;
            }
        }
        listView.currentIndex = newCurrentIndex
    }
    onFoldersChanged: {
        print("foldersChanged from FolderSelectorPane")
        refresh()
    }
    onFilterTextChanged: {
        print("foldersChanged from FolderSelectorPane")
        refresh()
    }

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

    Connections {
        target: listView
        onCurrentIndexChanged: {
            if (listView.currentIndex < 0)
                return;

            var vFilePath = listView.currentItem["filePath"]
            var vFolderPath = listView.currentItem["folderPath"]

            appControl.currentFile = vFilePath
            appControl.currentFolder = vFolderPath
        }
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
            onAccepted: {
                if (quickEditor.state == "open")
                    quickEditor.focus()
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

        clip: true
        
        anchors {
            top: filterPane.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        model: folderSelectorPane.qmlFiles

        property var foldedSections: []

        section.property: "folder"
        section.delegate: ItemDelegate
        {
            id: folderDelegate

            width: parent.width
            height: 55
            background: Rectangle { color: Qt.darker(Material.background) }

            topPadding: 0
            bottomPadding: 0
            rightPadding: 2

            function unfold() {
                var arrCopy = listView.foldedSections.slice();
                var sectionIndex = listView.foldedSections.indexOf(section)
                arrCopy.splice(sectionIndex, 1);
                listView.foldedSections = arrCopy
            }

            function fold() {
                var arrCopy = listView.foldedSections.slice();
                arrCopy.push("" + section);
                listView.foldedSections = arrCopy
            }

            function toggle() {
                if (isFolded)
                    unfold()
                else
                    fold()
            }

            property bool isFolded: (listView.foldedSections.indexOf(section) !== -1)
            Connections {
                target: listView
                onFoldedSectionsChanged: {
                    folderDelegate.isFolded = (listView.foldedSections.indexOf(section) !== -1)
                }
            }

            onClicked: toggle()

            Row {
                height: parent.height

                // Folder icon
                Image {
                    id: sectionHeaderIcon
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 5

                    fillMode: Image.PreserveAspectFit
                    source: folderDelegate.isFolded ? "qrc:///img/folder.svg":
                                                      "qrc:///img/folderOpen.svg";

                }

                // only display the folderName
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        var dirs = section.split("/");
                        return String(dirs[dirs.length - 1]);
                    }
                    font.family: "Montserrat"
                }
            }

            ToolTip.visible: hovered //infoButton.hovered
            ToolTip.delay: 1000
            ToolTip.text: ("" + section).replace("file:///", "")

            // Contextual folder actions
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                visible: folderDelegate.hovered

                IconButton {
                    id: newFileButton

                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: fileCreationPopup.openForFolder(section)
                    imageSource: "qrc:///img/newFile.svg"
                    ToolTip.text: "New file"
                }

                RoundButton {
                    id: infoButton
                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: Qt.openUrlExternally(section)//appControl.runCommand("cmd /c explorer \"%1\"".arg(modelData))

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5

                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: "qrc:///img/folder.svg"
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: "Open in explorer"
                }
                RoundButton {
                    id: trashButton
                    height: parent.height * 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5

                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: "qrc:///img/eye_off.svg"
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: "Stop watching folder"

                    onClicked: {
                        appControl.removeFromFolderList(section)

                        if (folderSelectorPane.qmlFiles.count == 0) {
                            appControl.currentFile = ""
                            appControl.currentFolder = ""
                        }
                    }
                }
            }
        }

        delegate: ItemDelegate
        {
            id: fileDelegate

            property string filePath: ListView.section + file
            property string folderPath: ListView.section

            property bool isSectionFolded: listView.foldedSections.indexOf(ListView.section) !== -1
            property bool matchesFilter: {
                return String(file).toLowerCase().includes(filterTextField.text.toLowerCase());
            }

            width: parent.width
            height: (isSectionFolded || !matchesFilter ) ? 0 : 40

            text: "" + file.substring(1)
            font.pointSize: 10
            font.family: "Segoe UI"

            highlighted: filePath === appControl.currentFile
            //highlighted: ListView.isCurrentItem

            onClicked: {
                listView.currentIndex = index
//                appControl.currentFile = fileDelegate.filePath;
//                appControl.currentFolder = folderPath;
            }

            // Contextual file actions
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                visible: fileDelegate.hovered

                IconButton {
                    id: exploreToButton

                    height: parent.height //* 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: Qt.openUrlExternally(fileDelegate.folderPath)
                    imageSource: "qrc:///img/folder.svg"
                    ToolTip.text: "Open in explorer"
                }

                IconButton {
                    id: editFileButton

                    height: parent.height //* 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: Qt.openUrlExternally(fileDelegate.filePath)
                    imageSource: "qrc:///img/edit.svg"
                    ToolTip.text: "Open file in external editor"
                }

                IconButton {
                    id: editFileContentButton

                    height: parent.height //* 0.8
                    width: height
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: editFileLocally(fileDelegate.filePath);
                    imageSource: "qrc:///img/code.svg"
                    ToolTip.text: "Quick edit"
                }
                // TODO: clone file
                // TODO: remove file
            }

        }
        
    }
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
            onHoveredChanged: {
                if (hovered)
                    focusTimer.restart()
            }
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
            onHoveredChanged: {
                if (hovered)
                    focusTimer.restart()
            }
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
