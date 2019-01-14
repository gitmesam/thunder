import QtQuick 2.0
import QtQuick.Controls 2.4

Rectangle {
    id: curveEditor

    color: "#f0808080"
    clip: true

    property int selectKey: -1
    property int selectComponent: -1

    property int row: 0
    property variant curve: clipModel.trackData(row)

    property int timeStep: minStep
    property real timeScale: 0.01

    property int valueStep: minStep
    property real valueScale: 0.01

    property int posX: 0
    property int posY: 0

    property bool braked: false

    onPosXChanged: canvas.requestPaint()
    onPosYChanged: canvas.requestPaint()

    Connections {
        target: clipModel
        onLayoutChanged: {
            points.model = 0
            curve = undefined
            var count = clipModel.rowCount()
            if(count >= row) {
                curve = clipModel.trackData(row)

                var minValue = Number.MAX_VALUE
                var maxValue = Number.MIN_VALUE
                for(var i = 0; i < canvas.componentsNumber; i++) {
                    for(var k = 0; k < curve.length - canvas.offset; k++) {
                        var key = curve[k + canvas.offset]
                        var py = -(key[i + canvas.offset])

                        minValue = Math.min(py, minValue)
                        maxValue = Math.max(py, maxValue)
                    }
                }
                //canvas.valueScale = (Math.abs(minValue) + Math.abs(maxValue)) / curveEditor.height
            }
            canvas.requestPaint()
        }
    }

    onCurveChanged: {
        if(curve !== undefined) {
            canvas.componentsNumber = curve[0]
            canvas.keysNumber = (curve.length - 1)
            canvas.requestPaint()

            points.model = canvas.keysNumber * canvas.componentsNumber
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        contextType: "2d"

        antialiasing: false

        property int timeStep: rect.timeStep
        property int keysNumber: 0
        property int componentsNumber: 0

        property var colors: [Qt.rgba(1,0,0), Qt.rgba(0,1,0), Qt.rgba(0,0,1), Qt.rgba(1,1,0), Qt.rgba(1,0,1), Qt.rgba(0,1,1)]

        property int offset: 1
        property int leftOffset: componentsNumber + offset
        property int rightOffset: componentsNumber * 2 + offset

        function toScreenSpaceX(pos) {
            return ((pos / 1000.0) / timeScale) * timeStep + minStep
        }

        function toScreenSpaceY(pos) {
            return (pos / valueScale) * valueStep
        }

        onTimeStepChanged:requestPaint()

        onPaint: {
            context.clearRect(0, 0, canvas.width, canvas.height);
            if(curveEditor.curve !== undefined) {
                context.translate(-posX, posY - (canvas.height / vbar.size * vbar.position))

                for(var i = 0; i < componentsNumber; i++) {
                    context.strokeStyle = colors[i]
                    context.beginPath()

                    var key = curveEditor.curve[offset]
                    context.moveTo(toScreenSpaceX(key[0]), -toScreenSpaceY(key[i + offset]))

                    for(var k = 0; k < curveEditor.curve.length - offset; k++) {
                        var key1 = curveEditor.curve[k + offset]
                        var px1 = toScreenSpaceX(key1[0])
                        var py1 = -toScreenSpaceY(key1[i + offset])

                        var d = 0

                        var tx0 = px1
                        var ty0 = py1

                        if((k - 1) >= 0) {
                            var key0 = curveEditor.curve[(k - 1) + offset]
                            var px0 = toScreenSpaceX(key0[0])
                            var py0 = -toScreenSpaceY(key0[i + offset])

                            d = (px1 - px0) * 0.5

                            tx0 = px0 + d
                            ty0 = -toScreenSpaceY(key0[i + rightOffset])
                        }
                        var tx1 = px1 - d
                        var ty1 = -toScreenSpaceY(key1[i + leftOffset])

                        context.bezierCurveTo(tx0,ty0, tx1,ty1, px1,py1)
                    }
                    context.stroke();

                    if(selectKey >= 0 && (selectKey % componentsNumber) == i) {
                        context.strokeStyle = Qt.rgba(0.3, 0.3, 0.3)

                        key = curveEditor.curve[Math.floor(selectKey / canvas.componentsNumber) + offset]
                        var px = toScreenSpaceX(key[0])
                        var py = -toScreenSpaceY(key[i + offset])

                        var value = key[i + leftOffset]
                        tx1 = (1.0 / Math.sqrt(points.dist * points.dist + value * value)) * points.dist * -points.dist + px
                        value -= key[i + 1]
                        ty1 =-((1.0 / Math.sqrt(points.dist * points.dist + value * value)) * value) * points.dist + py

                        context.beginPath()
                        context.moveTo(px, py)
                        context.lineTo(tx1, ty1)
                        context.stroke();

                        value = key[i + rightOffset]
                        tx1 = (1.0 / Math.sqrt(points.dist * points.dist + value * value)) * points.dist * points.dist + px
                        value -= key[i + 1]
                        ty1 =-((1.0 / Math.sqrt(points.dist * points.dist + value * value)) * value) * points.dist + py

                        context.beginPath()
                        context.moveTo(px, py)
                        context.lineTo(tx1, ty1)
                        context.stroke();
                    }
                }
                context.setTransform(1, 0, 0, 1, 0, 0);
            }
        }
    }

    Repeater {
        model: curveEditor.height / valueStep
        Rectangle {
            anchors.left: curveEditor.left
            height: 1
            width: 50
            color: theme.hoverColor
            y: index * valueStep + ((posY - (canvas.height / vbar.size * vbar.position)) % valueStep)

            property int shift: (posY - (canvas.height / vbar.size * vbar.position)) / valueStep
            Label {
                anchors.bottom: parent.top
                anchors.right: parent.right
                color: theme.hoverColor
                text: {
                    var value = -(index - parent.shift) * valueScale
                    return value.toLocaleString(Qt.locale("en_EN"), 'f', 4) * 1
                }
                font.pointSize: 8
                renderType: Text.NativeRendering
            }
        }
    }

    Repeater {
        id: points

        property int pointSize: 6
        property int pointCenter: pointSize * 0.5
        property int dist: 50

        Item {
            id: item
            property variant key: curveEditor.curve[Math.floor(index / canvas.componentsNumber) + 1]
            property int component: index % canvas.componentsNumber

            x: canvas.toScreenSpaceX(key[0]) - posX - points.pointCenter
            y: -canvas.toScreenSpaceY(key[component + 1]) + (posY - (canvas.height / vbar.size * vbar.position)) - points.pointCenter

            function commitKey() {
                var data = curve
                data[Math.floor(index / canvas.componentsNumber) + 1] = item.key
                curve = data
            }

            Rectangle {
                color: (selectKey == index) ? theme.hoverBlueColor : "#a0606060"
                border.color: theme.textColor

                height: points.pointSize
                width: points.pointSize

                rotation: 45

                MouseArea {
                    anchors.fill: parent

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

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

                    onPressed: {
                        selectKey = index
                        selectComponent = item.component

                        canvas.requestPaint()

                        xLabel.visible = true
                        xLabel.x = item.x

                        yLabel.visible = true
                        yLabel.y = item.y
                    }

                    onReleased: {
                        xLabel.visible = false
                        yLabel.visible = false
                    }

                    onClicked: {
                        if(mouse.button === Qt.RightButton) {
                            menu.open()
                        }
                    }

                    onPositionChanged: {
                        if(drag.active) {
                            xLabel.x = item.x
                            yLabel.y = item.y

                            var x = Math.round(item.x / timeStep) * timeStep - points.pointSize

                            item.key[0] = Math.max(Math.round((x + posX) / timeStep), 0) * timeScale * 1000
                            var value = (-((item.y - posY + 3) / valueStep) * valueScale) - item.key[item.component + 1]
                            item.key[item.component + 1] += value
                            item.key[item.component + canvas.leftOffset]  += value
                            item.key[item.component + canvas.rightOffset] += value

                            item.commitKey()
                        }
                    }
                }


            }

            Rectangle {
                id: leftTangent
                visible: (selectKey == index) && (Math.floor(index / canvas.componentsNumber) > 0)
                color: "#a0606060"
                border.color: theme.textColor
                height: 6
                width: 6

                x: {
                    var value = item.key[item.component + canvas.leftOffset]
                    value = ((1.0 / Math.sqrt(points.dist * points.dist + value * value)) * points.dist) * -points.dist
                    return value
                }
                y: {
                    var value = item.key[item.component + canvas.leftOffset] - item.key[item.component + 1]
                    value = -((1.0 / Math.sqrt(points.dist * points.dist + value * value)) * value) * points.dist
                    return value
                }

                MouseArea {
                    anchors.fill: parent

                    drag.target: parent
                    drag.axis: Drag.XAxis | Drag.YAxis
                    drag.minimumX:-points.dist
                    drag.maximumX: 0
                    drag.minimumY:-points.dist
                    drag.maximumY: points.dist
                    drag.threshold: 0

                    drag.onActiveChanged: {
                        if(!drag.active) {
                            clipModel.setTrackData(curveEditor.row, curveEditor.curve)
                        }
                    }

                    onPositionChanged: {
                        if(drag.active) {
                            item.key[item.component + canvas.leftOffset] = (parent.y / parent.x) * valueStep + item.key[item.component + 1]
                            if(!braked) {
                                item.key[item.component + canvas.rightOffset] = -(parent.y / parent.x) * valueStep + item.key[item.component + 1]
                            }

                            item.commitKey()
                        }
                    }
                }
            }

            Rectangle {
                id: rightTangent
                visible: (selectKey == index) && (Math.floor(index / canvas.componentsNumber) < canvas.keysNumber - 1)
                color: "#a0606060"
                border.color: theme.textColor
                height: 6
                width: 6
                x: {
                    var value = item.key[item.component + canvas.rightOffset]
                    return (1.0 / Math.sqrt(points.dist * points.dist + value * value)) * points.dist * points.dist
                }
                y: {
                    var value = item.key[item.component + canvas.rightOffset] - item.key[item.component + 1]
                    return -((1.0 / Math.sqrt(points.dist * points.dist + value * value)) * value) * points.dist
                }

                MouseArea {
                    anchors.fill: parent

                    drag.target: parent
                    drag.axis: Drag.XAxis | Drag.YAxis
                    drag.minimumX: 0
                    drag.maximumX: points.dist
                    drag.minimumY:-points.dist
                    drag.maximumY: points.dist
                    drag.threshold: 0

                    drag.onActiveChanged: {
                        if(!drag.active) {
                            clipModel.setTrackData(curveEditor.row, curveEditor.curve)
                        }
                    }

                    onPositionChanged: {
                        if(drag.active) {
                            item.key[item.component + canvas.rightOffset] = -(parent.y / parent.x) * valueStep + item.key[item.component + 1]
                            if(!braked) {
                                item.key[item.component + canvas.leftOffset] = (parent.y / parent.x) * valueStep + item.key[item.component + 1]
                            }
                            item.commitKey()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: xLabel
        visible: false
        anchors.top: parent.top
        color: "#a0000000"
        radius: 3

        width: xlabel.width + 6
        height: xlabel.height

        Label {
            id: xlabel
            color: theme.textColor
            text: {
                if(selectKey >= 0 && curveEditor.curve) {
                    var key = curveEditor.curve[Math.floor(selectKey / canvas.componentsNumber) + 1]
                    var value = key[0] / 1000.0
                    return value.toLocaleString(Qt.locale("en_EN"), 'f', 2).replace('.', ':')
                }
                return ""
            }
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: yLabel
        visible: false
        anchors.left: parent.left
        color: "#a0000000"
        radius: 3

        width: ylabel.width + 6
        height: ylabel.height

        Label {
            id: ylabel
            color: theme.textColor
            text: {
                if(selectKey >= 0 && curveEditor.curve) {
                    var key = curveEditor.curve[Math.floor(selectKey / canvas.componentsNumber) + 1]
                    var value = key[selectComponent + 1]
                    return value.toLocaleString(Qt.locale("en_EN"), 'f', 2) * 1
                }
                return ""
            }
            anchors.centerIn: parent
        }
    }

    ScrollBar {
        id: vbar
        hoverEnabled: true
        active: hovered || pressed
        orientation: Qt.Vertical
        size: parent.height
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        onPositionChanged: canvas.requestPaint()
    }

    ContextMenu {
        id: menu
        y: parent.height

        font.pointSize: 8
        margins: 18

        Action {
            text: "Delete Key"
        }
        Action {
            text: "Edit Key"
            onTriggered: functionCreate(Name, text)
        }
        Action {
            text: "Flat"
            onTriggered: functionCreate(Name, text)
        }
        Action {
            text: "Brake the force"
            checkable: true
            onTriggered: functionCreate(Name, text)
        }
    }
}
