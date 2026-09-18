---
name: anf-launch-date-audit
description: >-
  Weekly audit that compares launch dates in the ANF Launch Calendar SharePoint list
  (Original Release Date and Revised Release Date) against the Customer announcement date
  on NFSAAS Jira Initiatives, and emails an executive report showing every date that does
  not match. Leads with an At a Glance panel (overdue, due in 7 / 30 / 60 days), then
  Upcoming Launches, then the full comparison table. Use when the user types /launchaudit
  or asks for the weekly launch date audit, launch calendar audit, launch date mismatch
  report, SharePoint vs Jira date comparison, or launch date variance report.
---

# ANF Launch Date Audit

Weekly reconciliation of two systems that both claim to hold ANF launch dates:

| System | Holds | Read via |
|---|---|---|
| **ANF Launch Calendar** (SharePoint list) | `Original Release Date*`, `Revised Release date (if applicable)`, `Status` | `user-workiq` → `ask_work_iq` |
| **NFSAAS Jira Initiatives** (ngage Data Center) | `Customer announcement date` (`customfield_25618`) | `user-jira_oss` → `jira_search` |

The audit answers one question: **where do these two disagree?**

Jira has no Original/Revised pair — it stores a single current date. So the comparison is
always *SharePoint effective date* vs *Jira current date*. See "Date semantics" below.

## Workflow

```
- [ ] Step 1: Pull the SharePoint launch calendar
- [ ] Step 2: Pull the Jira initiative set
- [ ] Step 3: Match calendar rows to Jira initiatives
- [ ] Step 4: Classify each pair's date variance
- [ ] Step 5: Build the report (At a Glance → Upcoming → Table)
- [ ] Step 6: Email it
- [ ] Step 7: Save the snapshot
```

Never fabricate a date, a match, or a Jira key. Anything that cannot be resolved goes in the
**Unmatched** section, not into the table with a guessed value.

---

### Step 1: Pull the SharePoint launch calendar

Call `ask_work_iq` with the list page anchored in `fileUrls`. Passing the URL in `fileUrls` is
what makes WorkIQ read the list itself rather than search for prose about it — without it the
call returns a vague summary.

```
fileUrls: ["https://netapp.sharepoint.com/sites/CloudStorage/Lists/ANF%20Launch%20Calendar/Whats%20Next.aspx"]
```

```
From the ANF Launch Calendar SharePoint list, output ONE inline markdown table. Do NOT produce
a CSV file and do NOT give me a download link - output every matching row inline, however many
there are.

Include ONLY rows where Status is NOT "Launched".

Columns, in this exact order:
ID | Feature Name | Disclosure Level (private, public preview or GA) | Original Release Date* |
Revised Release date (if applicable) | Status | Launch Type

Rules:
- Report each date EXACTLY as stored, in YYYY-MM-DD form.
- If "Revised Release date (if applicable)" is empty for a row, write the literal word BLANK.
  Never copy the Original Release Date into the Revised column.
- If "Disclosure Level" is empty for a row, write the literal word BLANK.
- Sort by Feature Name ascending. At the end state the total row count.
```

Four rules that keep this reliable:

1. **Ask for `Disclosure Level` by its full name.** The list has *no* column called `Stage`, but
   `Disclosure Level (private, public preview or GA)` holds exactly that value, and it is what
   makes stage matching in Step 3 deterministic. Omit it and every multi-stage feature collapses
   into a false ambiguity. WorkIQ will happily relabel it "Stage" in its output — that is a
   rendering convenience, not a schema field, so always request the real name.
2. **Demand `BLANK` for empty Revised cells.** Asked loosely, WorkIQ back-fills the Revised
   column with the Original date. That silently invents a rebaseline that never happened and
   corrupts the Revised-vs-Jira column, which is the one number the report exists to show.
3. **Demand the table inline.** Above ~20 rows WorkIQ defaults to uploading a CSV to a Teams
   async-gateway URL that cannot be fetched without auth. The "do not produce a CSV file"
   instruction is load-bearing.
4. **Trust the row count it reports.** If the returned row count and the actual table rows
   disagree, re-ask in two halves (Status = "On Track", then everything else) and merge.

Pull `ID` as well. It is the only stable row identifier — titles repeat across stages — so cite
it when reporting a finding and use it to disambiguate in `alias-map.json`.

Excluding `Launched` items is deliberate — the list carries years of shipped history and a
launched feature's date no longer needs reconciling. If the user asks for a full audit,
drop the Status filter and ask for all items.

### Step 2: Pull the Jira initiative set

`NFSAAS` lives on **ngage Jira Data Center**. Use `user-jira_oss`. Atlassian Cloud Jira tools
cannot see these keys.

