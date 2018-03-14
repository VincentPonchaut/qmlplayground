import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import SyntaxHighlighter 1.1
import QtQuick.Window 2.2

import "./palettes/"

Pane {
    id: quickEditor
    property bool blockUpdates: false
    property alias text: quickEditorTextArea.text
    property BasePalette mPalette: DarkPalette {}
    
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

            property int currentLine: cursorRectangle.y / cursorRectangle.height + 1
            
            onTextChanged: {
                if (quickEditor.blockUpdates)
                    return;

                 if (text.length > 0) {
                     saveFile(appControl.currentFile, quickEditorTextArea.text);
                     contentPage.reload()
                }
            }

            // Style
            color: quickEditor.mPalette.editorNormal
            selectionColor: quickEditor.mPalette.editorSelection
            selectedTextColor: quickEditor.mPalette.editorSelectedText

            font.family: "Consolas"
            font.pointSize: 11

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
    
    function show() {
        state = "open"
    }
    function toggle() {
        state = (state == "open" ? "closed" : "open");
        text = readFileContent(appControl.currentFile)
    }
    
    states: [
        State {
            name: "open"
            PropertyChanges {
                target: quickEditor
                width: contentRow.width / 2
            }
        },
        State {
            name: "closed"
            PropertyChanges {
                target: quickEditor
                width: 0
            }
        }
    ]
    state: "closed"
    
}
