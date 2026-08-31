import QtQuick
import QtQuick.Effects
import qs.Commons

Item {
  id: root

  property color accent: "#ff4d3d"
  property color foreground: "#f5f5f5"
  property color background: "#151515"
  property int activityLevel: 0
  property int unreadCount: 0
  property bool animated: true
  property url avatarSource: "https://github.com/dhh.png?size=256"

  implicitWidth: 72
  implicitHeight: 72

  Rectangle {
    id: signalRing
    anchors.centerIn: parent
    width: Math.min(parent.width, parent.height)
    height: width
    radius: width / 2
    color: "transparent"
    border.width: Math.max(1, width * 0.035)
    border.color: root.activityLevel > 0 ? root.accent : Util.alpha(root.foreground, 0.25)
    opacity: 0.85

    SequentialAnimation on scale {
      running: root.animated && root.activityLevel > 0
      loops: Animation.Infinite
      NumberAnimation { from: 0.94; to: 1.03; duration: Math.max(420, 1250 - root.activityLevel * 220); easing.type: Easing.InOutSine }
      NumberAnimation { from: 1.03; to: 0.94; duration: Math.max(420, 1250 - root.activityLevel * 220); easing.type: Easing.InOutSine }
    }
  }

  Rectangle {
    id: photoMask
    anchors.centerIn: parent
    width: parent.width * 0.82
    height: width
    radius: width / 2
    color: "white"
    visible: false
    layer.enabled: true
  }

  Rectangle {
    id: photoFrame
    anchors.centerIn: parent
    width: parent.width * 0.82
    height: width
    radius: width / 2
    color: root.background
    border.width: 1
    border.color: Util.alpha(root.foreground, 0.18)

    Text {
      anchors.centerIn: parent
      text: "DHH"
      color: root.foreground
      font.pixelSize: parent.width * 0.25
      font.bold: true
      visible: portrait.status !== Image.Ready
    }
  }

  Item {
    anchors.fill: photoFrame
    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: photoMask
      maskThresholdMin: 0.3
      maskSpreadAtMin: 0.3
    }

    Image {
      id: portrait
      anchors.fill: parent
      source: root.avatarSource
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      smooth: true
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: parent.height * 0.02
    spacing: Math.max(1, parent.width * 0.025)
    visible: root.activityLevel > 0

    Repeater {
      model: 3
      Rectangle {
        required property int index
        width: Math.max(1, root.width * 0.035)
        height: root.height * (0.08 + index * 0.025)
        radius: width / 2
        color: root.accent
        anchors.verticalCenter: parent.verticalCenter

        SequentialAnimation on scale {
          running: root.animated && root.activityLevel > 0
          loops: Animation.Infinite
          PauseAnimation { duration: index * 80 }
          NumberAnimation { from: 0.55; to: 1.35; duration: 180 }
          NumberAnimation { from: 1.35; to: 0.55; duration: 230 }
          PauseAnimation { duration: (2 - index) * 80 }
        }
      }
    }
  }

  Rectangle {
    anchors.right: parent.right
    anchors.top: parent.top
    width: parent.width * 0.24
    height: width
    radius: width / 2
    color: root.accent
    border.width: Math.max(1, width * 0.12)
    border.color: root.background
    visible: root.unreadCount > 0

    SequentialAnimation on scale {
      running: root.animated && root.unreadCount > 0
      loops: Animation.Infinite
      NumberAnimation { from: 0.88; to: 1.18; duration: 420; easing.type: Easing.OutQuad }
      NumberAnimation { from: 1.18; to: 0.88; duration: 620; easing.type: Easing.InQuad }
    }
  }

  Rectangle {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: parent.width * 0.22
    height: width
    radius: width / 2
    color: root.activityLevel > 0 ? root.accent : "#777777"
    border.width: Math.max(1, width * 0.12)
    border.color: root.background
  }
}
