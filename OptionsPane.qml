import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
Pane {
  id: optionsPane

  // Settings
  property alias xRatio: xRatioSlider.value
  property alias yRatio: yRatioSlider.value

  property alias aspectRatioIndex: aspectRatioCombo.currentIndex
  property var selectedAspectRatio: aspectRatioCombo.model[aspectRatioIndex]

  property alias showBorder: showContentBorderCheckBox.checked
  property alias clearConsoleOnReload: clearConsoleCheckbox.checked

  Material.theme: Material.Dark
  background: Rectangle { color: "#1d1d1d" }

  Flow {
    id: contentPageHeader
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 20

    //        width: parent.width * 0.85
//    anchors.horizontalCenter: parent.horizontalCenter

    // Aspect ratio
    ComboBox {
      id: aspectRatioCombo
      Material.theme: Material.Dark
      font.pointSize: 12
      width: 200 * dp

      font.pixelSize: 13 * dp

      ToolTip.visible: aspectRatioCombo.hovered
      ToolTip.text: "Change content's aspect ratio"

//      delegate: ItemDelegate {
//        Material.theme: Material.Dark
//        width: aspectRatioCombo.width
//        highlighted: aspectRatioCombo.highlightedIndex === index
//      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.background.bottom

        text: String("current: %1x%2").arg(contentPage.actualWidth.toFixed(0)).arg(contentPage.actualHeight.toFixed(0))
        color: "lightgrey"
        font.pixelSize: 12 * dp
      }
      delegate: ItemDelegate {
        width: parent.width
        text: modelData[aspectRatioCombo.textRole]
        font.pixelSize: 13 * dp
        font.italic: index === aspectRatioCombo.currentIndex
        opacity: index === aspectRatioCombo.currentIndex ? 0.5 : 1.0
        highlighted: index === aspectRatioCombo.currentIndex
      }
      popup: Popup {
          y: aspectRatioCombo.height - 1
          width: aspectRatioCombo.width
          implicitHeight: contentItem.implicitHeight
          padding: 1

          contentItem: ListView {
              clip: true
              implicitHeight: contentHeight
              model: aspectRatioCombo.popup.visible ? aspectRatioCombo.delegateModel : null
              currentIndex: aspectRatioCombo.highlightedIndex

              ScrollIndicator.vertical: ScrollIndicator { }
          }

          background: Rectangle {
              border.color: "black"
              radius: 2
          }
      }

      textRole: "name"
      model: [
        {
          "name": "Responsive",
          "w" : -1,
          "h" : -1
        },
        {
          "name": "16:9",
          "w" : 1280,
          "h" : 720
        },
        {
          "name": "iPhone X, XS, 11 Pro",
          "w" : 375,
          "h" : 812
        },
        {
          "name": "iPhone 6, 7, 8 Plus",
          "w" : 414,
          "h" : 736
        },
        {
          "name": "Google Pixel 3XL",
          "w" : 412,
          "h" : 847
        },
        {
          "name": "Samsung Galaxy S10",
          "w" : 360,
          "h" : 760
        }
      ]
    }

    Control {
      width: sizeRatioColumn.childrenRect.width
      height: 50 * dp

      ToolTip.visible: !sizeRatioColumn.enabled && hovered
      ToolTip.text: "Select 'Responsive' to enable"

      Column {
        id: sizeRatioColumn
        height: parent.height
        //visible: !settings.applyContentRatio
        enabled: !settings.applyContentRatio

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
    }

    Item {
      id: semanticBlank
      width: 30 * dp
      height: 50 * dp
    }

    CheckBox {
      id: showContentBorderCheckBox
      text: "Border"

      ToolTip.visible: showContentBorderCheckBox.hovered
      ToolTip.text: "Show a glowing border around content"
    }

    Item {
      id: semanticBlank2
      width: 30 * dp
      height: 50 * dp
    }

    // Clear console checkbox
    CheckBox {
      id: clearConsoleCheckbox
//      anchors.verticalCenter: parent.verticalCenter

      text: "Clear console on reload"
    }

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
