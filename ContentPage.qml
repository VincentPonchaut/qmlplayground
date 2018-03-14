import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

Page {
    id: contentPage

    property int reloadCount: 0;
    function reload()
    {
        contentLoader.source = "";

        var targetSrc = targetFile()

        if (targetSrc.length > 0)
            targetSrc += "?" + reloadCount++;

        if (hack.running)
            hack.stop()

        contentLoader.source = targetSrc
    }

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
            source: targetFile()
            property string errorText;
            
            onStatusChanged:
            {
                if (source.length <= 0)
                    return;

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
        TextArea {
            id: errorText
            anchors.centerIn: parent
            color: "red"
            readOnly: true
            visible: contentLoader.source.length > 0 && contentLoader.status == Loader.Error
            
            text: "Errors in the QML file !\n%1".arg(contentLoader.errorText)
        }
    }

    Timer {
        id: hack
        interval: 500
        running: false
        repeat: true

        onTriggered: {
            contentPage.reload();
        }
    }
}
