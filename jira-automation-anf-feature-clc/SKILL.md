---
name: jira-automation-anf-feature-clc
description: End-to-end ANF feature readiness automation, run as a single invocation in two phases. Phase 1 creates the Feature Readiness Tracker structure in Jira by cloning template Epic NFSAAS-170129 under an Initiative that has a Feature Stage, recreating every child Story with the correct owners and launch-date-derived due dates, copying the template Status Summary scaffold, preventing duplicates, and verifying by re-reading Jira. Phase 2 then runs the anf-plr-readiness-tracking-page skill to publish the matching Confluence PLR tracking page under PLR Dashboard - Product Lifecycle Readiness in the ANF space, titled with the Jira Summary only and covering all three stages. The Feature Readiness column shows Status Summary from the parent Initiative only; the JIRA column shows the Initiative row. Returns one combined leadership-ready report covering both. Use when the user asks to create a Jira feature readiness tracker Epic, clone the ANF readiness checklist Epic, set up CLC/readiness Stories for an initiative, or types /anfclc.
disable-model-invocation: true
---

# JIRA Automation ANF Feature CLC

Creates the Jira Feature Readiness Tracker Epic and its child Stories under an ANF Initiative that has a Feature Stage, then publishes the matching Confluence PLR tracking page.

## Orchestration: one invocation, two phases

This skill is the orchestrator. A single invocation always produces both artifacts. Do not stop after Jira and do not ask the user whether to continue.

| Phase | Work | Instructions |
|---|---|---|
| 1 | Jira readiness Epic and child Stories | The rest of this file |
| 2 | Confluence PLR tracking page, created or updated for this stage | `~/.cursor/skills/anf-plr-readiness-tracking-page/SKILL.md` |

Rules:

1. Run Phase 1 to completion, including its verification, before starting Phase 2.
2. Phase 2 is mandatory. Enter it automatically once Phase 1 verification passes, carrying `<INITIATIVE_KEY>` and the newly created `<EPIC_KEY>` forward as its inputs.
3. Halt before Phase 2 only when Phase 1 verification fails, or when Phase 1 stopped on the duplicate check. In either case say which phase halted and why. If the user explicitly asked for the Jira structure alone, skip Phase 2 and say so.
4. Emit one combined report at the end covering both phases. Never emit a separate Phase 1 report and Phase 2 report.
5. Track the two phases as a task list so the invocation cannot end with Phase 2 unstarted.

Both phases run in the same session and share the same MCP servers, so no data needs to be re-read between them. If you delegate Phase 2 to a subagent, pass `<INITIATIVE_KEY>` and `<EPIC_KEY>` explicitly and tell it to read the Phase 2 skill file, because a subagent inherits none of this session's context.

## Purpose

When a Jira Initiative is created, assigned, or updated with a **Feature Stage**, create the Jira Feature Readiness tracking structure at the same time by cloning the ANF Feature Readiness Tracker template Epic under that Initiative.

## Trigger

Execute this workflow when either condition is true:

1. A Jira Initiative is newly created and contains a Feature Stage.
2. An existing Jira Initiative is assigned or updated with a Feature Stage.

Run this workflow once per Initiative and Feature Stage. Before creating anything, check whether a Feature Readiness Tracker Epic already exists under the Initiative for the same Feature Stage. If one exists, do not create a duplicate. Verify the existing Epic and report it instead.

## Inputs

- Initiative URL or key: `<INITIATIVE_KEY>`
- Template Epic: `NFSAAS-170129`
- New Epic name: `<EPIC_NAME>`
- Feature Stage: `<FEATURE_STAGE>`
- Launch date: `<LAUNCH_DATE>`

`<EPIC_NAME>` convention: `<Initiative summary> - feature readiness checklist (<FEATURE_STAGE>)`

## Scope discipline (no hallucination)

Operate only on the issues named in this skill and the ones passed in: the Initiative key given by the user, the template Epic `NFSAAS-170129` and its children, and the new Epic and Stories this run creates. Do not read, search, or pull values from any other Jira issue or Confluence page. Every field value must come from one of those sources, read at run time. If a required value is missing, report it as missing rather than inferring it from an unrelated issue, a screenshot, or memory.

## Which Jira to use (critical)

ANF `NFSAAS` issues live in **ngage Jira Data Center**, not Atlassian Cloud.

- Use the **`user-jira_oss`** MCP server (`jira.ngage.netapp.com`) for all Jira reads and writes.
- Do **not** use the Atlassian Cloud Jira tools � `NFSAAS` keys return "Issue does not exist or you do not have permission to see it."
- Do not use direct HTTP or REST API calls.

## Field IDs (ngage Jira)

