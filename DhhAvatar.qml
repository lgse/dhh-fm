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
    opacity: 0.8

    SequentialAnimation on scale {
      running: root.animated && root.activityLevel > 0
      loops: Animation.Infinite
      NumberAnimation { from: 0.94; to: 1.03; duration: Math.max(420, 1250 - root.activityLevel * 220); easing.type: Easing.InOutSine }
      NumberAnimation { from: 1.03; to: 0.94; duration: Math.max(420, 1250 - root.activityLevel * 220); easing.type: Easing.InOutSine }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: parent.width * 0.82
    height: width
    radius: width / 2
    color: root.background
    border.width: 1
    border.color: Util.alpha(root.foreground, 0.18)
    clip: true

    Rectangle {
      id: face
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.16
      width: parent.width * 0.52
      height: parent.height * 0.66
      radius: width * 0.42
      color: "#e5a273"

      Rectangle {
        x: -width * 0.08
        y: parent.height * 0.27
        width: parent.width * 0.58
        height: parent.height * 0.17
        radius: height / 2
        color: "transparent"
        border.width: Math.max(1, root.width * 0.025)
        border.color: "#282018"
      }

      Rectangle {
        x: parent.width * 0.50
        y: parent.height * 0.27
        width: parent.width * 0.58
        height: parent.height * 0.17
        radius: height / 2
        color: "transparent"
        border.width: Math.max(1, root.width * 0.025)
        border.color: "#282018"
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.57
        width: parent.width * 0.75
        height: parent.height * 0.42
        radius: width * 0.32
        color: "#6a3d29"

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: parent.height * 0.38
          width: parent.width * 0.34
          height: Math.max(1, parent.height * 0.09)
          radius: height / 2
          color: "#1b1110"

          SequentialAnimation on scale {
            running: root.animated && root.activityLevel > 0
            loops: Animation.Infinite
            NumberAnimation { from: 0.65; to: 1.35; duration: 170 }
            PauseAnimation { duration: 90 }
            NumberAnimation { from: 1.35; to: 0.65; duration: 150 }
            PauseAnimation { duration: 240 }
          }
        }
      }
    }
  }

  Rectangle {
    id: unreadBadge
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
