.pragma library

function number(value) {
  var parsed = Number(value)
  return isFinite(parsed) && parsed >= 0 ? parsed : 0
}

function compactNumber(value) {
  var amount = number(value)
  if (amount < 1000) return String(Math.round(amount))
  if (amount < 1000000) return trimDecimal(amount / 1000) + "K"
  if (amount < 1000000000) return trimDecimal(amount / 1000000) + "M"
  return trimDecimal(amount / 1000000000) + "B"
}

function trimDecimal(value) {
  var rounded = Math.round(value * 10) / 10
  return String(rounded).replace(/\.0$/, "")
}

function relativeTime(iso, nowMs) {
  var timestamp = Date.parse(String(iso || ""))
  if (!isFinite(timestamp)) return "unknown"
  var now = nowMs === undefined ? Date.now() : Number(nowMs)
  var seconds = Math.max(0, Math.floor((now - timestamp) / 1000))
  if (seconds < 45) return "just now"
  if (seconds < 3600) return Math.floor(seconds / 60) + "m ago"
  if (seconds < 86400) return Math.floor(seconds / 3600) + "h ago"
  if (seconds < 604800) return Math.floor(seconds / 86400) + "d ago"
  return new Date(timestamp).toLocaleDateString()
}

function statusLine(stats, lastCreatedAt, nowMs) {
  var total = stats ? number(stats.total) : 0
  if (!lastCreatedAt) return "Tuning the transmitter"
  if (total === 0) return "Dead air · last signal " + relativeTime(lastCreatedAt, nowMs)
  return total + (total === 1 ? " transmission" : " transmissions")
    + " today · last " + relativeTime(lastCreatedAt, nowMs)
}

function kindLabel(kind) {
  if (kind === "reply") return "Reply"
  if (kind === "quote") return "Quote"
  if (kind === "repost") return "Repost"
  return "Post"
}

function filteredPosts(posts, filter) {
  var rows = Array.isArray(posts) ? posts : []
  if (filter === "posts")
    return rows.filter(function(post) { return post.kind !== "reply" })
  if (filter === "replies")
    return rows.filter(function(post) { return post.kind === "reply" })
  return rows
}

function engagement(post) {
  var metrics = post && post.metrics ? post.metrics : {}
  return number(metrics.likes) + number(metrics.reposts)
    + number(metrics.replies) + number(metrics.quotes)
}

function activityLevel(total) {
  var count = number(total)
  if (count >= 24) return 3
  if (count >= 8) return 2
  if (count > 0) return 1
  return 0
}
