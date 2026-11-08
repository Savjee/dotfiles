import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})
  property var remotes: []
  property bool refreshing: false
  property string lastError: ""
  property string actionStatus: ""
  property string _desiredName: ""
  property int _desired: -1

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/xavier.rclone"
  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 2, 1, 60)
  readonly property bool busy: statusProcess.running || aboutProcess.running || controlProcess.running
  readonly property var displayRemotes: overlayDesired(remotes)
  readonly property int mountedCount: countMounted(displayRemotes)
  readonly property int remoteCount: displayRemotes.length
  readonly property bool active: mountedCount > 0
  readonly property real speed: sumSpeed(displayRemotes)
  readonly property var transferring: Model.flattenTransfers(displayRemotes)
  readonly property var activityGroups: Model.activityGroups(displayRemotes)
  readonly property var recent: Model.flattenRecent(displayRemotes)
  readonly property int uploadingCount: countUploads(displayRemotes)
  readonly property bool transferringNow: transferring.length > 0 || uploadingCount > 0 || speed >= 1
  readonly property string speedText: Model.formatSpeed(speed)
  readonly property string directionalSpeedText: Model.directionalSpeedText(transferring)
  readonly property string activityHeadline: Model.activityHeadline(activityGroups, statusText)
  readonly property string statusText: {
    if (remoteCount === 0) return "No remotes"
    if (transferringNow) return speedText || "Transferring"
    if (mountedCount === 0) return "Unmounted"
    if (mountedCount === remoteCount) return remoteCount === 1 ? "Mounted" : mountedCount + " mounted"
    return mountedCount + " of " + remoteCount + " mounted"
  }

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    if (n < min) n = min
    if (n > max) n = max
    return n
  }

  function helperPath() {
    return pluginDir + "/status.sh"
  }

  function overlayDesired(list) {
    if (_desiredName === "" || _desired === -1) return list
    var out = []
    for (var i = 0; i < list.length; i++) {
      var item = list[i] || {}
      if (item.name === _desiredName) {
        var copy = {}
        for (var key in item) copy[key] = item[key]
        copy.mounted = _desired === 1
        out.push(copy)
      } else {
        out.push(item)
      }
    }
    return out
  }

  function countMounted(list) {
    var n = 0
    for (var i = 0; i < list.length; i++) if (list[i] && list[i].mounted) n++
    return n
  }

  function sumSpeed(list) {
    var total = 0
    for (var i = 0; i < list.length; i++) total += Number(list[i] && list[i].speed || 0)
    return total
  }

  function countUploads(list) {
    var n = 0
    for (var i = 0; i < list.length; i++) n += Number(list[i] && list[i].uploadsInProgress || 0) + Number(list[i] && list[i].uploadsQueued || 0)
    return n
  }

  function refresh() {
    if (statusProcess.running) return
    refreshing = true
    _statusOutput = ""
    _statusError = ""
    statusProcess.command = ["/usr/bin/bash", helperPath()]
    statusProcess.running = true
  }

  function refreshAbout() {
    if (aboutProcess.running) return
    aboutProcess.command = ["/usr/bin/bash", helperPath(), "--about"]
    aboutProcess.running = true
  }

  function applyStatus(raw, fromAbout) {
    var parsed = Model.parseStatus(raw)
    if (!parsed.ok) {
      lastError = parsed.error || "Could not read rclone status"
      return
    }
    remotes = Model.mergeQuota(parsed.remotes, remotes)
    lastError = ""
    if (_desiredName !== "") {
      var found = null
      for (var i = 0; i < remotes.length; i++) {
        if (remotes[i] && remotes[i].name === _desiredName) found = remotes[i]
      }
      if (found && found.mounted === (_desired === 1)) {
        _desiredName = ""
        _desired = -1
      }
    }
  }

  function elideStatus(text) {
    var value = String(text || "").replace(/\s+/g, " ").trim()
    return value.length > 140 ? value.substring(0, 137) + "…" : value
  }

  function setMounted(name, want) {
    var remote = String(name || "")
    if (remote === "" || controlProcess.running) return
    _desiredName = remote
    _desired = want ? 1 : 0
    _controlOutput = ""
    _controlError = ""
    _controlAction = want ? "start" : "stop"
    controlProcess.command = [Quickshell.env("HOME") + "/.local/bin/rclone-mount-control", want ? "start" : "stop", remote]
    controlProcess.running = true
  }

  function restartMount(name) {
    var remote = String(name || "")
    if (remote === "" || controlProcess.running) return
    _desiredName = remote
    _desired = -1
    _controlOutput = ""
    _controlError = ""
    _controlAction = "restart"
    actionStatus = "Restarting " + remote + "…"
    controlProcess.command = [Quickshell.env("HOME") + "/.local/bin/rclone-mount-control", "restart", remote]
    controlProcess.running = true
  }

  function toggleMounted(name) {
    var remote = String(name || "")
    var list = displayRemotes
    for (var i = 0; i < list.length; i++) {
      if (list[i] && list[i].name === remote) {
        setMounted(remote, !list[i].mounted)
        return
      }
    }
  }

  function openCloud() {
    Quickshell.execDetached(["uwsm-app", "--", "nautilus", Quickshell.env("HOME") + "/Cloud"])
  }

  function openFolder(name) {
    var remote = String(name || "")
    if (remote === "") {
      openCloud()
      return
    }
    Quickshell.execDetached(["uwsm-app", "--", "nautilus", Quickshell.env("HOME") + "/Cloud/" + remote])
  }

  function openFile(file) {
    if (!file || !file.path) {
      if (file && file.remote) openFolder(file.remote)
      else openCloud()
      return
    }
    var local = Quickshell.env("HOME") + "/Cloud/" + String(file.remote || "") + "/" + String(file.path).replace(/^\//, "")
    Quickshell.execDetached(["uwsm-app", "--", "nautilus", "--select", local])
  }

  property string _statusOutput: ""
  property string _statusError: ""
  property string _aboutOutput: ""
  property string _aboutError: ""
  property string _controlOutput: ""
  property string _controlError: ""
  property string _controlAction: ""

  Timer {
    id: refreshTimer
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: aboutTimer
    interval: 60000
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: if (root.active) root.refreshAbout()
  }

  Timer {
    id: delayedRefresh
    interval: 800
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: settleTimer
    property int ticks: 0
    interval: 1200
    repeat: true
    running: false
    onTriggered: {
      ticks += 1
      root.refresh()
      if (ticks >= 8) {
        ticks = 0
        running = false
        root._desiredName = ""
        root._desired = -1
      }
    }
  }

  Timer {
    id: actionStatusTimer
    interval: 2200
    repeat: false
    onTriggered: root.actionStatus = ""
  }

  Process {
    id: statusProcess
    running: false
    command: []
    stdout: StdioCollector { id: statusStdout; waitForEnd: true; onStreamFinished: root._statusOutput = text }
    stderr: StdioCollector { id: statusStderr; waitForEnd: true; onStreamFinished: root._statusError = text }
    onExited: function(exitCode) {
      root.refreshing = false
      var stdout = String(statusStdout.text || root._statusOutput || "")
      var stderr = String(statusStderr.text || root._statusError || "")
      if (exitCode === 0) root.applyStatus(stdout, false)
      else root.lastError = root.elideStatus(stderr || stdout || "Could not read rclone status")
    }
  }

  Process {
    id: aboutProcess
    running: false
    command: []
    stdout: StdioCollector { id: aboutStdout; waitForEnd: true; onStreamFinished: root._aboutOutput = text }
    stderr: StdioCollector { id: aboutStderr; waitForEnd: true; onStreamFinished: root._aboutError = text }
    onExited: function(exitCode) {
      var stdout = String(aboutStdout.text || root._aboutOutput || "")
      if (exitCode === 0) root.applyStatus(stdout, true)
    }
  }

  Process {
    id: controlProcess
    running: false
    command: []
    stdout: StdioCollector { id: controlStdout; waitForEnd: true; onStreamFinished: root._controlOutput = text }
    stderr: StdioCollector { id: controlStderr; waitForEnd: true; onStreamFinished: root._controlError = text }
    onExited: function(exitCode) {
      var stdout = String(controlStdout.text || root._controlOutput || "")
      var stderr = String(controlStderr.text || root._controlError || "")
      if (exitCode !== 0) {
        root._desiredName = ""
        root._desired = -1
        root.lastError = root.elideStatus(stderr || stdout || "rclone mount command failed")
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
      } else {
        root.lastError = ""
        root.actionStatus = root._controlAction === "restart" ? root._desiredName + " restarted" : ""
        if (root.actionStatus !== "") actionStatusTimer.restart()
      }
      root._controlAction = ""
      settleTimer.ticks = 0
      settleTimer.restart()
      delayedRefresh.restart()
    }
  }
}
