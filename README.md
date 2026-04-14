# ANF Feature Readiness Skills

Cursor AI skills for automating ANF Feature Readiness Plans, Initiative Hubs, and Weekly PLR Reports.

## Skills

| Skill | Description |
|---|---|
| **feature-readiness-plan** | Creates a Feature Readiness Plan (Private Preview / Public Preview / GA) from a Jira issue, calculates milestone dates, populates owners, publishes to Confluence |
| **feature-readiness-hub** | Creates an Initiative-level parent page in Confluence that groups all feature plans under one initiative |
| **Weekly-Ring** | Generates the weekly PLR meeting report - Confluence page + HTML email with the full feature table |

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
