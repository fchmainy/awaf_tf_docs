# Scenario #2: Managing with terraform an existing WAF Policy


## Goals

You may already have multiple WAF policies protecting your applications and these WAF policies have evolved over the past months or years. It may be very complicated to do an extensive inventory of each policy, each entity and every attribute.
So the goal here is to **import** the current policy, which will be our current baseline. Every new change, addition of a Server Technology, parameter, attack signature... will be done through Terraform in addition or correction of this new baseline.

## Pre-requisites

**on the BIG-IP:**

 - [ ] version 15.1 minimal
 - [ ] credentials with REST API access
 - [ ] /Common/scenario2 WAF policy (Rapid deployment template) created


**on Terraform:**

 - [ ] use of F5 bigip provider version 1.14.0 minimal
 - [ ] use of Hashicorp version followinf [Link](https://clouddocs.f5.com/products/orchestration/terraform/latest/userguide/overview.html#releases-and-versioning)



## Policy Import

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
bigip = "10.1.1.9:443"
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
  address  = var.bigip
  username = var.username
  password = var.password
}

resource "bigip_waf_policy" "this" {
  partition.           = "Common"
  name                 = "scenario2"
  template_name        = "POLICY_TEMPLATE_RAPID_DEPLOYMENT"
}
```

**outputs.tf**
```terraform
output "policyId" {
	value	= bigip_waf_policy.this.policy_id
}


output "policyJSON" {
        value   = bigip_waf_policy.this.policy_export_json
}
```

As you can see, we only define the two required attributes of the **"bigip_waf_policy"** terraform resource: name and template_name. It is required to provide them in order to be able to manage the resource.


Just before we go. We need the Policy ID. There are multiple ways we can get it:
- check on the iControl REST API Endpoint: /mgmt/tm/asm/policies?$filter=name+eq+**scenario2**&$select=id
- get a script example in the lab/scripts/ folder
- using a Go code 

run the following piece of code in the [Go PlayGround](https://go.dev/play/)

```golang
package main

import (
	"crypto/md5"
	b64 "encoding/base64"
	"fmt"
	"strings"
)

func Hasher(policyName string) string {
	hasher := md5.New()
	hasher.Write([]byte(policyName))
	encodedString := b64.StdEncoding.EncodeToString(hasher.Sum(nil))

	return strings.TrimRight(encodedString, "=")
}

func main() {
	var partition string = "Common"
	var policyName string = "scenario2"

	fullName := "/" + partition + "/" + policyName
	policyId := Hasher(fullName)

	r := strings.NewReplacer("/", "_", "-", "_", "+", "-")
	fmt.Println("Policy Id: ", r.Replace(policyId))
}
```

Now, run the following commands, so we can:
	1. Initialize the terraform project
	2. Import the current WAF policy into our state
	3. Set the JSON WAF Policy as our new baseline
	4. Configure the lifecycle of our WAF Policy

```console
foo@bar:~$ terraform init
Initializing the backend...

Initializing provider plugins...
[...]

Terraform has been successfully initialized!

foo@bar:~$ terraform import -var-file=inputs.tfvars bigip_waf_policy.this EdchwjSqo9cFtYP-iWUJmw
bigip_waf_policy.this: Importing from ID "EdchwjSqo9cFtYP-iWUJmw"...
bigip_waf_policy.this: Import prepared!
  Prepared bigip_waf_policy for import
bigip_waf_policy.this: Refreshing state... [id=EdchwjSqo9cFtYP-iWUJmw]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```




Now update your terraform main.tf file with the ouputs of the following two commands:


```console
foo@bar:~$ terraform show -json | jq '.values.root_module.resources[].values.policy_export_json | fromjson' > importedWAFPolicy.json

