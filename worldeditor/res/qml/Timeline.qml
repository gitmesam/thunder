import QtQuick 2.0
import QtQuick.Controls 2.4
import QtGraphicalEffects 1.0

Rectangle {
    id: rect

    antialiasing: false

    color: "#606060"
    property string textColor: "#ffffff"
    property string emitterColor: "#40000000"
    property string functionColor: "#40000000"
    property string hoverColor: "#60000000"

    property string blueColor: "#0277bd"
    property string hoverBlueColor: "#0288d1"

    property string greenColor: "#2e7d32"
    property string hoverGreenColor: "#388e3c"

    property string redColor: "#c62828"
    property string hoverRedColor: "#d32f2f"

    property int posX: (width / hbar.size * hbar.position)

    property int rowHeight: 17

    property int selectKey: -1
    property int selectRow: -1

    property int minStep: 8
    property int maxStep: 40

    property int maxPos: 0

    property real timeScale: 0.01
    property int stepSize: minStep

    signal addKey(int row, real position)
    signal removeKey(int row, int index)
    signal moveKey(int row, int index, real position)

    Connections {
        target: clipModel
        onLayoutChanged: {
            repeater.model = 0
            repeater.model = clipModel.rowCount()

            maxPos = 0
            for(var i = 0; i < repeater.model; i++) {
                maxPos = Math.max(clipModel.keyPosition(i, clipModel.keysCount(i) - 1), maxPos)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            selectKey = -1
            selectRow = -1
            clipModel.position = Math.max(Math.round((mouseX - posX) / stepSize), 0) * timeScale
        }
        onWheel: {
            if(wheel.angleDelta.y > 0) {
                stepSize += 1;
                if(stepSize > maxStep) {
                    if(timeScale > 0.01) {
                        stepSize = minStep;
                        timeScale /= 5;
                    }
                }
            } else {
                stepSize -= 1;
                if(stepSize < minStep) {
                    stepSize = maxStep;
                    timeScale *= 5.0;
                }
            }
        }

        onPositionChanged: {
            if(selectKey == -1) {
                clipModel.position = Math.max(Math.round((mouseX - posX) / stepSize), 0) * timeScale
            }
        }
    }

    Item {
        id: ruler
        x: 0
        width: parent.width
        height: parent.height

        property int shift: posX / (stepSize * 5)
        Repeater {
            model: ruler.width / (stepSize * 5)
            Rectangle {
                anchors.bottom: ruler.bottom
                height: ruler.height - 12
                width: 1
                color: textColor
                x: (index * 5) * stepSize - (posX % (stepSize * 5))
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    color: textColor
                    text: {
                        var value = ((index + ruler.shift) * 5) * timeScale
                        return value.toLocaleString(Qt.locale("en_EN"), 'f', 2).replace('.', ':')
                    }
                    font.pointSize: 8

                    renderType: Text.NativeRendering
                }
            }
        }

        Repeater {
            model: ruler.width / stepSize
            Rectangle {
                anchors.bottom: ruler.bottom
                height: ruler.height - 15
                width: 1
                x: index * stepSize - (posX % stepSize)
                color: textColor
            }
        }
    }
    Item {
        id: list
        anchors.fill: parent

        anchors.topMargin: 19
        clip: true

        focus: true
        Keys.onPressed: {
            if(event.key === Qt.Key_Delete) {
                removeKey(selectRow, selectKey)
                selectKey = -1
                selectRow = -1
            }
        }

        Repeater {
            id: repeater
            anchors.fill: parent

            Rectangle {
                height: rowHeight
                width: ruler.width
                y: index * height - (rect.height / vbar.size * vbar.position)
                color: "#a0808080"

                property int row: index

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onDoubleClicked: {
                        addKey(row, Math.max(Math.round((mouseX - posX) / stepSize), 0) * timeScale)
                    }
                    onClicked: {
                        selectKey = -1
                        selectRow = -1

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
                            onTriggered: addKey(row, Math.max(Math.round((menu.x - posX) / stepSize), 0) * timeScale)
                        }
                        MenuItem {
                            text: qsTr("Delete Key")
                            onTriggered: removeKey(selectRow, selectKey)
                        }
                    }
                }

                Repeater {
                    id: keys
                    model: clipModel.keysCount(row)

                    Rectangle {
                        id: key
                        color: (selectKey == index && selectRow == row) ? hoverBlueColor : "#a0606060"
                        border.color: textColor

                        height: 9
                        width: 9

                        x: ((clipModel.keyPosition(row, index) / 1000.0) / timeScale) * stepSize - posX - 4.5
                        y: 2
                        rotation: 45

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            drag.target: key
                            drag.axis: Drag.XAxis
                            drag.minimumX: 0
                            drag.maximumX: ruler.width
                            drag.threshold: 0

                            drag.onActiveChanged: {
                                if(!drag.active) {
                                    moveKey(row, index, Math.max(Math.round((key.x - posX) / stepSize), 0) * timeScale)
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

        ScrollBar {
            id: hbar
            hoverEnabled: true
            active: hovered || pressed
            orientation: Qt.Horizontal
            size: {
                var result = ((maxPos / 1000.0) / timeScale) * rect.stepSize
                return parent.width / (result + maxStep * 2)
            }
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    Rectangle {
        id: position

        x: (clipModel.position / timeScale) * stepSize - posX
        width: 1
        height: parent.height
        color: redColor
    }
}
