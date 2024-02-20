# GitHub runner script

This directory contains a script `github-runner.sh` that will create an Azure Container App that can be used as a self-hosted GitHub runner.

It accepts the following arguments:

1. The name of the Azure Container App to create.

## Prerequisites

- [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) - to create Azure resources:

    ```console
    winget install Microsoft.AzureCLI
    ```

- Azure role `Contributor` at the subscription scope.

## References

- [Deploy self-hosted CI/CD runners and with Azure Container Apps jobs](https://learn.microsoft.com/en-us/azure/container-apps/tutorial-ci-cd-runners-jobs?tabs=bash&pivots=container-apps-jobs-self-hosted-ci-cd-github-actions)
