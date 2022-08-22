# F5 BIG-IP Terraform Provider
# A.WAF Resources


## Introduction

The goal of this project is to demonstrate some great and common real life use cases of managing F5 BIG-IP A.WAF through Terraform.
Every scenario down here describe the use case, the goals and gives details on the workflow and the related (Infrastructure as) Code.

Every scenario is independant but we raise the bar progressively in term of complexity so we recommend taking time starting from the begining :) It will take approximately ~5 minutes per scenario.

For users who can run these exercices in [UDF](https://udf.f5.com) you will find every file and scenarios in $HOME/terraform. The infrastructure is the following:
![infrastructure](https://github.com/fchmainy/awaf_tf_docs/raw/main/0.Appendix/UDF-lab-architecture.jpeg)

## Some use-cases



### Scenario #1: Creating a WAF Policy

[The goal of this lab](https://github.com/fchmainy/awaf_tf_docs/tree/main/1.create) is to create a new A.WAF Policy from scratch and manage some entities additions.


------


### Scenario #2: Managing with terraform an existing WAF Policy
The goal of [this lab](https://github.com/fchmainy/awaf_tf_docs/blob/main/2.import/README.md) is to take an existing A.WAF Policy -- that have been created and managed on a BIG-IP outside of Terraform -- and to import and manage its lifecycle using the F5’s  BIG-IP terraform provider.


------


### Scenario #3: Migrating a WAF Policy from a BIG-IP to another BIG-IP
[This lab](https://github.com/fchmainy/awaf_tf_docs/tree/main/3.migrate) is a variant of the [previous one](https://github.com/fchmainy/awaf_tf_docs/blob/main/2.import). It takes a manualy managed A.WAF Policy from an existig BIG-IP and migrate it to a different BIG-IP through Terraform resources.

Now we have 2 BIG-IPs having 2 distincts A.WAF resources but sharing the same specifications and objects so this scenario is also the perfect fit for qualifcations & productions environments. 


------


### Scenario #4: Managing an A.WAF Policy on a different devices 
The goal of [this lab](https://github.com/fchmainy/awaf_tf_docs/tree/main/4.multiple) is to manage an A.WAF Policy on multiple devices. It can be:
- different standalone devices serving the same applications
- different devices serving different purposes, for example changes tested first on a QA/Test BIG-IP before applying into production.


------


### Scenario #5: Managing an A.WAF Policy with Policy Builder on a single device
The goal of [this lab](https://github.com/fchmainy/awaf_tf_docs/tree/main/5.policyBuilderSingle)) is to manage Policy Builder Suggestions an A.WAF Policy on a single device or cluster. As the traffic flows through the BIG-IP, it is easy to manage suggestions from the Policy Builder and enforce them on the WAF Policy. It also shows what can be the management workflow:
- the security engineer regularly checks the sugestions directly on the BIG-IP WebUI and clean the irrelevant suggestions.
- once the cleaning is done, the terraform engineer (who can also be the security engineer btw) issue a terraform apply for the current suggestions. You can filter the suggestions on their scoring level (from 5 to 100% - 100% having the highest confidence level).
- Every suggestions application can be tracked on Terraform and can easily be roll-backed if needed.


------


### Scenario #6: Managing an A.WAF Policy with Policy Builder on multiple device
The goal of [this lab](https://github.com/fchmainy/awaf_tf_docs/tree/main/6.policyBuilderMultiple)) is to manage Policy Builder Suggestions an A.WAF Policy from on multiple devices or clusters. Several use cases are covered here:
- multiple devices serving and protecting the same application (multiple datacenters, application spanned across multiple clouds... By nature, each standalone device or clusters can see different traffic patterns so the suggestions can be somehow differents. The goal here is to consolidate the suggestions before enforcing.
- Production BIG-IPs protecting the application therefore seeing the real life traffic flow for seeding the Policy Builder but all changes need to be validated in the qualification environment before enforcing into production.

*Note: The two uses cases aforementioned are not mutually exclusive and can be managed within a single workflow*
