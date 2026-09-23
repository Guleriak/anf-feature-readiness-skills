---
name: anf-plr-readiness-tracking-page
description: Creates the per-feature readiness tracking Confluence page under PLR Dashboard - Product Lifecycle Readiness in the ANF space, wiring two ngage Jira Data Center macros into it - the Feature Readiness column showing Status Summary from the parent Initiative only, and the JIRA column showing the Initiative as a table of Summary, Customer Announcement Date, Target Release Version, TPM/PM/TME Feature Owner, Tier, Customer Facing Name, and Stage. One page per feature covers all three stages (Private Preview, Public Preview, GA), titled with the Jira Summary only and no stage suffix. Runs automatically at the end of the jira-automation-anf-feature-clc skill so the Jira readiness Epic and its Confluence tracking page are created together. Use when the user asks to create the PLR readiness tracking page, the feature readiness tracking Confluence page, add a feature to the PLR Dashboard, or types /plrtracking.
---

# ANF PLR Readiness Tracking Page

Creates one Confluence tracking page per ANF feature under the PLR Dashboard, driven entirely by Jira data.

## Purpose

The PLR Dashboard aggregates every feature's readiness into a single Page Properties Report. Each feature needs its own page holding a Page Properties table so the dashboard row appears. This skill creates that page and points its two Jira macros at the right issues.

One page per feature, not per stage. A feature moves through Private Preview, Public Preview, and GA, each stage typically carrying its own Initiative and its own readiness Epic in Jira. All three belong on the same page: the stage table records the Initiative for each stage, and the two Jira macros grow to cover every stage tracked so far. The page title therefore carries no stage.

The dashboard's Page Properties Report selects pages by the CQL `label = "plr-anf-tracking"`, not by parent page. A page without that label never appears on the dashboard no matter where it sits. See "Label and placement".

## Trigger

Run this workflow when either condition is true:

1. **As Phase 2 of `jira-automation-anf-feature-clc`.** That skill is the orchestrator and enters this phase automatically, in the same session, once its Jira work is verified. When running as Phase 2, do not emit a standalone report; hand the results back so the orchestrator can fold them into its single combined report.
2. **Standalone**, when the user asks directly for a PLR readiness tracking page for a feature, or types `/plrtracking`. In that case emit the report described at the end of this file.

Run this workflow once per Initiative and Feature Stage, but write into **one page per feature**. When a page already exists for the feature, update it for the new stage instead of creating a second page. Check for an existing page before creating anything (see "Duplicate check").

## Inputs

- Initiative key: `<INITIATIVE_KEY>`, the ANF Initiative, e.g. `NFSAAS-146542`
- Readiness Epic key: `<EPIC_KEY>`, the Feature Readiness Tracker Epic created under that Initiative, e.g. `NFSAAS-184920`

When chained from `jira-automation-anf-feature-clc`, both keys come from that run. When invoked directly with only the Initiative key, find the Epic with:

```
project = NFSAAS AND issuetype = Epic AND labels = ANF-Feature-Readiness AND "Parent Link" = <INITIATIVE_KEY>
```

If no readiness Epic exists, stop and tell the user to run `jira-automation-anf-feature-clc` first. Do not create the page with an empty or guessed Feature Readiness macro.

## Fixed Confluence targets

| Item | Value |
|---|---|
| Cloud ID | `cb69b23c-616e-461b-9cf1-b3015880f8dd` |
| Site | `https://netapp.atlassian.net` |
| Space | `ANF`, spaceId `138051584` |
| Parent page ("PLR Dashboard - Product Lifecycle Readiness") | `669944123` |
| Dashboard label the report matches | `plr-anf-tracking` |
| Reference template page | `669515990`, "Template - Feature Name Readiness Tracking" (lives in `CLOUDVOL`; reference only, the body comes from `page-body.html`) |
| Jira DC serverId (ngage) | `dd58387a-f8a3-3a85-86f5-fe657bbc68a6` |
| Jira DC server name | `Jira - ngage` |
| Page Properties macro id | `Feature_Details-2` |
| Jira DC browse URL prefix | `https://jira.ngage.netapp.com/browse/` |

