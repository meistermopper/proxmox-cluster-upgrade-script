const { execSync } = require("node:child_process");
const fs = require("node:fs");

// The first argument is the path to the temporary commit message file (.git/COMMIT_EDITMSG)
const commitMsgFile = process.argv[2];
// The second argument specifies the source of the message (e.g., "message", "merge", "template", or empty)
const commitSource = process.argv[3];

if (!commitMsgFile) {
  console.error("[AI-Commit-Hook] Error: No commit message file path provided.");
  process.exit(1);
}

/**
 * Get git diff for staged changes.
 */
function getGitDiff() {
  try {
    return execSync("git diff --cached").toString();
  } catch {
    console.error("[AI-Commit-Hook] Error fetching git diff.");
    process.exit(1);
  }
}

/**
 * Call Gemini API to generate commit message.
 */
async function generateCommitMessage(diff) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.warn(
      "\n⚠️ [AI-Commit-Hook] Warning: GEMINI_API_KEY environment variable is not set!",
    );
    console.warn(
      "Please set GEMINI_API_KEY to enable automatic AI commit messages.\n",
    );
    return null;
  }

  // Precise prompt for structured commit messages with English header and body
  const prompt = `You are a professional Git expert. Generate a detailed and structured commit message based on the following git diff of staged changes.
Use the "Conventional Commits" format.

Format:
<type>(<scope>): <short summary in English>

- <Detailed change 1 in English>
- <Detailed change 2 in English (WHAT was changed and WHY)>

Rules:
1. Type must be one of: feat, fix, docs, style, refactor, perf, test, build, ci, chore.
2. The scope corresponds to the affected component (e.g., cluster, upgrade, config, ha, node, global).
3. The summary header must be short and concise in English.
4. The bullet points in the body must be detailed and in English, describing WHAT was changed and WHY.
5. Respond ONLY with the raw commit message text. Do NOT wrap in markdown code blocks (\`\`\`), do NOT include introductions or explanations.

Here is the git diff:
${diff}`;

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API Error: ${response.status} - ${errText}`);
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  return text ? text.trim() : null;
}

async function main() {
  // Skip if commit originates from special source (e.g. merge, amend, -m message)
  if (commitSource && commitSource !== "") {
    return;
  }

  // Check if user already typed a commit message in VS Code input box
  let existingContent = "";
  if (fs.existsSync(commitMsgFile)) {
    existingContent = fs
      .readFileSync(commitMsgFile, "utf-8")
      .split("\n")
      .filter((line) => !line.trim().startsWith("#"))
      .join("\n")
      .trim();
  }

  // If input box already contains user text, do not overwrite it
  if (existingContent.length > 0) {
    return;
  }

  const diff = getGitDiff();
  if (!diff.trim()) {
    return; // Nothing staged
  }

  console.log("[AI-Commit-Hook] Generating commit message via Gemini...");
  try {
    const commitMsg = await generateCommitMessage(diff);
    if (commitMsg) {
      fs.writeFileSync(commitMsgFile, commitMsg, "utf-8");
      console.log("[AI-Commit-Hook] Commit message successfully injected.");
    }
  } catch (err) {
    console.error("\n❌ [AI-Commit-Hook] Generation error:", err.message);
    // Continue commit gracefully so user can type manually as fallback
  }
}

main();
