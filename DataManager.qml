import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

QtObject {
    id: dataManager

    // -----------------------------------------------------------------------------
    // Data
    // -----------------------------------------------------------------------------

    property var dataFiles: [
        "C:/Users/Vincent/Desktop/test.json"
    ]

    property var settings: Settings {
        property alias dataFiles: dataManager.dataFiles
        property alias currentDataFile: dataManager.currentDataFile
    }

    property string currentDataFile: dataFiles[0]
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
    }

    onCurrentDataFileChanged: {
        parseData()
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
            Material.theme: Material.Dark
            anchors.fill: parent

            Column {
                anchors.fill: parent
                spacing: 20

                Column {
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    ComboBox {
                        id: dataFileComboBox
                        width: parent.width
                        model: dataManager.dataFiles

                        property bool locked: false

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
                            text: "Clear"
                            onClicked: {
                                dataManager.dataFiles = []
                            }
                        }
                    }
                }

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
