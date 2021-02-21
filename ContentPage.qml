import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

import QtQuick.Window 2.12

Page {
    id: contentPage
//    property int avelebleWidth: width - (folderSelectorPane.visible ? folderSelectorPane.width : 0) - (quickEditor.visible ? quickEditor.width : 0)
    property int reloadCount: 0;
    property alias actualWidth: contentPane.width
    property alias actualHeight: contentPane.height

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

    padding: 0
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

      property int targetHeight: parent.width * 0.95 * settings.selectedAspectRatio["h"] / settings.selectedAspectRatio["w"]
      property int targetWidth: parent.height * 0.95 * settings.selectedAspectRatio["w"] / settings.selectedAspectRatio["h"]

      height: {
        if (!settings.applyContentRatio)
          return parent.height * settings.contentYRatio / 100;

        if (targetWidth / parent.width > 1)
          return targetHeight
        else
          return parent.height * 0.95
//        if (parent.width > parent.height)
//          return parent.height * 0.95;
//        else
//          return width * settings.selectedAspectRatio["h"] / settings.selectedAspectRatio["w"]
      }
      width: {
        if (!settings.applyContentRatio)
          return parent.width * settings.contentXRatio / 100

        if (targetWidth / parent.width > 1)
          return parent.width * 0.95
        else
          return targetWidth
//        if (parent.width > parent.height)
//          return height * settings.selectedAspectRatio["w"] / settings.selectedAspectRatio["h"]
//        else
//          return parent.width * 0.95
      }

      anchors.centerIn: parent

      clip: true

      padding: 3
      property color borderColor: Material.accent
      SequentialAnimation on borderColor {
        running: true
        loops: Animation.Infinite
        ColorAnimation {
          duration: 2000
          from: Material.accent
          to: "orange"
        }
        ColorAnimation {
          duration: 2000
          from: "orange"
          to: Material.accent
        }
      }
      background: Rectangle {
        color: Material.background

//        border.color: contentPane.borderColor
//        border.width: 3


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

      Rectangle {
        id: contentBorder
        visible: settings.showContentBorder

        anchors.fill: parent
//        anchors.margins: -parent.padding
        anchors.margins: -3
        color: "transparent";

        border.color: contentPane.borderColor
        border.width: 3


      }
    }

    FpsItem {
      anchors.top: parent.top
      anchors.right: parent.right
    }
}
