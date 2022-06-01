# Scenario #1: Creating a WAF Policy


## Pre-requisites

**on the BIG-IP:**

- [ ] version 15.1 minimal
- [ ] credentials with REST API access


**on Terraform:**

- [ ] use of F5 bigip provider version 1.14.0 minimal
- [ ] use of Hashicorp version followinf [Link](https://clouddocs.f5.com/products/orchestration/terraform/latest/userguide/overview.html#releases-and-versioning)



## Policy Creation

Create 3 files:
- main.tf
- variables.tf
- inputs.tfvars



**variables.tf**
```terraform
variable bigip {}
variable username {}
variable password {}
```

**inputs.tfvars**
```terraform
bigip = "10.1.1.9:8443"
username = "admin"
password = "yYyYyYy"
```

**main.tf**
```terraform
terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.14"
    }
  }
}
provider "bigip" {
  address  = var.bigip
  username = var.username
  password = var.password
}

resource "bigip_waf_policy" "this" {
  name                 = "/Common/scenario1"
  template_name        = "POLICY_TEMPLATE_RAPID_DEPLOYMENT"
  application_language = "utf-8"
  enforcement_mode     = "blocking"
  server_technologies  = ["MySQL", "Unix/Linux", "MongoDB"]
}
```

Now that you have your terraform project all set up, you can run it:

```console
foo@bar:~$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding f5networks/bigip versions matching "1.14.0"...
- Installing f5networks/bigip v1.14.0...
- Installed f5networks/bigip v1.14.0 (signed by a HashiCorp partner, key ID 0F284A6527D73A63)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario1

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # bigip_waf_policy.this will be created
  + resource "bigip_waf_policy" "this" {
      + application_language = "utf-8"
      + case_insensitive     = false
      + enable_passivemode   = false
      + enforcement_mode     = "blocking"
      + id                   = (known after apply)
      + name                 = "/Common/scenario1"
      + policy_export_json   = (known after apply)
      + policy_id            = (known after apply)
      + server_technologies  = [
          + "MySQL",
          + "Unix/Linux",
          + "MongoDB",
        ]
      + template_name        = "POLICY_TEMPLATE_RAPID_DEPLOYMENT"
      + type                 = "security"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: scenario1

To perform exactly these actions, run the following command to apply:
    terraform apply "scenario1"

foo@bar:~$ terraform apply "scenario1"
bigip_waf_policy.this: Creating...
bigip_waf_policy.this: Still creating... [10s elapsed]
bigip_waf_policy.this: Creation complete after 17s [id=41UMLL7yDtzoa0000Wimzw]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Now, your WAF Policy might evolve over time. You  may want to add entities, manage  attack signature exceptions...

## Policy lifecycle management

Create a **parameters.tf** file:

```terraform
data "bigip_waf_entity_parameter" "P1" {
  name            = "Parameter1"
  type            = "explicit"
  data_type       = "alpha-numeric"
  perform_staging = true
}

data "bigip_waf_entity_parameter" "P2" {
  name            = "Parameter2"
  type            = "wildcard"
  data_type       = "alpha-numeric"
  perform_staging = false
  signature_overrides_disable = [200001494, 200001472]
}

data "bigip_waf_entity_parameter" "P3" {
  name            = "Parameter3"
  type            = "explicit"
  data_type       = "alpha-numeric"
  is_header	  = true
  sensitive_parameter = true
  perform_staging = true
}
```

And add references to these parameters in the **"bigip_waf_policy"** TF resource in the **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
  name                 = "/Common/scenario1"
  template_name        = "POLICY_TEMPLATE_RAPID_DEPLOYMENT"
  application_language = "utf-8"
  enforcement_mode     = "blocking"
  server_technologies  = ["MySQL", "Unix/Linux", "MongoDB"]
  parameters           = [data.bigip_waf_entity_parameter.P1.json, data.bigip_waf_entity_parameter.P2.json, data.bigip_waf_entity_parameter.P3.json]
}
```

run it:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario1
bigip_waf_policy.this: Refreshing state... [id=41UMLL7yDtzoa0000Wimzw]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # bigip_waf_policy.this will be updated in-place
  ~ resource "bigip_waf_policy" "this" {
        id                   = "41UMLL7yDtzoa0000Wimzw"
        name                 = "/Common/scenario1"
      + parameters           = [
          + jsonencode(
                {
                  + dataType       = "alpha-numeric"
                  + name           = "Parameter1"
                  + performStaging = true
                  + type           = "explicit"
                }
            ),
          + jsonencode(
                {
                  + dataType           = "alpha-numeric"
                  + name               = "Parameter2"
                  + signatureOverrides = [
                      + {
                          + enabled            = false
                          + signatureReference = {
                              + signatureId = 200001494
                            }
                        },
                      + {
                          + enabled            = false
                          + signatureReference = {
                              + signatureId = 200001472
                            }
                        },
                    ]
                  + type               = "wildcard"
                }
            ),
          + jsonencode(
                {
                  + dataType           = "alpha-numeric"
                  + isHeader           = true
                  + name               = "Parameter3"
                  + performStaging     = true
                  + sensitiveParameter = true
                  + type               = "explicit"
                }
            ),
        ]
        # (9 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: scenario1

To perform exactly these actions, run the following command to apply:
    terraform apply "scenario1"

foo@bar:~$ terraform apply "scenario1"
bigip_waf_policy.this: Modifying... [id=41UMLL7yDtzoa0000Wimzw]
bigip_waf_policy.this: Still modifying... [id=41UMLL7yDtzoa0000Wimzw, 10s elapsed]
bigip_waf_policy.this: Modifications complete after 17s [id=41UMLL7yDtzoa0000Wimzw]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

Of course, what we have done by adding parameters in the **parameters.tf** file can also be done with URLs, filetypes and attack signatures using the data sources and resources defintions as it is documented in the [bigip terraform provider official documentation](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs).
