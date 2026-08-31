import QtQuick
import qs.Commons

Item {
  id: root

  property color accent: "#ff4d3d"
  property color foreground: "#f5f5f5"
  property color background: "#151515"
  property int activityLevel: 0
  property int unreadCount: 0
  property bool animated: true
  property bool locked: false
  readonly property bool talking: animated && !locked && activityLevel > 0

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
      running: root.talking
      loops: Animation.Infinite
      NumberAnimation { from: 0.94; to: 1.03; duration: Math.max(420, 1250 - root.activityLevel * 220); easing.type: Easing.InOutSine }
      NumberAnimation { from: 1.03; to: 0.94; duration: Math.max(420, 1250 - root.activityLevel * 220); easing.type: Easing.InOutSine }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: parent.width * 0.84
    height: width
    radius: width / 2
    color: root.background
    border.width: 1
    border.color: Util.alpha(root.foreground, 0.18)
  }

  Item {
    id: head
    anchors.centerIn: parent
    width: parent.width * 0.88
    height: width
    transformOrigin: Item.Bottom

    SequentialAnimation on rotation {
      running: root.talking
      loops: Animation.Infinite
      NumberAnimation { from: -2.4; to: 2.2; duration: 950; easing.type: Easing.InOutSine }
      NumberAnimation { from: 2.2; to: -1.2; duration: 720; easing.type: Easing.InOutSine }
      NumberAnimation { from: -1.2; to: -2.4; duration: 520; easing.type: Easing.InOutSine }
    }

    SequentialAnimation on scale {
      running: root.talking
      loops: Animation.Infinite
      NumberAnimation { from: 0.985; to: 1.012; duration: 950; easing.type: Easing.InOutSine }
      NumberAnimation { from: 1.012; to: 0.985; duration: 1240; easing.type: Easing.InOutSine }
    }

    Image {
      anchors.fill: parent
      source: Qt.resolvedUrl("assets/dhh-cutout.png")
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: true
      smooth: true
    }

    // A deliberately simple South Park-style mouth laid over the portrait.
    // At bar size it reads as speech; in the panel the tiny jaw flap is visible.
    Rectangle {
      id: mouth
      x: parent.width * 0.39
      y: parent.height * 0.695
      width: parent.width * 0.22
      height: parent.height * 0.075
      radius: width / 2
      color: root.background
      transformOrigin: Item.Top
      visible: root.talking

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: parent.width * 0.72
        height: parent.height * 0.27
        radius: height / 2
        color: root.foreground
      }

      SequentialAnimation on scale {
        running: root.talking
        loops: Animation.Infinite
        NumberAnimation { from: 0.16; to: 1.0; duration: 150; easing.type: Easing.OutQuad }
        PauseAnimation { duration: 70 }
        NumberAnimation { from: 1.0; to: 0.22; duration: 120; easing.type: Easing.InQuad }
        PauseAnimation { duration: 180 }
        NumberAnimation { from: 0.22; to: 0.72; duration: 110 }
        NumberAnimation { from: 0.72; to: 0.16; duration: 130 }
        PauseAnimation { duration: 260 }
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
    color: root.locked ? "#777777" : (root.activityLevel > 0 ? root.accent : "#777777")
    border.width: Math.max(1, width * 0.12)
    border.color: root.background

    Text {
      anchors.centerIn: parent
      visible: root.locked && parent.width >= 10
      text: "󰌾"
      color: root.foreground
      font.pixelSize: parent.width * 0.58
    }
  }
}
