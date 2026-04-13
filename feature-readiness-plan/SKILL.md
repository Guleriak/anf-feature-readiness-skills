---
name: feature-readiness-plan
description: Automates Feature Readiness Plan creation when a Jira issue is assigned or updated with a Feature Stage (Private Preview, Public Preview, or GA). Reads Jira fields, selects the correct Confluence template, creates the readiness page, populates ownership, calculates due dates from the launch date, and links Jira to Confluence. When an Initiative Key exists, stores drafts under ~/feature-readiness-hubs/<initiative-dir>/ alongside hub index.md and runs feature-readiness-hub before publish; without an Initiative Key, uses ~/feature-readiness-drafts/. Use when a feature readiness plan needs to be created or updated, or when a Jira issue has a Feature Stage field set.
---

# Feature Readiness Plan

When a Jira issue is assigned or updated with a Feature Stage, execute the following steps in order.

## Operating Mode: Local Draft First (Default)

Always create the Feature Readiness Plan page **locally first** for offline review.

- Do not publish to Confluence by default.
- Create the local template draft file that can be reviewed/edited offline.
- Publish to Confluence only after explicit user confirmation.

### Local Draft Location and Naming

**When `Initiative Key` is present** (after resolving it in Step 1):

- **Initiative directory**: Under `~/feature-readiness-hubs/`, use **one directory per Initiative** with the **same naming rules** as **feature-readiness-hub** (sanitized Initiative summary from Jira; no issue key in the folder name). If needed, load the Initiative issue by key to read its **summary** for the folder name.
- **Hub** for that initiative (from **feature-readiness-hub**): `~/feature-readiness-hubs/<Initiative directory>/index.md`
- **This feature's plan**: `~/feature-readiness-hubs/<Initiative directory>/<Feature Name> Feature Readiness Plan.md`
- Do **not** include the feature or initiative **Jira key** in the filename.

**When `Initiative Key` is missing:**

- Save under: `~/feature-readiness-drafts/`
- Filename: `<Feature Name> Feature Readiness Plan.md` (no Jira key in the filename).

## Step 1: Read Jira Fields

Retrieve these fields from the Jira issue:

| Field | Jira Field Name |
|---|---|
| Feature Name | Summary / Feature Name |
| Jira Key | Issue Key (e.g. PROJ-123) |
| Initiative Key | Parent Initiative key (for example via Parent Link / Epic Link hierarchy) |
| Stage | Feature Stage (Private Preview / Public Preview / GA) |
| Target Launch Date | Target Launch Date |
| Program / Semester | Program / Semester |
| Feature TPM | Feature TPM |
| Target Release Version | Target Release Version |
| Engineering Owner | Engineering Owner |
| Product Manager | Product Manager |
| Customer Announcement Date | Customer Announcement Date |
| Design Owner | Design Owner (optional — leave blank if missing) |

### Stop Rule After Step 1

Do **not** continue beyond Step 1 if all of the following are true:

- Customer Announcement Date is missing
- Initial Target Date is missing
- Revised Target Date is missing



If any condition above is met:
- Stop the workflow at Step 1
- Do not execute Step 2 onward
- Report which field(s) are missing or that the initiative is `Scoped`

## Step 2: Select the Correct Template

All templates are located at:
**https://netapp.atlassian.net/wiki/spaces/ANF/pages/138160611/Template+Feature+Readiness+Plan**

| Feature Stage | Template to Use |
|---|---|
| Private Preview | Private Preview Feature Readiness Plan template |
| Public Preview | Public Preview Feature Readiness Plan template |
| GA | GA Feature Readiness Plan template |

## Step 3: Create a Local Draft Page (Do Not Publish Yet)

Create a local markdown draft file using the path from **Local Draft Location and Naming** (either `~/feature-readiness-hubs/<Initiative directory>/<Feature Name> Feature Readiness Plan.md` or `~/feature-readiness-drafts/...`), copying the applicable template from step 2.

Ensure the **initiative directory** exists when using the hub layout (the **feature-readiness-hub** step may create it together with `index.md`).

