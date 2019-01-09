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
            repeater.model = 0 // to update repeater
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
                x: (index * 5) * stepSize - (posX % (stepSize * 5)) + minStep
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
                x: index * stepSize - (posX % stepSize) + minStep
                color: textColor
            }
        }
    }

    Rectangle {
        id: curveEditor
        anchors.fill: parent
        color: "#f0808080"
        anchors.topMargin: 19
        clip: true

        property int selectKey: -1
        property int selectRow: -1

        property int row: 8

        property variant curve: undefined

        Connections {
            target: clipModel
            onLayoutChanged: {
                var count = clipModel.rowCount()
                if(count >= curveEditor.row) {
                    curveEditor.curve = clipModel.trackData(curveEditor.row)
                }
            }
        }

        onCurveChanged: {
            if(curveEditor.curve != undefined) {
                canvas.componentsNumber = curveEditor.curve[0]
                canvas.keysNumber = curveEditor.curve.length - 1
                canvas.requestPaint()

                points.model = canvas.keysNumber * canvas.componentsNumber
            }
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            contextType: "2d"

            antialiasing: false

            property int stepSize: rect.stepSize
            property int keysNumber: 0
            property int componentsNumber: 0
            property real scale: 0.2

            property int yStep: maxStep
            property int posY: height * 0.5

            property var colors: [Qt.rgba(1,0,0), Qt.rgba(0,1,0), Qt.rgba(0,0,1), Qt.rgba(1,1,0), Qt.rgba(1,0,1), Qt.rgba(0,1,1)]

            property int offset: 1
            property int leftOffset: componentsNumber + offset
            property int rightOffset: componentsNumber * 2 + offset

            function toScreenSpace(pos) {
                return ((pos / 1000.0) / timeScale) * stepSize + minStep
            }

            onStepSizeChanged:requestPaint()

            onPaint: {
                if(curveEditor.curve != undefined) {
                    context.clearRect(0, 0, canvas.width, canvas.height);
                    context.translate(-posX, posY)

                    for(var i = 0; i < componentsNumber; i++) {
                        context.strokeStyle = colors[i]
                        context.beginPath()

                        var key = curveEditor.curve[offset]
                        context.moveTo(toScreenSpace(key[0]), -(key[i + offset] / scale))

                        for(var k = 0; k < curveEditor.curve.length - offset; k++) {
                            var key1 = curveEditor.curve[k + offset]
                            var px1 = toScreenSpace(key1[0])
                            var py1 = -(key1[i + offset] / scale)

                            var d = 0

                            var tx0 = px1
                            var ty0 = py1

                            if((k - 1) >= 0) {
                                var key0 = curveEditor.curve[(k - 1) + offset]
                                var px0 = toScreenSpace(key0[0])
                                var py0 = -(key0[i + offset] / scale)

                                d = (px1 - px0) * 0.5

                                var right = key0[i + rightOffset]
                                tx0 = px0 + d
                                ty0 = -right / scale
                            }
                            var left = key1[i + leftOffset]
                            var tx1 = px1 - d
                            var ty1 = -left / scale

                            context.bezierCurveTo(tx0,ty0, tx1,ty1, px1,py1)
                        }
                        context.stroke();
                    }
                    context.setTransform(1, 0, 0, 1, 0, 0);
                }
            }

        }

        Repeater {
            model: curveEditor.height / maxStep
            Rectangle {
                anchors.left: curveEditor.left
                height: 1
                width: curveEditor.width
                color: hoverColor
                y: index * maxStep + (canvas.posY % maxStep)

                property int shift: canvas.posY / maxStep
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    color: hoverColor
                    text: {
                        var value = -(index - parent.shift) * maxStep * canvas.scale
                        return value.toLocaleString(Qt.locale("en_EN"), 'f', 4)
                    }
                    font.pointSize: 8

                    renderType: Text.NativeRendering
                }
            }
        }

        Repeater {
            id: points

            Item {
                id: item
                property variant key: curveEditor.curve[Math.floor(index / canvas.componentsNumber) + 1]
                property int component: index % canvas.componentsNumber
                property int dist: 50

                x: canvas.toScreenSpace(key[0]) - 3
                y: -key[component + 1] / canvas.scale + canvas.posY - 3

                Rectangle {
                    color: (parent.selectKey === index) ? hoverBlueColor : "#a0606060"
                    border.color: textColor

                    height: 6
                    width: 6

                    rotation: 45

                    MouseArea {
                        anchors.fill: parent

                        drag.target: item
                        drag.axis: Drag.XAxis | Drag.YAxis
                        drag.minimumX: 0
                        drag.maximumX: rect.width
                        drag.minimumY: 0
                        drag.maximumY: rect.height
                        drag.threshold: 0

                        drag.onActiveChanged: {
                            if(!drag.active) {
                                clipModel.setTrackData(curveEditor.row, curveEditor.curve)
                            }
                        }

                        onPositionChanged: {
                            if(drag.active) {
                                var x = Math.round(item.x / stepSize) * stepSize - 6

                                item.key[0] = Math.max(Math.round((x + posX) / stepSize), 0) * timeScale * 1000
                                item.key[item.component + 1] = -(item.y - canvas.posY + 3) * canvas.scale

                                var data = curveEditor.curve;
                                data[Math.floor(index / canvas.componentsNumber) + 1] = item.key
                                curveEditor.curve = data
                            }
                        }

                        onPressed: {
                            selectKey = index
                            //selectRow = row
                        }
                    }
                }

                Rectangle {
                    id: leftTangent
                    visible: (Math.floor(index / canvas.componentsNumber) > 0)
                    color: "#a0606060"
                    border.color: textColor
                    height: 6
                    width: 6

                    x: {
                        var value = item.key[item.component + canvas.leftOffset]
                        return (1.0 / Math.sqrt(item.dist * item.dist + value * value)) * item.dist * -item.dist
                    }
                    y: {
                        var value = item.key[item.component + canvas.leftOffset]
                        return -((1.0 / Math.sqrt(item.dist * item.dist + value * value)) * value) * item.dist
                    }

                    MouseArea {
                        anchors.fill: parent

                        drag.target: parent
                        drag.axis: Drag.XAxis | Drag.YAxis
                        drag.minimumX:-item.dist
                        drag.maximumX: 0
                        drag.minimumY:-item.dist
                        drag.maximumY: item.dist
                        drag.threshold: 0

                        drag.onActiveChanged: {
                            if(!drag.active) {
                                clipModel.setTrackData(curveEditor.row, curveEditor.curve)
                            }
                        }

                        onPositionChanged: {
                            if(drag.active) {
                                if(drag.active) {
                                    item.key[item.component + canvas.leftOffset] = (parent.y / parent.x) * canvas.yStep

                                    var data = curveEditor.curve;
                                    data[Math.floor(index / canvas.componentsNumber) + 1] = item.key
                                    curveEditor.curve = data
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: rightTangent
                    visible: (Math.floor(index / canvas.componentsNumber) < canvas.keysNumber - 1)
                    color: "#a0606060"
                    border.color: textColor
                    height: 6
                    width: 6
                    x: {
                        var value = item.key[item.component + canvas.rightOffset]
                        return (1.0 / Math.sqrt(item.dist * item.dist + value * value)) * item.dist * item.dist
                    }
                    y: {
                        var value = item.key[item.component + canvas.rightOffset]
                        return -((1.0 / Math.sqrt(item.dist * item.dist + value * value)) * value) * item.dist
                    }

                    MouseArea {
                        anchors.fill: parent

                        drag.target: parent
                        drag.axis: Drag.XAxis | Drag.YAxis
                        drag.minimumX: 0
                        drag.maximumX: item.dist
                        drag.minimumY:-item.dist
                        drag.maximumY: item.dist
                        drag.threshold: 0

                        drag.onActiveChanged: {
                            if(!drag.active) {
                                clipModel.setTrackData(curveEditor.row, curveEditor.curve)
                            }
                        }

                        onPositionChanged: {
                            if(drag.active) {
                                item.key[item.component + canvas.rightOffset] = -(parent.y / parent.x) * canvas.yStep

                                var data = curveEditor.curve;
                                data[Math.floor(index / canvas.componentsNumber) + 1] = item.key
                                curveEditor.curve = data
                            }
                        }
                    }
                }
            }


        }

    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 19
        clip: true

        visible: false

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
                width: rect.width
                y: index * height - (rect.height / vbar.size * vbar.position)
                color: "#a0808080"

                property int row: index

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onDoubleClicked: {
                        addKey(row, Math.max(Math.round((mouseX + posX) / stepSize), 0) * timeScale)
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
                            onTriggered: addKey(row, Math.max(Math.round((menu.x + posX) / stepSize), 0) * timeScale)
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
                        color: (selectKey == index && selectRow == row) ? hoverBlueColor : "#a0606060"
                        border.color: textColor

                        height: 9
                        width: 9

                        x: ((clipModel.keyPosition(row, index) / 1000.0) / timeScale) * stepSize - posX + minStep - 4.5
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
                                    moveKey(row, index, Math.max(Math.round((parent.x + posX) / stepSize), 0) * timeScale)
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

        x: (clipModel.position / timeScale) * stepSize - posX + minStep - 1
        width: 2
        height: parent.height
        color: redColor
    }
}