| Field | ID |
|---|---|
| Epic Name | `customfield_11001` |
| Epic Link | `customfield_11000` |
| Parent Link | `customfield_13907` |
| Stage (Feature Stage) | `customfield_22400` |
| Status Summary | `customfield_24641` |
| Customer Announcement Date (T0) | `customfield_25618` |
| TPM Feature Owner | `customfield_23615` |
| PM Feature Owner | `customfield_22311` |
| TME Feature Owner | `customfield_29700` |

Read the Initiative with `fields: "*all"` to resolve these in one call.

Also read the template Epic `NFSAAS-170129` and each of its child Stories before creating anything, because the Status Summary text has to be copied from Jira rather than retyped. See "Carry over the Status Summary".

## Source fields to resolve from the Initiative

Read these values from Jira. Do not guess names or dates.

- TPM Feature Owner: `<TPM_FEATURE_OWNER>`
- PM Feature Owner: `<PM_FEATURE_OWNER>`
- TME Feature Owner: `<TME_FEATURE_OWNER>`
- Feature Stage: `<FEATURE_STAGE>`
- Launch date / Customer Announcement Date: `<LAUNCH_DATE>`

If a required dynamic owner or launch date is missing, continue creating the Epic and Stories, leave only the affected field unassigned or without a due date, and clearly report the missing source field. Do not invent a value.

## Safety rules

1. Do not modify the Initiative in any way. Do not change its summary, description, fields, status, labels, dates, or formatting.
2. Do not move, edit, or change the original template Epic `NFSAAS-170129` or any of its children.
3. Create all new issues in project `NFSAAS`.
4. Use Jira MCP tools only. Do not use direct HTTP or REST API calls.
5. Do not create duplicate readiness Epics or duplicate child Stories.
6. Preserve names exactly as Jira resolves them. Do not guess user account IDs.

## Duplicate check (before creating anything)

Search for an existing readiness Epic under the Initiative:

```
project = NFSAAS AND issuetype = Epic AND labels = ANF-Feature-Readiness AND "Parent Link" = <INITIATIVE_KEY>
```

If a result exists for the same Feature Stage, stop and report it instead of creating a new Epic.

## Create the new Epic

Epic creation fails if `Epic Name` is missing, and it can fail when too many fields are set at once. Use two steps:

1. **Create** the Epic in `NFSAAS` with a short summary plus `customfield_11001` (Epic Name). Nothing else.
2. **Update** the same Epic with:
   - Summary and Epic Name = `<EPIC_NAME>`
   - Description (see formatting rules below)
   - Priority `P2`
   - Labels including `ANF-Feature-Readiness`
   - Parent Link (`customfield_13907`) = `<INITIATIVE_KEY>`
   - **Due date = `<LAUNCH_DATE>`** � the Epic due date always equals the launch date
   - **Status Summary (`customfield_24641`) = the template Epic's Status Summary, copied verbatim** � see "Carry over the Status Summary"
3. Add a `Cloners` issue link from the new Epic to `NFSAAS-170129`, matching the pattern of prior clones.
4. Keep the Initiative unchanged.

### Epic description formatting (avoid oversized text)

- Store the description as **plain body text**. Do **not** use Jira wiki heading markup (`h1.`, `h2.`) for the steps � Jira renders headings as large bold text, which makes the whole description look oversized.
- The MCP tool converts Markdown to wiki markup and **mangles list syntax**: Markdown `#` becomes `h1.`, and `1.` / `2.` numbering produces a stray `##` heading on the first line. Avoid both.
- Write the "Steps" list as plain sequential lines using `1)`, `2)`, `3)` � which pass through unconverted and render at body size.
- Do not attempt font-family or font-size settings such as "Aptos body" or size 10. Jira wiki markup has no font-family or point-size syntax, and the instance stylesheet controls rendering. The only reliable control is body text vs. heading, so always keep the description as body text.
- After writing, re-read the description and confirm no `h1.`, `h2.`, or `##` markup is present.

## Carry over the Status Summary

`Status Summary` (`customfield_24641`) is a separate Jira text field, not part of the Description. It is **not** copied when issues are created through the API, and ngage Jira pre-fills every new `NFSAAS` issue with the field default:

```
- *Risks:* 
- *Issues:*
- *Next Steps:* 
- *Mitigation Plan:* 
```

Because that default looks populated, a run can silently finish with the wrong content. The template Epic's Status Summary is the weekly status reporting scaffold, and it must be present on the new Epic:

```
* Feature onboarding doc status (including %, draft, review, complete) 

* CLC % (key items open), blockers, asks to the PMs /MSFT. Breakout on CLC pending NTAP vs MSFT)
 
* Supportability (CSS) - Status of deep dive, brownbag session, testing, etc.
 
* Dev / Engr Update

* Risks/Blockers/Delays - list here �Why�

Note:  Please copy/paste previous week status in the 'Comments' section before updating for the current week
```

