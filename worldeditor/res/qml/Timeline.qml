import QtQuick 2.0
import QtQuick.Controls 2.4
import QtGraphicalEffects 1.0

import "qrc:/QML/qml/."

Rectangle {
    id: rect

    antialiasing: false
    color: theme.backColor

    property int posX: (width / hbar.size * hbar.position)

    property int rowHeight: 17

    property int selectKey: -1
    property int selectRow: -1

    property int minStep: 8
    property int maxStep: 40

    property int maxPos: 0

    property real timeScale: 0.01
    property int timeStep: minStep

    signal addKey(int row, real position)
    signal removeKey(int row, int index)
    signal moveKey(int row, int index, real position)

    Theme {
        id: theme
    }

    Connections {
        target: clipModel
        onLayoutChanged: {
            maxPos = 0
            for(var i = 0; i < clipModel.rowCount(); i++) {
                maxPos = Math.max(clipModel.keyPosition(i, clipModel.keysCount(i) - 1), maxPos)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            selectKey = -1
            selectRow = -1
            clipModel.position = Math.max(Math.round((mouseX - posX) / timeStep), 0) * timeScale
        }
        onWheel: {
            if(wheel.angleDelta.y > 0) {
                timeStep += 1;
                if(timeStep > maxStep) {
                    if(timeScale > 0.01) {
                        timeStep = minStep;
                        timeScale /= 5;
                    }
                }
            } else {
                timeStep -= 1;
                if(timeStep < minStep) {
                    timeStep = maxStep;
                    timeScale *= 5.0;
                }
            }
        }

        onPositionChanged: {
            if(selectKey == -1) {
                clipModel.position = Math.max(Math.round((mouseX - posX) / timeStep), 0) * timeScale
            }
        }
    }

    Item {
        id: ruler
        x: 0
        width: parent.width
        height: parent.height

        Repeater {
            model: ruler.width / (timeStep * 5)
            Rectangle {
                anchors.bottom: ruler.bottom
                height: ruler.height - 12
                width: 1
                color: theme.textColor
                x: (index * 5) * timeStep - (posX % (timeStep * 5)) + minStep
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    color: theme.textColor
                    text: {
                        var value = ((index + Math.floor(posX / (timeStep * 5))) * 5) * timeScale
                        return value.toLocaleString(Qt.locale("en_EN"), 'f', 2).replace('.', ':')
                    }
                    font.pointSize: 8

                    renderType: Text.NativeRendering
                }
            }
        }

        Repeater {
            model: ruler.width / timeStep
            Rectangle {
                anchors.bottom: ruler.bottom
                height: ruler.height - 15
                width: 1
                x: index * timeStep - (posX % timeStep) + minStep
                color: theme.textColor
            }
        }
    }

    CurveEditor {
        anchors.fill: parent
        anchors.topMargin: 19
        //visible: false

        posX: (width / hbar.size * hbar.position)
        posY: height * 0.5

        row: 8
        timeStep: parent.timeStep
        timeScale: parent.timeScale

        valueStep: parent.timeStep * 2
        valueScale: 1.0//parent.timeScale
    }

    KeyframeEditor {
        //id: keyframeEditor

        anchors.fill: parent
        anchors.topMargin: 19
        visible: false
    }

    ScrollBar {
        id: hbar
        hoverEnabled: true
        active: hovered || pressed
        orientation: Qt.Horizontal
        size: {
            var result = ((maxPos / 1000.0) / timeScale) * parent.timeStep
            return parent.width / (result + maxStep * 2)
        }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Rectangle {
        id: position
        x: (clipModel.position / timeScale) * timeStep - posX + minStep - 1
        width: 2
        height: parent.height
        color: theme.redColor
    }
}
