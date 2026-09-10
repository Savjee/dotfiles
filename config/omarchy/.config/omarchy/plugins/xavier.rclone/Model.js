function parseStatus(raw) {
  var text = String(raw || "").trim()
  if (text === "") return { ok: false, remotes: [], error: "empty" }
  try {
    var parsed = JSON.parse(text)
    if (!parsed || typeof parsed !== "object") return { ok: false, remotes: [], error: "invalid" }
    if (parsed.error && !parsed.ok) return { ok: false, remotes: [], error: String(parsed.error) }
    var remotes = Array.isArray(parsed.remotes) ? parsed.remotes : []
    return { ok: true, remotes: remotes }
  } catch (e) {
    return { ok: false, remotes: [], error: "Failed to parse rclone status" }
  }
}

function mergeQuota(nextList, prevList) {
  var prev = {}
  for (var i = 0; i < prevList.length; i++) {
    var item = prevList[i] || {}
    if (item.name) prev[item.name] = item
  }
  var out = []
  for (var j = 0; j < nextList.length; j++) {
    var next = nextList[j] || {}
    var old = prev[next.name]
    if (old && !next.quotaKnown && old.quotaKnown) {
      next.usedBytes = old.usedBytes
      next.totalBytes = old.totalBytes
      next.freeBytes = old.freeBytes
      next.quotaKnown = old.quotaKnown
    }
    out.push(next)
  }
  return out
}

function flattenTransfers(remotes) {
  var groups = activityGroups(remotes)
  var out = []
  for (var i = 0; i < groups.length; i++) {
    var list = groups[i] && groups[i].files ? groups[i].files : []
    for (var j = 0; j < list.length && out.length < 16; j++) out.push(list[j])
  }
  return out
}

function fileCountWord(n, noun) {
  var count = Number(n || 0)
  if (count === 1) return "1 " + noun
  return count + " " + noun + "s"
}

function capitalize(text) {
  var value = String(text || "")
  if (value === "") return ""
  return value.charAt(0).toUpperCase() + value.slice(1)
}

function formatEta(seconds) {
  var value = Number(seconds)
  if (!isFinite(value) || value < 0) return ""
  if (value < 1) return "a moment"
  if (value < 60) return Math.round(value) + "s left"
  var minutes = Math.round(value / 60)
  if (minutes < 60) return minutes + "m left"
  var hours = Math.floor(minutes / 60)
  var rem = minutes % 60
  if (rem === 0) return hours + "h left"
  return hours + "h " + rem + "m left"
}

function fileProgressText(file) {
  if (!file) return ""
  if (file.queued) return "Queued"
  var bits = []
  if (Number(file.size || 0) > 0) bits.push(formatBytes(file.bytes) + " / " + formatBytes(file.size))
  else if (Number(file.bytes || 0) > 0) bits.push(formatBytes(file.bytes))
  return bits.join(" · ")
}

function activityGroups(remotes) {
  var groups = []
  for (var i = 0; i < remotes.length; i++) {
    var remote = remotes[i]
    if (!remote) continue
    var files = remote.transferring && remote.transferring.length ? remote.transferring.slice() : []
    var uploads = uploadCount(remote)
    var speed = Number(remote.speed || 0)
    if (files.length === 0 && uploads === 0 && speed < 1) continue
    var uploadFiles = 0
    var downloadFiles = 0
    for (var j = 0; j < files.length; j++) {
      if (files[j] && files[j].direction === "download") downloadFiles++
      else uploadFiles++
    }
    var namedCount = files.length
    if (namedCount === 0 && uploads > 0) {
      uploadFiles = uploads
      files = [{
        remote: remote.name,
        name: uploads === 1 ? "Waiting to upload" : "Waiting to upload " + uploads + " files",
        path: "",
        bytes: 0,
        size: 0,
        percentage: 0,
        speed: speed,
        eta: -1,
        direction: "upload",
        queued: true
      }]
    }
    var verb = "transferring"
    if (downloadFiles > 0 && uploadFiles === 0) verb = "downloading"
    else if (uploadFiles > 0 && downloadFiles === 0) verb = "uploading"
    var count = namedCount > 0 ? namedCount : uploads
    var headline = providerLabel(remote.type) + " is " + verb
    if (count > 0) headline += " " + fileCountWord(count, "file")
    groups.push({
      name: remote.name,
      type: remote.type,
      label: providerLabel(remote.type),
      speed: speed,
      files: files,
      count: count,
      verb: verb,
      headline: headline,
      caption: count > 0 ? capitalize(verb) + " " + fileCountWord(count, "file") : "Transferring",
      speedText: formatSpeed(speed)
    })
  }
  return groups
}

