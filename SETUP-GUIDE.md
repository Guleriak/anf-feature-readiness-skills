# ANF Feature Readiness Skills — Team Setup Guide

This guide walks you through installing and configuring the Cursor AI skills that automate Feature Readiness Plans, Initiative Hubs, and the Weekly PLR Report.

---

## What You Get

| Skill | What It Does | Trigger |
|---|---|---|
| **feature-readiness-plan** | Creates a Feature Readiness Plan (Private Preview / Public Preview / GA) from a Jira issue, calculates milestone dates, populates owners, publishes to Confluence | Give Cursor a Jira issue key that has a Feature Stage |
| **feature-readiness-hub** | Creates an Initiative-level parent page in Confluence that groups all feature plans under one initiative | Automatically invoked by feature-readiness-plan when an Initiative Key exists, or run standalone |
| **Weekly-Ring** | Generates the weekly PLR meeting report — Confluence page + HTML email with the full feature table | Type `/anfplrweeklyreport` or ask Cursor to generate the weekly report |

---

## Prerequisites

- **macOS** or **Linux** desktop
- **Cursor IDE** (latest version) — download from [cursor.com](https://www.cursor.com)
- A **NetApp Jira** account with an API token
- An **Atlassian Cloud** account (for Confluence access)
- Access to the internal **SMTP relay** (for sending email reports)

---

## Step 1: Install Cursor IDE

1. Download Cursor from [https://www.cursor.com](https://www.cursor.com)
2. Install and launch it
3. Sign in with your Cursor account (or create one)
4. Open a terminal inside Cursor: **Ctrl+`** (backtick) or **Cmd+`** on macOS

---

## Step 2: Copy the Skills Folder

The skills live under `~/.cursor/skills/`. Create that directory and copy the three skill folders into it.

### Option A: Clone from the Git repository

```bash
git clone https://github.com/Guleriak/anf-feature-readiness-skills.git ~/.cursor/skills
```

### Option B: Copy from a shared zip/tar archive

If someone shared an archive with you:

```bash
mkdir -p ~/.cursor/skills
# extract the archive into ~/.cursor/skills/
tar xzf anf-feature-readiness-skills.tar.gz -C ~/.cursor/skills/
```

### Option C: Copy from a teammate's machine

```bash
mkdir -p ~/.cursor/skills

# Copy the three skill folders (adjust the source path)
cp -R /path/to/source/feature-readiness-plan ~/.cursor/skills/
cp -R /path/to/source/feature-readiness-hub  ~/.cursor/skills/
cp -R /path/to/source/Weekly-Ring             ~/.cursor/skills/
```

### Verify the folder structure

After copying, you should see this layout:

```
~/.cursor/skills/
├── feature-readiness-plan/
│   ├── SKILL.md                  # Main skill instructions
│   ├── ownership-rules.md        # Owner assignment rules
│   └── templates/
│       ├── private-preview.md    # Stage template (fetched live from Confluence)
│       ├── public-preview.md
│       └── ga.md
├── feature-readiness-hub/
│   ├── SKILL.md                  # Hub skill instructions
│   └── reference-hub-template.md # Offline reference of the hub template
└── Weekly-Ring/
    └── SKILL.md                  # Weekly report skill instructions
```

---

## Step 3: Configure MCP Servers

The skills depend on three MCP (Model Context Protocol) servers that connect Cursor to Jira, Confluence, and email. You configure them in `~/.cursor/mcp.json`.

### 3a. Create / edit `~/.cursor/mcp.json`

Create the file if it does not exist:

```bash
touch ~/.cursor/mcp.json
```

Paste the following template and **replace all placeholder values** with your own credentials:

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

### 3b. Get your credentials

#### Jira OSS (LLM Proxy)

| Placeholder | How to get it |
|---|---|
| `YOUR_USERNAME` | Your NetApp username (e.g. `jsmith`) |
| `YOUR_LITELLM_KEY` | Request from the AI/OpenEng team — this is your LiteLLM proxy API key |
| `YOUR_JIRA_BASE64_TOKEN` | Base64-encoded Jira PAT. Generate a Personal Access Token in Jira, then encode: `echo -n "YOUR_JIRA_PAT" \| base64` |

#### Atlassian MCP Server (Confluence)

- No credentials in `mcp.json` — the Atlassian MCP server uses **OAuth browser login**.
- On first use, Cursor will prompt you to authenticate in your browser. Click through the Atlassian OAuth flow and authorize the MCP server.
- Your session is cached — you only authenticate once per session.

#### SMTP

| Placeholder | How to get it |
|---|---|
| `YOUR_NAME@netapp.com` | Your NetApp email address |

The SMTP relay server (`scs000816612.rtp.openenglab.netapp.com:9084`) must be reachable from your network (on-prem or VPN).

---

## Step 4: Personalize the Skills (Important!)

Several values in the skills are specific to the original author. **You must update these for your own Confluence space.**

### 4a. Update your personal Confluence "Drafts" page

The skills publish draft pages under your personal Confluence Drafts space. You need your own Drafts page ID.

1. Go to your Confluence personal space: `https://netapp.atlassian.net/wiki/spaces/~YOUR_USERNAME/overview`
2. Navigate to or create a **Drafts** page
3. Copy the **page ID** from the URL (the number in the URL, e.g. `592781410`)
4. Update these locations in the skill files:

**In `~/.cursor/skills/feature-readiness-plan/SKILL.md`**, find and replace:

| Find | Replace with |
|---|---|
| `592781410` (the Drafts parentId) | Your own Drafts page ID |
| `429359104` (the spaceId for `~kguleria`) | Your own personal space ID |
| `~kguleria` | `~YOUR_USERNAME` |

**In `~/.cursor/skills/feature-readiness-hub/SKILL.md`**, find and replace:

| Find | Replace with |
|---|---|
| `592781410` (the Drafts parentId) | Your own Drafts page ID |
| `429359104` (the spaceId) | Your own personal space ID |
| `~kguleria` | `~YOUR_USERNAME` |

### 4b. Update email address for Weekly Report

In `~/.cursor/skills/Weekly-Ring/SKILL.md`, find `kiran.guleria@netapp.com` and replace with your email, or the team distribution list you want reports sent to.

### How to find your Confluence Space ID

1. Open Cursor and start a chat
2. Ask Cursor: "Use the Atlassian MCP to call `getConfluencePage` on page ID `<your Drafts page ID>`"
3. The response will include `spaceId` — use that value

---

## Step 5: Restart Cursor

After saving `mcp.json` and the skill files:

1. Close Cursor completely
2. Reopen Cursor
3. The MCP servers will connect automatically on launch

---

## Step 6: Verify the Setup

### Test Jira connectivity

Open Cursor Agent chat (**Cmd+L** or **Ctrl+L**) and type:

```
Fetch Jira issue NFSAAS-144193 and show me its summary and status
```

You should see the issue details returned. If you get an auth error, double-check your Jira token in `mcp.json`.

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

## How to Use the Skills

### Create a Feature Readiness Plan

In Cursor Agent chat, say:

```
Create a feature readiness plan for NFSAAS-XXXXX
```

Replace `NFSAAS-XXXXX` with the actual Jira issue key. Cursor will:

1. Read the Jira issue fields (stage, dates, owners, initiative)
2. Select the correct template (Private Preview / Public Preview / GA)
3. Calculate milestone dates from the Customer Announcement Date
4. Create a local draft at `~/feature-readiness-hubs/<initiative>/` or `~/feature-readiness-drafts/`
5. Ask you to review before publishing to Confluence

### Create a Feature Readiness Hub (standalone)

```
Create a feature readiness hub for initiative NFSAAS-XXXXX
```

This creates the Initiative-level parent page that feature plans are published under.

### Generate the Weekly PLR Report

```
/anfplrweeklyreport
```

Or say:

```
Generate the ANF feature readiness weekly report
```

This fetches all feature data, creates a Confluence meeting notes page, and sends an HTML email.

---

## Creating the Shareable Archive

To package everything for a teammate, run:

```bash
cd ~/.cursor/skills
tar czf ~/Desktop/anf-feature-readiness-skills.tar.gz \
  feature-readiness-plan/ \
  feature-readiness-hub/ \
  Weekly-Ring/ \
  SETUP-GUIDE.md
```

Share `anf-feature-readiness-skills.tar.gz` with your team. They follow this guide starting from Step 1.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| "MCP server not found" | Restart Cursor after editing `mcp.json` |
| Jira auth fails | Regenerate your Jira PAT and re-encode to Base64 |
| Confluence auth prompt keeps appearing | Clear browser cookies for `atlassian.com` and re-authenticate |
| SMTP connection refused | Ensure you are on the NetApp VPN or on-prem network |
| Skills not recognized by Cursor | Verify files are at `~/.cursor/skills/<skill-name>/SKILL.md` (exact path) |
| "Drafts page not found" on publish | Update the `parentId` and `spaceId` in SKILL.md to your own values (Step 4a) |
| Dates calculated wrong | Check that the Jira issue has a `Customer Announcement Date` field populated |

---

## File Reference

| File | Purpose |
|---|---|
| `~/.cursor/mcp.json` | MCP server connections (Jira, Confluence, SMTP) |
| `~/.cursor/skills/feature-readiness-plan/SKILL.md` | Feature plan automation instructions |
| `~/.cursor/skills/feature-readiness-plan/ownership-rules.md` | Rules for assigning owners to milestone rows |
| `~/.cursor/skills/feature-readiness-plan/templates/*.md` | Stage templates (fetched live from Confluence) |
| `~/.cursor/skills/feature-readiness-hub/SKILL.md` | Initiative hub page automation |
| `~/.cursor/skills/feature-readiness-hub/reference-hub-template.md` | Offline snapshot of the hub template |
| `~/.cursor/skills/Weekly-Ring/SKILL.md` | Weekly PLR report automation |
| `~/feature-readiness-hubs/` | Local drafts organized by initiative |
| `~/feature-readiness-drafts/` | Local drafts for features without an initiative |