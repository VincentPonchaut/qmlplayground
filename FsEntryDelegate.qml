import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.12
import QtQml.Models 2.13

ItemDelegate {
    id: root

    property int row: index
    property var parentIndex: null
    property var modelIndex: parentIndex != null ? fsProxy.index(
                                                       row, 0,
                                                       parentIndex) : fsProxy.index(
                                                       row, 0)
    property var itemData: fsProxy.data(modelIndex,
                                        fsProxy.roleFromString("entry"))

    width: parent.width
    height: childrenRect.height

    Label {
        id: labelRouge
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        verticalAlignment: Text.AlignVCenter

        //text: typeof (itemData) !== "undefined" ? "" + itemData.name : ""
        //        text: String(fsProxy.data(modelIndex, fsProxy.roleFromString(
        //                                      "name"))) + " H " + fsProxy.rowCount(
        //                  modelIndex) + root.row
        text: "" + itemData.name + fsProxy.rowCount(modelIndex)
    }
    ListView {
        anchors.top: labelRouge.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: childrenRect.height

        anchors.leftMargin: 20
        interactive: false

        model: fsProxy.rowCount(modelIndex)
        delegate: Item {
            width: parent.width
            height: childrenLoader.item.height

            Loader {
                id: childrenLoader
                width: parent.width
                height: childrenRect.height
                //                asynchronous: true
            }

            //            BusyIndicator {
            //                width: parent.width
            //                height: parent.height
            //                visible: running
            //                running: childrenLoader.status == Loader.Loading
            //            }
            Component.onCompleted: {
                childrenLoader.setSource("FsEntryDelegate.qml", {
                                             "parentIndex": root.modelIndex
                                         })
            }
        }
    }
}