function activityHeadline(groups, fallback) {
  if (!groups || groups.length === 0) return fallback || ""
  var count = 0
  var verb = groups[0].verb
  for (var i = 0; i < groups.length; i++) {
    count += Number(groups[i].count || 0)
    if (groups[i].verb !== verb) verb = "transferring"
  }
  return capitalize(verb) + " " + fileCountWord(count, "file")
}

function directionalSpeedText(transfers) {
  var upload = 0
  var download = 0
  for (var i = 0; i < transfers.length; i++) {
    var item = transfers[i]
    if (!item) continue
    var speed = Number(item.speed || 0)
    if (!isFinite(speed) || speed < 1) continue
    if (item.direction === "download") download += speed
    else upload += speed
  }
  if (upload < 1 && download < 1) return ""
  if (download > upload) return "↓ " + formatSpeed(download)
  return "↑ " + formatSpeed(upload)
}

function flattenRecent(remotes) {
  var out = []
  for (var i = 0; i < remotes.length; i++) {
    var list = remotes[i] && remotes[i].recent ? remotes[i].recent : []
    for (var j = 0; j < list.length; j++) out.push(list[j])
  }
  out.sort(function(a, b) {
    return String(b.completedAt || "").localeCompare(String(a.completedAt || ""))
  })
  return out.slice(0, 8)
}

function relativeTime(timestamp) {
  var then = Date.parse(String(timestamp || ""))
  if (!isFinite(then)) return ""
  var seconds = Math.max(0, Math.floor((Date.now() - then) / 1000))
  if (seconds < 60) return "just now"
  var minutes = Math.floor(seconds / 60)
  if (minutes < 60) return minutes + "m ago"
  var hours = Math.floor(minutes / 60)
  if (hours < 24) return hours + "h ago"
  return Math.floor(hours / 24) + "d ago"
}

function recentMeta(item) {
  if (!item) return ""
  var bits = []
  bits.push(item.error ? "Failed" : (item.direction === "download" ? "Downloaded" : "Uploaded"))
  if (Number(item.bytes || 0) > 0) bits.push(formatBytes(item.bytes))
  if (item.remote) bits.push(String(item.remote))
  var when = relativeTime(item.completedAt)
  if (when) bits.push(when)
  return bits.join(" · ")
}

function providerLabel(type) {
  var key = String(type || "").toLowerCase()
  var labels = {
    drive: "Google Drive",
    onedrive: "OneDrive",
    sharepoint: "SharePoint",
    dropbox: "Dropbox",
    box: "Box",
    mega: "Mega",
    protondrive: "Proton Drive",
    s3: "S3",
    b2: "B2",
    webdav: "WebDAV",
    ftp: "FTP",
    sftp: "SFTP",
    seafile: "Seafile",
    pcloud: "pCloud",
    swift: "Swift",
    crypt: "Crypt",
    alias: "Alias",
    union: "Union",
    chunker: "Chunker",
    compress: "Compress",
    cache: "Cache",
    internetarchive: "Internet Archive",
    jottacloud: "Jottacloud",
    koofr: "Koofr",
    mailru: "Mail.ru",
    opendrive: "OpenDrive",
    premiumizeme: "premiumize.me",
    putio: "put.io",
    qingstor: "QingStor",
    sharefile: "ShareFile",
    sugarsync: "SugarSync",
    uptobox: "Uptobox",
    yandex: "Yandex",
    zoho: "Zoho"
  }
  return labels[key] || (key ? key : "Cloud")
}

