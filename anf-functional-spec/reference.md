# Reference – Sample JQL & Snippets

Server JIRA base for all links: `https://jira.ngage.netapp.com/browse/<KEY>`

## 0. Derive the feature set from the PLR Dashboard (authoritative)
Confluence CQL (via `searchConfluenceUsingCql`), then exclude pages whose title contains `Template`:
```
label in ("feature-plr-apr-sept2026", "feature-plr-kr") order by title
```
Canonical dashboard page: `138147845` (space `ANF`). The `detailssummary` macro on that page holds the live label list – re-read it (adf format) if labels may have changed. Take the NFSAAS key from each page's JIRA field / public-name match.

### Verified initiative keys (fallback snapshot – last verified 2026-06-16, 20 features)
```
key in (
  NFSAAS-144193, NFSAAS-92177, NFSAAS-143712, NFSAAS-92295, NFSAAS-134506,
  NFSAAS-153531, NFSAAS-146169, NFSAAS-60559, NFSAAS-122270, NFSAAS-123068,
  NFSAAS-61898, NFSAAS-60610, NFSAAS-131018, NFSAAS-133040, NFSAAS-47661,
  NFSAAS-151267, NFSAAS-134793, NFSAAS-47957, NFSAAS-136602, NFSAAS-155269
)
```
> Excluded (NOT on the dashboard): NFSAAS-133033, NFSAAS-136160, NFSAAS-130277, NFSAAS-104569, NFSAAS-134065, NFSAAS-105262, NFSAAS-77386. Template page `138155651` is always excluded.

## 1. Fetch PLR initiatives
```
key in (NFSAAS-92295, NFSAAS-153531, ...)
```
Fields: `summary, customfield_29903, customfield_22400, customfield_24204, customfield_22314, customfield_25618, created, status`
> Do NOT `ORDER BY customfield_25618` – it errors when values are null. Sort client-side.

## 2. Batch-fetch CSA approval tickets
```
key in (CSA-628, CSA-1096, CSA-1218, ...)
```
Fields: `summary, status, created, customfield_14300, customfield_17000`
- `customfield_14300` = required approvers (usernames)
- `customfield_17000` = approvers who signed off
- **Pending = 14300 minus 17000**

## 3. Find Microsoft FS-review tickets (ANF project)
```
project = ANF AND summary ~ "Dependency Microsoft Owner" AND (summary ~ "<feature keyword>" OR ...) ORDER BY created DESC
```
Fields: `summary, status, created, resolutiondate, assignee, comment` (+ `changelog` via `jira_get_issue` for assignment / Blocked dates)
- `assignee` = Microsoft owner (Adel, Jitesh, Paulo, Kevin, Phil, ...)
- Pending = status not Done.
- Resolution/cycle time = `resolutiondate – created`; open tickets show current age.

## 4. Resolve a username
`jira_get_user_profile(user_identifier="aambasth")` -> display name.

### Username cache (extend as needed)
| user | display |
|------|---------|
| aambasth | Aditya Ambasth |
| minara | Minar Aware |
| bsridhar | Sridhar Balasubramanian |
| howen | Owen Hughes |
| rajeshk | Rajesh Khandelwal |
| rthorne | Robert Thorne |
| sneil | Neil Stanley |
| luces | Sean Luce |
| krzysztj | Krzysztof Jakimiak |
| mossa | Alan Moss |
| diugas | Dziugas Eiva |
| rakesh8 | Rakesh Kumar |
| dylanl | Dylan Leahy |
| roliveir | Robert Oliveira |
| kaman | Aman Kohli |
| nsanwali | Nidhi Sanwalia |
| vkondapa | Jagan Kondapalli |
| rujuta | Rujuta Antarkar |
| xiaoweic | Xiaowei Chu |
| adityas4 | Aditya Sheth |
| amritb | Amrit Bhatia |
| sbartosz | Bartosz Sypniewski |
| amaurya | Abhishek Maurya |
| vaibhavn | Vaibhav Nagvekar |
| pnanto | Patrick Nanto |
| ksaravan | Saravana Kumar K |

## 5. Link snippets
Confluence (interactive smart link):
```html
<a href="https://jira.ngage.netapp.com/browse/CSA-1265" data-card-appearance="inline">CSA-1265</a>
```
Email (plain link – smart links do not render in email):
```html
<a href="https://jira.ngage.netapp.com/browse/CSA-1265" style="color:#0052cc;text-decoration:none;font-weight:600;">CSA-1265</a>
```
