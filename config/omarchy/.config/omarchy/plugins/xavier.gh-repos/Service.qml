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
    : (Quickshell.env("HOME") + "/.config/omarchy/plugins/xavier.gh-repos")
  readonly property string helperPath: pluginDir + "/fetch.sh"

  property bool refreshing: false
  property string lastError: ""
  property int repoCount: 0
  property string _output: ""
  property string _error: ""

  function refresh(seedOnly) {
    if (fetchProcess.running) return
    _output = ""
    _error = ""
    refreshing = true
    var cmd = helperPath
    if (seedOnly) cmd += " --seed"
    fetchProcess.command = ["bash", "-lc", cmd]
    fetchProcess.running = true
  }

  function applyResult(raw, exitCode) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "").trim().split("\n").pop() || "{}") } catch (e) { parsed = null }
    if (parsed && typeof parsed === "object") {
      repoCount = Number(parsed.count || 0)
      lastError = parsed.ok === false ? String(parsed.error || "fetch failed") : String(parsed.error || "")
      return
    }
    if (exitCode !== 0) lastError = String(raw || "fetch failed")
  }

  Component.onCompleted: root.refresh(true)

  function ping() { return "ok" }

  Process {
    id: fetchProcess
    running: false
    command: []
    stdout: StdioCollector { id: fetchStdout; waitForEnd: true; onStreamFinished: root._output = text }
    stderr: StdioCollector { id: fetchStderr; waitForEnd: true; onStreamFinished: root._error = text }
    onExited: function(exitCode) {
      root.refreshing = false
      var stdout = String(fetchStdout.text || root._output || "")
      var stderr = String(fetchStderr.text || root._error || "")
      root.applyResult(stdout || stderr, exitCode)
    }
  }
}
