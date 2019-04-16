import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

Item {
    id: dataManager

    // -----------------------------------------------------------------------------
    // Data
    // -----------------------------------------------------------------------------

    property var dataFiles: []

    property var settings: Settings {
        property alias dataFiles: dataManager.dataFiles
        property alias currentDataFile: dataManager.currentDataFile
    }

    property string currentDataFile;
    property var dataObject: readFileContents(currentDataFile)

    // -----------------------------------------------------------------------------
    // Logic
    // -----------------------------------------------------------------------------

    function requestEditData() {
        if (!dataPopup.visible)
        {
            dataPopup.show()
        }
        else
        {
            dataPopup.requestActivate()
            dataPopup.raise()
        }
    }

    function parseData() {
        // Read from file
        var vDataObject = readFileContents(dataManager.currentDataFile)

        // Parse the JSON
        vDataObject = JSON.parse(vDataObject);

        // Iterate and require property adding
        for (var vProperty in vDataObject) if (vDataObject.hasOwnProperty(vProperty))
        {
            appControl.addContextProperty(vProperty, vDataObject[vProperty]);
        }

        appControl.sendDataMessage(readFileContents(dataManager.currentDataFile));
    }

    onCurrentDataFileChanged: {
        parseData()
    }

    // Send data to clients as soon as connected
    Connections {
        target: serverControl
        onActiveClientsChanged: {
            appControl.sendDataMessage(readFileContents(dataManager.currentDataFile));
        }
    }


    // -----------------------------------------------------------------------------
    // View
    // -----------------------------------------------------------------------------

    property var dataPopup: Window
    {
        id: dataPopup
        width: 400
        height: 500
        title: "Add custom data"

        Pane {
//            Material.theme: Material.Dark
            anchors.fill: parent

            Page {
                anchors.fill: parent
                spacing: 20

                header: Column {
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    ComboBox {
                        id: dataFileComboBox
                        width: parent.width

                        model: dataManager.dataFiles
                        currentIndex: dataManager.dataFiles.indexOf(dataManager.currentDataFile)

                        property bool locked: false

                        delegate: ItemDelegate {
                            width: dataFileComboBox.width
                            highlighted: dataFileComboBox.highlightedIndex === index

                            contentItem: Column {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 2

                                Label {
                                    height: 30
                                    text: filenameFromUrl(modelData)
                                    font: dataFileComboBox.font
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Label {
                                    height: 10
                                    text: "" + modelData
                                    font.pointSize: 8
                                    font.family: "Segoe UI"
                                    font.italic: true
                                    color: "grey"
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            //                            contentItem: Label {
                            //                                width: parent.width
                            //                                text: modelData
                            ////                                color: "#21be2b"
                            //                                font: control.font
                            //                                elide: Text.ElideLeft
                            //                                verticalAlignment: Text.AlignVCenter
                            //                            }

                            //                            text: filenameFromUrl(modelData)
                            //                            ToolTip.visible: hovered
                            //                            ToolTip.text: modelData

                            //                            Text {
                            //                                anchors.verticalCenter: parent.verticalCenter
                            //                                anchors.right: parent.right
                            //                                anchors.rightMargin: 5
                            //                                text: "" + modelData
                            //                                font.pointSize: 9
                            //                                font.family: "Segoe UI"
                            //                                font.italic: true
                            //                            }

                            function filenameFromUrl(pUrl) {
                                var s = String(pUrl)
                                var i = s.lastIndexOf("/")
                                i++
                                return s.substring(i)
                            }
                        }

                        onCurrentIndexChanged: {
                            if (locked)
                                return;
                            dataManager.currentDataFile = dataManager.dataFiles[currentIndex]
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5

                        ToolButton {
                            text: "Add"
                            onClicked: {
                                dataFileDialog.fileMode = Labs.FileDialog.OpenFile
                                dataFileDialog.open()
                            }
                        }
                        ToolButton {
                            text: "New"
                            onClicked: {
                                dataFileDialog.fileMode = Labs.FileDialog.SaveFile
                                dataFileDialog.open()
                            }
                        }
                        ToolButton {
                            text: "Clear All"
                            onClicked: {
                                dataManager.dataFiles = []
                            }
                        }
                    }
                }

                ScrollView {
                    anchors.fill: parent

//                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    TextArea {
                        width: parent.width
                        text: dataObject

                        selectByKeyboard: true
                        selectByMouse: true
                        //                    tabStopDistance: 4

                        Keys.onTabPressed: {
                            insert(cursorPosition, "    ");
                        }
                        onTextChanged: {
                            writeFileContents(currentDataFile,
                                              text,
                                              function onFileWritten() {
                                                  dataManager.parseData()
                                              })
                        }
                    }
                }
            }

//            ListView {
//                anchors.fill: parent
//                model: dataManager.dataFiles
//                delegate: ItemDelegate {
//                    width: parent.width
//                    text: modelData
//                    highlighted: modelData == dataManager.currentDataFile
//                }
//            }
        }
    }

    property var dataFileDialog: Labs.FileDialog {
        id: dataFileDialog
        onAccepted: {
            dataFileComboBox.locked = true;

            var vCurrentFile = String(currentFile).replace("file:///", "")

            dataManager.dataFiles.push(vCurrentFile);
            dataManager.dataFilesChanged()

            dataManager.currentDataFile = vCurrentFile
            dataFileComboBox.currentIndex = dataFiles.indexOf(dataManager.currentDataFile)

            dataPopup.requestActivate()
            dataPopup.raise()

            dataFileComboBox.locked = false;
        }
    }

    // -----------------------------------------------------------------------------
    // Utils
    // -----------------------------------------------------------------------------

    function readFileContents(pPath)
    {
        return appControl.readFileContents(pPath); // make it synchronous
    }

    function writeFileContents(fileUrl, text, callback)
    {
        if (appControl.writeFileContents(fileUrl, text))
            callback.call(fileUrl)
        else
            print("Could not write to " + fileUrl)
    }
}
