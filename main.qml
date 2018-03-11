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

    property var folderList: [
        "test1",
        "test2",
        "test3",
        "test4",
        "test5"
    ];
    onFolderListChanged: appControl.folderList = folderList

    property string currentFolder;
    Labs.FolderDialog {
        id: folderDialog
        folder: settings.currentFolder
        onAccepted: addToFolderList(folder)
    }

    property string currentFile

    Settings {
        id: settings

        // Logic state
        property alias currentFolder: root.currentFolder
        property alias currentFile: root.currentFile
        property alias folderList: root.folderList

        // Options
        property alias showContentBackground: showContentBackgroundCheckBox.checked
        property alias contentXRatio: xRatioSlider.value
        property alias contentYRatio: yRatioSlider.value
        property alias fileFilterTextFieldText: fileFilterTextField.text

        // Visual states
        property alias folderSelectorPaneState: folderSelectorPane.state
        property alias optionsPaneState: optionsPane.state
    }

    // -----------------------------------------------------------------------------
    // View
    // -----------------------------------------------------------------------------

//    padding: 0

    header: ToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {
                onClicked: folderSelectorPane.toggle()

                Image {
                    id: menuIcon
                    anchors.fill: parent
                    anchors.margins: 5

                    fillMode: Image.PreserveAspectFit

                    states: [
                        State {
                            name: "open"
                            when: folderSelectorPane.state == "open"
                            PropertyChanges {
                                target: menuIcon
                                source: "qrc:///img/backArrow.svg"
                            }
                        },
                        State {
                            name: "closed"
                            when: folderSelectorPane.state == "closed"
                            PropertyChanges {
                                target: menuIcon
                                source: "qrc:///img/menu.svg"
                            }
                        }
                    ]
                }

                ToolTip.visible: hovered
                ToolTip.text: folderSelectorPane.state == "open" ? "Hide folders":
                                                                   "Show folders"
            }
            Row {
                Layout.fillWidth: true
                height: parent.height
                spacing: 5

                Label {
                    id: folderLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: "" + root.currentFolder
                    elide: Label.ElideRight
                    verticalAlignment: Qt.AlignVCenter
                }

                ComboBox {
                    id: fileComboBox
                    width: parent.width - folderLabel.width - editToolButton.width - 3 * parent.spacing
                    editable: true

                    Material.theme: Material.Dark
                    font.pointSize: folderLabel.font.pointSize

                    // TODO: make that property a root one
                    property var fileList;
                    property string textFilter: fileFilterTextField.text;

                    model: fileList.filter(function(item) {
                        return item.indexOf(fileFilterTextField.text) !== -1;
                    });

                    property bool mutable: false;
                    onCurrentTextChanged: {
                        if (!mutable) {
                            root.currentFile = root.currentFolder + currentText;
                            //print("acjanjnsdlaknjsdl : ", root.currentFile)
                        }
                    }
                }
                ToolButton {
                    id: editToolButton
                    text: "Edit"
                    enabled: root.currentFile.length > 0
                    onClicked: editCurrentFileExternally()
                }
            }

            RoundButton {
                Material.theme: Material.Dark
                enabled: root.currentFolder.length > 0
                anchors.rightMargin: 20
                text: "x"
                onClicked: root.currentFolder = ""

                ToolTip.visible: hovered
                ToolTip.text: "Close current folder"
            }
        }
    }

    Pane {
        id: folderSelectorPane

        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.left: parent.left

        width: parent.width * 1/4
        height: parent.height

        Material.theme: Material.Dark
        Material.elevation: 15
        z: contentPage.z + 10
        padding: 0

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

            ToolButton {
                id: newFolderButton

                visible: folderSectionTitlePane.hovered
                anchors.right: parent.right

                onClicked: folderCreationPopup.open()

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    anchors.margins: 5
                    source: "qrc:///img/newFolder.svg"
                    mipmap: true
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

            model: root.folderList

            delegate: ItemDelegate {
                id: folderDelegate
                width: parent.width

                highlighted: (modelData == root.currentFolder);

                // only display the folderName
                text: {
                    var dirs = modelData.split("/");
                    return String(dirs[dirs.length - 1]);
                }

                // Set as current when clicked
                onClicked: {
                    root.currentFolder = modelData
                    reloadLoader()
                }

                ToolTip.visible: hovered //infoButton.hovered
                ToolTip.delay: 1000
                ToolTip.text: ("" + modelData).replace("file:///", "")

                // Contextual folder actions
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    visible: parent.hovered

                    RoundButton {
                        id: newFileButton
                        height: parent.height * 0.8
                        width: height

                        onClicked: fileCreationPopup.open()

                        Image {
                            anchors.fill: parent
                            anchors.margins: 5

                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            source: "qrc:///img/newFile.svg"
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: "New file"
                    }

                    RoundButton {
                        id: infoButton
                        height: parent.height * 0.8
                        width: height

                        onClicked: appControl.runCommand("cmd /c explorer \"%1\"".arg(modelData))

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

                        Image {
                            anchors.fill: parent
                            anchors.margins: 5

                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            source: "qrc:///img/trash.svg"
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: "Remove folder"

                        onClicked: removeFromFolderList(index)
                    }
                }
            }
        }
        RoundButton {
            id: addFolderButton
            width: 60
            height: width
            text: "+"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            onClicked: folderDialog.open()

            ToolTip.visible: hovered
            ToolTip.text: "Add another folder"
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

//        Behavior on x { PropertyAnimation {} }
        transitions: Transition {
            from: "open"
            to: "closed"
            reversible: true

            NumberAnimation { properties: "x"; easing.type: Easing.InOutQuad }
        }

        function toggle() {
            state = (state == "open" ? "closed" : "open");
        }
    }

    Pane {
        width: parent.width - listView.width
        height: parent.height

        anchors.left: folderSelectorPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        padding: 0

        Pane {
            id: optionsPane
            width: parent.width

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            Material.theme: Material.Dark
            background: Rectangle { color: "#1d1d1d" }

            Row {
                id: contentPageHeader
                spacing: 20

                width: parent.width * 0.85
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    id: filterFilesLabel
                    text: "Filter files: "
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextField {
                    id: fileFilterTextField
                    anchors.baseline: filterFilesLabel.baseline
                    placeholderText: "Enter search text..."
                    selectByMouse: true
                }

                CheckBox {
                    id: showContentBackgroundCheckBox
                    text: "Background"
                }

                Column {
                    id: sizeRatioColumn
                    height: parent.height

                    Row {
                        height: parent.height * 0.5
                        Label {
                            text: "Width "
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: xRatioSlider
                            anchors.verticalCenter: parent.verticalCenter
                            from: 0
                            to: 100
                            stepSize: 5
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "%1\%".arg(Math.floor(xRatioSlider.value))
                        }
                    }
                    Row {
                        height: parent.height * 0.5
                        Label {
                            text: "Height"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Slider {
                            id: yRatioSlider
                            anchors.verticalCenter: parent.verticalCenter
                            from: 0
                            to: 100
                            stepSize: 5
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "%1\%".arg(Math.floor(yRatioSlider.value))
                        }
                    }
                }

                /*
                ComboBox {
                    model: ListModel {
                        ListElement { name: "1:1"; xValue: 1; yValue: 1 }
                        ListElement { name: "16:9"; xValue: 16; yValue: 9 }
                    }
                    textRole: "name"
                    onCurrentIndexChanged: {
                        var itemData = model.get(currentIndex);
                        print(itemData)

                        var w = contentPane.authorizedWidth;
                        var h = contentPane.authorizedHeight;

                        if (itemData.xValue > itemData.yValue)
                        {
                            // height is the one to be scaled
                            h *= (itemData.yValue / itemData.xValue)
                        }
                        else if (itemData.xValue < itemData.yValue)
                        {
                            // width is the one to be scaled
                            w *= (itemData.xValue / itemData.yValue)
                        }

                        contentPane.screenXFactor = itemData.xValue
                        contentPane.screenYFactor = itemData.yValue

//                        contentPane.actualWidth = w
//                        contentPane.actualHeight = h
                    }
                }*/
            } // end contentPageHeader

            states: [
                State {
                    name: "open"
                    PropertyChanges {
                        target: optionsPane
                        y: 0
                    }
                },
                State {
                    name: "closed"

                    PropertyChanges {
                        target: optionsPane
                        y: -optionsPane.height
                    }
                    AnchorChanges {
                        target: optionsPane
                        anchors.top: undefined //remove myItem's left anchor
                    }
                }
            ]
            state: "closed"

            transitions: Transition {
                from: "open"
                to: "closed"
                reversible: true

                NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad }
            }

            function toggle() {
                state = (state == "open" ? "closed" : "open");
            }
        }

        Page {
            id: contentPage

            width: parent.width
            height: (parent.height - optionsPane.height)

            anchors.top: optionsPane.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            //padding: paddingSlider.value

            background: Rectangle {
                color: "#4f4f4f"

                Image {
                    anchors.fill: parent
                    source: "qrc:/img/checkerboard.svg";
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }

            Pane {
                id: contentPane

                width: parent.width * xRatioSlider.value / 100
                height: parent.height * yRatioSlider.value / 100
                anchors.centerIn: parent

                clip: true

                background: Rectangle {
                    color: settings.showContentBackground ? Material.background : "transparent";
                    border.color: Material.accent
                    border.width: 3
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
//                    asynchronous: true
                    visible: status == Loader.Ready
                    source: targetFile()
                    property string errorText;

                    onStatusChanged: {
                        if (status == Loader.Error) {
                            contentLoader.errorText = "" + contentLoader.sourceComponent.errorString()
                            contentLoader.errorText = contentLoader.errorText.replace(new RegExp(root.currentFolder, 'g'), "");
                            hack.start()
                        }
                        else if (hack.running) {
                            hack.stop()
                        }
                    }
                }
                Label {
                    id: errorText
                    anchors.centerIn: parent
                    color: "red"
                    visible: contentLoader.status == Loader.Error

                    text: "Errors in the QML file !\n%1".arg(contentLoader.errorText)
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
            anchors.centerIn:  parent
            spacing: 20

            RoundButton {
                anchors.baseline: baseFolderLabel.baseline
                Material.elevation: 1

                onClicked: folderCreationDialog.open()

                Image {
                    source: "qrc:///img/folder.svg"
                    anchors.margins: 5
                }
            }

            Label {
                id: baseFolderLabel
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

//        TextField {
//            id: baseFolderTextField

//            anchors.horizontalCenter: parent.horizontalCenter
//            anchors.left: baseFolderLabel.right
//            anchors.right: parent.right

//            font.pointSize: 10

//            readOnly: true
//            text: root.currentFolder
//        }
//        Label {
//            id: baseFolderLabel
//            text: "Base folder: "

//            anchors.left: parent.left
//            anchors.right: baseFolderTextField.left
//            anchors.verticalCenter: baseFolderTextField.verticalCenter
//        }


//        GridLayout {
////        Grid { spacing: 20
//            anchors.fill: parent
//            columns: 2
//            rows: 2
//            columnSpacing: 20

//            flow: Grid.TopToBottom

//            Label {
//                width: parent.width * 1/5
//                text: "Create in:"
//                horizontalAlignment: Text.AlignRight
//                verticalAlignment: Text.AlignVCenter
//                Layout.fillWidth: true
////                Layout.fillHeight: true
//            }
//            Label {
//                width: parent.width * 1/5
//                text: "Name:"
//                horizontalAlignment: Text.AlignRight
//                verticalAlignment: Text.AlignVCenter
//                Layout.fillWidth: true
////                Layout.fillHeight: true
//            }

//            TextField {
//                width: parent.width * 4/5
//                readOnly: true
//                text: root.currentFolder
//                Layout.fillWidth: true
////                Layout.fillHeight: true
//            }
//            TextField {
//                width: parent.width * 4/5
//                placeholderText: "Enter folder name..."
//                Layout.fillWidth: true
////                Layout.fillHeight: true
//            }
//        }

//        Column {
//            anchors.fill: parent
//            spacing: 20

//            Button {
//                anchors.horizontalCenter: parent.horizontalCenter
//                text: root.currentFolder
//            }
//            TextField {
//                anchors.horizontalCenter: parent.horizontalCenter
//                placeholderText: "Enter folder name..."
//            }
//            Button {
//                anchors.horizontalCenter: parent.horizontalCenter
//                text: "Create"
//            }
//        }
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

        Row {
            anchors.centerIn:  parent
            spacing: 20

            Label {
                id: baseFolderForFileCreationLabel
                anchors.baseline: baseFolderLabel.baseline
                text: root.currentFolder.replace("file:///","") + "/"
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
            if (optionsPane.state == "closed")
                optionsPane.toggle()
            fileFilterTextField.forceActiveFocus()
        }
    }

    Connections {
        target: appControl
        onFileChanged: reloadLoader();
        onDirectoryChanged: reloadLoader();
    }

    function refreshFileComboBox(pFileList)
    {
        fileComboBox.mutable = true;
        fileComboBox.fileList = pFileList
        fileComboBox.mutable = false;
    }

    onCurrentFolderChanged: {
        var qmlFileList = appControl.listFiles(root.currentFolder);

        refreshFileComboBox(qmlFileList);
        fileFilterTextField.text = ""

        if (qmlFileList.indexOf("/main.qml") !== -1)
            root.currentFile = root.currentFolder + "/main.qml";
        else
            root.currentFile = root.currentFolder + qmlFileList[0];
        //root.currentFile = root.currentFolder + "/main.qml"; // Reset current file // TODO: let the combo handle file list and not seek a main
    }
    onCurrentFileChanged: {
        print("current file changed " + root.currentFile)
        var fileName = root.currentFile.replace(root.currentFolder, "");
        print("filename: " + fileName)

        if (fileComboBox.currentText !== fileName)
        {
            var index = fileComboBox.find(fileName);
            if (index === -1)
            {
                var qmlFileList = appControl.listFiles(root.currentFolder);
                refreshFileComboBox(qmlFileList);
                index = fileComboBox.find(fileName);
            }

            fileComboBox.currentIndex = index;
        }

        reloadLoader();
    }

    function targetFile() {
        return root.currentFolder.length > 0 ? root.currentFile : "";
    }

    property int reloadCount: 0;
    function reloadLoader()
    {
        if (root.currentFolder.length > 0)
        {
            var targetSrc = targetFile() //root.currentFolder + "/main.qml";
            contentLoader.source = targetSrc + "?" + reloadCount++;
            console.log(contentLoader.source)
        }
        else
        {
            contentLoader.source = "";
        }
    }

    function removeFromFolderList(pFolderIndex)
    {
        print("removing folder ", root.folderList[pFolderIndex])

        if (root.folderList[pFolderIndex] == root.currentFolder)
            root.currentFolder = "";

        var copy = root.folderList.slice()
        copy.splice(pFolderIndex,1)
        root.folderList = copy
    }
    function addToFolderList(pFolder)
    {
        print("adding folder ", pFolder)
        root.currentFolder = "" + pFolder;

        var copy = root.folderList.slice()
        copy.push("" + pFolder)
        root.folderList = copy
    }

    function editCurrentFileExternally() {

        appControl.runCommand("cmd /c \"start %1\"".arg(root.currentFile.replace("file:///", "")))
        //appControl.runCommandWithArgs("start", [root.currentFile.replace("file:///", "")]);

        //appControl.openFileExternally(root.currentFile.replace("file:///", ""))
        //appControl.runCommand("cmd /c \"start %1\"".arg(commandArg));

//        var commandArg = "";
//        var newPathFields = [];
//        var pathFields = root.currentFile.replace("file:///", "").split("/");

//        pathFields.forEach(function(pPathField)
//        {
//            if (pPathField.indexOf(" ") !== -1)
//            {
//                newPathFields.push("\"" + pPathField+ "\"");
//            }
//            else
//            {
//                newPathFields.push(pPathField);
//            }
//        });

//        commandArg = newPathFields.join("/");
//        commandArg = commandArg.replace(new RegExp("/",'g'), "\\\\")

//        appControl.runCommand("cmd /c \"start %1\"".arg(commandArg));

//        appControl.runCommandWithArgs("cmd /c start",
//                                      [
////                                          "/c",
////                                          "start",
//                                          "\"%1\"".arg(root.currentFile)
//                                      ]);
    }

    Timer {
        id: hack
        interval: 2000
        running: false
        repeat: true

        onTriggered: {
            reloadLoader();
        }
    }
}