```
project = NFSAAS AND issuetype = Initiative AND cf[25618] is not EMPTY
ORDER BY cf[25618] ASC
```

Request these fields:

| Field | ID |
|---|---|
| Customer announcement date | `customfield_25618` |
| Customer Facing Name | `customfield_29903` |
| Stage | `customfield_22400` |
| Tier | `customfield_29902` |
| Target Release Version | `customfield_20602` |
| Summary, Status | `summary,status` |

The scope is **portfolio-wide**, not one TPM's features — the calendar covers all of ANF, so
scoping Jira to `"TPM Feature Owner" in (currentUser())` leaves most calendar rows unmatched and
hides real drift on features owned by others. Add that clause back only if the user asks for a
personal view.

`jira_search` caps `limit` at 50 and the set runs past that (56 on the 2026-09-18 run), so
**page it**: call once with `start_at: 0`, read `total` from the response, then call again with
`start_at: 50`. Requesting `limit: 100` does not error, it silently returns 50.

**Exclude** initiatives whose status category is Done *and* whose status name is `Cancelled` —
cancelled work has no launch to reconcile. Keep `Done` initiatives: a Done initiative still
sitting on the calendar as "On Track" is exactly the kind of drift this audit exists to catch.

### Step 3: Match calendar rows to Jira initiatives

This is the fragile part. Work through the strategies in order and stop at the first hit.

1. **Override map.** Read `~/anf-launch-date-audit/alias-map.json` and apply any
   `calendar title (+ stage)` → `Jira key` entry first. This map is the accumulated human
   judgment from prior runs; it always wins.
2. **Exact summary match** on the normalized calendar title vs the Jira `summary`.
3. **Customer Facing Name + Stage.** Normalize the calendar title, strip any trailing stage
   suffix, and match the remainder against `customfield_29903`; then match the calendar's
   `Disclosure Level` against `customfield_22400`.
4. **Fuzzy name + Stage.** Same as above with token-overlap matching, to absorb real drift
   such as calendar "Top clients/files for volume IOPS metrics" vs Jira "Top K clients/files
   for volume IOPS metrics", or calendar "Cache origin volumes" vs Jira "ANF origin volumes".

**Stage is the tiebreaker, and `Disclosure Level` is where it lives.** A feature that ships in
phases appears once per stage in *both* systems, so name alone always ties. Never break that tie
by date proximity — pairing each Jira initiative with the nearest calendar date is what inverted
the two "Top clients/files" rows on the 2026-09-18 run, because the calendar's Private Preview
date (7/09) had already slipped past the Public Preview one (7/14). Match on stage, then report
whatever date gap falls out, however implausible it looks.

Normalization before comparing: lowercase, collapse whitespace, strip `ANF` prefix, strip
trailing punctuation, and treat `-`/`–`/`—` as equivalent separators.

Stage vocabulary — the calendar and Jira spell these differently:

| Calendar text | Jira `customfield_22400` |
|---|---|
| `Private Preview`, `Private preview`, `PrP` | `Private Preview` |
| `Public Preview`, `Public preview`, `PuP` | `Public Preview` |
| `GA`, `General Availability` | `GA` |

**When `Disclosure Level` is blank** on a repeated title, do not guess. Report it once under
**Ambiguous** with every candidate Jira key listed, and ask the user to resolve it. When they
do, write the decision into `alias-map.json` so the next run resolves it silently. Reach for
this only after `Disclosure Level` has genuinely come back empty — with that column pulled, a
run should normally resolve every pairing outright.

Anything still unresolved is reported, never dropped:

- **Unmatched calendar rows** — on the calendar, no Jira initiative found.
- **Unmatched Jira initiatives** — in Jira with a launch date, absent from the calendar.

### Step 4: Classify each pair's date variance

**Date semantics.** The calendar's effective date is `Revised Release Date` when present,
otherwise `Original Release Date`. Compare that to Jira's `customfield_25618`. Variance is
signed: positive means Jira is *later* than the calendar (a slip Jira knows about and the
calendar does not).

| Badge | Condition |
|---|---|
| 🟢 Aligned | Dates identical |
| 🟡 Minor drift | 1–7 days apart |
| 🟠 Drift | 8–30 days apart |
| 🔴 Major drift | More than 30 days apart |
| 🔴 Jira stale | Calendar has a Revised date, and Jira still equals the *Original* |
| ⚪ No Jira date | Matched, but `customfield_25618` is empty |
| ⚪ Not on calendar | Jira has a date, no calendar row matched |

`Jira stale` outranks the day-count badges — it is a specific, actionable finding (someone
rebaselined the calendar and never updated Jira), so classify it first and only fall through
to the day-count buckets when it does not apply.

