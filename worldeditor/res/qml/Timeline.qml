import QtQuick 2.0
import QtQuick.Controls 2.4
import QtGraphicalEffects 1.0

Rectangle {
    id: rect

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

    property int minStep: 8
    property int maxStep: 40

    property int selectKey: -1
    property int selectRow: -1

    signal addKey(int row, real position)
    signal removeKey(int row, int index)
    signal moveKey(int row, int index, real position)

    MouseArea {
        anchors.fill: parent
        onClicked: {
            selectKey = -1
            selectRow = -1
            clipModel.position = Math.max(Math.round((mouseX - 40) / ruler.stepSize), 0) * ruler.timeScale
        }
        onWheel: {
            if(wheel.angleDelta.y > 0) {
                ruler.stepSize += 1;
                if(ruler.stepSize > maxStep) {
                    if(ruler.timeScale > 0.01) {
                        ruler.stepSize  = minStep;
                        ruler.timeScale/= 5;
                    }
                }
            } else {
                ruler.stepSize -= 1;
                if(ruler.stepSize < minStep) {
                    ruler.stepSize = maxStep;
                    ruler.timeScale*= 5;
                }
            }

        }
    }

    Item {
        id: ruler

        property int index: 0
        property real timeScale: 0.01
        property real timePos: 0.0
        property int stepSize: minStep

        x: 40
        width: parent.width
        height: parent.height

        Repeater {
            model: ruler.width / (ruler.stepSize * 5)
            Rectangle {
                anchors.bottom: ruler.bottom
                height: ruler.height - 12
                width: 1
                color: textColor
                x: index * ruler.stepSize * 5
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    color: textColor
                    text: ((index * 5) * ruler.timeScale).toLocaleString(Qt.locale("en_EN"), 'f', 2).replace('.', ':')
                    font.pointSize: 8
                }
            }
        }

        Repeater {
            model: ruler.width / ruler.stepSize
            Rectangle {
                anchors.bottom: ruler.bottom
                height: ruler.height - 15
                width: 1
                color: textColor
                x: index * ruler.stepSize
            }
        }
    }

    ListView {
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

        model: clipModel
        delegate: Component {
            Rectangle {
                height: 17
                width: ruler.width
                color: "#a0808080"

                property int row: index

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onDoubleClicked: {
                        addKey(row, Math.max(Math.round((mouseX - 40) / ruler.stepSize), 0) * ruler.timeScale)
                    }
                    onClicked: {
                        selectKey = -1
                        selectRow = -1
                    }
                }

                Repeater {
                    model: clipModel.keysCount(row)
                    Rectangle {
                        id: key
                        color: (selectKey == index && selectRow == row) ? hoverBlueColor : "#a0606060"
                        border.color: textColor

                        height: 9
                        width: 9

                        x: ((clipModel.keyPosition(row, index) / 1000.0) / ruler.timeScale) * ruler.stepSize + 40 - 4.5
                        y: 2
                        rotation: 45

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            drag.target: key
                            drag.axis: Drag.XAxis
                            drag.minimumX: 0
                            drag.maximumX: ruler.width

                            drag.onDragFinished: {
                                moveKey(row, index, Math.max(Math.round((key.x - 40) / ruler.stepSize), 0) * ruler.timeScale)
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
    }

    Rectangle {
        id: position

        x: (clipModel.position / ruler.timeScale) * ruler.stepSize + 40
        width: 1
        height: parent.height
        color: redColor
    }

}
