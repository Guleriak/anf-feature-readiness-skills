# ANF Launch Date Audit — Reference

## Systems and endpoints

| Item | Value |
|---|---|
| SharePoint list | `https://netapp.sharepoint.com/sites/CloudStorage/Lists/ANF%20Launch%20Calendar/Whats%20Next.aspx` |
| SharePoint read path | `user-workiq` → `ask_work_iq`, list URL passed in `fileUrls` |
| Jira instance | ngage Data Center, `https://jira.ngage.netapp.com` |
| Jira read path | `user-jira_oss` → `jira_search`, `jira_get_issue` |
| Jira browse URL | `https://jira.ngage.netapp.com/browse/<KEY>` |
| Jira project | `NFSAAS` (project id `18612`) |
| Email transport | `user-smtp` → `smtp_send_email` |

`NFSAAS` keys are **not** visible to the Atlassian Cloud Jira tools in
`user-Atlassian-MCP-Server`; they return "Issue does not exist or you do not have permission
to see it." Use `user-jira_oss` for every Jira read in this skill.

## Jira fields

| Field | ID | Notes |
|---|---|---|
| Customer announcement date | `customfield_25618` | The only launch date on an Initiative. Populated on roughly a third of the set. |
| Customer Facing Name | `customfield_29903` | Marketing name; the primary matching key against calendar titles |
| Stage | `customfield_22400` | `Private Preview` / `Public Preview` / `GA` |
| Tier | `customfield_29902` | `T1` / `T2` / `T3` |
| Target Release Version | `customfield_20602` | e.g. `2638.0.0+ANF` |
| TPM Feature Owner | `customfield_23615` | Scopes the initiative set |
| PM Feature Owner | `customfield_22311` | Not in the table; useful when assigning a mismatch |
| TME Feature Owner | `customfield_29700` | As above |

### Fields that do not exist on these Initiatives

Do not query for a Jira "Original" or "Revised" release date. `Target Date`
(`customfield_23208`), `Target Release Date` (`customfield_17024`), `Target start`/`Target end`
(`customfield_15001` / `_15002`) and `duedate` are **not on the NFSAAS Initiative screen** —
requesting them returns nothing and invites the mistake of treating a silent omission as an
empty value. `customfield_25618` is the single source of launch date truth in Jira.

### Reconstructing an original date from Jira

Not part of the default audit, but available when someone disputes a variance. Jira DC has no
batch changelog tool (`jira_batch_get_changelogs` returns "only available on Jira Cloud"), so
fetch per issue:

```
jira_get_issue(issue_key="NFSAAS-60610", fields="customfield_25618", include="changelog")
```

Walk the history for entries whose field is `Customer announcement date`; the earliest
`fromString` is the original value. This is one call per issue — use it for a handful of
disputed rows, not for the whole set.

## Scope and expected leftovers

Both sides are portfolio-wide: every unlaunched calendar row against every NFSAAS Initiative
carrying a customer announcement date. Scoping Jira to one TPM was tried and abandoned — it left
26 of 36 calendar rows unmatched and hid real drift on features owned by others.

Even matched portfolio-wide, three groups will not pair up, and all three are legitimate:

- **Closed Jira initiatives with no calendar row** (27 on the 2026-09-18 run). These shipped and
  their calendar rows now read `Launched`, which the Step 1 filter excludes. Count them, omit
  them from the table, and say so.
- **Live Jira initiatives with no calendar row** (7 on that run). A genuine finding: a committed
  date the customer-facing calendar does not know about. Always list these.
- **Calendar rows with no Jira initiative** (13). Usually a later stage that has no Initiative
  yet, such as Immutable Backup Vault Public Preview and GA. Worth naming, because the calendar
  is promising a date nothing in Jira is tracking.

A feature can be matched at one stage and unmatched at another; that is normal and often the
most interesting row on the page.

## Matching: worked examples

Real pairings from the live data, showing why each strategy exists.

