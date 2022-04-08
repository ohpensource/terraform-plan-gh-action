# TERRAFORM-PLAN-GH-ACTION

Repository containing Ohpen's Github Action to plan Terraform configuration with Ohpen standard.

- [TERRAFORM-PLAN-GH-ACTION](#TERRAFORM-PLAN-GH-ACTION)
  - [code-of-conduct](#code-of-conduct)
  - [github-action](#github-action)

## code-of-conduct

Go crazy on the pull requests :) ! The only requirements are:

> - Use _conventional-commits_.
> - Include _jira-tickets_ in your commits.
> - Create/Update the documentation of the use case you are creating, improving or fixing. **[Boy scout](https://biratkirat.medium.com/step-8-the-boy-scout-rule-robert-c-martin-uncle-bob-9ac839778385) rules apply**. That means, for example, if you fix an already existing workflow, please include the necessary documentation to help everybody. The rule of thumb is: _leave the place (just a little bit)better than when you came_.

### github-action

This action performs a [_terraform plan_](https://www.terraform.io/cli/commands/plan) on the IAC that is specified. The (required) inputs are:

- _region_: aws region name.
- _access-key_: user access key to be used.
- _secret-key_: user secret key to be used.
- _terraform-folder_: folder where the terraform configuration is.
- _backend-configuration_: path of the tfvars file with backend configuration.
- _terraform-var-file_: tfvars file to use as variables input.
- _terraform-state-file_: File where terraform will write down the plan.

⚠️ Attention! Terraform will try to assume the deployment role in the destination AWS account. Such deployment will fail if the user is not allowed to assume such role.

Here is an example:

```yaml
name: CI
on:
  pull_request:
    branches: ["main"]
jobs:
  plan-team-branch-deployment:
    needs: [configure-team-branch-environment, download-artifacts]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/download-artifact@v2
        with:
          name: deployment-folder
          path: deployment-folder
      - uses: actions/download-artifact@v2
        with:
          name: deployment-team-branch-conf
          path: deployment-team-branch-conf
      - uses: ohpensource/terraform-plan-gh-action/action@0.0.0.1
        name: terraform plan
        with:
          region: $REGION
          access-key: $COR_AWS_ACCESS_KEY_ID
          secret-key: $COR_AWS_SECRET_ACCESS_KEY
          terraform-folder: "deployment-folder/terraform"
          backend-configuration: "deployment-team-branch-conf/backend.tfvars"
          terraform-var-file: "deployment-team-branch-conf/terraform.tfvars"
          terraform-state-file: "deployment-team-branch-plan/tfplan"
```
