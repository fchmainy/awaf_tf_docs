# Scenario #5: Managing an A.WAF Policy with Policy Builder on a single device


## Goals
The goal of this lab is to manage Policy Builder Suggestions an A.WAF Policy on a single device or cluster. As the traffic flows through the BIG-IP, it is easy to manage suggestions from the Policy Builder and enforce them on the WAF Policy. It also shows what can be the management workflow:
 - the security engineer regularly checks the sugestions directly on the BIG-IP WebUI and clean the irrelevant suggestions.
 - once the cleaning is done, the terraform engineer (who can also be the security engineer btw) issue a terraform apply for the current suggestions. You can filter the suggestions on their scoring level (from 5 to 100% - 100% having the highest confidence level).
 - Every suggestions application can be tracked on Terraform and can easily be roll-backed if needed.

## Pre-requisites

**on the BIG-IP:**

 - [ ] version 15.1 minimal
 - [ ] A.WAF Provisioned
 - [ ] credentials with REST API access
 - [ ] an A.WAF Policy with Policy Builder enabled and Manual traffic Learning

**on Terraform:**

 - [ ] use of F5 bigip provider version 1.14.0 minimal
 - [ ] use of Hashicorp version followinf [Link](https://clouddocs.f5.com/products/orchestration/terraform/latest/userguide/overview.html#releases-and-versioning)


## Policy Creation

Create 4 files:

**variables.tf**
```terraform
variable prod_bigip {}
variable username {}
variable password {}
```

**inputs.tfvars**
```terraform
prod_bigip = "10.1.1.9:8443"
username = "admin"
password = "whatIsYourBigIPPassword?"
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
  alias    = "prod"
  address  = var.prod_bigip
  username = var.username
  password = var.password
}

data "http" "scenario5" {
  url = "https://raw.githubusercontent.com/fchmainy/awaf_tf_docs/main/4.multiple/lab/Common_scenario4__2022-6-2_13-38-14__production.f5demo.com.json?token=GHSAT0AAAAAABMHNSKUQZBAYO7NCJUZBEF6YUYUHVA"
  request_headers = {
  	Accept = "application/json"
  }
}

resource "bigip_waf_policy" "this" {
    provider	           = bigip.prod
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario5.body
}
```
*Note: the template name can be set to anything. When it is imported, we will overwrite the value*


**outputs.tf**
```terraform
output "policyId" {
	value	= bigip_waf_policy.this.policy_id
}

output "policyJSON" {
        value   = bigip_waf_policy.this.policy_export_json
}
```
Here, we are referencing an existing policy from a GitHub repository but it can also be created from zero on both BIG-IPs.

Now initialize, plan and apply your new Terraform project.
```console
foo@bar:~$ terraform init

foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario5

foo@bar:~$ terraform apply "scenario5"

```


===

## Simulate a WAF Policy workflow

Here is a typical workflow:
 1. the security engineer (yourself) regularly checks the sugestions directly on the BIG-IP WebUI and clean the irrelevant suggestions (the WAF Polciy we downloaded from the GitHub repo already contains Policy Builder suggestions so we do not have to generate traffic for this example).
 2. once the cleaning is done, the terraform engineer (also yourself :) ) creates a unique **bigip_waf_pb_suggestions** data source issue a terraform apply for the current suggestions. You can filter the suggestions on their scoring level (from 5 to 100% - 100% having the highest confidence level).

*Note: Every suggestions application can be tracked on Terraform and can easily be roll-backed if needed.*

### 1. Go to your BIG-IP WebUI and clean the irrelevant suggestions
:warning: **IMPORTANT** you can ignore suggestions but you should never accept them on the WebUI, otherwise you will then have to reconciliate the changes between the WAF Policy on the BIG-IP and the latest known WAF Policy in your terraform state.

For example, remove all the suggestions with a scoring = 1%

### 2. Use Terraform to enforce the policy builder suggestions


Create a **suggestions.tf** file:

the name of the **bigip_waf_pb_suggestions** data source should be unique so we can track what modifications have been enforced and when it was.

```terraform
data "bigip_waf_pb_suggestions" "03JUN20221715" {
  policy_name            = "scenario5"
  partition              = "Common"
  minimum_learning_score = 100
}

output "03JUN20221715" {
	value	= bigip_waf_pb_suggestions.03JUN20221715.json
}
```

You can check here the suggestions before they are applied to the BIG-IP:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario5

foo@bar:~$ terraform apply "scenario5"

foo@bar:~$ terraform output 03JUN20221715 | jq .
```

update the **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
    suggestions		 = [data.bigip_waf_pb_suggestions.03JUN20221715.json]
}
```

now, plan & apply!:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario5

foo@bar:~$ terraform apply "scenario4"
```