Rules:

1. Read `customfield_24641` from the template Epic `NFSAAS-170129` at run time and copy that value into the new Epic. Read it from Jira every run � do not paste the sample above, and do not retype the bullets from a rendered page or screenshot.
2. Read `customfield_24641` from each template child Story and copy it to the matching new Story. The template children currently all carry the `- *Risks:*` scaffold, so the practical effect is that the child value is preserved; still copy it from Jira rather than assuming.
3. New `NFSAAS` issues are pre-filled with the same `- *Risks:*` scaffold the template children carry, so a child Story usually needs no write at all. Verify each new Story against its template counterpart and write the field only where it differs. That avoids the Markdown-to-wiki mangling described in rule 5.
4. Copy the raw field value byte for byte, including bullet characters, blank lines, trailing spaces, and the `Note:` line. Keep `Note:` as its own paragraph � it is not a bullet in the template.
5. The MCP tool runs Markdown-to-wiki conversion on text fields, which can turn `*Risks:*` into `_Risks:_` and can collapse blank lines between bullets. After writing, re-read `customfield_24641` and compare it to the template value. If it was altered, write it again until the stored value matches the template.
6. Set Status Summary in the Epic **update** step, not the create step, for the same reason the other fields are deferred: Epic creation fails when too many fields are set at once.
7. Never edit `customfield_24641` on the template Epic `NFSAAS-170129` or on its children.

## Recreate the child Stories

Create one Story in `NFSAAS` per template child and set `customfield_11000` (Epic Link) to the newly created Epic. Preserve each template child's Summary (including any trailing space), Description, Priority (`P2`), Issue Type (`Story`), and Status Summary (`customfield_24641`). Do not link the new Stories to the original template Epic.

The template Epic currently has **9** children. The template changes over time, so always list its children at run time with `"Epic Link" = NFSAAS-170129` and clone what is actually there. If the count or the summaries differ from the table below, follow the template and report the drift instead of silently following this table.

| # | Story summary | Assignee | Due date |
|---|---|---|---|
| 1 | Feature Onboarding Doc | TPM Feature Owner | 16 weeks before `<LAUNCH_DATE>` |
| 2 | CLC Attestations | TPM Feature Owner | 3 weeks before `<LAUNCH_DATE>` |
| 3 | MSFT CSS Supportability Check List (SCL) tracker | TPM Feature Owner | 2 weeks before `<LAUNCH_DATE>` |
| 4 | Billing/Meter Changes related checklist | PM Feature Owner | 15 weeks before `<LAUNCH_DATE>` |
| 5 | Security Checklist | Justin Tang | Template rule, else blank |
| 6 | Capacity Management review/tracking | Judy Gulia | 4 weeks before `<LAUNCH_DATE>` |
| 7 | Content coverage and quality (Public Docs) | Manish Chabria | 3 weeks before `<LAUNCH_DATE>` |
| 8 | TME Outbound content | TME Feature Owner | Same date as `<LAUNCH_DATE>` |
| 9 | Retrospective | TPM Feature Owner | No rule defined |

Where the table says "Template rule, else blank": preserve the template child's due-date rule if one exists; otherwise leave blank and report that no due-date rule was supplied.

`Retrospective` is always assigned to the TPM Feature Owner, resolved from the Initiative the same way as Stories 1-3. It has no due-date rule yet, so create it with no due date and report that the due-date rule is still undefined.

## Date calculation rules

1. Treat `<LAUNCH_DATE>` (Customer Announcement Date) as T0.
2. Calculate dates using calendar weeks:
   - 16 weeks = 112 calendar days before launch
   - 15 weeks = 105 calendar days before launch
   - 4 weeks = 28 calendar days before launch
   - 3 weeks = 21 calendar days before launch
   - 2 weeks = 14 calendar days before launch
3. Write Jira due dates as `YYYY-MM-DD`.
4. If a calculated due date falls on Saturday or Sunday, move it to the preceding Friday.
5. The TME Outbound content due date remains exactly the launch date unless Jira rejects a weekend date. If rejected, report the validation error rather than silently changing the date.
6. Never calculate a due date when `<LAUNCH_DATE>` is missing or invalid.

## Assignment resolution rules

Assign by **email address** � the ngage user lookup fails on display names, "Last, First" strings, and guessed usernames.

1. Resolve TPM, PM, and TME owners from the Initiative fields, then map each username to its email via the user profile lookup.
2. Fixed assignees resolve to these Jira accounts. Note the spellings differ from the names used in the rules:

