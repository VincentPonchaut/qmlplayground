import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

import QtQuick.Window 2.12

Page {
    id: contentPage

    property int reloadCount: 0;
    function reload()
    {
        contentLoader.active = false;
        contentLoader.source = "";

        var targetSrc = targetFile()

        if (targetSrc.length > 0)
            targetSrc += "?" + reloadCount++;

        contentLoader.source = targetSrc
        contentLoader.active = true;
    }
    function load() { reload() }

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
        
        width: parent.width * settings.contentXRatio / 100
        height: parent.height * settings.contentYRatio / 100
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
            visible: status == Loader.Ready
//            source: targetFile()
//            asynchronous: true

            property string errorText;
            
            onStatusChanged:
            {
                if (source.length <= 0)
                    return;

                if (status == Loader.Error) {
                    contentLoader.errorText = "" + contentLoader.sourceComponent.errorString()
                    contentLoader.errorText = contentLoader.errorText.replace(new RegExp(appControl.currentFolder, 'g'), "");
                }
                else {
                    contentLoader.errorText = ""
                }
            }
        }
        BusyIndicator {
            anchors.centerIn: parent
            running: contentLoader.status == Loader.Loading
        }
        Text {
            id: errorText
            anchors.fill: parent
            color: "red"
            visible: contentLoader.errorText.length > 0
            text: "Errors in the QML file !\n%1".arg(contentLoader.errorText)
            wrapMode: Text.Wrap

            font.pointSize: 10
        }
    }
}