New pages go in the **ANF** space under `669944123`. Older feature pages created by earlier runs live in `CLOUDVOL` under "Copy of PLR Dash" (`584352624`); leave them where they are and never write new pages there.

## Which systems to use (critical)

Two different Atlassian instances are involved. Do not mix them up.

- Confluence pages live in **Atlassian Cloud**. Use the `user-Atlassian-MCP-Server` MCP tools.
- `NFSAAS` issues live in **ngage Jira Data Center**. Use the `user-jira_oss` MCP server to read field values. Atlassian Cloud Jira tools return "Issue does not exist or you do not have permission to see it." for `NFSAAS` keys.
- Do not use direct HTTP or REST API calls for either system.

The Jira macros on the page are rendered by Confluence against the linked ngage instance via `serverId`. This skill only writes the macro definition; it never fetches issue data into the page body.

## Scope discipline (no hallucination)

Operate only on the fixed targets in the table above and the exact issue keys passed in (`<INITIATIVE_KEY>`, `<EPIC_KEY>`). Do not read, search, or draw values from any other Confluence page or Jira issue. The only reads allowed are: the two passed-in Jira keys, the parent page `669944123` for the duplicate check, the page this skill creates or updates, and the Jira keys already written on that page from earlier stages. If a required value is missing from those sources, report it as missing. Never infer or copy a value from an unrelated page, a screenshot, or memory.

## Jira fields to read from the Initiative

Read `<INITIATIVE_KEY>` from ngage Jira with these fields:

| Field | ID | Used for |
|---|---|---|
| Summary | `summary` | Page title |
| Tier | `customfield_29902` | Tier cell |
| Customer Announcement Date (T0) | `customfield_25618` | Launch Date cell |
| Stage (Feature Stage) | `customfield_22400` | Which stage column gets the Initiative link |
| Customer Facing Name | `customfield_29903` | Duplicate-check search term only, never the title |

Never type these values from a screenshot or a rendered page. If Tier, Customer Announcement Date, or Stage is missing, still create the page, leave only the affected cell empty, and report the missing source field. Do not invent a value.

## Page title

Convention: the Initiative **Summary**, verbatim. No stage, no suffix, nothing appended.

Example: Initiative `NFSAAS-146542` with Summary "Large file support for ANF large volumes and flex cache volumes" gives exactly that string as the title.

Rules:

1. Use the Jira Summary verbatim unless the user supplies a display name for this run, in which case prefer theirs.
2. Do **not** append the Feature Stage, "Feature Readiness", or any other suffix. One page serves all three stages, so a stage in the title would be wrong as soon as the feature advances.
3. Do not substitute Customer Facing Name for the Summary. That field is only used to find pages created under older naming conventions during the duplicate check.
4. Confluence titles must be unique within a space. If the title is taken, it is almost certainly this feature's own page, so follow "Duplicate check" and update it rather than inventing a variant title.

## Duplicate check (before creating anything)

The page is per feature, so a second page for a later stage is always a mistake.

1. List children of parent `669944123`.
2. Search for an existing page for this feature, trying both the Summary and the Customer Facing Name, because earlier pages were titled `<Customer Facing Name> - <Stage>` and may sit in `CLOUDVOL`:

```
space in (ANF, CLOUDVOL) AND type = page AND (title ~ "<Summary>" OR title ~ "<Customer Facing Name>")
```

3. If a page exists for this feature in **any** stage, do not create a second one. Update that page as described in "Updating an existing page for a new stage", and report that an existing page was updated rather than created. Do not rename the existing page unless the user asks.
4. Never modify the reference template page `669515990`, the parent page `669944123`, the old parent `584352624`, or any other feature's page.

## Updating an existing page for a new stage

Read the page with `contentFormat: "html"`, then change only these things:

