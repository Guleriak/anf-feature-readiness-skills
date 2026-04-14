# ANF Feature Readiness Skills - Setup Guide (Mac + PC)

This guide walks you through installing and configuring the Cursor AI skills that automate Feature Readiness Plans, Initiative Hubs, and the Weekly PLR Report. Works on **macOS, Windows, and Linux**.

---

## What You Get

| Skill | What It Does | Trigger |
|---|---|---|
| **Weekly-Ring** | Generates the weekly PLR meeting report - Confluence page + HTML email with the full feature table | Type `/anfplrweeklyreport` or ask Cursor to generate the weekly report |
| **feature-readiness-plan** | Creates a Feature Readiness Plan (Private Preview / Public Preview / GA) from a Jira issue, calculates milestone dates, populates owners, publishes to Confluence | Give Cursor a Jira issue key that has a Feature Stage |
| **feature-readiness-hub** | Creates an Initiative-level parent page in Confluence that groups all feature plans under one initiative | Automatically invoked by feature-readiness-plan when an Initiative Key exists, or run standalone |

---

## Prerequisites

- **Cursor IDE** (latest version) - download from [cursor.com](https://www.cursor.com) (available for Mac, Windows, and Linux)
- A **NetApp Jira** account with an API token
- An **Atlassian Cloud** account (for Confluence access)
- Access to the internal **SMTP relay** (for sending email reports) - requires VPN or on-prem network
- **Git** installed ([git-scm.com](https://git-scm.com/downloads) - comes pre-installed on macOS)

---

## Step 1: Install Cursor IDE

1. Download Cursor from [https://www.cursor.com](https://www.cursor.com)
   - **Mac**: Download the `.dmg`, drag to Applications
   - **Windows**: Download the `.exe` installer, run it
   - **Linux**: Download the `.AppImage` or `.deb`
2. Launch Cursor and sign in (or create a free account)
3. Open the built-in terminal:
   - **Mac**: Press **Cmd + `** (backtick)
   - **Windows/Linux**: Press **Ctrl + `** (backtick)

---

## Step 2: Install the Skills

The skills live under your Cursor skills folder. Choose your platform below.

### Mac / Linux

**Option A - One-line installer (recommended):**

```bash
curl -sL https://raw.githubusercontent.com/Guleriak/anf-feature-readiness-skills/main/install-skills.sh | bash
```

**Option B - Git clone:**

```bash
git clone https://github.com/Guleriak/anf-feature-readiness-skills.git ~/.cursor/skills
```

**Option C - Manual download:**

1. Go to [https://github.com/Guleriak/anf-feature-readiness-skills](https://github.com/Guleriak/anf-feature-readiness-skills)
2. Click the green **Code** button, then **Download ZIP**
3. Extract the ZIP and copy the folders to `~/.cursor/skills/`

### Windows (PC)

**Option A - Git clone (recommended):**

Open **PowerShell** or **Command Prompt** and run:

```powershell
git clone https://github.com/Guleriak/anf-feature-readiness-skills.git "%USERPROFILE%\.cursor\skills"
```

Or in PowerShell:

```powershell
git clone https://github.com/Guleriak/anf-feature-readiness-skills.git "$env:USERPROFILE\.cursor\skills"
```

**Option B - Manual download (no Git needed):**

1. Go to [https://github.com/Guleriak/anf-feature-readiness-skills](https://github.com/Guleriak/anf-feature-readiness-skills)
2. Click the green **Code** button, then **Download ZIP**
3. Extract the ZIP file
4. Open File Explorer and navigate to `C:\Users\YOUR_USERNAME\.cursor\`
5. Create a folder called `skills` if it doesn't exist
6. Copy these folders from the extracted ZIP into `C:\Users\YOUR_USERNAME\.cursor\skills\`:
   - `Weekly-Ring`
   - `feature-readiness-plan`
   - `feature-readiness-hub`

> **Tip**: The `.cursor` folder may be hidden. In File Explorer, click **View > Show > Hidden items** to see it.

### Verify the folder structure

After installing, you should see this layout:

**Mac/Linux:** `~/.cursor/skills/`
**Windows:** `C:\Users\YOUR_USERNAME\.cursor\skills\`

```
skills/
  Weekly-Ring/
    SKILL.md                  # Weekly report instructions
  feature-readiness-plan/
    SKILL.md                  # Feature plan instructions
    ownership-rules.md        # Owner assignment rules
    templates/
      private-preview.md
      public-preview.md
      ga.md
  feature-readiness-hub/
    SKILL.md                  # Hub skill instructions
    reference-hub-template.md
```

---

## Step 3: Configure MCP Servers

The skills depend on three MCP (Model Context Protocol) servers that connect Cursor to Jira, Confluence, and email. You configure them in a single file.

### Where is the config file?

| Platform | Path |
|---|---|
| **Mac / Linux** | `~/.cursor/mcp.json` |
| **Windows** | `C:\Users\YOUR_USERNAME\.cursor\mcp.json` |

### Create or edit the file

**Mac / Linux:**

```bash
touch ~/.cursor/mcp.json
open ~/.cursor/mcp.json
```

**Windows (PowerShell):**

```powershell
if (!(Test-Path "$env:USERPROFILE\.cursor\mcp.json")) { New-Item "$env:USERPROFILE\.cursor\mcp.json" -ItemType File }
notepad "$env:USERPROFILE\.cursor\mcp.json"
```

### Paste this template

Replace all `YOUR_*` placeholder values with your own credentials:

```json
{
  "mcpServers": {
    "jira_oss": {
      "url": "https://llm-proxy-api.ai.openeng.netapp.com/mcp/jira_oss",
      "type": "http",
      "headers": {
        "x-litellm-api-key": "Bearer user=YOUR_USERNAME&key=YOUR_LITELLM_KEY",
        "x-mcp-jira_oss-authorization": "Token YOUR_JIRA_BASE64_TOKEN"
      }
    },
    "Atlassian-MCP-Server": {
      "url": "https://mcp.atlassian.com/v1/mcp"
    },
    "smtp": {
      "type": "http",
      "url": "http://scs000816612.rtp.openenglab.netapp.com:9084/mcp",
      "headers": {
        "X-SMTP-From": "YOUR_NAME@netapp.com"
      }
    }
  }
}
```

### How to get your credentials

#### Jira OSS (LLM Proxy)

| Placeholder | How to get it |
|---|---|
| `YOUR_USERNAME` | Your NetApp username (e.g. `jsmith`) |
| `YOUR_LITELLM_KEY` | Request from the AI/OpenEng team - this is your LiteLLM proxy API key |
| `YOUR_JIRA_BASE64_TOKEN` | Base64-encoded Jira PAT (see below) |

**To create your Jira Base64 token:**

*Mac / Linux:*
```bash
echo -n "YOUR_JIRA_PAT" | base64
```

*Windows (PowerShell):*
```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("YOUR_JIRA_PAT"))
```

Replace `YOUR_JIRA_PAT` with your actual Jira Personal Access Token (generate one at your Jira profile settings).

#### Atlassian MCP Server (Confluence)

- No credentials needed in `mcp.json` - the Atlassian MCP server uses **OAuth browser login**.
- On first use, Cursor will prompt you to authenticate in your browser. Click through the Atlassian OAuth flow.
- Your session is cached - you only authenticate once per session.

#### SMTP

| Placeholder | How to get it |
|---|---|
| `YOUR_NAME@netapp.com` | Your NetApp email address |

The SMTP relay server must be reachable from your network (on-prem or VPN).

---

## Step 4: Personalize the Skills (Important!)

Several values in the skills are specific to the original author. **You must update these for your own Confluence space.**

### 4a. Update your personal Confluence "Drafts" page

The feature-readiness-plan and feature-readiness-hub skills publish draft pages under your personal Confluence Drafts space.

1. Go to your Confluence personal space: `https://netapp.atlassian.net/wiki/spaces/~YOUR_USERNAME/overview`
2. Navigate to or create a **Drafts** page
3. Copy the **page ID** from the URL (the number in the URL, e.g. `592781410`)
4. Update these values in the skill files:

**In `feature-readiness-plan/SKILL.md`** and **`feature-readiness-hub/SKILL.md`**, find and replace:

| Find | Replace with |
|---|---|
| `592781410` (the Drafts parentId) | Your own Drafts page ID |
| `429359104` (the spaceId for `~kguleria`) | Your own personal space ID |
| `~kguleria` | `~YOUR_USERNAME` |

### 4b. Update email address for Weekly Report

In `Weekly-Ring/SKILL.md`, find `kiran.guleria@netapp.com` and replace with your email address, or the team distribution list you want reports sent to.

### How to find your Confluence Space ID

1. Open Cursor and start an Agent chat
2. Ask: "Use the Atlassian MCP to call `getConfluencePage` on page ID `<your Drafts page ID>`"
3. The response will include `spaceId` - use that value

---

## Step 5: Restart Cursor

After saving `mcp.json` and the skill files:

1. **Close Cursor completely** (Cmd+Q on Mac, Alt+F4 on Windows)
2. **Reopen Cursor**
3. The MCP servers will connect automatically on launch

---

## Step 6: Verify the Setup

Open Cursor Agent chat (**Cmd+L** on Mac, **Ctrl+L** on Windows) and test each connection:

### Test Jira connectivity

```
Fetch Jira issue NFSAAS-144193 and show me its summary and status
```

You should see the issue details. If you get an auth error, double-check your Jira token in `mcp.json`.

### Test Confluence connectivity

```
Fetch Confluence page 138160611 and show me its title
```

If prompted to authenticate, complete the Atlassian OAuth flow in your browser.

### Test SMTP (optional)

```
Send a test email to YOUR_NAME@netapp.com with subject "Test" and body "MCP SMTP working"
```

---

## Step 7: Run the Weekly Report

In Cursor Agent chat, type:

```
/anfplrweeklyreport
```

Or say:

```
Generate the ANF feature readiness weekly report
```

Cursor will fetch all 28 feature pages, enrich with JIRA data, create the Confluence page, and send the email.

---

## Updating to the Latest Version

To get the latest skills and rules from GitHub:

**Mac / Linux:**

```bash
curl -sL https://raw.githubusercontent.com/Guleriak/anf-feature-readiness-skills/main/install-skills.sh | bash
```

**Windows (PowerShell):**

```powershell
cd "$env:USERPROFILE\.cursor\skills"
git pull origin main
```

Or re-download the ZIP from GitHub and overwrite the folders.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| "MCP server not found" | Restart Cursor after editing `mcp.json` |
| Jira auth fails | Regenerate your Jira PAT and re-encode to Base64 |
| Confluence auth prompt keeps appearing | Clear browser cookies for `atlassian.com` and re-authenticate |
| SMTP connection refused | Ensure you are on the NetApp VPN or on-prem network |
| Skills not recognized by Cursor | Verify files are at the correct path (see Step 2) and restart Cursor |
| "Drafts page not found" on publish | Update the `parentId` and `spaceId` in SKILL.md to your own values (Step 4a) |
| `.cursor` folder not visible (Windows) | In File Explorer: View > Show > Hidden items |
| `git` not found (Windows) | Install Git from [git-scm.com](https://git-scm.com/downloads) |
| PowerShell script execution blocked | Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` in PowerShell |

---

## File Reference

| File | Purpose |
|---|---|
| `~/.cursor/mcp.json` | MCP server connections (Jira, Confluence, SMTP) |
| `skills/Weekly-Ring/SKILL.md` | Weekly PLR report automation |
| `skills/feature-readiness-plan/SKILL.md` | Feature plan automation |
| `skills/feature-readiness-plan/ownership-rules.md` | Rules for assigning owners to milestone rows |
| `skills/feature-readiness-plan/templates/*.md` | Stage templates |
| `skills/feature-readiness-hub/SKILL.md` | Initiative hub page automation |
| `skills/feature-readiness-hub/reference-hub-template.md` | Offline snapshot of the hub template |
| `rules/weekly-ring-report.mdc` | Formatting consistency rules (copy to `~/.cursor/rules/`) |
