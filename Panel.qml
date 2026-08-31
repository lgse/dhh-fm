import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "lgse.dhh-fm"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var radioService: null
  property string feedFilter: "all"
  property string setupSource: "x-api"
  property bool configEditorOpen: false
  property double nowMs: Date.now()

  readonly property var barIdentity: hostWidget || root
  readonly property var stats: radioService ? radioService.stats : ({})
  readonly property var posts: radioService ? radioService.posts : []
  readonly property var visiblePosts: Model.filteredPosts(posts, feedFilter)
  readonly property int activityLevel: Model.activityLevel(stats.total)
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }
  function scrollPanel(delta) {
    feedFlick.contentY = Math.max(0, Math.min(feedFlick.contentY + delta,
      Math.max(0, feedFlick.contentHeight - feedFlick.height)))
  }

  function saveConfiguration() {
    if (!radioService) return
    radioService.configure(setupSource, bearerInput.text, rssInput.text)
    bearerInput.text = ""
  }

  onOpenedChanged: {
    if (!opened || !radioService) return
    radioService.markSeen()
    if (!radioService.configured) configEditorOpen = true
    if (radioService.source === "x-api" || radioService.source === "rss" || radioService.source === "demo")
      setupSource = radioService.source
  }
  onPostsChanged: {
    if (opened && radioService) radioService.markSeen()
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: root.nowMs = Date.now()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(530))
    contentHeight: panel.fittedContentHeight(Style.space(700))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) { if (dy !== 0) root.scrollPanel(dy * Style.space(70)) }

      Column {
        anchors.fill: parent
        spacing: Style.space(10)

        Row {
          width: parent.width
          spacing: Style.space(12)

          DhhAvatar {
            width: Style.space(68)
            height: width
            accent: Color.urgent
            foreground: Color.foreground
            background: Color.background
            activityLevel: root.activityLevel
            unreadCount: root.radioService ? root.radioService.unreadCount : 0
          }

          Column {
            width: parent.width - Style.space(68) - settingsButton.width - refreshButton.width - parent.spacing * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Row {
              spacing: Style.space(7)
              Text {
                text: "DHH FM"
                color: Color.foreground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: onAirText.implicitWidth + Style.space(12)
                height: Style.space(20)
                radius: height / 2
                color: root.activityLevel > 0 ? Util.alpha(Color.urgent, 0.2) : Util.alpha(Color.foreground, 0.08)
                Text {
                  id: onAirText
                  anchors.centerIn: parent
                  text: root.activityLevel > 0 ? "● ON AIR" : "○ DEAD AIR"
                  color: root.activityLevel > 0 ? Color.urgent : Util.alpha(Color.foreground, 0.6)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }
            }

            Text {
              width: parent.width
              text: Model.statusLine(root.stats,
                root.radioService ? root.radioService.lastCreatedAt : "", root.nowMs)
              color: Util.alpha(Color.foreground, 0.7)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: "Always broadcasting · @dhh"
              color: Util.alpha(Color.foreground, 0.48)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }

          Rectangle {
            id: settingsButton
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(34)
            height: width
            radius: Style.cornerRadius
            color: root.configEditorOpen ? Util.alpha(Color.accent, 0.2)
              : (settingsMouse.containsMouse ? Util.alpha(Color.foreground, 0.12) : Util.alpha(Color.foreground, 0.06))
            Text {
              anchors.centerIn: parent
              text: "󰒓"
              color: root.configEditorOpen ? Color.accent : Color.foreground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
            }
            MouseArea {
              id: settingsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.configEditorOpen = !root.configEditorOpen
            }
          }

          Rectangle {
            id: refreshButton
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(34)
            height: width
            radius: Style.cornerRadius
            color: refreshMouse.containsMouse ? Util.alpha(Color.foreground, 0.12) : Util.alpha(Color.foreground, 0.06)
            Text {
              anchors.centerIn: parent
              text: root.radioService && root.radioService.refreshing ? "󰑓" : "󰑐"
              color: Color.foreground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              RotationAnimation on rotation {
                running: root.radioService ? root.radioService.refreshing : false
                loops: Animation.Infinite
                from: 0; to: 360; duration: 800
              }
            }
            MouseArea {
              id: refreshMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.radioService) root.radioService.refresh()
            }
          }
        }

        Grid {
          id: statsGrid
          width: parent.width
          columns: 4
          columnSpacing: Style.space(7)
          rowSpacing: Style.space(7)

          Repeater {
            model: [
              { label: "24H SIGNALS", value: Model.compactNumber(root.stats.total) },
              { label: "POSTS", value: Model.compactNumber(root.stats.posts) },
              { label: "REPLIES", value: Model.compactNumber(root.stats.replies) },
              { label: Number(root.stats.views || 0) > 0 ? "PUBLIC VIEWS" : "ENGAGEMENT",
                value: Model.compactNumber(Number(root.stats.views || 0) > 0 ? root.stats.views : root.stats.engagement) }
            ]

            Rectangle {
              required property var modelData
              width: (statsGrid.width - statsGrid.columnSpacing * 3) / 4
              height: Style.space(62)
              radius: Style.cornerRadius
              color: Util.alpha(Color.foreground, 0.045)
              border.width: 1
              border.color: Util.alpha(Color.foreground, 0.1)
              Column {
                anchors.centerIn: parent
                spacing: Style.space(2)
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.value
                  color: Color.foreground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.title
                  font.bold: true
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: Util.alpha(Color.foreground, 0.52)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: warningText.implicitHeight + Style.space(16)
          radius: Style.cornerRadius
          color: Util.alpha(Color.urgent, 0.09)
          border.width: 1
          border.color: Util.alpha(Color.urgent, 0.22)
          visible: root.radioService && root.radioService.lastError !== ""
          Text {
            id: warningText
            anchors.fill: parent
            anchors.margins: Style.space(8)
            text: root.radioService ? root.radioService.lastError : ""
            color: Color.foreground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }
        }

        Rectangle {
          width: parent.width
          height: configContent.implicitHeight + Style.space(24)
          radius: Style.cornerRadius
          color: Util.alpha(Color.foreground, 0.045)
          border.width: 1
          border.color: Util.alpha(Color.foreground, 0.12)
          visible: root.configEditorOpen

          Column {
            id: configContent
            x: Style.space(12)
            y: Style.space(12)
            width: parent.width - Style.space(24)
            spacing: Style.space(9)

            Text {
              text: "Tune the station"
              color: Color.foreground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Choose a source. Credentials stay in a private local file and are never passed on the command line."
              color: Util.alpha(Color.foreground, 0.62)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
            }

            Row {
              spacing: Style.space(6)
              Repeater {
                model: [
                  { key: "x-api", label: "X API" },
                  { key: "rss", label: "RSS" },
                  { key: "demo", label: "Demo" }
                ]
                Rectangle {
                  id: sourceChoice
                  required property var modelData
                  width: choiceText.implicitWidth + Style.space(20)
                  height: Style.space(29)
                  radius: height / 2
                  color: root.setupSource === modelData.key ? Color.accent : Util.alpha(Color.foreground, 0.07)
                  Text {
                    id: choiceText
                    anchors.centerIn: parent
                    text: sourceChoice.modelData.label
                    color: root.setupSource === sourceChoice.modelData.key ? Color.background : Color.foreground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: root.setupSource === sourceChoice.modelData.key
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setupSource = sourceChoice.modelData.key
                  }
                }
              }
            }

            Rectangle {
              width: parent.width
              height: Style.space(34)
              radius: Style.cornerRadius
              color: Util.alpha(Color.foreground, 0.06)
              border.width: 1
              border.color: bearerInput.activeFocus ? Color.accent : Util.alpha(Color.foreground, 0.16)
              visible: root.setupSource === "x-api"
              TextInput {
                id: bearerInput
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                verticalAlignment: TextInput.AlignVCenter
                color: Color.foreground
                selectionColor: Color.accent
                selectedTextColor: Color.background
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                echoMode: TextInput.Password
                selectByMouse: true
                clip: true
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.radioService && root.radioService.source === "x-api"
                    ? "Bearer token saved — paste to replace" : "Paste OAuth 2.0 bearer token"
                  color: Util.alpha(Color.foreground, 0.4)
                  font: parent.font
                  visible: parent.text.length === 0
                }
                onAccepted: root.saveConfiguration()
              }
            }

            Rectangle {
              width: parent.width
              height: Style.space(34)
              radius: Style.cornerRadius
              color: Util.alpha(Color.foreground, 0.06)
              border.width: 1
              border.color: rssInput.activeFocus ? Color.accent : Util.alpha(Color.foreground, 0.16)
              visible: root.setupSource === "rss"
              TextInput {
                id: rssInput
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                verticalAlignment: TextInput.AlignVCenter
                color: Color.foreground
                selectionColor: Color.accent
                selectedTextColor: Color.background
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                selectByMouse: true
                clip: true
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.radioService && root.radioService.source === "rss"
                    ? "RSS URL saved — paste to replace" : "https://your-instance/dhh/rss"
                  color: Util.alpha(Color.foreground, 0.4)
                  font: parent.font
                  visible: parent.text.length === 0
                }
                onAccepted: root.saveConfiguration()
              }
            }

            Text {
              width: parent.width
              visible: root.setupSource === "demo"
              text: "Preview the complete interface with clearly labeled sample transmissions."
              color: Util.alpha(Color.foreground, 0.62)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
            }

            Rectangle {
              width: parent.width
              height: Style.space(34)
              radius: Style.cornerRadius
              color: Color.accent
              opacity: root.radioService && root.radioService.configuring ? 0.55 : 1
              Text {
                anchors.centerIn: parent
                text: root.radioService && root.radioService.configuring ? "Tuning…" : "Save & tune"
                color: Color.background
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }
              MouseArea {
                anchors.fill: parent
                enabled: !(root.radioService && root.radioService.configuring)
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.saveConfiguration()
              }
            }
          }
        }

        Row {
          spacing: Style.space(6)
          Repeater {
            model: [
              { key: "all", label: "All" },
              { key: "posts", label: "Posts" },
              { key: "replies", label: "Replies" }
            ]
            Rectangle {
              required property var modelData
              width: tabText.implicitWidth + Style.space(20)
              height: Style.space(30)
              radius: height / 2
              color: root.feedFilter === modelData.key ? Color.accent : Util.alpha(Color.foreground, 0.06)
              Text {
                id: tabText
                anchors.centerIn: parent
                text: modelData.label
                color: root.feedFilter === modelData.key ? Color.background : Color.foreground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.bold: root.feedFilter === modelData.key
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.feedFilter = modelData.key
              }
            }
          }
        }

        Flickable {
          id: feedFlick
          width: parent.width
          height: parent.height - y
          contentWidth: width
          contentHeight: feedColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Column {
            id: feedColumn
            width: feedFlick.width
            spacing: Style.space(8)

            Rectangle {
              width: parent.width
              height: setupColumn.implicitHeight + Style.space(28)
              radius: Style.cornerRadius
              color: Util.alpha(Color.foreground, 0.045)
              border.width: 1
              border.color: Util.alpha(Color.foreground, 0.12)
              visible: root.posts.length === 0
              Column {
                id: setupColumn
                anchors.fill: parent
                anchors.margins: Style.space(14)
                spacing: Style.space(7)
                Text {
                  text: "The transmitter needs a signal"
                  color: Color.foreground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Text {
                  width: parent.width
                  text: "Choose the official X API or an RSS-compatible fallback above. No browser cookies or X password required."
                  color: Util.alpha(Color.foreground, 0.65)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.Wrap
                }
                Text {
                  width: parent.width
                  text: "Use Demo to preview the station without credentials."
                  color: Color.accent
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WrapAnywhere
                }
              }
            }

            Repeater {
              model: root.visiblePosts
              Rectangle {
                id: card
                required property var modelData
                width: feedColumn.width
                height: cardContent.implicitHeight + Style.space(20)
                radius: Style.cornerRadius
                color: cardMouse.containsMouse ? Util.alpha(Color.foreground, 0.07) : Util.alpha(Color.foreground, 0.04)
                border.width: 1
                border.color: Util.alpha(Color.foreground, 0.1)

                Column {
                  id: cardContent
                  x: Style.space(10)
                  y: Style.space(10)
                  width: parent.width - Style.space(20)
                  spacing: Style.space(6)

                  Row {
                    width: parent.width
                    Text {
                      width: parent.width - timeLabel.width
                      text: Model.kindLabel(card.modelData.kind).toUpperCase()
                      color: card.modelData.kind === "reply" ? Color.accent : Util.alpha(Color.foreground, 0.55)
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                    Text {
                      id: timeLabel
                      text: Model.relativeTime(card.modelData.created_at, root.nowMs)
                      color: Util.alpha(Color.foreground, 0.48)
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }

                  Text {
                    width: parent.width
                    text: String(card.modelData.text || "")
                    color: Color.foreground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    wrapMode: Text.Wrap
                  }

                  Text {
                    width: parent.width
                    visible: String(card.modelData.reply_to_text || "") !== ""
                    text: "↳ " + String(card.modelData.reply_to_text || "")
                    color: Util.alpha(Color.foreground, 0.55)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }

                  Row {
                    spacing: Style.space(14)
                    Text {
                      text: "♥ " + Model.compactNumber((card.modelData.metrics || {}).likes)
                        + "  ↻ " + Model.compactNumber((card.modelData.metrics || {}).reposts)
                        + "  ↩ " + Model.compactNumber((card.modelData.metrics || {}).replies)
                      color: Util.alpha(Color.foreground, 0.5)
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                    }
                    Text {
                      text: "Reply"
                      color: Color.accent
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Style.space(5)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.radioService) root.radioService.replyTo(card.modelData.id)
                      }
                    }
                    Text {
                      text: "Copy"
                      color: Util.alpha(Color.foreground, 0.7)
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Style.space(5)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.radioService) root.radioService.copyLink(card.modelData.url)
                      }
                    }
                  }
                }

                MouseArea {
                  id: cardMouse
                  anchors.fill: parent
                  acceptedButtons: Qt.LeftButton
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  propagateComposedEvents: true
                  z: -1
                  onClicked: if (root.radioService) root.radioService.openUrl(card.modelData.url)
                }
              }
            }
          }
        }
      }
    }
  }
}