function uploadCount(remote) {
  if (!remote) return 0
  return Number(remote.uploadsInProgress || 0) + Number(remote.uploadsQueued || 0)
}

function remoteMeta(remote) {
  if (!remote) return ""
  if (!remote.mounted) return "Unmounted"
  var speed = formatSpeed(remote.speed)
  var uploads = uploadCount(remote)
  var transfers = remote.transferring && remote.transferring.length ? remote.transferring.length : 0
  if (speed && (uploads > 0 || transfers > 0)) return speed
  if (uploads > 0) return uploads === 1 ? "Uploading 1 file" : "Uploading " + uploads + " files"
  if (transfers > 0) return transfers === 1 ? "Transferring 1 file" : "Transferring " + transfers + " files"
  if (speed) return speed
  if (remote.quotaKnown) return usageText(remote.usedBytes, remote.totalBytes)
  if (remote.cacheFiles > 0) return formatBytes(remote.cacheBytes) + " cached"
  return "Mounted"
}

function formatBytes(bytes) {
  var value = Number(bytes || 0)
  if (!isFinite(value) || value < 0) return "0 B"
  if (value === 0) return "0 B"
  var units = ["B", "KB", "MB", "GB", "TB"]
  var index = 0
  while (value >= 1000 && index < units.length - 1) {
    value = value / 1000
    index++
  }
  var decimals = value >= 100 || index === 0 ? 0 : (value >= 10 ? 1 : 2)
  return value.toFixed(decimals).replace(/\.0+$/, "").replace(/(\.\d)0$/, "$1") + " " + units[index]
}

function formatSpeed(bytesPerSec) {
  var value = Number(bytesPerSec || 0)
  if (!isFinite(value) || value < 1) return ""
  return formatBytes(value) + "/s"
}

function formatPercent(value) {
  var number = Number(value || 0)
  if (!isFinite(number) || number <= 0) return "0%"
  if (number >= 10) return Math.round(number) + "%"
  return number.toFixed(1).replace(/\.0$/, "") + "%"
}

function usageText(usedBytes, totalBytes) {
  if (Number(totalBytes || 0) > 0) return formatBytes(usedBytes) + " of " + formatBytes(totalBytes)
  return formatBytes(usedBytes)
}

function fileGlyph(name) {
  var ext = String(name || "").toLowerCase()
  var index = ext.lastIndexOf(".")
  ext = index >= 0 ? ext.substring(index + 1) : ""
  if ("jpg jpeg png gif webp avif heic svg bmp tif tiff".split(" ").indexOf(ext) >= 0) return "󰋩"
  if ("mp4 mov mkv webm avi m4v mpg mpeg wmv".split(" ").indexOf(ext) >= 0) return "󰈫"
  if ("pdf txt md doc docx xls xlsx ppt pptx odt ods odp rtf csv".split(" ").indexOf(ext) >= 0) return "󰈙"
  return "󰈔"
}

if (typeof module !== "undefined") {
  module.exports = {
    parseStatus: parseStatus,
    mergeQuota: mergeQuota,
    flattenTransfers: flattenTransfers,
    activityGroups: activityGroups,
    activityHeadline: activityHeadline,
    directionalSpeedText: directionalSpeedText,
    flattenRecent: flattenRecent,
    relativeTime: relativeTime,
    recentMeta: recentMeta,
    fileProgressText: fileProgressText,
    formatEta: formatEta,
    uploadCount: uploadCount,
    providerLabel: providerLabel,
    remoteMeta: remoteMeta,
    formatBytes: formatBytes,
    formatSpeed: formatSpeed,
    formatPercent: formatPercent,
    usageText: usageText,
    fileGlyph: fileGlyph
  }
}