| Rule name | Jira display name | Email to use |
|---|---|---|
| Justin Tang | Tang, Justin | `Justin.Tang@netapp.com` |
| Judy Gulia | Gulla, Judy | `Judy.Gulla@netapp.com` |
| Manish Chabria | Chabbria, Manish | `Manish.Chabbria@netapp.com` |

3. If Jira user lookup fails, confirm the person via Slack user search where email is authoritative, or find a recent issue assigned to them with a JQL `assignee` clause.
4. If Jira finds multiple matches, use the exact active Jira user matching the full display name. If still ambiguous, leave the Story unassigned and report the ambiguity.
5. If an assignee cannot be assigned because of permissions or project-role restrictions, retain the Story, leave it unassigned, and report the error.

## Phase 1 verification

After creation, re-read the Initiative, new Epic, and every child Story. Verify:

- The Initiative was not altered.
- The new Epic exists in `NFSAAS`.
- The new Epic Parent Link equals `<INITIATIVE_KEY>`.
- The new Epic Summary and Epic Name equal `<EPIC_NAME>`.
- The new Epic Due date equals `<LAUNCH_DATE>`.
- The new Epic description renders at normal body size, with no heading markup on the steps.
- The new Epic contains label `ANF-Feature-Readiness`.
- The new Epic `Status Summary` (`customfield_24641`) matches the template Epic's Status Summary verbatim, and is **not** the `- *Risks:* / - *Issues:* / - *Next Steps:* / - *Mitigation Plan:*` field default. Re-read the field and diff it against the template value; do not judge this from the create response.
- Each new Story `Status Summary` matches its template counterpart.
- The new Epic has one child Story per template child. Query `"Epic Link" = <NEW_EPIC_KEY>` and expect the same total as `"Epic Link" = NFSAAS-170129`.
- Each Story has the correct Epic Link, assignee, and due date according to the rules above.
- No duplicate Feature Readiness Tracker Epic or duplicate child Stories were created.
- The original template Epic and children were not changed; the template still has the same number of children it had at the start of the run.

Do not proceed to Phase 2 unless the new Epic and every child Story have been re-read and verified in Jira.

## Phase 2: create or update the Confluence PLR tracking page

The tracking page is one page per feature covering all three stages, published under PLR Dashboard - Product Lifecycle Readiness (`669944123`) in the ANF space and titled with the Initiative Summary alone, no stage. If a page already exists for the feature from an earlier stage, Phase 2 updates it rather than creating a second one.

Once the Phase 1 verification above passes, immediately continue into Phase 2 without pausing for confirmation. Read `~/.cursor/skills/anf-plr-readiness-tracking-page/SKILL.md` and follow it, passing:

- `<INITIATIVE_KEY>` � the Initiative just used
- `<EPIC_KEY>` � the readiness Epic just created

Follow that skill's duplicate check, page body, creation, and verification steps in full. Do not emit its report separately; fold its results into the combined report below.

## Combined report (both phases)

Return one report covering the whole invocation:

**Phase 1, Jira**

1. Target Initiative key and URL
2. New Epic key and URL
3. Parent Link verification
4. Feature Stage and launch date used
5. A table containing every child Story with: Story key, Summary, Assignee, Due date, Assignment source or rule, Verification status
6. Confirmation that Status Summary was copied from the template Epic to the new Epic and from each template child to each new Story, with the source read from Jira at run time
7. Explicit confirmations that the Initiative was not altered, the source template Epic and its children were not altered, and duplicate creation was prevented

**Phase 2, Confluence**

8. Page title, page ID, and URL, whether it was created or updated, and confirmation that it is a child of PLR Dashboard - Product Lifecycle Readiness (`669944123`, space ANF)
9. Which issue each macro points at: Feature Readiness Status Summary from the parent Initiative only (never the readiness Epic), JIRA to the same stage Initiative or Initiatives
10. Which stage column received the Initiative link, and which stages are still empty on the page
11. Tier and Launch Date written, with the Jira field each came from
12. The required follow-up: add the `plr-anf-tracking` label so the page shows on the dashboard, and move the page if a different location is wanted
13. Confirmation that the reference template page and the PLR Dashboard page were not altered

**Across both**

14. Any missing Jira fields, unresolved users, skipped dates, permission problems, duplicates, or other errors, and which phase each came from
15. If Phase 2 was skipped or halted, say so explicitly and give the reason

Do not report success for the invocation unless Phase 1 was verified in Jira and Phase 2 was verified by re-reading the Confluence page.

## Scope boundary

This skill owns both phases: the **Jira** structure and, through `anf-plr-readiness-tracking-page`, the **PLR tracking page**. It does not create the Confluence Feature Readiness Plan page � that is the separate `feature-readiness-plan` skill, which builds a different, more detailed page. Run it afterward only if the user asks for it.