| Calendar title | Jira | Strategy |
|---|---|---|
| `Regionally Redundant Backup Data (GZRS-RA Storage Account support) Private Preview` | `NFSAAS-60610`, same summary | Exact summary |
| `Immutable Backup Vault - Private Preview` | `NFSAAS-136602` `ANF Immutable Backup Vault - Private Preview` | Exact after stripping the `ANF` prefix |
| `Top clients/files for volume IOPS metrics` | `customfield_29903` = `Top K clients/files for volume IOPS metrics` | Fuzzy name; the calendar drops "K" |
| `Application volume group for Custom Applications` | `customfield_29903` = `Application volume group for custom applications` | Fuzzy name, case only; appears twice, split by `Disclosure Level` into items 115 (Private Preview) and 79 (Public Preview) |
| `Cache origin volumes` | `customfield_29903` = `ANF origin volumes` | Fuzzy name — the noun differs, so the pairing rests on `Disclosure Level` plus there being exactly one candidate per stage |

## Stage lives in `Disclosure Level`

Titles repeat across stages, so stage is the tiebreaker on almost every multi-phase feature.
The list has **no** column named `Stage`; the value sits in
`Disclosure Level (private, public preview or GA)`. Request it by that exact name in Step 1.
WorkIQ relabels it `Stage` in its own output, which makes it easy to assume a `Stage` field
exists — it does not, and asking for one returns nothing.

Casing is inconsistent in the data (`Private Preview`, `Private preview`, `private preview`,
`GA (General)`), so normalize before comparing.

**Never break a stage tie by date proximity.** On the 2026-09-18 run, pairing each Jira
initiative with the nearest calendar date inverted the two `Top clients/files for volume IOPS
metrics` rows, because Private Preview had slipped to 7/09 while Public Preview still read
7/14 — later stage, earlier date. Both rows looked self-consistent and the error was invisible
in the output. Match on stage and report the gap that results, however odd it looks.

Only when `Disclosure Level` is genuinely blank on a repeated title does the row go to
**Ambiguous** with its candidates listed, for the user to resolve into the alias map.

## Alias map format

`~/anf-launch-date-audit/alias-map.json`. Keys under `aliases` are the normalized calendar
title. Where two calendar rows share a title, disambiguate by appending the Original Release
Date as `title::YYYY-MM-DD` — it is the only stable distinguishing value the list exposes.

```json
{
  "_ignore": ["insight - netapp conference", "ignite conference (microsoft)"],
  "aliases": {
    "application volume group for custom applications::2026-06-11": "NFSAAS-61898",
    "cache origin volumes::2026-08-04": "NFSAAS-47957"
  }
}
```

`_ignore` lists calendar rows that are not features at all — conferences and marketing
milestones. They are excluded from the tables and counts, and noted once in the report so
their absence is visible rather than silent.

The seed copy ships with the skill and carries only `_ignore`; `aliases` starts empty and
grows as the user resolves ambiguities. Never add an entry the user has not confirmed.

## Email rendering rules

These mirror the locked-in rules from the `Weekly-Ring` report so both land the same way in
Outlook. Each one exists because of a specific rendering failure.

1. **All CSS inline.** No `<style>` block — Outlook strips it on forward and reply.
2. **`font-family` on every element.** `Calibri, Segoe UI, Arial, Helvetica, sans-serif` on
   `<body>`, `<p>`, `<td>`, `<th>`, `<h2>`, `<a>`, `<div>`. Outlook drops `<body>` inheritance
   when a message is forwarded.
3. **HTML attributes alongside CSS on tables:** `cellpadding="0" cellspacing="0" border="0"
   width="100%" role="presentation"`. Outlook for Windows renders through Word, which ignores
   CSS-only table styling.
4. **`bgcolor` attribute on every cell** — `bgcolor="#ffffff"` on `<td>`, `bgcolor="#0052CC"`
   on `<th>` — because Outlook discards CSS `background-color` on forward.
