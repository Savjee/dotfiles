import QtQuick
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool busy: false
  property string fontFamily: Style.font.family

  implicitWidth: iconSize
  implicitHeight: iconSize

  Text {
    anchors.centerIn: parent
    text: root.busy ? "󰘿" : "󰅟"
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: Math.round(root.iconSize)
  }
}
