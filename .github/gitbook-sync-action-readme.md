# Gitbook Sync Action

This action is used in `release.yaml` and is run after new charts have been released.

<!-- TOC -->

- [Gitbook Sync Action](#gitbook-sync-action)
  - [Prequisites](#prequisites)
  - [Process](#process)
    - [get-current-chart-release-versions](#get-current-chart-release-versions)
    - [Create_pr](#create_pr)
  - [Dev Stuff](#dev-stuff)
    - [Modify Different Branches](#modify-different-branches)
    - [Deploy Token](#deploy-token)

<!-- /TOC -->

## Prequisites

- github deploy token
- helm repo with published charts
- github account, destination repo and source repo (this is source)
- book.json in destination repo

## Process

### get-current-chart-release-versions

This job will look at a helm repo and parse the info into a file `chart-versions.json` this will be of the form:

```json
{
    "chart1_name": "1.2.3",
    "chart2_name": "2.3.4",
    "chart3_name": "3.4.5"
}
```

This job will pull in **all** charts in that repo.  This allows the next job to be dynamically built out if we add charts.

> Note this workflow does not include dev charts.
> This job also strips the repo away from the name since `helm search repo x` stores the name as `<local_repo>/<chart_name>` (ex: `greymatter/fabric`).
> This chart replaces `agent` and `server` with `spire_agent` and `spire_server` as those are the variables used in the gitbook repo.

The chart is passed from one runner to another runner by storing it in an artifact `chart-versions`

### Create_pr

Here is where the super fancy stuff begins.  This job pulls in the destination repo, rebuilds `book.json` using the versions we sourced in the prior job.  If there are any changes the job then creates a branch and pr in the gitbook repo.

## Dev Stuff

Since the first job gets all the charts in the repo we can quickly expand the variables published to gitbook.  To do so, update gitbook with a key, add that key to the `CHARTS` environment variable in the `create_pr` job (space separated array).  If the chart name matches the variable name in gitbook then you're good; otherwise, you'll need to add a `sed` in the `get-current-chart-release-versions` job to massage the `chart-versions.json` artifact.  If the key is in `cts` but not in gitbook any changes will not be reflected in the destination repo pr.

### Modify Different Branches

If you want to use this workflow with a non default branch then set the `BRANCH_TO_UPDATE` to the desired branch in the `create_pr` job.

### Deploy Token

To get this to work you will need to add a deploy token to your pushing repo:

- click your profile in github then settings > developer settings > personal access tokens
- create a new token with "write:packages" and "repo" and "read:org"
- copy the generated token
- in the pushing repo go to settings > secrets > New repository secret and create a secret "deploy_token" and paste in the generated toke from the last step
- in the github action reference it with `${{ secrets.deploy_token }}.
