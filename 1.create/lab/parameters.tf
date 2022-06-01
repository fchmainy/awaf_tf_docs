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
  is_header       = true
  sensitive_parameter = true
  perform_staging = true
}
