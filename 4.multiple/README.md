# Scenario #4: Managing an A.WAF Policy on a different devices


## Goals
The goal of this lab) is to manage an A.WAF Policy on multiple devices. It can be:
 - different standalone devices serving the same applications
 - different devices serving different purposes, for example changes tested first on a QA/Test BIG-IP before applying into production.

## Pre-requisites

**on the BIG-IP:**

 - [ ] version 15.1 minimal
 - [ ] A.WAF Provisioned
 - [ ] credentials with REST API access


**on Terraform:**

 - [ ] use of F5 bigip provider version 1.14.0 minimal
 - [ ] use of Hashicorp version followinf [Link](https://clouddocs.f5.com/products/orchestration/terraform/latest/userguide/overview.html#releases-and-versioning)


## Policy Creation

Create 4 files:

**variables.tf**
```terraform
variable qa_bigip {}
variable prod_bigip {}
variable username {}
variable password {}
```

**inputs.tfvars**
```terraform
qa_bigip = "10.1.1.4:8443"
prod_bigip = "10.1.1.9:8443"
username = "admin"
password = "as09.1qa"
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
  alias    = "old"
  address  = var.previous_bigip
  username = var.username
  password = var.password
}
provider "bigip" {
  alias    = "new"
  address  = var.latest_bigip
  username = var.username
  password = var.password
}


resource "bigip_waf_policy" "current" {
  provider	       = bigip.old
  name                 = "/Common/scenario3"
  template_name        = "POLICY_TEMPLATE_RAPID_DEPLOYMENT"
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
