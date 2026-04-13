---
name: feature-readiness-hub
description: Builds a Jira-backed Initiative-level parent page in Confluence from the ANF [Template] Feature Readiness Plan hub, for use as the folder under which per-feature readiness plans live. Accepts a Jira Initiative key or numeric issue id. Invoked by feature-readiness-plan Step 4 when a feature has an Initiative Key. Publishes under personal Drafts by default; optional Confluence parent override when the user specifies a different parentId or URL. Use when creating a new initiative readiness area or when ensuring the hub exists before a feature plan publish.
---

# Feature Readiness Hub

Create an **Initiative-level** Confluence page (same structure as the ANF hub template) so **feature-readiness-plan** pages can be published **under** it.

## Required input

- **Initiative**: Jira issue **key** (e.g. `ANF-12345`) or **numeric issue id** (e.g. `123456`). Treat either as the parameter the user passes.

## Optional input

- **Confluence parent** (publish location): If the user gives a **`parentId`**, parent **URL**, or explicit instruction (e.g. "under Features - Project Plans"), use that as the publish parent.  
- If **not** specified, use the **default** below.

## Operating mode: local draft first (default)

- Do **not** publish to Confluence until the user explicitly confirms.
- **Root**: `~/feature-readiness-hubs/`
- **One directory per Initiative** (mirrors the hub “folder” in Confluence). **Hub markdown** is always **`index.md`** inside that directory.
- **Initiative directory name**: Sanitize the **Initiative summary** from Jira for a single path segment: replace or remove characters illegal in paths (`/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`, newlines); collapse whitespace; trim; you may truncate to a reasonable length (e.g. 120 chars). **Do not** put the Jira issue key in the directory name.
- **Full path to hub draft**: `~/feature-readiness-hubs/<Initiative directory>/index.md`
- **Feature readiness plans** for that initiative live in the **same directory** as sibling files (see **feature-readiness-plan**): `<Feature Name> Feature Readiness Plan.md` (no Jira key in filename).

Ensure the initiative directory and `~/feature-readiness-hubs/` exist before writing.

## Step 1: Load the Initiative from Jira

Using Atlassian MCP `getJiraIssue` (or equivalent) with the provided key or id, read at least:

| Purpose | Typical Jira fields |
| --- | --- |
| Title / link | Issue key, summary, web/browse URL |
| PLR table hints | Status, assignee; any initiative fields your org uses (e.g. program, release version, launch dates, PM/TPM) — map from real field names on the issue |

If the issue cannot be loaded, **stop** and report the error.

## Step 2: Load the hub template from Confluence

Canonical source (parent of the Private/Public/GA child templates):

- https://netapp.atlassian.net/wiki/spaces/ANF/pages/138160611/Template+Feature+Readiness+Plan  
- **Page ID**: `138160611`  
- Use `getConfluencePage` with `contentFormat: markdown` to pull the **current** body.

Optional offline shape check: [reference-hub-template.md](reference-hub-template.md).

## Step 3: Build the local draft

1. Create the initiative directory under `~/feature-readiness-hubs/` per **Operating mode** (sanitized Initiative summary). **Save the hub as `index.md`** inside that directory (not a top-level file under `~/feature-readiness-hubs/`).
2. **Copy** the template body from Step 2 (or refresh from Confluence). **Remove** the entire **How to Use this Template** section (including numbered steps and contact line), per template instructions.

3. **Confluence page title** (and leading `#` title in markdown if used):  
   `_<Initiative Summary>_ - initiative readiness plan`  
   Align with hub guidance: title like *`<name> - feature readiness plan`* — here the name is the **Initiative summary**.

4. **Top of page body**: Prominent link to the Initiative, e.g.  
   `[<INITIATIVE-KEY>](https://jira.ngage.netapp.com/browse/<INITIATIVE-KEY>)`  
   (Use the site your org uses if different; **feature-readiness-plan** standard is ngage for Jira links.)

