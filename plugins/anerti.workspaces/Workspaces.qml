import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "anerti.workspaces"

  readonly property color fg: Color.foreground
  readonly property color fgBright: themePalette.brightForeground
  readonly property color fgDim: Qt.darker(Color.foreground, 1.05)
  readonly property color ink: Color.background

  ThemePalette { id: themePalette }

  readonly property real lean: Math.tan(22 * Math.PI / 180)
  readonly property real tuck: 16
  readonly property real pad: Math.ceil(lean * 29)
  readonly property var widths: [40, 30, 22]
  readonly property var heights: [29, 23, 17]

  readonly property var screen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0

  readonly property var ids: root.workspaceIds()
  readonly property var leftIds: ids.slice(0, 3)
  readonly property var rightIds: ids.slice(3)
  readonly property real sideWidth: Math.max(groupWidth(leftIds.length), groupWidth(rightIds.length))

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5, 6]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function groupWidth(count) {
    var total = 0
    for (var i = 0; i < count; i++) total += root.widths[Math.min(i, 2)]
    return total
  }

  onFocusedIdChanged: {
    if (!root.setting("roll", true) || !root.screen || !Hyprland.focusedMonitor) return
    if (Hyprland.focusedMonitor.name === root.screen.name) wipe.run()
  }

  PanelWindow {
    screen: root.screen
    visible: wipe.running
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "vault-tec-roll"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    RollWipe {
      id: wipe
      anchors.fill: parent
    }
  }

  FontLoader {
    id: shareTech
    source: Qt.resolvedUrl("assets/fonts/ShareTechMono-Regular.ttf")
  }

  implicitWidth: root.vertical ? root.barSize : strip.width
  implicitHeight: root.vertical ? strip.width : root.barSize

  Item {
    id: strip
    anchors.centerIn: parent
    width: rightGroup.x + root.sideWidth + root.pad
    height: root.barSize
    rotation: root.vertical ? 90 : 0

    Item {
      id: leftGroup
      x: root.pad + root.sideWidth - width
      width: root.groupWidth(root.leftIds.length)
      height: parent.height

      Repeater {
        model: root.leftIds

        Pill {
          required property int modelData
          required property int index

          workspaceId: modelData
          distance: root.leftIds.length - 1 - index
          slant: root.lean
          x: leftGroup.width - root.groupWidth(root.leftIds.length - index)
        }
      }
    }

    Item {
      id: rightGroup
      x: wedge.x + wedge.width - root.tuck
      width: root.groupWidth(root.rightIds.length)
      height: parent.height

      Repeater {
        model: root.rightIds

        Pill {
          required property int modelData
          required property int index

          workspaceId: modelData
          distance: index
          slant: -root.lean
          x: root.groupWidth(index)
        }
      }
    }

    Item {
      id: wedge
      x: leftGroup.x + leftGroup.width - root.tuck
      width: logo.width + 48
      height: parent.height

      Item {
        id: wedgeArt
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: wedgeButton.tooltipHovered ? 0.1 : 0
          shadowEnabled: wedgeButton.tooltipHovered
          shadowColor: Util.alpha(root.fg, 0.7)
          shadowBlur: 0.6
          shadowHorizontalOffset: 0
          shadowVerticalOffset: 0
          autoPaddingEnabled: true
        }

        Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer

          ShapePath {
            strokeWidth: -1
            fillColor: root.fg
            startX: 0; startY: 0
            PathLine { x: wedge.width; y: 0 }
            PathLine { x: wedge.width - 14; y: wedge.height }
            PathLine { x: 14; y: wedge.height }
            PathLine { x: 0; y: 0 }
          }
        }

        Image {
          id: logo
          anchors.centerIn: parent
          height: 20
          width: Math.round(height * 930.07 / 360)
          source: Qt.resolvedUrl("assets/vaulttec-omarchy-ink.svg")
          sourceSize.width: width * 2
          sourceSize.height: height * 2
          fillMode: Image.PreserveAspectFit
          smooth: true
          visible: false
        }

        MultiEffect {
          anchors.fill: logo
          source: logo
          brightness: 1.0
          colorization: 1.0
          colorizationColor: root.ink
        }
      }

      WidgetButton {
        id: wedgeButton
        anchors.fill: parent
        bar: root.bar
        text: " "
        labelVisible: false
        tooltipText: "Menu"
        onPressed: function(button) {
          if (!root.bar) return
          if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
          else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
        }
      }
    }
  }

  component Pill: Item {
    id: pill

    property int workspaceId: 0
    property int distance: 0
    property real slant: 0

    readonly property var workspace: root.workspaceById(workspaceId)
    readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
    readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === workspaceId
    readonly property bool hovered: button.tooltipHovered
    readonly property real pillHeight: focused ? 29 : root.heights[Math.min(distance, 2)]
    readonly property color fill: focused ? root.fg
      : Util.alpha(root.fgBright, hovered ? 0.20 : (occupied ? 0.12 : 0.06))

    width: root.widths[Math.min(distance, 2)]
    height: root.barSize

    Item {
      id: body
      anchors.bottom: parent.bottom
      width: parent.width
      height: pill.pillHeight

      Behavior on height { NumberAnimation { duration: 150 } }

      layer.enabled: pill.focused
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Util.alpha(root.fg, 0.5)
        shadowBlur: 0.35
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        autoPaddingEnabled: true
      }

      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          strokeWidth: -1
          fillColor: pill.fill
          startX: 0; startY: body.height
          PathLine { x: body.width; y: body.height }
          PathLine { x: body.width - pill.slant * body.height; y: 0 }
          PathLine { x: -pill.slant * body.height; y: 0 }
          PathLine { x: 0; y: body.height }

          Behavior on fillColor { ColorAnimation { duration: 150 } }
        }
      }

      Text {
        readonly property real lift: 3 + font.pixelSize / 2

        x: (body.width - width) / 2 - pill.slant * lift
        rotation: root.vertical ? -90 : 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        height: font.pixelSize
        verticalAlignment: Text.AlignBottom
        renderType: Text.QtRendering
        text: pill.workspaceId === 10 ? "0" : String(pill.workspaceId)
        color: pill.focused ? root.ink : (pill.occupied || pill.hovered ? root.fgBright : root.fgDim)
        font.family: shareTech.name
        font.pixelSize: 13
        font.bold: pill.focused
        font.letterSpacing: 13 * 0.08

        Behavior on color { ColorAnimation { duration: 150 } }
      }
    }

    WidgetButton {
      id: button
      anchors.fill: parent
      bar: root.bar
      text: " "
      labelVisible: false
      onPressed: function() { root.focusWorkspace(pill.workspaceId) }
    }
  }
}
