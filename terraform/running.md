# Testing the Terraform Config Locally

The CI/CD build pipeline will create secrets and set environment variables to
config terraform for a specific environment

If you want to test the terraform configuration locally then you should create
`vars.env` file such as below:

```shell
export TF_VAR_azurermSubscriptionId=""
export TF_VAR_azurermClientId=""
export TF_VAR_azurermClientSecret=""
export TF_VAR_azurermTenantId=""
export TF_VAR_adminUsername=""
export TF_VAR_adminPassword=""
```

and '[source](https://bash.cyberciti.biz/guide/Source_command)' it to make the
variables available to the shell where you wish to run `terraform` like so
`source vars.env`. Environment variables starting with `TF_VAR_` will
automatically be assigned to terraform variables and can be accessed in the
config like so `var.adminPassword`.


### Using Windows

If you are using a windows system that does not support the [Windows Linux
Subsystem](https://docs.microsoft.com/en-us/windows/wsl/about) (WSL) or you
simply do not want to use WSL, then you can achieve a similar function by
creating a batch (.bat) file like so

```shell
set TF_VAR_azurermSubscriptionId=""
set TF_VAR_azurermClientId=""
set TF_VAR_azurermClientSecret=""
set TF_VAR_azurermTenantId=""
set TF_VAR_adminUsername=""
set TF_VAR_adminPassword=""
```

and 'sourcing' it like so `call env.bat`.

## Terraform State Backend

This terraform configuration uses an azure storage account to track the state of
the configured environment.

The initialisation of the terraform state backend occurs very early in the
terraform pipeline and therefore cannot uses variables, including those set with
`TF_VAR_`.

You must provide these arguments to the `terraform` command like so
```
terraform -backend-config="storage_account_name=<storage account name>" -backend-config="access_key=<storage account key>"
```