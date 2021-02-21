import QtQuick 2.6
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import QtQuick.Window 2.2

import QmlPlayground 1.0

import "./palettes/"

Page {
  id: quickEditor

  property alias text: quickEditorTextArea.text
  property BasePalette mPalette: DarkPalette {}

  signal requestFileSave();

  background: Rectangle {
    color: quickEditor.mPalette.background
  }

  padding: 0
  clip: true

  ScrollView {
    id: scrollView

    //        width: parent.width - lineNumbers.width
    //        height: parent.height

    //        anchors.top: parent.top
    //        anchors.bottom: parent.bottom
    //        anchors.left: lineNumbers.right
    //        anchors.leftMargin: 20
    anchors.fill: parent

    Rectangle {
      id: lineNumbers

      width: column.width * 1.2
      color: quickEditor.mPalette.lineNumbersBackground

      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
      }

      Column {
        id: column
        y: 2.0 * Screen.logicalPixelDensity //- scrollView.contentY
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
          model: quickEditorTextArea.lineCount
          delegate: Text {
            anchors.right: column.right
            color: index + 1 === quickEditorTextArea.currentLine ?
                     quickEditor.mPalette.label :
                     quickEditor.mPalette.lineNumber
            font.family: "Consolas"
            font.pointSize: 11
            font.bold: index + 1 === quickEditorTextArea.currentLine
            text: index + 1
          }
        }
      }
    }

    TextArea {
      id: quickEditorTextArea
      //            anchors.fill: parent
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: lineNumbers.right
      anchors.leftMargin: 20

      selectByMouse: true
      selectByKeyboard: true
      wrapMode: TextEdit.NoWrap

      Keys.onTabPressed: {
        quickEditorTextArea.insert(cursorPosition, "    ");
      }

      property int currentLine: cursorRectangle.y / cursorRectangle.height + 1

      // Style
      color: quickEditor.mPalette.editorNormal
      selectionColor: quickEditor.mPalette.editorSelection
      selectedTextColor: quickEditor.mPalette.editorSelectedText

      font.family: "Consolas"
      font.pointSize: 10.5

      SyntaxHighlighter {
        id: syntaxHighlighter

        normalColor: quickEditor.mPalette.editorNormal
        commentColor: quickEditor.mPalette.editorComment
        numberColor: quickEditor.mPalette.editorNumber
        stringColor: quickEditor.mPalette.editorString
        operatorColor: quickEditor.mPalette.editorOperator
        keywordColor: quickEditor.mPalette.editorKeyword
        builtInColor: quickEditor.mPalette.editorBuiltIn
        markerColor: quickEditor.mPalette.editorMarker
        itemColor: quickEditor.mPalette.editorItem
        propertyColor: quickEditor.mPalette.editorProperty
      }

      Component.onCompleted: {
        syntaxHighlighter.setHighlighter(quickEditorTextArea)
        syntaxHighlighter.rehighlight()
      }
    }
  }

  property bool hasModifications: (quickEditor.text != root.currentFileContents)

  footer: Pane {
    width: parent.width
    height: 50
    //        visible: quickEditor.hasModifications
    padding: 0

    Material.theme: Material.Dark

    Label {
      anchors.centerIn: parent
      text: !quickEditor.hasModifications ? "No changes":
                                            "Pending modifications (Ctrl+S to save)"
      color: !quickEditor.hasModifications ? Material.foreground:
                                             Material.accent
    }

    ToolButton {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      visible: action.enabled

      action: saveAction

      ToolTip.visible: hovered
      ToolTip.text: "Save modifications\n(Ctrl+S)"

      Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: "qrc:///img/save.svg"
      }
    }
  }

  function show() {
    state = "open"
    focus()
  }
  function toggle() {
    state = (state == "open" ? "closed" : "open");
  }
  function focus() {
    quickEditorTextArea.forceActiveFocus()
  }

  Action {
    id: saveAction
    //        text: qsTr("&Save")
    shortcut: StandardKey.Save
    enabled: quickEditor.state == "open" && quickEditor.hasModifications
    onTriggered: {
      quickEditor.requestFileSave()

      //            // temporary hack
      //            quickEditor.hasModifications = false;
      //            quickEditor.hasModifications = Qt.binding(function(){ return (quickEditor.text != root.currentFileContents); })
    }
  }

  states: [
    State {
      name: "open"
      PropertyChanges {
        target: quickEditor
        visible: true
      }
    },
    State {
      name: "closed"
      PropertyChanges {
        target: quickEditor
        visible: false
      }
    }
  ]
  state: "closed"

}
