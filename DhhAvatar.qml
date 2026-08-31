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

  onTalkingChanged: {
    if (!talking) {
      lowerJaw.rotation = 0
      lowerJaw.y = head.mouthCut
    }
  }

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

    readonly property real mouthCut: height * 0.705

    // Split the portrait at the mouth like a paper cutout. The upper portrait
    // stays fixed while the lower jaw tilts around the cut line.
    Item {
      id: upperHead
      x: 0
      y: 0
      width: parent.width
      height: head.mouthCut
      clip: true

      Image {
        width: head.width
        height: head.height
        source: Qt.resolvedUrl("assets/dhh-cutout.png")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        smooth: true
      }
    }

    Rectangle {
      x: parent.width * 0.39
      y: head.mouthCut - parent.height * 0.008
      width: parent.width * 0.22
      height: parent.height * 0.045
      radius: width / 2
      color: root.background
      visible: root.talking
    }

    Item {
      id: lowerJaw
      x: 0
      y: head.mouthCut
      width: parent.width
      height: parent.height - head.mouthCut
      clip: true
      transformOrigin: Item.TopLeft

      Image {
        x: 0
        y: -head.mouthCut
        width: head.width
        height: head.height
        source: Qt.resolvedUrl("assets/dhh-cutout.png")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
        smooth: true
      }

      SequentialAnimation on rotation {
        running: root.talking
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 2.8; duration: 125; easing.type: Easing.OutQuad }
        PauseAnimation { duration: 65 }
        NumberAnimation { from: 2.8; to: -1.7; duration: 145; easing.type: Easing.InOutQuad }
        NumberAnimation { from: -1.7; to: 2.1; duration: 120; easing.type: Easing.InOutQuad }
        PauseAnimation { duration: 85 }
        NumberAnimation { from: 2.1; to: 0; duration: 150; easing.type: Easing.InQuad }
        PauseAnimation { duration: 260 }
      }

      SequentialAnimation on y {
        running: root.talking
        loops: Animation.Infinite
        NumberAnimation { from: head.mouthCut; to: head.mouthCut + head.height * 0.018; duration: 125 }
        NumberAnimation { from: head.mouthCut + head.height * 0.018; to: head.mouthCut; duration: 210 }
        PauseAnimation { duration: 610 }
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

    Item {
      anchors.centerIn: parent
      width: parent.width * 0.56
      height: parent.height * 0.62
      visible: root.locked && parent.width >= 8

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: parent.width * 0.64
        height: parent.height * 0.58
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, parent.width * 0.1)
        border.color: root.foreground
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * 0.58
        radius: Math.max(1, width * 0.12)
        color: root.foreground
      }
    }
  }
}