foo@bar:~$ terraform show -no-color
# bigip_waf_policy.this:
resource "bigip_waf_policy" "this" {
    application_language = "utf-8"
    id                   = "EdchwjSqo9cFtYP-iWUJmw"
    name                 = "/Common/scenario2"
    policy_export_json   = jsonencode(
        {
            [...]
        }
    )
    policy_id            = "EdchwjSqo9cFtYP-iWUJmw"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
}
```

using the collected data from the terraform import, we are now updating our **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
    application_language = "utf-8"
    name                 = "/Common/scenario2"
    policy_id            = "EdchwjSqo9cFtYP-iWUJmw"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = file("${path.module}/importedWAFPolicy.json")
}
```

You can note that we replaced the "policy_export_json" argument with "policy_import_json" pointing to the imported WAF Policy JSON file.

Finally, we can plan & apply our new project.

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario2
bigip_waf_policy.this: Refreshing state... [id=EdchwjSqo9cFtYP-iWUJmw]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place
[...]
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Saved the plan to: scenario2

To perform exactly these actions, run the following command to apply:
    terraform apply "scenario2"

foo@bar:~$ terraform apply "scenario2"
bigip_waf_policy.this: Modifying... [id=EdchwjSqo9cFtYP-iWUJmw]
bigip_waf_policy.this: Still modifying... [id=EdchwjSqo9cFtYP-iWUJmw, 10s elapsed]
bigip_waf_policy.this: Modifications complete after 16s [id=EdchwjSqo9cFtYP-iWUJmw]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

policyId = "EdchwjSqo9cFtYP-iWUJmw"
policyJSON = "{[...]}"
```

## Policy lifecycle management
Now you can manage your WAF Policy as we did [in the previous lab](https://github.com/fchmainy/awaf_tf_docs/edit/main/1.create/README.md#policy-lifecycle-management)

You can check your WAF Policy on your BIG-IP after each terraform apply.

### Defining parameters

Create a **parameters.tf** file:

```terraform
data "bigip_waf_entity_parameter" "P1" {
  name            = "Parameter1"
  type            = "explicit"
  data_type       = "alpha-numeric"
  perform_staging = true
  signature_overrides_disable = [200001494, 200001472]
}
```

And add references to these parameters in the **"bigip_waf_policy"** TF resource in the **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
  [...]
  parameters           = [data.bigip_waf_entity_parameter.P1.json]
}
```

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario2
foo@bar:~$ terraform apply "scenario2"
```

### Defining URLs

Create a **urls.tf** file:

```terraform
data "bigip_waf_entity_url" "U1" {
  name		              = "/URL1"
  description                 = "this is a test for URL1"
  type                        = "explicit"
  protocol                    = "http"
  perform_staging             = true
  signature_overrides_disable = [12345678, 87654321]
  method_overrides {
    allow  = false
    method = "BCOPY"
  }
  method_overrides {
    allow  = true
    method = "BDELETE"
  }
}

data "bigip_waf_entity_url" "U2" {
  name                        = "/URL2"
}
```

And add references to this URL in the **"bigip_waf_policy"** TF resource in the **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
  [...]
  urls                 = [data.bigip_waf_entity_url.U1.json, data.bigip_waf_entity_url.U2.json]
}
```

and run it:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario2
foo@bar:~$ terraform apply "scenario2"
```

### Defining Attack Signatures

Create a **signatures.tf** file:

```terraform
data "bigip_waf_signatures" "S1" {
  signature_id     = 200104004
  description      = "Java Code Execution"
  enabled          = true
  perform_staging  = true
}

data "bigip_waf_signatures" "S2" {
  signature_id     = 200104005
  enabled          = false
}
```

And add references to this URL in the **"bigip_waf_policy"** TF resource in the **main.tf** file:

```terraform
resource "bigip_waf_policy" "this" {
  [...]
  signatures       = [data.bigip_waf_signatures.S1.json, data.bigip_waf_signatures.S2.json]
}
```

and run it:

```console
foo@bar:~$ terraform plan -var-file=inputs.tfvars -out scenario2
foo@bar:~$ terraform apply "scenario2"
```


