import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
  id: root
  moduleName: "anerti.terminal-protocol-controller"
  ipcTarget: "anerti.terminal-protocol-controller"

  readonly property string backend: decodeURIComponent(Qt.resolvedUrl("bin/terminal-protocol-controller").toString().replace("file://", ""))
  readonly property var parts: [
    { key: "bar", label: "Menu bar", description: "Vault-Tec wedge and Vault Boy status panels" },
    { key: "menu", label: "Menu", description: "Pip-Boy menu on Super + Space" },
    { key: "cursor", label: "Mouse cursor", description: "VaultTec cursors instead of Omarchy's" },
    { key: "crt", label: "CRT effect", description: "Scanlines and vignette over the screen" },
    { key: "unlock", label: "Unlock screen", description: "RobCo terminal lock screen" },
    { key: "login", label: "Login screen", description: "Terminal boot screen; asks for your password" }
  ]

  property var status: ({ installed: true, busy: false })
  property var pending: ({})
  property bool downloading: false
  property bool downloadFailed: false
  property int cursor: -1

  readonly property bool working: status.busy || Object.keys(pending).length > 0
  readonly property string statusText: {
    if (downloading) return "Downloading the theme"
    if (!status.installed) return downloadFailed ? "Download failed, check your connection" : "Theme not installed"
    return working ? "Applying changes" : ""
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function checked(key) {
    return pending[key] ? pending[key].want : status[key] === true
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function update(text) {
    var next
    try { next = JSON.parse(text) } catch (e) { return }
    var now = Date.now()
    var p = Object.assign({}, pending)
    for (var key in p) {
      if (next[key] === p[key].want || (!next.busy && now - p[key].at > 3000)) delete p[key]
    }
    pending = p
    status = next
    if (!next.installed && !downloading && !downloadFailed) {
      downloading = true
      installProc.running = true
    }
  }

  function flip(key) {
    if (!status.installed || pending[key]) return
    var want = !checked(key)
    var p = Object.assign({}, pending)
    p[key] = { want: want, at: Date.now() }
    pending = p
    Quickshell.execDetached(["setsid", "-f", "bash", backend, "set", key, want ? "on" : "off"])
  }

  onOpenedChanged: {
    if (!opened) return
    downloadFailed = false
    refresh()
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProc
    command: ["bash", root.backend, "status"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.update(text) }
  }

  Process {
    id: installProc
    command: ["bash", root.backend, "install"]
    onExited: function(exitCode) {
      root.downloading = false
      root.downloadFailed = exitCode !== 0
      root.refresh()
    }
  }

  Timer {
    interval: 1500
    repeat: true
    running: root.opened || root.working
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        RadiationIcon {
          anchors.centerIn: parent
          iconSize: Style.bar.iconFont
          color: button.foreground
        }
      }
    }
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.cursor = Math.max(0, Math.min(root.parts.length - 1, root.cursor + dy))
      }
      onActivateRequested: if (root.cursor >= 0) root.flip(root.parts[root.cursor].key)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(14)

        Row {
          width: parent.width
          spacing: Style.space(14)

          RadiationIcon {
            id: heroIcon
            anchors.verticalCenter: parent.verticalCenter
            iconSize: Style.font.display
            color: root.bar.foreground
            opacity: root.status.installed ? 1.0 : 0.5
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - heroIcon.width - parent.spacing
            spacing: Style.space(2)

            Text {
              text: "Terminal Protocol Controller"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              visible: text !== ""
              textFormat: Text.PlainText
              text: root.statusText.toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelArt {
          width: parent.width
          source: Qt.resolvedUrl("assets/vault-boy-walking-neutral.gif")
          playing: root.opened
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        Repeater {
          model: root.parts

          Toggle {
            required property var modelData
            required property int index
            width: column.width
            label: modelData.label
            description: modelData.description
            checked: root.checked(modelData.key)
            hasCursor: root.cursor === index
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            enabled: root.status.installed
            opacity: enabled && !root.pending[modelData.key] ? 1.0 : 0.5
            onHovered: function(on) { if (on) root.cursor = index }
            onClicked: root.flip(modelData.key)
          }
        }
      }
    }
  }
}