**Closed vs overdue.** A past date does not mean late. Treat an initiative as **closed** when
its Jira status category is `Done` or the calendar says `Launched`; it shipped, and its date
needs no chasing. Only a past date on a *live* initiative is **overdue**. Getting this
backwards turns the headline number into noise — on a typical run most past-dated
initiatives are simply closed.

Also flag, as a note on the row rather than a badge:

- **Status conflict** — Jira status is `Done` or `Cancelled` while the calendar still says
  `On Track` or `At Risk`. This is the most common real finding: engineering closed the work
  and nobody updated the customer-facing calendar.
- **Stage collision** — a Jira date matches a *different* stage's calendar row exactly. It
  usually means one of the two systems has the stage labelled wrong, and it is easy to miss
  because each row looks self-consistent.

### Step 5: Build the report

Three sections, in this order. Lead with the numbers; detail comes after.

**1. At a Glance** — a single row of count tiles, computed from the *reference date* (the
calendar effective date; Jira's date when there is no calendar row). Closed initiatives are
excluded from the date buckets and counted on their own tile:

| Tile | Definition |
|---|---|
| Overdue | Reference date before today, **and not closed** |
| Due ≤ 7 days | Today through today + 7 |
| Due ≤ 30 days | Today + 8 through today + 30 |
| Due ≤ 60 days | Today + 31 through today + 60 |
| Beyond 60 days | Later than today + 60 |
| Closed | Jira status category `Done`, or calendar `Launched` |
| **Revised ≠ Jira** | Of the rows carrying a Revised date, how many disagree with Jira |

The five date buckets plus Closed are exclusive and sum to the tracked total. State the total
and the run date directly beneath the tiles.

Render the last tile as a fraction (`6 of 6`), not a bare count. The denominator is what gives
it meaning: six mismatches out of six rows is a broken process, six out of forty is routine
drift, and a bare "6" cannot tell those apart.

**2. Upcoming Launches** — every live feature that is overdue or lands inside the next 60 days,
sorted by reference date ascending. This is the "what is actually coming" view, so keep it short
enough to read without scrolling. Columns in this order:

Feature, Jira Key, Stage, Cal Date, Jira Date, Jira Status, Variance.

The feature name leads, not the date. The two date columns sit adjacent so the eye compares them
without crossing the row, and `Stage` sits immediately before them because a date only means
something once you know which stage it belongs to.

**3. Where Cal Revised and Jira Date disagree** — the heart of the report. Take every
calendar-matched initiative whose dates do not agree (`Revised vs Jira` is anything other than
`Match`) and **split it into three status segments, in this order: In Progress, Blocked, Done.**
Each segment gets its own heading with a count, a one-line explanation of what that group means,
and its own table sorted by gap size descending. Where the calendar has no Revised date, sort on
the gap against the original instead, so the biggest exposure still leads.

Tint every row in a segment by its Jira status:

| Segment | Row tint | Canvas `rowTone` | Reads as |
|---|---|---|---|
| In Progress | Light green `#E8F5E9` | `success` | In flight — chase these |
| Blocked | Light red `#FFEBEE` | `danger` | Stuck — escalate |
| Done | Light blue `#E3F2FD` | `info` | Shipped — calendar hygiene, not schedule risk |

Segment columns: Feature, Jira Key, Stage, Cal Revised, Jira Date, Revised vs Jira, Cal Status,
Note. **Drop the Jira Status column inside a segment** — the segment heading already carries it.
Keep `Cal Status`, because the whole point of the Done segment is that Jira says shipped while the
calendar still says On Track. Fold the per-row flags (`Overdue`, `No revised date (orig …, N d)`,
`Stage collision`) into the Note column.

Segmenting this way separates two problems that look identical in a flat table but need different
owners: a Done row with a 72-day gap is somebody forgetting to close a calendar entry, while an
In Progress row with the same gap is a date nobody has renegotiated with the customer.

**4. Full comparison table** — all tracked features, sorted by reference date ascending. This is
the reference view, so default its filter to *all* rather than to mismatches; the segmented
section above already isolates those.

| # | Column | Source |
|---|---|---|
| 1 | Variance | Step 4 badge |
| 2 | Feature | Calendar `Feature Name` |
| 3 | Jira Key | Linked to `https://jira.ngage.netapp.com/browse/<KEY>` |
| 4 | Stage | `customfield_22400` |
| 5 | Tier | `customfield_29902` |
| 6 | Cal Revised | `Revised Release date (if applicable)` |
| 7 | Jira Date | `customfield_25618` |
| 8 | **Revised vs Jira** | Signed days, Jira minus `Cal Revised` |
| 9 | Calendar Status | SharePoint `Status` |
| 10 | Jira Status | Jira `status.name` |
| 11 | Note | Status conflict / stage collision / blank |

**Do not show a Calendar Original column.** The audit's question is whether the *current*
committed dates agree, and the original is only scaffolding for deriving the effective date.

Column 8 is the point of the report, so keep it literal — it compares `Cal Revised` against
`Jira Date` and nothing else:

| Cell | When |
|---|---|
| `Match` | Revised date equals the Jira date |
| `+N d` / `−N d` | Revised date is set and differs; positive means Jira is later |
| `No revised date` | A calendar row matched but that cell is blank, so the original still stands |
| `—` | No calendar row matched at all |

For a `No revised date` row the calendar is still effectively promising the original date, so
put that comparison in the Note (`"original 10/29 is 2 days after Jira"`) rather than dropping
it. Report how many of the rows that *do* carry a Revised date disagree, as a fraction — "6 of
6 disagree" lands far harder than six scattered row badges.

Follow the table with **Unmatched** and **Ambiguous** lists. Close with up to five executive
bullets covering only red and yellow items: the largest variances, the stale-Jira findings,
the overdue items, and the decisions needed. Do not narrate the aligned rows, and do not
include a week-over-week diff section.

### Step 6: Email it

Send with `user-smtp` → `smtp_send_email`, `is_html: true`, header
`X-SMTP-From: kiran.guleria@netapp.com`. Default recipient `kguleria@netapp.com`; ask before
adding anyone else.

Subject: `ANF Launch Date Audit – <Month DD, YYYY>`

Use [email-template.html](email-template.html) as the structural reference. Replace the data,
never the structure. The formatting rules there are not cosmetic — they are what keeps the
report readable after Outlook forwards and replies. See
[reference.md](reference.md) for the full rendering rules and the rationale behind each.

### Step 7: Save the snapshot

After a successful send, overwrite `~/anf-launch-date-audit/last-audit.json`:

```json
{
  "run_date": "YYYY-MM-DD",
  "features": {
    "NFSAAS-60610": {
      "title": "...", "stage": "...", "calendar_original": "YYYY-MM-DD",
      "calendar_revised": "YYYY-MM-DD", "jira_date": "YYYY-MM-DD",
      "delta_days": 0, "badge": "...", "calendar_status": "...", "jira_status": "..."
    }
  }
}
```

The snapshot is a **record, not a report section**. Keep writing it — it costs nothing and
preserves the history — but do not render a "What changed since last run" block in the email or
on screen. Read it only when the user explicitly asks what moved since last week.

**Only write the snapshot after the email actually sends.** If the user previews without
sending, leave the previous snapshot in place so the next real run still has a valid baseline.

---

## Running it weekly

The intended cadence is **every Monday at 8:00 AM**, ahead of the week's feature readiness
meetings, so the mismatches are on the table before commitments get repeated. The skill is
stateless apart from `alias-map.json` and `last-audit.json`, so a run is just `/launchaudit`.

Three ways to make it recur:

- **Cursor Automation** (preferred) — a scheduled automation on `0 8 * * 1`. Create it from the
  Agents Window with the `automate` skill; the Automations editor handoff is unavailable in a
  normal chat window, so this cannot be set up from an ordinary session.
- **In-session**: `/loop 7d /launchaudit`, which lasts only as long as the session.
- **Unattended**: a macOS LaunchAgent, same pattern as
  `~/anf-plr-weekly-report/com.netapp.anf-plr-report.plist`. Not installed by default — ask
  before creating one.

A Monday run reads whatever the calendar and Jira say that morning. It does not need the
previous snapshot to produce a report, so a missed week costs nothing but the diff.

## Files

| Path | Purpose |
|---|---|
| `alias-map.json` (this directory) | Seed override map, copied to the working directory on first run |
| [email-template.html](email-template.html) | Canonical HTML structure for the email |
| [reference.md](reference.md) | Field IDs, email rendering rules, worked matching examples |
| `~/anf-launch-date-audit/alias-map.json` | Live override map, edited as ambiguities get resolved |
| `~/anf-launch-date-audit/last-audit.json` | Previous run snapshot, kept as a record; read only on request |

## Scope boundary

This skill **reads only**. It never edits a Jira issue, a SharePoint item, or a Confluence
page. When the audit finds a mismatch, it reports it and names the decision needed — a human
decides which system is wrong.

Distinct from `Weekly-Ring` (the weekly PLR feature readiness status report) and
`anf-plr-readiness-tracking-page` (which creates per-feature PLR pages). This skill compares
dates across two systems and does nothing else.
