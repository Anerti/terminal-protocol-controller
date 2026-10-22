import QtQuick
import QtQuick.Effects

Item {
  id: root

  property real iconSize: 16
  property color color: "white"

  implicitWidth: iconSize
  implicitHeight: iconSize

  Image {
    id: mask
    anchors.fill: parent
    visible: false
    source: Qt.resolvedUrl("assets/radiation.png")
    sourceSize: Qt.size(128, 128)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
  }

  MultiEffect {
    anchors.fill: mask
    source: mask
    colorization: 1.0
    colorizationColor: root.color
  }
}