Use following instruction to edit the file
- Title the new page: "< $Stage$ Preview for <feature name> - feature readiness plan
- In the `Feature Details` section, include Jira macro/query blocks for both:
  - Add a **live Jira Issue/Filter macro** for the Feature query using: `key = <Jira Key>`
  - Add a second **live Jira Issue/Filter macro** for the Initiative query using a multi-row pattern:
    - `key = <Initiative Key> OR issue in linkedIssues(<Initiative Key>) ORDER BY key`
  - Always configure macros using the ngage URL pattern: `https://jira.ngage.netapp.com/issues/?jql=<encoded JQL>`
  - Always set display options to:
    - Display as: `Table`
    - Maximum issues: `20`
    - Columns: `key,key,summary,type,created,updated,due,assignee,reporter,priority,status,resolution`
  - These must be executable Jira macros (rendering issue table/count on page load), **not plain text bullets**.
  - If `Initiative Key` is unavailable, keep a visible placeholder: `TODO: Initiative Jira macro`
- Use the ownership rules (see [ownership-rules.md](ownership-rules.md)) to replace owners and reviewers in-place in "Milestone Tracking Checklist for Private Preview" table but do not add a separate table for the ownership.
- Use the **Customer Announcement Date** (JIRA field `customfield_25618`) as **T0**. Read the offset for each milestone from the selected Confluence template (e.g. T-16w, T-8w, T-3d) and compute the exact calendar date.
- Remove "How to Use this Template" section
- Keep any unresolved fields clearly marked as `TODO`.
- Follow the template strictly. No new sections are to be added.


### Rules

1. **Always output exact calendar dates** (e.g. `4/2/2026`). Never leave relative offsets like "T-8w" in the Due Date column.
2. **Weekend adjustment**: If a computed date falls on a Saturday or Sunday, move it to the preceding Friday.
3. **Strikethrough on recalculation**: When the launch date changes and dates must be recalculated, **do NOT delete the old date**. Strike it out and add the new date next to it. Example: `~~3/19/2026~~ 4/2/2026`.

### How to Calculate

For each milestone row in the template that has an offset like `T-Nw` or `T-Nd`:
- Convert weeks to days (1w = 7d).
- Subtract that number of days from the Customer Announcement Date.
- Write the resulting exact date in `M/D/YYYY` format.

**Example** — Customer Announcement Date = 10/21/2026:
- T-16w → 10/21 − 112 days = **7/1/2026**
- T-8w → 10/21 − 56 days = **8/26/2026**
- T-3d → 10/21 − 3 days = **10/18/2026** (Sat → moved to **10/16/2026** Fri)

- Populate all calculated exact dates directly in the readiness table on the Confluence page.
- If the Target Launch Date changes, **strikethrough the old dates and add new recalculated dates** next to them. Never delete old dates.

## Step 4: Ensure Feature Readiness Hub exists (blocking before publish)

When **`Initiative Key`** from Step 1 is **present**, the published feature readiness plan must live **under** that initiative's **Feature Readiness Hub** in Confluence. Follow **`feature-readiness-hub`** in full.

If the user stops after a **local draft only** (no publish), Step 4 may be **deferred** until they confirm publish; once they proceed to **Step 8**, Step 4 must be complete.

Do **not** go to **Step 8** until a valid hub **`pageId`** is established (unless the user gave a **Step 4 override**):

1. **Existing hub** — If the user supplies a Confluence **`pageId`** or **URL** for this initiative's hub, call `getConfluencePage` on that page to confirm it exists; record **`hubPageId`** and the hub's **`spaceId`** (from the same response).
2. **Discover hub** — If not supplied, search Confluence (e.g. CQL by title matching the initiative summary or other team conventions) or ask the user for the hub **`pageId`**/URL when search is inconclusive.
3. **Create hub** — If no hub exists, execute **feature-readiness-hub** for the **`Initiative Key`**: local hub at `~/feature-readiness-hubs/<Initiative directory>/index.md`, user review, user confirms publish (default parent: personal **Drafts** per that skill), then capture the new **`hubPageId`** and **`spaceId`** from the create response or `getConfluencePage`.

**When `Initiative Key` is missing:** Skip Step 4 entirely; **Step 8** uses **Personal Drafts** as the publish parent.

**Override:** If the user explicitly requests publishing the feature plan **directly under Drafts** or under another **`parentId`** (not under the Feature Readiness Hub), honor that and note the exception; Step 4 may be skipped for hub creation **only** for that publish, but do not assume an override unless the user stated it.

## Step 7: Review Gate (Required Before Publish)

Before publishing:
- If **Initiative Key** is present, **Step 4** must already be satisfied (**`hubPageId`** known and hub exists in Confluence, or a documented user override to publish elsewhere). If Step 4 is not done, run **feature-readiness-hub** (or validate user-supplied hub) now before continuing.
- User reviews local draft offline
- User confirms readiness to publish
- Agent applies any requested edits to the local draft

