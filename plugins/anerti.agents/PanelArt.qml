import QtQuick
import QtQuick.Effects
import qs.Commons

Item {
  id: root

  property alias source: gif.source
  property bool playing: true

  implicitHeight: Style.space(200)

  AnimatedImage {
    id: gif
    anchors.fill: parent
    visible: false
    fillMode: Image.PreserveAspectFit
    playing: root.playing && root.visible
    cache: false
    smooth: true
  }

  MultiEffect {
    anchors.fill: gif
    source: gif
    colorization: 1.0
    colorizationColor: Color.foreground
    shadowEnabled: true
    shadowColor: Util.alpha(Color.foreground, 0.35)
    shadowBlur: 0.6
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    autoPaddingEnabled: true
  }
}
