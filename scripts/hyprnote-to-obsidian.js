#!/opt/homebrew/bin/node

/**
 * Syncs Hyprnote meetings to Obsidian.
 * Creates a .synced-to-obsidian file in each meeting folder to track synced meetings.
 *
 * Skips sessions until XD Meeting.md exists (Hyprnote’s AI summary), so in-progress meetings
 * are not exported before that file is written.
 */

import { readdir, readFile, writeFile, access } from "fs/promises";
import { join } from "path";

const HYPRNOTE_SESSIONS = `${process.env.HOME}/Library/Application Support/hyprnote/sessions`;
const OBSIDIAN_VAULT = process.env.OBSIDIAN_VAULT ?? "/Users/xavier/Workspace/XD Brain";
const SYNC_MARKER = ".synced-to-obsidian";

async function fileExists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

function stripFrontmatter(content) {
  const match = content.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n([\s\S]*)$/);
  return match ? match[1].trim() : content.trim();
}

function indentHeaders(content) {
  return content.replace(/^(#{1,6})(\s+)/gm, (_, hashes, space) => hashes + "#" + space);
}

async function transcriptToPlainText(transcriptPath) {
  const data = JSON.parse(await readFile(transcriptPath, "utf8"));
  const transcripts = (data.transcripts ?? []).sort(
    (a, b) => new Date(a.started_at ?? 0) - new Date(b.started_at ?? 0)
  );
  const words = transcripts.flatMap((t) => {
    const w = (t.words ?? []).slice().sort((a, b) => (a.start_ms ?? 0) - (b.start_ms ?? 0));
    return w;
  });
  if (words.length === 0) return "";

  const lines = [];
  let currentChannel = null;
  let currentText = [];

  for (const w of words) {
    const ch = w.channel ?? 0;
    const text = (w.text ?? "").trim();
    if (!text) continue;

    if (ch !== currentChannel) {
      if (currentText.length > 0) {
        lines.push(`Speaker ${currentChannel + 1}: ${currentText.join(" ").trim()}`);
      }
      currentChannel = ch;
      currentText = [text];
    } else {
      currentText.push(text);
    }
  }
  if (currentText.length > 0) {
    lines.push(`Speaker ${currentChannel + 1}: ${currentText.join(" ").trim()}`);
  }

  return lines.join("\n\n");
}

async function syncMeeting(sessionDir) {
  const metaPath = join(sessionDir, "_meta.json");
  const transcriptPath = join(sessionDir, "transcript.json");
  const markerPath = join(sessionDir, SYNC_MARKER);

  if (await fileExists(markerPath)) return null;
  if (!(await fileExists(metaPath)) || !(await fileExists(transcriptPath))) {
    return null;
  }

  const aiSummaryPath = join(sessionDir, "XD Meeting.md");
  if (!(await fileExists(aiSummaryPath))) {
    return null;
  }

  const meta = JSON.parse(await readFile(metaPath, "utf8"));
  const transcript = await transcriptToPlainText(transcriptPath);

  const memoPath = join(sessionDir, "_memo.md");

  let personalNotes = "";
  if (await fileExists(memoPath)) {
    personalNotes = indentHeaders(stripFrontmatter(await readFile(memoPath, "utf8"))).replace(/&nbsp;/g, " ");
  }

  const aiSummary = indentHeaders(
    stripFrontmatter(await readFile(aiSummaryPath, "utf8"))
  );

  const created = new Date(meta.created_at ?? meta.id);
  const dateStr = created.toISOString().slice(0, 10);
  const title = (meta.title ?? "Untitled Meeting").replace(/[/\\?%*:|"<>]/g, "-");
  let safeName = `${dateStr} ${title}.md`;
  let outPath = join(OBSIDIAN_VAULT, safeName);
  if (await fileExists(outPath)) {
    safeName = `${dateStr} ${title} (${(meta.id ?? "dup").slice(0, 8)}).md`;
    outPath = join(OBSIDIAN_VAULT, safeName);
  }

  const personalNotesSection = personalNotes.trim() ? `# Personal notes\n\n${personalNotes}\n\n` : "";
  const aiSummarySection = aiSummary.trim() ? `# AI Summary\n\n${aiSummary}\n\n` : "";

  const content = `---
categories: "[[Meetings]]"
date: "[[${dateStr}]]"
companies: []
people: []
projects: []
---

${personalNotesSection}${aiSummarySection}# Transcript

${transcript}
`;

  await writeFile(outPath, content, "utf8");
  await writeFile(markerPath, JSON.stringify({ synced_at: new Date().toISOString(), obsidian_path: safeName }), "utf8");

  return outPath;
}

async function main() {
  const entries = await readdir(HYPRNOTE_SESSIONS, { withFileTypes: true });
  const dirs = entries.filter((e) => e.isDirectory()).map((e) => join(HYPRNOTE_SESSIONS, e.name));

  let synced = 0;
  for (const dir of dirs) {
    const result = await syncMeeting(dir);
    if (result) {
      console.log("Synced:", result);
      synced++;
    }
  }

  if (synced === 0) {
    console.log("No new meetings to sync.");
  } else {
    console.log(`\nSynced ${synced} meeting(s).`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
