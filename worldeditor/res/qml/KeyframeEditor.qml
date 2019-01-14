import QtQuick 2.0
import QtQuick.Controls 2.4

Item {
    clip: true

    focus: true
    Keys.onPressed: {
        if(event.key === Qt.Key_Delete) {
            removeKey(selectRow, selectKey)
            selectKey = -1
            selectRow = -1
        }
    }

    Connections {
        target: clipModel
        onLayoutChanged: {
            repeater.model = 0 // to update repeater
            repeater.model = clipModel.rowCount()
        }
    }

    Repeater {
        id: repeater
        anchors.fill: parent

        Rectangle {
            height: rowHeight
            width: rect.width
            y: index * height - (rect.height / vbar.size * vbar.position)
            color: "#a0808080"

            property int row: index

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onDoubleClicked: {
                    addKey(row, Math.max(Math.round((mouseX + posX) / timeStep), 0) * timeScale)
                }
                onClicked: {
                    if(mouse.button === Qt.LeftButton) {
                        selectKey = -1
                        selectRow = -1
                    }

                    if(mouse.button === Qt.RightButton) {
                        menu.x = mouseX
                        menu.y = mouseY
                        menu.open()
                    }
                }

                Menu {
                    id: menu
                    y: parent.height

                    MenuItem {
                        text: qsTr("Add Key")
                        onTriggered: addKey(row, Math.max(Math.round((menu.x + posX) / timeStep), 0) * timeScale)
                    }
                    MenuItem {
                        text: qsTr("Delete Key")
                        visible: (selectRow >= 0 && selectKey >= 0)
                        onTriggered: {
                            var k = selectKey
                            var r = selectRow

                            selectKey = -1
                            selectRow = -1

                            removeKey(r, k)
                        }
                    }
                }
            }

            Repeater {
                id: keys
                model: clipModel.keysCount(row)

                Rectangle {
                    color: (selectKey == index && selectRow == row) ? theme.hoverBlueColor : "#a0606060"
                    border.color: theme.textColor

                    height: 9
                    width: 9

                    x: ((clipModel.keyPosition(row, index) / 1000.0) / timeScale) * timeStep - posX + minStep - 4.5
                    y: 2
                    rotation: 45

                    MouseArea {
                        anchors.fill: parent

                        drag.target: parent
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: rect.width
                        drag.threshold: 0

                        drag.onActiveChanged: {
                            if(!drag.active) {
                                moveKey(row, index, Math.max(Math.round((parent.x + posX) / timeStep), 0) * timeScale)
                            }
                        }

                        onPressed: {
                            selectKey = index
                            selectRow = row
                        }
                    }
                }
            }

            Rectangle {
                 color: "#606060"
                 height: 1
                 anchors.left: parent.left
                 anchors.right: parent.right
                 anchors.bottom: parent.bottom
            }
        }
    }

    ScrollBar {
        id: vbar
        hoverEnabled: true
        active: hovered || pressed
        orientation: Qt.Vertical
        size: parent.height / (repeater.model * rowHeight)
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

}
