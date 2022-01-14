# Virtual machine extensions and features for Linux

### CrowdStrike Falcon Install - Terraform Implementation

Create a file `<filename>.tfvars`

Add the following to the file

NOTE: You may also choose to use environment variables as TF_VAR_<variable_name>

```code
cid = "<FALCON_Customer_ID>"

client_id  = "<FALCON_CLIENT_ID>"

client_secret = "FALCON_CLIENT_SECRET"

instance_name = "unique_instance_name"

```

Apply the template

```terraform
terraform init
```
Output
```text

Initializing the backend...

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.random: version = "~> 3.1"
* provider.tls: version = "~> 3.1"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
```terraform
terraform apply -var-file=<filename>.tfvars
```