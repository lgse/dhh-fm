import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "lgse.dhh-fm"

  readonly property var radioService: bar && bar.shell ? bar.shell.serviceFor("lgse.dhh-fm") : null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property int activityLevel: Model.activityLevel(radioService ? radioService.stats.total : 0)

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.radioService = root.radioService
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onRadioServiceChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  Item {
    id: button
    implicitWidth: root.bar ? root.bar.barSize : 26
    implicitHeight: implicitWidth

    DhhAvatar {
      anchors.centerIn: parent
      width: parent.width - 2
      height: width
      accent: root.bar ? root.bar.urgent : "#ff4d3d"
      foreground: root.bar ? root.bar.foreground : "white"
      background: root.bar ? root.bar.background : "#151515"
      activityLevel: root.activityLevel
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton && root.radioService) root.radioService.refresh()
        else root.toggle()
      }
      onEntered: if (root.bar) root.bar.showTooltip(root,
        Model.statusLine(root.radioService ? root.radioService.stats : null,
          root.radioService ? root.radioService.lastCreatedAt : ""))
      onExited: if (root.bar) root.bar.hideTooltip(root)
    }
  }
}
