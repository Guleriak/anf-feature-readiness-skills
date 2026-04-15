---
name: Weekly-Ring
description: >-
  Generates the ANF Feature Readiness weekly meeting report. Fetches feature data
  from the PLR Dashboard Confluence page, enriches with Initiative-level JIRA IDs,
  JIRA Status, owners from JIRA custom fields, and Supportability Status. Creates
  a Confluence meeting notes page and sends an HTML email with the full table
  embedded. Use when the user types /anfplrweeklyreport or asks to generate the
  weekly feature readiness report, PLR report, or meeting notes.
---

# ANF PLR Weekly Report

## Workflow

When triggered, execute these steps in order:

### Step 1: Fetch Feature Data from PLR Dashboard

The PLR Dashboard (Page ID `584352624`) uses dynamic Page Properties Report macros that render empty in API. Fetch source pages directly by their known Page IDs (see **Feature Readiness Plan Page IDs** table below):

- **Primary method**: Fetch each page by Page ID using `getConfluencePage` (markdown format)
- **Fallback**: CQL query `label = "anf-feature-readiness-plan" AND space = "CLOUDVOL"` (may return empty if labels are missing)

#### CRITICAL: Page Properties Table is HORIZONTAL

The Confluence Page Properties macro renders as a **horizontal table** — headers in row 1, values in row 2:

```
| Status | Public facing Name | Release Version | Tier | Launch Date | Docs | Status Summary | JIRA |
|--------|-------------------|-----------------|------|-------------|------|----------------|------|
| <value> | <value>          | <value>         | <value> | <value>  | <value> | <value>     | <value> |
```

**DO NOT** treat it as a vertical key-value table (key in col 0, value in col 1) — that returns wrong data (e.g., "Status" → "Public facing Name").

Extract from each page's properties table:
- **Feature Name** → "Public facing Name" column (prefer JIRA `customfield_29903` as primary source)
- **Status** → "Status" column (contains Atlassian status macro, e.g., "GA - on track")
- **Tier** → Prefer JIRA `customfield_29902`, fallback to "Tier" column
- **Launch Date** → Prefer JIRA `customfield_25618`, fallback to "Launch Date" column
- **Release Version** → Prefer JIRA `customfield_20602`, fallback to "Release Version" column
- **Status Summary** → "Status Summary" column (detailed progress text)
- **Supportability Status** — CSS/supportability progress text (may be in a separate section)

#### Hard Stop Rule (Do Not Continue Past Step 1)

After Step 1 data collection, evaluate each initiative. If **any** of the following is true, **stop** and do not execute Step 2 or beyond for that initiative:

- **Customer Announcement Date** is missing
- **Initial Target Date** is missing
- **Revised Target Date** is missing
- Initiative **Stage/Status is `Scoped`**

When this rule is triggered:
- Return/record the initiative as **Step-1 only (insufficient planning data)**.
- Do not attempt JIRA enrichment, owner expansion, report table build, Confluence notes creation, or email generation for that initiative.
- Include a brief reason listing which required field(s) are missing or that the initiative is in `Scoped`.

### Step 2: Extract JIRA IDs from PLR Dashboard

**IMPORTANT**: Use the **JIRA Key Mapping** table below as the primary source for JIRA IDs. Do NOT search JIRA by summary — feature names in Confluence often differ from JIRA summaries.

The JIRA column on PLR pages uses Jira Legacy macros that do NOT render in markdown format. The mapping table was extracted from the ADF (raw) format of each page.

For each feature:
1. Look up the **primary JIRA key** from the JIRA Key Mapping table (first key listed = current/active stage)
2. If a feature is not in the mapping, fetch the page in **ADF format** and search for `jqlQuery` fields containing issue keys
3. As a last resort, scan the page body for `NFSAAS-\d+` patterns
4. Make JIRA IDs clickable: `https://jira.ngage.netapp.com/browse/<KEY>`

