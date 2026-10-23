import QtQuick
import qs.Commons

Item {
  id: root

  readonly property color phosphor: themePalette.brightForeground
  readonly property real bandHeight: height * 0.32
  readonly property bool running: roll.running

  function run() {
    roll.stop()
    roll.start()
  }

  ThemePalette { id: themePalette }

  clip: true
  visible: roll.running
  opacity: 0

  Item {
    id: lines
    width: parent.width
    height: parent.height + 16

    Repeater {
      model: Math.ceil(lines.height / 8)
      delegate: Rectangle {
        required property int index
        y: index * 8 + 5
        width: lines.width
        height: 2
        color: Util.alpha(root.phosphor, 0.22)
      }
    }
  }

  Rectangle {
    id: band
    width: parent.width
    height: root.bandHeight
    y: -height
    gradient: Gradient {
      GradientStop { position: 0.0; color: Util.alpha(root.phosphor, 0) }
      GradientStop { position: 0.44; color: Util.alpha(root.phosphor, 0.06) }
      GradientStop { position: 0.5; color: Util.alpha(root.phosphor, 0.5) }
      GradientStop { position: 0.56; color: Util.alpha(root.phosphor, 0.06) }
      GradientStop { position: 1.0; color: Util.alpha(root.phosphor, 0) }
    }
  }

  ParallelAnimation {
    id: roll

    SequentialAnimation {
      PropertyAction { target: root; property: "opacity"; value: 0.75 }
      PauseAnimation { duration: 126 }
      NumberAnimation { target: root; property: "opacity"; to: 0.55; duration: 72 }
      NumberAnimation { target: root; property: "opacity"; to: 0.7; duration: 108 }
      NumberAnimation { target: root; property: "opacity"; to: 0; duration: 54 }
    }

    SequentialAnimation {
      PropertyAction { target: band; property: "y"; value: -root.bandHeight }
      NumberAnimation { target: band; property: "y"; to: root.height; duration: 126 }
      NumberAnimation { target: band; property: "y"; to: -root.bandHeight; duration: 72 }
      NumberAnimation { target: band; property: "y"; to: root.height; duration: 108 }
    }

    SequentialAnimation {
      PropertyAction { target: lines; property: "y"; value: 0 }
      NumberAnimation { target: lines; property: "y"; to: -12; duration: 126 }
      NumberAnimation { target: lines; property: "y"; to: -6; duration: 72 }
      NumberAnimation { target: lines; property: "y"; to: -16; duration: 108 }
      NumberAnimation { target: lines; property: "y"; to: 0; duration: 54 }
    }
  }
}