5. **PLR dashboard table — JIRA column**  
   Replace instructional placeholder text with an **executable Jira Issue/Filter macro** (not a plain-text bullet). Same contract as **feature-readiness-plan**:
   - **JQL**: `key = <Initiative Key> OR issue in linkedIssues(<Initiative Key>) ORDER BY key`
   - **Macro URL pattern**: `https://jira.ngage.netapp.com/issues/?jql=<URL-encoded JQL>`
   - **Display**: Table  
   - **Maximum issues**: `20`  
   - **Columns**: `key,key,summary,type,created,updated,due,assignee,reporter,priority,status,resolution`

6. **Pre-fill** other PLR table cells from Jira where data exists; use `TODO` for anything unknown.

7. **Structure**: Do **not** add sections that are not on the hub template. Do **not** paste Private/Public/GA **stage** template bodies into this page — those are **separate** files in the **same initiative directory** (and Confluence children) created by **feature-readiness-plan** after publish.

8. **Label**: After publish, the page should carry label **`feature-tracking-ANF`** (add in Confluence UI if the API path used does not support labels).

## Step 4: Draft quality gates

Before treating the draft as final:

- Exactly **one** hub body and **one** main title.
- **No** "How to Use this Template" block.
- PLR dashboard table present; **JIRA** column uses the **ngage** Jira macro with the JQL and display settings above.
- No duplicate hub sections; no extra "ownership" tables beyond what the template already contains.

If any gate fails, fix the draft and re-check.

## Step 5: Review gate

User reviews the local file; apply edits; user **confirms** before publish.

## Step 6: Publish to Confluence (after confirmation only)

### Default publish location (use unless the user overrides)

| Setting | Value |
| --- | --- |
| **Parent page** | **Drafts** |
| **parentId** | Your Drafts page ID (see SETUP-GUIDE.md Step 4a) |
| **spaceId** | Your personal space ID (see SETUP-GUIDE.md Step 4a) |

Use `createConfluencePage` with:

- **`parentId`**: Your Drafts page ID (default) or the user-supplied parent page id.  
- **`spaceId`**: Always use the **`spaceId` of the chosen parent page** from `getConfluencePage` on that **`parentId`** so the create call matches Confluence's space.  
- **`contentFormat`**: **`markdown`** (or ADF if required for macros; prefer the format that preserves Jira macros in your environment).  
- Finalized **title** and **body**.

### Optional publish location (only when the user specifies)

If the user passes a different **`parentId`**, **page URL**, or named location (e.g. **Features - Project Plans**, page id **`138213259`** in space ANF **`138051584`**), resolve **`parentId`** and **`spaceId`** via **`getConfluencePage`** on that parent and publish there. State clearly in the response that a non-default parent was used.

After publish:

1. Add the new Confluence **URL** to the Jira Initiative (remote link or description/links), and optionally link the Initiative on the Confluence page if not already done.
2. Add label **`feature-tracking-ANF`** if not set by automation.
3. Tell the user the new page **`pageId`** and **`webUrl`**. They (or **feature-readiness-plan**) should use this **`pageId` as `parentId`** when publishing feature readiness plans for features under this Initiative (and resolve **`spaceId`** from that hub page when calling the API).

## Relationship to feature-readiness-plan

- **This skill** creates the **Feature Readiness Hub** parent page (one per Initiative), defaulting **under Drafts** until the user overrides the parent.
- **feature-readiness-plan** **calls this skill** via **Step 4** whenever the feature issue has an **Initiative Key**, to **ensure** the hub exists before publishing the feature plan **under** that hub (`hubPageId`).
- **feature-readiness-plan** creates **per-feature** stage plans; publish **under the hub's `pageId`** when **Initiative Key** is present (unless the user overrides), otherwise **under Drafts** per **feature-readiness-plan** Step 8.

See **feature-readiness-plan** Step 4 and Step 8 for the full gate and parent rules.