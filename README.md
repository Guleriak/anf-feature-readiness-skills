# ANF Feature Readiness Skills

Cursor AI skills for automating ANF Feature Readiness Plans, Initiative Hubs, and Weekly PLR Reports.

## Skills

| Skill | Description |
|---|---|
| **jira-automation-anf-feature-clc** | Creates the Feature Readiness Tracker Epic and child Stories in ngage Jira, then publishes or updates the PLR tracking page |
| **anf-plr-readiness-tracking-page** | Creates one Confluence PLR tracking page per feature under the ANF PLR Dashboard; Feature Readiness Status Summary comes from the parent Initiative |
| **feature-readiness-plan** | Creates a Feature Readiness Plan (Private Preview / Public Preview / GA) from a Jira issue, calculates milestone dates, populates owners, publishes to Confluence |
| **feature-readiness-hub** | Creates an Initiative-level parent page in Confluence that groups all feature plans under one initiative |
| **Weekly-Ring** | Generates the weekly PLR meeting report - Confluence page + HTML email with the full feature table |
| **anf-functional-spec** | Builds/updates the ANF Functional Spec & Approval Tracker on Confluence from the PLR Dashboard and NFSAAS Jira initiatives - pending CSA/MSFT approvers, cycle-time metrics, Done/In Progress/At Risk status, optional email digest |
| **anf-launch-date-audit** | Weekly Monday audit comparing launch dates in the ANF Launch Calendar (SharePoint) against the Customer announcement date on NFSAAS Jira Initiatives - flags every date the two systems disagree on, grouped by Jira status, and emails an executive report. Read-only |

## Quickstart

```bash
git clone https://github.com/Guleriak/anf-feature-readiness-skills.git ~/.cursor/skills
```

See [SETUP-GUIDE.md](SETUP-GUIDE.md) for full installation and configuration instructions.

## Additional Files

| Path | Purpose |
|---|---|
| `rules/weekly-ring-report.mdc` | Formatting and consistency rules for the weekly report (install to `~/.cursor/rules/`) |
| `install-skills.sh` | Helper script to install skills and rules to the correct paths |
