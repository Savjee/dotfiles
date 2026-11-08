import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: ""

  readonly property string pluginDir: manifest && manifest.__sourceDir
    ? String(manifest.__sourceDir)
    : (Quickshell.env("HOME") + "/.config/omarchy/plugins/xavier.scw")
  readonly property string helperPath: pluginDir + "/publish.sh"

  property bool refreshing: false
  property string lastError: ""
  property int serviceCount: 0
  property string _output: ""
  property string _error: ""

  function publish() {
    if (publishProcess.running) return
    _output = ""
    _error = ""
    refreshing = true
    publishProcess.command = ["bash", "-lc", helperPath]
    publishProcess.running = true
  }

  function applyResult(raw, exitCode) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "").trim().split("\n").pop() || "{}") } catch (e) { parsed = null }
    if (parsed && typeof parsed === "object") {
      serviceCount = Number(parsed.count || 0)
      lastError = parsed.ok === false ? String(parsed.error || "publish failed") : ""
      return
    }
    if (exitCode !== 0) lastError = String(raw || "publish failed")
  }

  Component.onCompleted: root.publish()

  function ping() { return "ok" }

  Process {
    id: publishProcess
    running: false
    command: []
    stdout: StdioCollector { id: publishStdout; waitForEnd: true; onStreamFinished: root._output = text }
    stderr: StdioCollector { id: publishStderr; waitForEnd: true; onStreamFinished: root._error = text }
    onExited: function(exitCode) {
      root.refreshing = false
      var stdout = String(publishStdout.text || root._output || "")
      var stderr = String(publishStderr.text || root._error || "")
      root.applyResult(stdout || stderr, exitCode)
    }
  }
}
