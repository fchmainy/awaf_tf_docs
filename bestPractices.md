<div align="center">
  
# Best practices and Recommendations

  
  
</div>
<br> <br> <br> 


## Terraform naming convention

* Use « _ » instead of “-“ in every terraform names: resource, data source, outputs…

* **Any resources or data sources that are unique in your deployment can be named “this”.**
    ```terraform
    resource "bigip_waf_policy" "this" {
        provider	           = bigip.new
        application_language = "utf-8"
        name                 = "/Common/scenario3"
        policy_id            = "YiEQ4l1Fw1U9UnB2-mTKWA"
        template_name        = "POLICY_TEMPLATE_COMPREHENSIVE"
        type                 = "security"
        policy_import_json   = file("${path.module}/currentWAFPolicy.json")
    }
    ```


* **Don't repeat the resource type in the name of the resource.**

     don't:
     ```terraform
       resource "bigip_waf_policy" "bigip_waf_policy_myPolicy" {}
    ```
   use instead:
    ```terraform
      resource "bigip_waf_policy" "myPolicy" {}
  ```


<br> <br> 

## Use TFVars input files

Any files with the *.auto.tfvars suffix will automatically be loaded to populate Input Variables.

You can have multiple tfvars input files:
-	One for the attack signatures (ex: signatures.auto.tfvars)
-	One for the parameters (ex: parameters.auto.tfvars)
-	One for the urls (ex: urls.auto.tfvars)
-	…

There is an example [here](https://github.com/fchmainy/awaf_tf_docs/tree/main/4.multiple#enforcing-attack-signatures-on-the-qa-environment)

Or you can manage all your input variables into a single tfvars file per WAF Policy. 
Simply don’t put all the inputs for all WAF policies into a single consolidated file, it will be unmanageable.

<br> <br> 

## Decompose your WAF Policies into terraform modules
You may have tens or hundreds of waf policies to manage.
There are two ways you can manage them:
 - **independantly** into discrete terraform projects (terraform plan, apply for every policy)
 - **globally** per device, per group of device, per environment... and you may not want to manage a dedicated terraform project per WAF Policy. In that case you can modularize your tf configuration in modules.

```terraform
module “policy1” {
  source                = "./myModuleLink"
  name                  = "scenario1"
  partition             = "Common"
  template_name         = "POLICY_TEMPLATE_RAPID_DEPLOYMENT"
  application_language  = "utf-8"
  enforcement_mode      = "blocking"
  server_technologies   = ["Apache Tomcat", "MySQL", "Unix/Linux", "MongoDB"]
  parameters            = var.parameters
  signatures            = var.signatures
  urls                  = var.urls
}
```

## Central Storage
Never store your terraform state files into a publicly accessible store
You can though, store your WAF policies into your SCM and refer at it in your resources:

```terraform
data "http" "scenario4" {
  url = "https://raw.githubusercontent.com/fchmainy/awaf_tf_docs/main/0.Appendix/scenario4.json"
  request_headers = {
  	Accept = "application/json"
  }
}

resource "bigip_waf_policy" "s4_qa" {
    provider	    	     = bigip.qa
    application_language = "utf-8"
    partition            = "Common"
    name                 = "scenario4"
    template_name        = "POLICY_TEMPLATE_FUNDAMENTAL"
    type                 = "security"
    policy_import_json   = data.http.scenario4.body
}
```


## Use with AS3
A WAF Policy itself is not enough to protect a service. It needs to be associated with a proxy configuration.

Again, it can be set in a single terraform module


## Manage Configuration Drifts
There may be situations where you have to make manual changes directly on your BIG-IP because of a specific feature not yet implemented in the terraform provider or someone in the security department having to make urgent configuration updates.
In that case, we do not have to override the changes to reconciliate the current configuration with our latest known state.

You can ask for a JSON export of the WAF policy directly from a BIG-IP and use it as the **policy_import_json** argument of the **"bigip_waf_policy**. Any other arguments defined in the resource overrides the same definition in the JSON payload.
For example, if you have 2 parameters P1 and P2 in your WAF JSON policy and you have a **bigip_waf_entity_parameters** list with P1, P2 and P3, the terraform resource will override P1 and P2 and will add P3 in the declaration before sending it to the BIG-IP.