### Step 3: Fetch JIRA Status for Each Issue

For each JIRA ID extracted in Step 2:
- Use jira_oss `jira_get_issue` tool with the issue key
- Extract the `status` field (e.g., Done, In Progress, At Risk, Blocked)
- Add as **JIRA Status** column

### Step 4: Fetch Owners from JIRA Custom Fields

For each JIRA issue, fetch these multi-user picker custom fields:
- **PM Feature Owner** — search JIRA fields for "PM Feature Owner" to find the custom field ID
- **TME Feature Owner** — search JIRA fields for "TME Feature Owner"
- **TPM Feature Owner** — search JIRA fields for "TPM Feature Owner"

For each field:
- Extract the username/account ID
- Resolve to display name using `jira_get_user_profile`
- Combine into a single column with each role on its own line: `PM: <name><br>TME: <name><br>TPM: <name>`

### Step 5: Format Status Summary as Three Bullets

Parse the raw Status Summary text from PLR pages and present it as exactly **three structured bullets**:

1. **Feature Onboarding:** Onboarding percentage and key milestones (CSS signoff, deep dive, brownbag, supportability status)
2. **CLC:** CLC/CS360 checklist progress percentages for the current stage, SDK/CLI status, Terraform status
3. **Feature Updates:** Everything else — risks, blockers, CCOA impact, dependencies, portal changes, dev status, launch dates, customer info

Extraction rules:
- Look for `Feature Onboarding XX%` or `Onboarding XX%` patterns for bullet 1. Include CSS signoff, deep dive, brownbag here. If absent, show "N/A".
- Look for `CLC.*XX%` patterns for bullet 2. Include SDK, CLI, Terraform status here. If absent, show "N/A".
- Everything remaining goes into bullet 3. If nothing remains, show "On track."
- Strip Confluence artifacts (UUIDs, checklist markers, excess whitespace) before rendering.

Rendering:
- **Confluence markdown**: `**Feature Onboarding:** ... <br/> **CLC:** ... <br/> **Feature Updates:** ...` inside table cells
- **HTML email**: Use `<b>Feature Onboarding:</b> ... <br><b>CLC:</b> ... <br><b>Feature Updates:</b> ...` within `<td>`. Do NOT use `<ul>/<li>` (Outlook breaks list spacing).

### Step 6: Build the Table

- Sort all features by **Launch Target date ascending**
- **Remove stage suffixes** from Feature Name (e.g., "Azure NetApp Files advanced ransomware protection (GA)" → "Azure NetApp Files advanced ransomware protection"). The Stage column already shows this info.
- Columns (in this exact order):

| # | Column | Source (Priority Order) |
|---|--------|------------------------|
| 1 | Status | PLR Page Properties "Status" column (Atlassian status macro, e.g., "GA - on track"). Color-coded. |
| 2 | Stage | **Primary:** JIRA `customfield_22400`. **Fallback:** PLR Page Properties "Stage" column. |
| 3 | Feature Name | **Primary:** JIRA `customfield_29903` (Public facing name). **Fallback:** PLR Page Properties "Public facing Name" column. **Last resort:** Page title (cleaned). |
| 4 | JIRA ID | JIRA Key Mapping table (clickable link) |
| 5 | JIRA Status | JIRA API `status` field |
| 6 | Tier | **Primary:** JIRA `customfield_29902`. **Fallback:** PLR Page Properties "Tier" column. |
| 7 | Launch Target | **Primary:** JIRA `customfield_25618` (Customer announcement date). **Fallback:** PLR Page Properties "Launch Date" column. |
| 8 | Release Version | **Primary:** JIRA `customfield_20602` (Target Release Version). **Fallback:** PLR Page Properties "Release Version" column. |
| 9 | PM/TME/TPM Feature Owner | JIRA custom fields (`customfield_22311`, `customfield_29700`, `customfield_23615`) |
| 10 | Status Summary | PLR Page Properties "Status Summary" column + "Supportability Status" if available |
| 11 | Notes | Empty column for meeting notes |