Only after explicit confirmation, continue to Step 8.

## Draft Quality Gates (Required Before Returning Draft to User)

Run these checks on the local markdown draft after generation and before handing the draft to the user.

### 1) Single-Template Integrity

- Ensure there is exactly one top-level draft body.
- Ensure there is exactly one stage criteria header (for example, `## Private Preview Feature Readiness Release Criteria`).
- Ensure the draft title appears only once.

### 2) Forbidden/Unexpected Sections

- Do **not** add ad-hoc sections that are not part of the selected template.
- Explicitly reject sections such as:
  - `## Test Run Parameters`
  - `## Ownership (from ownership-rules)` (ownership must be edited in-place in the milestone table, not added as a new section)
  - Any duplicate `## Feature Details` block outside the template structure

### 3) Template Structure Consistency

- Keep the selected Confluence template structure intact.
- Remove `How to Use this Template`.
- Do not append additional generated summaries after the template body.

### 4) Date/Owner Completion Checks

- Verify every milestone row due date uses exact calendar date or allowed values from template (for example `Post`, `N/A`).
- Verify weekend adjustment is applied.
- Verify owner substitutions are in-place per `ownership-rules.md`.
- Verify the `Feature Details` section includes two executable Jira Issue/Filter macros:
  - one for `key = <Jira Key>`
  - one for `key = <Initiative Key> OR issue in linkedIssues(<Initiative Key>) ORDER BY key` (or explicit `TODO: Initiative Jira macro` placeholder when unavailable).
- Verify each Jira macro is configured with:
  - ngage URL pattern (`jira.ngage.netapp.com/issues/?jql=...`)
  - Display as `Table`
  - `Maximum issues = 20`
  - Columns `key,key,summary,type,created,updated,due,assignee,reporter,priority,status,resolution`

### 5) Fail-Fast Behavior

If any quality gate fails:
- Do not present the draft as final.
- Fix the draft first, then re-run the quality gates.
- Only then return the draft path to the user.

### 6) Feature Readiness Hub before publish (when Initiative Key is present)

- Do not call **Step 8** until **Step 4** has produced a valid **`hubPageId`** (or the user gave an explicit **override** parent for this feature plan).
- If Step 4 was skipped incorrectly while **Initiative Key** is set, stop and complete **feature-readiness-hub** first.

## Step 8: Publish to Confluence and Link Jira

**Prerequisite:** If **Initiative Key** is present and there is **no** user override, **`hubPageId`** and hub **`spaceId`** from **Step 4** are **required** for `createConfluencePage`.

When publishing to Confluence, create the page as a child under one of the following:

**A) Feature Readiness Hub (default when Initiative Key is present)**  
- Use **`hubPageId`** from **Step 4** as **`parentId`**.  
- Set **`spaceId`** from `getConfluencePage` on that hub (do not assume ANF vs personal space).  
- This path is mandatory unless the user explicitly overrides (see **C**).

**B) Personal Drafts (default when Initiative Key is missing)**  
- Parent page: `Drafts`  
- Parent URL: `https://netapp.atlassian.net/wiki/spaces/~<YOUR_USERNAME>/pages/<YOUR_DRAFTS_PAGE_ID>/Drafts`  
- Set `parentId` to your Drafts page ID (see SETUP-GUIDE.md Step 4a).  
- Set `spaceId` to your personal space ID (see SETUP-GUIDE.md Step 4a).

**C) User-specified parent (override only)**  
- If the user explicitly requests a different **`parentId`** or **URL** (e.g. publish this feature plan directly under **Drafts**, or under **Features - Project Plans**), publish **there** instead of **A** or **B**.  
- Call `getConfluencePage` on that parent and use its **`spaceId`** and **`parentId`** in `createConfluencePage`.

Do not publish as a top-level page in the space unless the user explicitly requests it.

1. Add the Jira issue link (e.g. `PROJ-123`) at the top of the Confluence page.
2. Add the Confluence page URL back to the Jira issue (as a remote link or in the description/links section).

If user does not confirm publish, stop after local draft creation.

---

## Additional Resources

- For ownership assignment rules, see [ownership-rules.md](ownership-rules.md)
- For ensuring the Feature Readiness Hub parent page exists (**Step 4**), follow **feature-readiness-hub** (`feature-readiness-hub/SKILL.md`)