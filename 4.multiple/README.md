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
  alias    = "qa"
  address  = var.qa_bigip
  username = var.username
  password = var.password
}
provider "bigip" {
  alias    = "prod"
  address  = var.prod_bigip
  username = var.username
  password = var.password
}

data "http" "scenario4" {
  url = "https://raw.githubusercontent.com/fchmainy/awaf_tf_docs/main/4.multiple/lab/Common_scenario4__2022-6-2_13-38-14__production.f5demo.com.json?token=GHSAT0AAAAAABMHNSKUQZBAYO7NCJUZBEF6YUYUHVA"
  request_headers = {
  	Accept = "application/json"
  }
}

resource "bigip_waf_policy" "app1_qa" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
}

resource "bigip_waf_policy" "app1_prod" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
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