1. **Stage table.** Write the Initiative link into the column matching `<FEATURE_STAGE>`. Leave the other two stage cells exactly as they are, including any hand-written text such as "launched July 23".
2. **Feature Readiness macro.** Point `jqlQuery` at the parent Initiative only. Add `<INITIATIVE_KEY>` to that key list; do not drop Initiatives already there. If the existing query still lists a readiness Epic, replace those Epic keys with the parent Initiative keys. Never leave an Epic in this query.
3. **JIRA macro.** Add `<INITIATIVE_KEY>` to the existing `jqlQuery` key list; do not drop the Initiatives already there.
4. **Tier and Launch Date.** Set both from the Initiative passed to this run. If the stored values differ, overwrite them and report the old and new values, since the dashboard shows a single Launch Date per feature.

Everything else on the page, including the Notes table and the Retrospective section, is preserved byte for byte.

Send the full body back with only the intended cells changed. Three cautions:

- Judge the existing page from the HTML body, never from the markdown rendering. Markdown hides the Jira macros entirely, so a correctly wired page looks empty and invites a wrong "fix".
- Existing pages carry hand-written content the template does not have, such as actual launch dates, extra Jira links, and links to prior readiness plans. Preserve all of it.
- A full-body update makes Confluence regenerate every `data-local-id`. Existing inline comments are anchored to those IDs, so check for inline comments before updating a page that others have reviewed.

## Build the page body

Read [page-body.html](page-body.html) and substitute these tokens. Nothing else in that file changes.

| Token | Value |
|---|---|
| `{{TIER}}` | Initiative Tier, e.g. `T2` |
| `{{LAUNCH_DATE_US}}` | Customer Announcement Date as `M/D/YYYY`, e.g. `12/17/2026` |
| `{{READINESS_JQL}}` | `key = <INITIATIVE_KEY>` for one stage, or `key in (<INIT_1>, <INIT_2>)` once the page covers several. Initiative keys only; never a readiness Epic |
| `{{READINESS_COLUMNS}}` | `Status Summary` for one Initiative, `Key,Status Summary` for more than one |
| `{{READINESS_COLUMN_IDS}}` | `customfield_24641` for one Initiative, `issuekey,customfield_24641` for more than one |
| `{{INITIATIVE_JQL}}` | `key = <INITIATIVE_KEY>` for one stage, or `key in (<INIT_1>, <INIT_2>)` once the page covers several |
| `{{STAGE_PRIVATE_PREVIEW}}` | Initiative link for that stage, else empty |
| `{{STAGE_PUBLIC_PREVIEW}}` | Initiative link for that stage, else empty |
| `{{STAGE_GA}}` | Initiative link for that stage, else empty |
| `{{MACRO_ID_READINESS}}` | A freshly generated UUID |
| `{{MACRO_ID_JIRA}}` | A different freshly generated UUID |

Both macros query the **parent Initiative**. They differ only in columns.

- **Feature Readiness column** queries the parent Initiative or Initiatives and shows Status Summary (`customfield_24641`) from that Initiative only. Do not point this macro at the readiness Epic. With more than one Initiative, add the Key column so the stages are distinguishable.
- **JIRA column** queries the same Initiative or Initiatives, with the nine display columns. This renders one row per stage: Summary, Customer Announcement Date, Target Release Version, TPM/PM/TME Feature Owner, Tier, Customer Facing Name, Stage.

Pointing Feature Readiness at the Epic is the most likely failure. Verify after publishing that both `jqlQuery` values contain Initiative keys only.

### Stage cells

Write only the stage matching `<FEATURE_STAGE>` and leave the other two empty for a later run to fill:

```html
<a href="https://jira.ngage.netapp.com/browse/NFSAAS-146542">NFSAAS-146542</a>
```

Rules:

1. The link points at the **Initiative** for that stage, not the readiness Epic, matching the published feature pages.
2. Do not write "Not Started" or any other placeholder into the empty stages. Published pages leave them blank until the stage exists.
3. Map `<FEATURE_STAGE>` to exactly one column: `Private Preview`, `Public Preview`, or `GA`. If the Stage value is missing or does not map, leave all three cells empty and report it.
4. Launch-date annotations such as "launched July 23" are added by the TPM. Never write, reword, or remove them.

