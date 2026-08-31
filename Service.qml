import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var snapshot: ({
    source: "unconfigured",
    fetched_at: "",
    last_created_at: "",
    partial_history: true,
    error: "",
    unread_count: 0,
    stats: ({ total: 0, posts: 0, replies: 0, quotes: 0, reposts: 0, engagement: 0, views: 0 }),
    posts: []
  })
  property bool refreshing: false
  property string lastError: ""

  readonly property var stats: snapshot.stats || ({})
  readonly property var posts: snapshot.posts || []
  readonly property string source: String(snapshot.source || "unconfigured")
  readonly property string fetchedAt: String(snapshot.fetched_at || "")
  readonly property string lastCreatedAt: String(snapshot.last_created_at || "")
  readonly property int unreadCount: Math.max(0, Number(snapshot.unread_count || 0))
  readonly property bool configured: source !== "unconfigured"
  readonly property string helperPath: {
    var url = String(Qt.resolvedUrl("dhh-fm.py"))
    return decodeURIComponent(url.indexOf("file://") === 0 ? url.substring(7) : url)
  }

  function applySnapshot(text) {
    try {
      var value = JSON.parse(String(text || "{}"))
      if (!value || !Array.isArray(value.posts) || !value.stats)
        throw new Error("helper returned an invalid snapshot")
      root.snapshot = value
      root.lastError = String(value.error || "")
    } catch (error) {
      root.lastError = "Could not tune DHH FM: " + error
    }
  }

  function refresh() {
    if (refreshProcess.running) return
    root.refreshing = true
    root.lastError = ""
    refreshProcess.running = true
  }

  function markSeen() {
    if (root.unreadCount === 0 || markSeenProcess.running) return
    var next = Object.assign({}, root.snapshot)
    next.unread_count = 0
    root.snapshot = next
    markSeenProcess.running = true
  }

  function openUrl(url) {
    var target = String(url || "")
    if (target.indexOf("https://") !== 0 && target.indexOf("http://") !== 0) return
    Quickshell.execDetached(["xdg-open", target])
  }

  function replyTo(postId) {
    var id = String(postId || "")
    if (!/^\d+$/.test(id)) return
    openUrl("https://x.com/intent/tweet?in_reply_to=" + id)
  }

  function copyLink(url) {
    var target = String(url || "")
    if (!target) return
    copyProcess.command = ["wl-copy", target]
    copyProcess.running = true
  }

  Process {
    id: refreshProcess
    command: ["python3", root.helperPath, "refresh"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySnapshot(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim()) root.lastError = text.trim()
    }
    onExited: function(exitCode) {
      root.refreshing = false
      if (exitCode !== 0 && !root.lastError) root.lastError = "Feed helper exited with code " + exitCode
    }
  }

  Process { id: copyProcess }

  Process {
    id: markSeenProcess
    command: ["python3", root.helperPath, "mark-seen"]
  }

  Timer {
    interval: 10 * 60 * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