- **Owners column** — display each role on a separate line, NOT slash-separated:
  - HTML: `PM: <name><br>TME: <name><br>TPM: <name>`
  - Confluence: `PM: <name> <br/> TME: <name> <br/> TPM: <name>`
- Color-code Status column:
  - 🟢 Green = On Track / In Progress / Done
  - 🟡 Yellow = At Risk
  - 🟠 Orange = Delay
  - 🔴 Red = Blocked

### Step 7: Create Confluence Page

- **Parent page**: Template ANF Dashboard (Page ID `581009417`)
- **Space**: CLOUDVOL (Cloud ID: `netapp.atlassian.net`)
- **Title**: `Notes for Feature Readiness meeting - MM/DD/YYYY`
- Page structure (top to bottom):
  1. Intro: "Thank you for joining the ANF Feature Readiness weekly sync. Below is the current feature status. The full dashboard is available at PLR Dashboard."
  2. Link to PLR Dashboard (`https://netapp.atlassian.net/wiki/spaces/CLOUDVOL/pages/584352624`)
  3. **Actions / Open Items** — table with headers (#, Action Item, Owner, Due Date, Status) and **3 empty numbered rows** (1, 2, 3). These are manually filled after the meeting. Do NOT write "No open items" — always include the 3 blank numbered rows.
  4. **Feature Status Summary counts** — bold summary lines (NOT a table):
     - `**Total Features: <N> | T1: <N> | T2: <N> | T3: <N>**`
     - `**Launched: <N> | On Track: <N> | At Risk: <N> | Delay: <N> | Blocked: <N>**`
     - Counts are derived from the feature data. Place this section between the Actions table and the feature table.
  5. **Feature Status table** — the full feature table with all 11 columns (same order as Step 6)
  6. Use `contentFormat: "markdown"` when calling `updateConfluencePage` or `createConfluencePage`. NEVER use `"storage"` or `"adf"`.

### Step 8: Send HTML Email

- **Default recipients**: `kiran.guleria@netapp.com` (ask user if more needed)
- **Subject**: `ANF Feature Readiness Weekly Report – MM/DD/YYYY`
- **HTML body** sections in this exact order (top to bottom):
  1. **Title**: `<h2>` with report name and date
  2. **Intro paragraph**: "Thank you for joining the ANF Feature Readiness weekly sync. Below is the current feature status. The full dashboard is available at PLR Dashboard."
  3. **Callout box**: Light blue background (`#e3f2fd`), left blue border (`4px solid #0052CC`), linking to Confluence meeting notes page
  4. **Actions / Open Items heading + table**: 3 empty numbered rows (1, 2, 3) — columns: #, Action Item, Owner, Due Date, Status
  5. **Feature Status Summary counts**: Bold lines — `Total Features: N | T1: N | T2: N | T3: N` and `Launched: N | On Track: N | At Risk: N | Delay: N | Blocked: N`
  6. **Feature Status heading + full feature table**: All 11 columns, same order as Step 6
  7. **Footer**: Links to PLR Dashboard and Confluence meeting notes page (use `<p>` tags, no `<ul>/<li>`)
- Use the SMTP MCP `smtp_send_email` tool with `is_html: true`
- **Reference template**: Use `~/anf-plr-weekly-report/email_body.html` as the structural reference — only update data values, never change the HTML structure

#### Email Formatting Rules (IMPORTANT — see also `.cursor/rules/weekly-ring-report.mdc`)

1. **All CSS must be inline** — do NOT use `<style>` blocks. Every HTML element must have its styles in the `style=""` attribute. This prevents formatting loss when recipients forward or reply.
2. **All table rows must have white background** — no alternating row colors. Every `<td>` must include `background-color:white;`.
3. **Font size 10px everywhere in tables**:
   - **Header row**: `background:#0052CC; color:#ffffff; font-size:10px; padding:6px 8px; border:1px solid #333;`
   - **Data cells**: `padding:4px 6px; border:1px solid #333; font-size:10px; vertical-align:top; background-color:white;`
   - **CRITICAL**: All `<td>` and `<th>` must have `border:1px solid #333;` (dark visible grid lines on ALL sides). Do NOT use `border-bottom` only or light colors like `#ddd`. The table must render as a proper grid with clearly visible black/dark borders.
4. **Status column** — color ALL statuses (case-insensitive keyword match, priority order):
   - 🔴 "blocked" → `color:#d32f2f; font-weight:bold;`
   - 🔴 "at risk", "risk" → `color:#d32f2f; font-weight:bold;`
   - 🟠 "delay", "delayed" → `color:#e67e00; font-weight:bold;`
   - 🟢 "on track", "in progress" → `color:#2e7d32; font-weight:bold;`
   - 🟢 "done", "complete", "launched", "announced" → `color:#2e7d32; font-weight:bold;`
   - ⚪ "not started", "scoped" → `color:#666; font-weight:bold;`
   - 🟡 "pending" → `color:#B38600; font-weight:bold;`
   - Handle typos: "Launced" → "Launched", "Privew" → "Preview"
   - Default fallback: `color:#333; font-weight:bold;`
5. **Launch Target date** — show **one clean date** only (M/DD/YYYY). If cell has multiple dates, pick the latest future date. Strip stage labels and descriptive text.
6. **JIRA links**: `color:#0052CC; text-decoration:none;`
7. **Table**: `border-collapse:collapse; width:100%;` with `cellpadding="0" cellspacing="0" border="0"` HTML attributes
8. **Body font**: `font-family:Calibri,Segoe UI,Arial,Helvetica,sans-serif; font-size:12px;`
9. **Column widths** (must use `<colgroup>` with `<col>` elements): Status 7%, Stage 5%, Feature Name 15%, JIRA 6%, JIRA Status 5%, Tier 3%, Launch Target 6%, Release Version 6%, Owners 17%, Status Summary 27%, Notes 3%.

#### Cross-Platform Rendering Rules (Mac + PC + Forward/Reply/Edit)

The email MUST look identical on Outlook for Windows, Outlook for Mac, Apple Mail, Gmail, and when forwarded/replied/edited. These rules prevent formatting breakage:

1. **Font-family on EVERY element** — set `font-family:Calibri,Segoe UI,Arial,Helvetica,sans-serif;` on `<body>`, every `<p>`, every `<td>`, every `<th>`, every `<h2>`, every `<a>`, every `<div>`. Do NOT rely on `<body>` inheritance (Outlook strips it on reply/forward).
2. **HTML table attributes** — every `<table>` must include `cellpadding="0" cellspacing="0" border="0" width="100%" role="presentation"` as HTML attributes alongside the CSS `style`. Outlook Windows uses Word's engine which ignores CSS-only table styling.
3. **`bgcolor` HTML attribute** — add `bgcolor="#ffffff"` on every `<td>`, `bgcolor="#0052CC"` on every `<th>`. Outlook reads `bgcolor` when it drops CSS `background-color` on forward.
4. **Explicit line-height** — every `<td>`, `<th>`, `<p>` must include `line-height:1.4;mso-line-height-rule:exactly;`. The `mso-` prefix controls Outlook-specific rendering.
5. **MSO namespace** — `<html>` tag must include `xmlns:o="urn:schemas-microsoft-com:office:office"` so Outlook recognizes `mso-*` properties.
6. **No `<ul>/<li>` in footer** — use `<p>` tags instead. Outlook adds unpredictable spacing to list elements.
7. **Emoji + text labels** — always include the text label after status emoji because emoji render differently (or as squares) across Outlook versions.

## Key IDs

| Item | Value |
|---|---|
| PLR Dashboard Page ID | `584352624` |
| Parent Page ID (Template ANF Dashboard) | `581009417` |
| Confluence Space | `CLOUDVOL` |
| Confluence Cloud ID | `netapp.atlassian.net` |
| CQL Label | `anf-feature-readiness-plan` |
| JIRA Project | `NFSAAS` |
| JIRA Issue Type Filter | `Initiative` |
| JIRA Browse URL | `https://jira.ngage.netapp.com/browse/` |
| JIRA PM Feature Owner Field | `customfield_22311` |
| JIRA TME Feature Owner Field | `customfield_29700` |
| JIRA TPM Feature Owner Field | `customfield_23615` |
| JIRA Stage Field | `customfield_22400` |
| JIRA Customer Announcement Date Field | `customfield_25618` |
| JIRA Tier Field | `customfield_29902` |
| JIRA Target Release Version Field | `customfield_20602` |
| JIRA Public Facing Name Field | `customfield_29903` |

## Feature Readiness Plan Page IDs and JIRA Key Mapping

The JIRA keys below were extracted from Jira Legacy macros in the ADF format of each PLR page. The **primary key** (first listed) is used in the report. Additional keys are for other feature stages.

> **Note**: Jira Legacy macros do NOT render in markdown format — the JIRA column appears blank or shows only stage text. These keys were extracted from ADF format and should be used as the authoritative source. When a new feature is added, fetch its page in ADF format and search for `jqlQuery` to find the embedded JIRA key.

| # | Feature | Page ID | Primary JIRA Key | Additional JIRA Keys |
|---|---------|---------|-----------------|---------------------|
| 1 | Cool Access QoS | 138165048 | NFSAAS-144193 | NFSAAS-72669 |
| 2 | Capacity Pools | 138166796 | NFSAAS-136160 | NFSAAS-155258 |
| 3 | FreeIPA/Red Hat LDAP | 138147826 | NFSAAS-104569 | |
| 4 | Quota reporting | 138164444 | NFSAAS-79157 | |
| 5 | Advanced ransomware | 138164368 | NFSAAS-105317 | |
| 6 | Entra ID hybrid | 138162772 | NFSAAS-123068 | |
| 7 | Enable Backup by Default | 138165068 | NFSAAS-92177 | |
| 8 | DNS updates | 138163252 | NFSAAS-153531 | |
| 9 | Entra ID only auth | 138151023 | NFSAAS-134065 | |
| 10 | Large files | 138169225 | NFSAAS-130277 | |
| 11 | FlexCache/Cache Volumes | 138163022 | NFSAAS-105259 | NFSAAS-105258 |
| 12 | Object REST API/S3 | 138162912 | NFSAAS-121364 | NFSAAS-75745, NFSAAS-104571 |
| 13 | Online Archive | 138161971 | NFSAAS-146169 | NFSAAS-92180 |
| 14 | Directory quotas | 138162579 | NFSAAS-47661 | |
| 15 | Migration Assistant | 138162992 | NFSAAS-92295 | NFSAAS-60964 |
| 16 | Top K clients | 138169275 | NFSAAS-131018 | NFSAAS-156180 |
| 17 | Change Pool FSL | 138168732 | NFSAAS-143712 | |
| 18 | Async Deletion | 138153804 | NFSAAS-122270 | NFSAAS-159039, NFSAAS-159040 |
| 19 | AVG custom apps | 138155887 | NFSAAS-61898 | NFSAAS-156925, NFSAAS-131023 |
| 20 | Immutable Backup Vault | 138169340 | NFSAAS-136602 | NFSAAS-149369, NFSAAS-89650 |
| 21 | Exit Survey | 138160605 | NFSAAS-134793 | |
| 22 | Regionally Redundant Backup | 138162901 | NFSAAS-60610 | |
| 23 | SMB OPLOCKS | 138163012 | NFSAAS-134506 | |
| 24 | Consistency Group Snapshots | 138162545 | NFSAAS-60559 | |
| 25 | ANF Origin Volumes | 138165494 | NFSAAS-47957 | |
| 26 | Hybrid Replication DR | 138163049 | NFSAAS-151267 | |
| 27 | Content Distribution / ANF distributed namespaces | 138159977 | NFSAAS-105262 | NFSAAS-131023 |
| 28 | ANF extension for AKS (Trident) | 138163671 | NFSAAS-77386 | Plan table has no Tier — tier from Jira `customfield_29902` |

## Locked-In Formatting Rules (DO NOT CHANGE)

The following formatting decisions are final and must be reproduced identically on every report run. See also `.cursor/rules/weekly-ring-report.mdc` for the full specification and `~/anf-plr-weekly-report/email_body.html` as the canonical HTML template.

1. **Visible dark borders** — `border:1px solid #333;` on ALL `<td>` and `<th>`. No `border-bottom` only. No light colors.
2. **White backgrounds** — all data rows `background-color:white; bgcolor="#ffffff"`. No alternating row colors.
3. **10px font** — all table data and headers `font-size:10px;`. Body text outside tables is 12px. Summary counts are 13px bold.
4. **Actions table** — always 3 empty numbered rows (1, 2, 3) with `&nbsp;` cells. Never "No open items".
5. **Feature Status Summary counts** — bold summary lines between Actions table and feature table.
6. **Three-bullet Status Summary** — every feature row has exactly 3 bold-labeled bullets: **Feature Onboarding**, **CLC**, **Feature Updates**.
7. **Owners on separate lines** — `PM: <name><br>TME: <name><br>TPM: <name>`. Not slash-separated.
8. **Column widths** — Status 7%, Stage 5%, Feature Name 15%, JIRA 6%, JIRA Status 5%, Tier 3%, Launch Target 6%, Release Version 6%, Owners 17%, Status Summary 27%, Notes 3%. Use `<colgroup>`.
9. **Header row** — `background:#0052CC; color:#ffffff; bgcolor="#0052CC"`.
10. **All CSS inline** — no `<style>` blocks.
11. **Section order** — Title → Intro → Callout box → Actions table → Summary Counts → Feature Table → Footer.
12. **Cross-platform** — font-family on every element, `bgcolor` attributes, `mso-line-height-rule:exactly`, MSO namespace on `<html>`.
13. **Status colors** — Blocked/At Risk `#d32f2f`, Delay `#e67e00`, On Track/Done `#2e7d32`, Not Started `#666`, Pending `#B38600`. All bold.
14. **JIRA links** — `color:#0052CC; text-decoration:none;`.

## Automation

A standalone Python script is available at `~/anf-plr-weekly-report/` with a macOS LaunchAgent scheduled for **every Tuesday at 8:00 AM**.

| Component | Path |
|---|---|
| Python agent | `~/anf-plr-weekly-report/anf_plr_report.py` |
| LaunchAgent plist | `~/Library/LaunchAgents/com.netapp.anf-plr-report.plist` |
| Credentials | `~/anf-plr-weekly-report/.env` |
| Execution log | `~/anf-plr-weekly-report/report.log` |

The Python script uses the same JIRA Key Mapping (hardcoded `PAGE_ID_TO_JIRA_KEY` dict) as this skill. When adding a new feature, update both the mapping table above and the dict in `anf_plr_report.py`.

### Manual run

```bash
~/anf-plr-weekly-report/venv/bin/python3 ~/anf-plr-weekly-report/anf_plr_report.py
```

### Reload schedule

```bash
launchctl unload ~/Library/LaunchAgents/com.netapp.anf-plr-report.plist
launchctl load ~/Library/LaunchAgents/com.netapp.anf-plr-report.plist
```

See `~/anf-plr-weekly-report/README.md` for full setup instructions.
