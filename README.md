# ops-actions

![release workflow status badge](https://github.com/equinor/ops-actions/actions/workflows/release.yml/badge.svg?event=push&branch=main)

[Reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) for GitHub Actions, maintained by the [Ops team](https://github.com/orgs/equinor/teams/ops).

## Prerequisites

### OpenID Connect

For reusable workflows that login to Azure, run [this script](./scripts/oidc/) to configure OpenID Connect for the repository containing the caller workflow.