5. **Visible dark borders:** `border:1px solid #333;` on all `<td>` and `<th>`. Never
   `border-bottom` alone, never light greys.
6. **White rows.** No alternating backgrounds.
7. **10px font in tables**, 12px body text, 13px bold for the At a Glance tiles.
8. **Explicit line height:** `line-height:1.4; mso-line-height-rule:exactly;` on every
   `<td>`, `<th>`, `<p>`.
9. **MSO namespace** on `<html>`: `xmlns:o="urn:schemas-microsoft-com:office:office"`.
10. **No `<ul>`/`<li>`.** Outlook adds unpredictable list spacing — use `<p>` or `<br>`.
11. **Emoji plus a text label**, always. Emoji render as boxes in some Outlook builds, so
    "🔴 Major drift" stays legible when the glyph fails.
12. **Jira links:** `color:#0052CC; text-decoration:none;`.

### Colors

| Meaning | Hex |
|---|---|
| Aligned / on track | `#2e7d32` |
| Minor drift / pending | `#B38600` |
| Drift | `#e67e00` |
| Major drift / stale / overdue | `#d32f2f` |
| Missing / not tracked | `#666666` |
| Header blue, links | `#0052CC` |

### Column widths

Set with a `<colgroup>` on every table.

Full comparison: Variance 8%, Feature 20%, Jira Key 7%, Stage 7%, Tier 4%, Cal Revised 8%,
Jira Date 8%, Revised vs Jira 10%, Cal Status 7%, Jira Status 8%, Note 13%.

Upcoming launches: Feature 31%, Jira 12%, Stage 12%, Cal Date 9%, Jira Date 9%, Jira Status 11%,
Variance 16%.

Disagreement segments: Feature 28%, Jira Key 13%, Stage 13%, Cal Revised 10%, Jira Date 10%,
Revised vs Jira 12%, Cal Status 8%, Note 6%.

There is no Cal Original column — the report compares current committed dates only.

### Segment row tints

The disagreement section is split by Jira status and each segment is tinted. Outlook drops
`background-color` from a style attribute in some configurations, so set **both** the legacy
`bgcolor` attribute and the inline `background-color` on every `<td>`:

| Segment | Hex | Heading color |
|---|---|---|
| In Progress | `#E8F5E9` | `#2e7d32` |
| Blocked | `#FFEBEE` | `#d32f2f` |
| Done | `#E3F2FD` | `#0052CC` |

Tint the whole row, not one cell — a single tinted cell reads as a data point rather than a
grouping. The variance figure inside a tinted cell keeps its own red or amber text color; the
tint carries status, the text carries magnitude, and the two are different questions.

On the canvas these map to `Table`'s `rowTone`: `success`, `danger`, `info` respectively.

## Failure modes seen in practice

| Symptom | Cause | Fix |
|---|---|---|
| WorkIQ returns a CSV link instead of a table | More than ~20 rows and no explicit inline instruction | Keep "do not produce a CSV file" in the prompt; the gateway URL needs auth and cannot be fetched |
| WorkIQ answers with prose about the list | The list URL was not passed in `fileUrls` | Always anchor the call with `fileUrls` |
| Jira set looks short | `jira_search` caps at 50 and `limit: 100` silently returns 50 rather than erroring | Page it: call with `start_at: 0`, read `total`, call again with `start_at: 50` |
| Every `NFSAAS` lookup 404s | Cloud Jira tools used instead of `user-jira_oss` | Switch MCP servers |
| A date field comes back absent rather than null | The field is not on the Initiative screen | Only `customfield_25618` is reliable; see above |
| Revised equals Original on many rows | WorkIQ back-fills empty Revised cells from Original unless told not to | Demand the literal word `BLANK` for empty cells; a false rebaseline corrupts the Revised-vs-Jira column |
| Every multi-stage feature lands in Ambiguous | `Disclosure Level` was not requested in Step 1 | Ask for it by full name; there is no column called `Stage` |
