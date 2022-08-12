<div align="center">

# Scenario #5: Managing an A.WAF Policy with Policy Builder on a single device

</div>

</br></br>

## Goals
The goal of this lab is to manage Policy Builder Suggestions an A.WAF Policy on a single device or cluster. As the traffic flows through the BIG-IP, it is easy to manage suggestions from the Policy Builder and enforce them on the WAF Policy. It also shows what can be the management workflow:
 - the security engineer regularly checks the sugestions directly on the BIG-IP WebUI and clean the irrelevant suggestions.
 - once the cleaning is done, the terraform engineer (who can also be the security engineer btw) issue a terraform apply for the current suggestions. You can filter the suggestions on their scoring level (from 5 to 100% - 100% having the highest confidence level).
 - Every suggestions application can be tracked on Terraform and can easily be roll-backed if needed.

</br></br>

## Pre-requisites

**on the BIG-IP:**

 - [ ] version 15.1 minimal
 - [ ] A.WAF Provisioned
 - [ ] credentials with REST API access
 - [ ] an A.WAF Policy with Policy Builder enabled and Manual traffic Learning

**on Terraform:**

 - [ ] use of F5 bigip provider version 1.15.0 minimal
 - [ ] use of Hashicorp version followinf [Link](https://clouddocs.f5.com/products/orchestration/terraform/latest/userguide/overview.html#releases-and-versioning)

</br></br>

## Policy Creation

We already have exported a WAF Policy called **scenario5.json** [available here](https://raw.githubusercontent.com/fchmainy/awaf_tf_docs/main/0.Appendix/scenario5_wLearningSuggestions.json) including several Policy Builder Suggestions so you won't have to generate traffic.

So you have to create 4 files:

**variables.tf**
```terraform
variable prod_bigip {}
variable username {}
variable password {}
```

**inputs.auto.tfvars**
```terraform
prod_bigip = "10.1.1.8:443"
username = "admin"
password = "whatIsYourBigIPPassword?"
```

**main.tf**
```terraform
terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.15"
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
  url = "https://raw.githubusercontent.com/fchmainy/awaf_tf_docs/main/0.Appendix/scenario5_wLearningSuggestions.json"
  request_headers = {
  	Accept = "application/json"
  }
}

resource "bigip_waf_policy" "this" {
    provider	           = bigip.prod
    application_language = "utf-8"
    partition            = "Common"
    name                 = "scenario5"
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


Now initialize, plan and apply your new Terraform project.
```console
foo@bar:~$ terraform init

foo@bar:~$ terraform plan -out scenario5

foo@bar:~$ terraform apply "scenario5"

```

Now you can go on your BIG-IP UI and associate the A.WAF Policy **scenario5** to the Virtual Server **scenario5.vs**.
Note: remember, the Virtual Server and the whole application service can be automated using the BIG-IP provider with the AS3 or FAST resources.


</br></br>

## Simulate a WAF Policy workflow

Here is a typical workflow:
You should have 22 Learning Suggestions with your WAF Policy.

 1. the security engineer (yourself) regularly checks the sugestions directly on the BIG-IP WebUI and clean the irrelevant suggestions. Let's say we will remove the following suggestion:
	* **Enable HTTP Protocol Compliace Check** HTTP Check: Check maximum number of parameters

 2. once the cleaning is done, the terraform engineer (here it is also yourself :) but in a real life he can be a different individual) creates a unique **bigip_waf_pb_suggestions** data source before issuing a terraform apply for the current suggestions. You can filter the suggestions on their scoring level (from 5 to 100% - 100% having the highest confidence level).

*Note: Every suggestions application can be tracked on Terraform and can easily be roll-backed if needed.*

</br>

### 1. Go to your BIG-IP WebUI and clean the irrelevant suggestions
:warning: **IMPORTANT** you can ignore suggestions but you should never accept them on the WebUI, otherwise you will then have to reconciliate the changes between the WAF Policy on the BIG-IP and the latest known WAF Policy in your terraform state.

For example, remove all the suggestions with a scoring = 1%

</br>

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

foo@bar:~$ terraform output 03JUN20221715 | jq '. | length'
```

update the **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
    provider	         = bigip.prod
    application_language = "utf-8"
    partition            = "Common"
    name                 = "scenario5"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
    modifications		 = [data.bigip_waf_pb_suggestions.03JUN20221715.json]
}
```

now, plan & apply!:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario5

foo@bar:~$ terraform apply "scenario5"
```