## Create the page

Call `createConfluencePage` with `contentFormat: "html"`, `spaceId: "138051584"`, `parentId: "669944123"`, `status: "current"`, the title, and the substituted body.

Notes that matter:

1. `contentFormat: "html"` is required. The `data-type="extension"` and `data-extension-key="jira"` divs convert to `ac:structured-macro ac:name="jira"` with all parameters preserved. Markdown and ADF bodies cannot express these macros.
2. Keep the Page Properties (`details`) macro wrapper and its `id` value `Feature_Details-2`. The PLR Dashboard report reads the columns out of that macro; a page without it contributes no dashboard row.
3. Omit `data-local-id` attributes. Confluence generates fresh ones. Do not copy them from the template, or the new page will share local IDs with the template.
4. Only the current stage's cell is filled. The other two stay empty for later runs.

## Label and placement

The dashboard report matches `label = "plr-anf-tracking"`, and the Atlassian MCP tools cannot set labels on create or update. So every run ends with the page unlabelled and therefore invisible on the dashboard until a human tags it.

1. Always create the page under `669944123` so it is easy to find, then tell the user, in the report, to add the `plr-anf-tracking` label and move the page if they want it elsewhere. Say it plainly as a required follow-up, not as an aside.
2. Do not attempt REST or HTTP calls to work around the missing label tool.
3. If an existing page already carries the label, an update run does not disturb it, and no follow-up is needed. Say so instead of repeating the instruction.

## Verification

After creating the page, re-read it with `getConfluencePage` using `contentFormat: "html"` and verify:

- The page exists in space `ANF` with `parentId` = `669944123`.
- The title is the Jira Summary verbatim, with no stage and no suffix.
- The Page Properties macro is present with id `Feature_Details-2`.
- The Feature Readiness macro `jqlQuery` contains `<INITIATIVE_KEY>` only (plus any other stage Initiatives already on the page), its `columnIds` includes `customfield_24641`, and it does **not** contain `<EPIC_KEY>` or any other readiness Epic.
- The JIRA macro `jqlQuery` contains `<INITIATIVE_KEY>`, plus every Initiative that was already there, and its `columnIds` lists all nine fields.
- Both macros carry `serverId` `dd58387a-f8a3-3a85-86f5-fe657bbc68a6` and `server` `Jira - ngage`.
- The stage column for `<FEATURE_STAGE>` holds the Initiative link, and the other two stage cells are unchanged.
- Tier and Launch Date cells match the Initiative's Jira values.
- The reference template page `669515990` and the parent page `669944123` were not modified.
- Only one tracking page exists for this feature across all stages and both spaces.

## Required report (standalone runs only)

When invoked as Phase 2 of `jira-automation-anf-feature-clc`, skip this section and let the orchestrator report. When run standalone, return:

1. Page title, page ID, and URL, and whether the page was created or updated
2. Parent verification (child of PLR Dashboard - Product Lifecycle Readiness, `669944123`, space ANF)
3. Initiative key driving both macros (Feature Readiness Status Summary and the JIRA row), the readiness Epic key from Phase 1 (not used in Feature Readiness), and which stage column received the Initiative link
4. Which stages the page now covers, and which remain empty
5. A table of the values written: Tier, Launch Date, plus the source Jira field for each, noting any value overwritten by this run
6. Confirmation that the Feature Readiness macro shows Status Summary from the parent Initiative only and the JIRA macro shows one row per stage Initiative
7. The required follow-up: add the `plr-anf-tracking` label so the page appears on the dashboard, and move the page if a different location is wanted
8. Any missing Jira fields or duplicate pages found
9. Explicit confirmation that the reference template page and the PLR Dashboard page were not altered

Do not report success unless the page has been re-read and verified in Confluence.

## Scope boundary

This skill creates the **Confluence PLR tracking page** only. It does not create or modify any Jira issue; that is `jira-automation-anf-feature-clc`. It is also distinct from `feature-readiness-plan`, which builds the detailed per-feature readiness plan page from a different template.
