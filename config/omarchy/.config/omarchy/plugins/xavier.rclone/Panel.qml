import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "xavier.rclone"
  ipcTarget: "xavier.rclone"

  property string focusSection: "header"
  property int remoteIndex: 0
  property int fileIndex: 0
  property bool cursorActive: false
  readonly property string heroPhraseText: rclone.transferringNow
    ? rclone.activityHeadline
    : rclone.statusText
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color iconColor: rclone.active ? foreground : dim
  readonly property bool headerHasCursor: cursorActive && focusSection === "header"
  readonly property var remotes: rclone.displayRemotes

  function ensureCursor() {
    if (remoteIndex >= remotes.length) remoteIndex = Math.max(0, remotes.length - 1)
    if (fileIndex >= rclone.transferring.length) fileIndex = Math.max(0, rclone.transferring.length - 1)
    if (focusSection === "remotes" && remotes.length === 0) focusSection = "header"
    if (focusSection === "files" && rclone.transferring.length === 0) focusSection = remotes.length > 0 ? "remotes" : "header"
  }

  function moveCursor(dx, dy) {
    cursorActive = true
    ensureCursor()
    if (dy === 0) return
    if (focusSection === "header") {
      if (dy > 0 && remotes.length > 0) {
        focusSection = "remotes"
        remoteIndex = 0
      }
      return
    }
    if (focusSection === "remotes") {
      if (dy < 0 && remoteIndex === 0) {
        focusSection = "header"
        return
      }
      if (dy > 0 && remoteIndex >= remotes.length - 1) {
        if (rclone.transferring.length > 0) {
          focusSection = "files"
          fileIndex = 0
        }
        return
      }
      remoteIndex = Math.max(0, Math.min(remotes.length - 1, remoteIndex + dy))
      return
    }
    if (focusSection === "files") {
      if (dy < 0 && fileIndex === 0) {
        focusSection = remotes.length > 0 ? "remotes" : "header"
        if (focusSection === "remotes") remoteIndex = Math.max(0, remotes.length - 1)
        return
      }
      fileIndex = Math.max(0, Math.min(rclone.transferring.length - 1, fileIndex + dy))
    }
  }

  function selectedRemote() {
    if (remotes.length === 0) return null
    return remotes[Math.max(0, Math.min(remoteIndex, remotes.length - 1))]
  }

  function selectedFile() {
    if (rclone.transferring.length === 0) return null
    return rclone.transferring[Math.max(0, Math.min(fileIndex, rclone.transferring.length - 1))]
  }

  function activateCursor() {
    ensureCursor()
    if (focusSection === "header") rclone.openCloud()
    else if (focusSection === "remotes") {
      var remote = selectedRemote()
      if (remote) rclone.openFolder(remote.name)
    } else if (focusSection === "files") rclone.openFile(selectedFile())
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    rclone.refresh()
    rclone.refreshAbout()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Service {
    id: rclone
    settings: root.settings
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "rclone · " + (rclone.transferringNow
      ? rclone.activityHeadline + (rclone.directionalSpeedText ? " · " + rclone.directionalSpeedText : "")
      : rclone.statusText)
    dimmed: !rclone.active
    text: rclone.transferringNow ? "󰘿" : "󰅟"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) rclone.openCloud()
      else if (buttonCode === Qt.MiddleButton) rclone.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") rclone.refresh()
        else if (t === "o" || t === "O") {
          var remote = root.selectedRemote()
          if (remote) rclone.openFolder(remote.name)
          else rclone.openCloud()
        }
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          Item {
            id: header
            width: parent.width
            implicitHeight: hero.implicitHeight
            readonly property bool ringVisible: root.headerHasCursor
            function focusHero() {
              root.cursorActive = true
              root.focusSection = "header"
            }

            PanelHero {
              id: hero
              width: parent.width
              title: "rclone"
              meta: root.heroPhraseText
              detail: rclone.directionalSpeedText
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconOpacity: rclone.active ? 1.0 : 0.5
              iconComponent: Component {
                CloudIcon {
                  iconSize: Style.font.display
                  busy: rclone.transferringNow
                  color: root.iconColor
                  fontFamily: root.fontFamily
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: rclone.actionStatus !== "" || rclone.lastError !== ""
            width: parent.width
            text: rclone.actionStatus !== "" ? rclone.actionStatus : rclone.lastError
            color: rclone.lastError !== "" && rclone.actionStatus === "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "MOUNTS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              visible: remotes.length === 0
              width: parent.width
              text: "No rclone remotes yet. Add one with rclone config and it will show up here."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }

            Column {
              visible: remotes.length > 0
              width: parent.width
              spacing: Style.space(4)

              Repeater {
                model: remotes
                MountGroup {
                  required property var modelData
                  required property int index
                  width: parent.width
                  remote: modelData
                  rowIndex: index
                }
              }
            }
          }

          PanelSeparator {
            visible: rclone.recent.length > 0
            foreground: root.foreground
          }

          Column {
            visible: rclone.recent.length > 0
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "RECENT ITEMS"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Column {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: rclone.recent
                RecentRow {
                  required property var modelData
                  width: parent.width
                  item: modelData
                }
              }
            }
          }
        }
      }
    }
  }

  component MountGroup: Column {
    id: mountGroup
    property var remote: null
    property int rowIndex: 0
    spacing: Style.space(8)
    readonly property var group: {
      var groups = rclone.activityGroups
      var name = remote ? String(remote.name || "") : ""
      for (var i = 0; i < groups.length; i++)
        if (groups[i] && groups[i].name === name) return groups[i]
      return null
    }
    readonly property int fileOffset: {
      var groups = rclone.activityGroups
      var n = 0
      var name = remote ? String(remote.name || "") : ""
      for (var i = 0; i < groups.length; i++) {
        if (groups[i] && groups[i].name === name) break
        n += (groups[i].files || []).length
      }
      return n
    }

    PanelSeparator {
      visible: mountGroup.rowIndex > 0
      width: parent.width
      foreground: root.foreground
      opacity: 0.55
    }

    RemoteRow {
      width: parent.width
      remote: mountGroup.remote
      rowIndex: mountGroup.rowIndex
    }

    Item {
      visible: mountGroup.group !== null
      width: parent.width
      implicitHeight: filesColumn.implicitHeight

      Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: Style.space(10)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(1, Style.spacing.hairline)
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)
      }

      Column {
        id: filesColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Style.space(16)
        spacing: Style.space(6)

        Repeater {
          model: mountGroup.group && mountGroup.group.files ? mountGroup.group.files : []
          FileRow {
            required property var modelData
            required property int index
            width: parent.width
            file: modelData
            rowIndex: mountGroup.fileOffset + index
          }
        }
      }
    }
  }

  component RemoteRow: CursorSurface {
    id: remoteRow
    property var remote: null
    property int rowIndex: 0
    readonly property string remoteName: remote ? String(remote.name || "") : ""
    readonly property bool mounted: remote ? remote.mounted === true : false

    hasCursor: root.cursorActive && root.focusSection === "remotes" && root.remoteIndex === rowIndex
    foreground: root.foreground
    implicitHeight: remoteInner.implicitHeight + Style.spacing.rowPaddingX

    RowLayout {
      id: remoteInner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(8)

      Item {
        Layout.fillWidth: true
        implicitHeight: remoteLabels.implicitHeight

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            root.cursorActive = true
            root.focusSection = "remotes"
            root.remoteIndex = remoteRow.rowIndex
          }
          onClicked: if (remoteRow.remote) rclone.openFolder(remoteRow.remoteName)
        }

        Column {
          id: remoteLabels
          width: parent.width
          spacing: Style.space(1)

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: remoteRow.remoteName
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: remoteRow.remote
              ? Model.providerLabel(remote.type) + " · " + Model.remoteMeta(remote)
              : ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }
      }

      PanelActionButton {
        id: actionsButton
        iconText: "󰇙"
        tooltipText: "Mount actions"
        foreground: root.foreground
        fontFamily: root.fontFamily
        enabled: !rclone.busy
        Layout.alignment: Qt.AlignVCenter
        onClicked: actionsPopup.opened ? actionsPopup.close() : actionsPopup.open()
      }

      Popup {
        id: actionsPopup
        x: actionsButton.x + actionsButton.width - width
        y: actionsButton.y + actionsButton.height + Style.space(4)
        width: Style.space(210)
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: if (root.opened) Qt.callLater(function() { keyCatcher.forceActiveFocus() })

        background: BorderSurface {
          color: Color.background
          borderSpec: Border.flat(root.dim, 1)
          radius: Style.cornerRadius
        }

        contentItem: Column {
          width: parent.width

          MountActionChoice {
            width: parent.width
            iconText: "󰑐"
            label: "Restart mount"
            enabled: remoteRow.mounted && !rclone.busy
            onChosen: {
              actionsPopup.close()
              rclone.restartMount(remoteRow.remoteName)
            }
          }
        }
      }
    }
  }

  component MountActionChoice: CursorSurface {
    id: actionChoice
    property string iconText: ""
    property string label: ""
    signal chosen()

    foreground: root.foreground
    implicitHeight: Style.space(44)
    radius: 0

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: actionChoice.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      enabled: actionChoice.enabled
      onClicked: actionChoice.chosen()
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.space(12)
      anchors.rightMargin: Style.space(12)
      spacing: Style.space(9)

      Text {
        textFormat: Text.PlainText
        text: actionChoice.iconText
        color: actionChoice.enabled ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
      }

      Text {
        Layout.fillWidth: true
        textFormat: Text.PlainText
        text: actionChoice.label
        color: actionChoice.enabled ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
    }
  }

  component FileRow: CursorSurface {
    id: fileRow
    property var file: null
    property int rowIndex: 0
    readonly property string fileName: file ? String(file.name || "Untitled") : "Untitled"
    readonly property bool queued: file ? file.queued === true : false
    readonly property real fraction: {
      if (!file || queued) return 0
      var pct = Number(file.percentage || 0)
      if (pct > 0) return Math.max(0, Math.min(1, pct / 100))
      var size = Number(file.size || 0)
      if (size > 0) return Math.max(0, Math.min(1, Number(file.bytes || 0) / size))
      return 0
    }

    hasCursor: root.cursorActive && root.focusSection === "files" && root.fileIndex === rowIndex
    foreground: root.foreground
    implicitHeight: fileLine.implicitHeight + Style.space(6)

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: {
        root.cursorActive = true
        root.focusSection = "files"
        root.fileIndex = fileRow.rowIndex
      }
      onClicked: rclone.openFile(fileRow.file)
    }

    RowLayout {
      id: fileLine
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: Model.fileGlyph(fileRow.fileName)
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        textFormat: Text.PlainText
        Layout.fillWidth: true
        text: fileRow.fileName
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: false
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        visible: text !== ""
        text: Model.fileProgressText(fileRow.file)
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        Layout.alignment: Qt.AlignVCenter
      }

      Item {
        visible: !fileRow.queued
        Layout.preferredWidth: Style.space(36)
        implicitHeight: Math.max(2, Style.spacing.hairline * 2)
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
          id: fileTrack
          anchors.fill: parent
          radius: height / 2
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
        }

        Rectangle {
          anchors.left: fileTrack.left
          anchors.verticalCenter: fileTrack.verticalCenter
          height: fileTrack.height
          radius: fileTrack.radius
          color: root.foreground
          width: Math.max(fileRow.fraction > 0 ? fileTrack.height : 0, fileTrack.width * fileRow.fraction)

          Behavior on width {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }

  component RecentRow: CursorSurface {
    id: recentRow
    property var item: null
    readonly property string itemName: item ? String(item.name || "Untitled") : "Untitled"

    foreground: root.foreground
    implicitHeight: recentContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: rclone.openFile(recentRow.item)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: Model.fileGlyph(recentRow.itemName)
        color: recentRow.item && recentRow.item.error ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        id: recentContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: recentRow.itemName
          color: recentRow.item && recentRow.item.error ? root.urgent : root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: Model.recentMeta(recentRow.item)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
