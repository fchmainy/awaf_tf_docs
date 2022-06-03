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
 - the security engineer (yourself) regularly checks the sugestions directly on the BIG-IP WebUI and clean the irrelevant suggestions (the WAF Polciy we downloaded from the GitHub repo already contains Policy Builder suggestions so we do not have to generate traffic for this example).
 - once the cleaning is done, the terraform engineer (also yourself :) ) creates a unique **bigip_waf_pb_suggestions** data source issue a terraform apply for the current suggestions. You can filter the suggestions on their scoring level (from 5 to 100% - 100% having the highest confidence level).
Every suggestions application can be tracked on Terraform and can easily be roll-backed if needed.


 - enforcing attack signatures on the QA environment
 - checking if these changes does not break the application and identify potential False Positives
 - applying the changes on QA before applying them on Production

### Enforcing attack signatures on the QA environment

Create a **suggestions.tf** file:

```terraform
variable "signatures" {
  type            = map(object({
 	signature_id  	= integer
	name 		        = string
	description	    = string
  }))
}

signatures = {
    200000070 = {
        signature_id 	= 200000070
        description 	= 'SQL-INJ "master.." database (Headers)'
	enabled		= true
	perform_staging	= false
    }
    200000071 = {
        signature_id 	= 200000071
        description 	= 'SQL-INJ "master.." database (Parameters)'
	enabled		= true
	perform_staging	= false
    }
    200000072 = {
        signature_id 	= 200000072
        description 	= 'SQL-INJ "UNION SELECT" (Headers)'
	enabled		= true
	perform_staging	= false
    }
    200000073 = {
        signature_id 	= 200000073
        description 	= 'SQL-INJ "UNION SELECT" (Parameter)'
	enabled		= true
	perform_staging	= false
    }
    200000076 = {
        signature_id 	= 200000076
        description 	= 'SQL-INJ "mysql" (Headers)'
	enabled		= true
	perform_staging	= false
    }
}

data "bigip_waf_signatures" "map" {
  for_each		= var.signatures
  
  signature_id		= each.value["signature_id"]
  description		= each.value["description"]
  enabled		= each.value["enabled"]
  perform_staging	= each.value["perform_staging"]
}
```


update the **main.tf** file:

```terraform
resource "bigip_waf_policy" "s4_qa" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
    signatures		 = [data.bigip_waf_signatures.map.*.json]
}

resource "bigip_waf_policy" "s4_prod" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
}
```

now, plan & apply!:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario4

foo@bar:~$ terraform apply "scenario4"
```

We can verify that the 5 attack signatures have been enabled and enforced on the scenario4 WAF Policy on the QA BIG-IP.

Now, the applicatiopn owner identified that these last changes on the QA device have introduced some FP. Using the log events on the A.WAF GUI, we identified that :
 - the attack signature **"200000073"** should be disabled globally
 - the attack signature **"200000070"** should be disabled for the **"/U1"** URL 
 - the attack signaure **"200000071"** should be disabled at the parameter **"P1"** defined under the **"/U1"** URL.
 
 so we can proceed to the final changes before enforcing into production:
 
**signatures.tf** file:

```terraform
variable "signatures" {
  type = map(object({
 	signature_id  	= integer
	name 		= string
	description	= string
  }))
}

signatures = {
    200000070 = {
        signature_id 	= 200000070
        description 	= 'SQL-INJ "master.." database (Headers)'
	enabled		= true
	perform_staging	= false
    }
    200000071 = {
        signature_id 	= 200000071
        description 	= 'SQL-INJ "master.." database (Parameters)'
	enabled		= true
	perform_staging	= false
    }
    200000072 = {
        signature_id 	= 200000072
        description 	= 'SQL-INJ "UNION SELECT" (Headers)'
	enabled		= true
	perform_staging	= false
    }
    200000073 = {
        signature_id 	= 200000073
        description 	= 'SQL-INJ "UNION SELECT" (Parameter)'
	enabled		= false
	perform_staging	= false
    }
    200000076 = {
        signature_id 	= 200000076
        description 	= 'SQL-INJ "mysql" (Headers)'
	enabled		= true
	perform_staging	= false
    }
}

data "bigip_waf_signatures" "map" {
  for_each		= var.signatures
  
  signature_id		= each.value["signature_id"]
  description		= each.value["description"]
  enabled		= each.value["enabled"]
  perform_staging	= each.value["perform_staging"]
}
```

**parameters.tf** file:

```terraform
data "bigip_waf_entity_parameter" "P1" {
  name            		= "P1"
  type            		= "explicit"
  data_type       		= "alpha-numeric"
  perform_staging 		= true
  signature_overrides_disable 	= [200000071]
  url		  		= data.bigip_waf_entity_url.U1
}
```

**urls.tf** file:

```terraform
data "bigip_waf_entity_url" "U1" {
  name		              	= "/U1"
  type                        	= "explicit"
  perform_staging             	= false
  signature_overrides_disable 	= [200000070]
}
```


update the **main.tf** file:

```terraform
resource "bigip_waf_policy" "s4_qa" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
    signatures		 = [data.bigip_waf_signatures.map.*.json]
    parameters		 = [data.bigip_waf_entity_parameter.P1.json]
    urls		 = [data.bigip_waf_entity_url.U1.json]
}

resource "bigip_waf_policy" "s4_prod" {
    application_language = "utf-8"
    name                 = "/Common/scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
    signatures		 = [data.bigip_waf_signatures.map.*.json]
    parameters		 = [data.bigip_waf_entity_parameter.P1.json]
    urls		 = [data.bigip_waf_entity_url.U1.json]
}
```

now, plan & apply!:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario4

foo@bar:~$ terraform apply "scenario4"
```