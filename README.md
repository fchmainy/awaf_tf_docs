# F5 BIG-IP Terraform Provider
# A.WAF Resources


## Introduction


## Some use-cases



### Scenario #1: Creating a WAF Policy

[The goal of this lab](https://github.com/fchmainy/awaf_tf_docs/tree/main/1.create) is to create a new A.WAF Policy from scratch and manage some entities additions.


------
### Scenario #2: Managing with terraform an existing WAF Policy
The goal of [this lab](https://github.com/fchmainy/awaf_tf_docs/blob/main/2.import/README.md) is to take an existing A.WAF Policy -- that have been created and managed on a BIG-IP outside of Terraform -- and to import and manage its lifecycle using the F5’s  BIG-IP terraform provider.


------
### Scenario #3: Migrating a WAF Policy from a BIG-IP to another BIG-IP
[This lab]() is a variant of the [previous one](https://github.com/fchmainy/awaf_tf_docs/blob/main/2.import/README.md). It takes a manualy managed A.WAF Policy from an existig BIG-IP and migrate it to a different BIG-IP through Terraform resources.

Now we have 2 BIG-IPs having 2 distincts A.WAF resources but sharing the same specifications and objects so this scenario is also the perfect fit for qualifcations & productions environments. 


------
