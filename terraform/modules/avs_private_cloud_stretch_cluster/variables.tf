#################################################################
# module variables
#################################################################
variable "sddc_name" {
  type        = string
  description = "Azure resource name assigned to the avs sddc being created"
}

variable "sddc_sku" {
  type        = string
  description = "The sku value for the AVS SDDC management cluster nodes"
}

variable "management_cluster_size" {
  type        = number
  description = "The number of nodes to include in the management cluster"
  default     = 3
}

variable "rg_name" {
  type        = string
  description = "Resource Group Name where the expressroute gateway and the associated public ip are being deployed"
}

variable "rg_location" {
  type        = string
  description = "Resource Group location"
  default     = "westus2"
}

variable "avs_network_cidr" {
  type        = string
  description = "The full /22 network CIDR range summary for the private cloud managed components"
}

variable "expressroute_authorization_key_name_1" {
  type        = string
  description = "The name to use for the expressRoute authorization key for circuit 1"
}

variable "expressroute_authorization_key_name_2" {
  type        = string
  description = "The name to use for the expressRoute authorization key for circuit 2"
}

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
}

variable "internet_enabled" {
  type        = bool
  description = "set the internet snat to on or off"
  default     = false
}

variable "hcx_enabled" {
  type        = bool
  description = "Enable the HCX addon toggle value"
  default     = false
}

variable "hcx_key_names" {
  type        = list(string)
  description = "list of key names to use when generating hcx site activation keys."
  default     = []
}

#################################################################
# telemetry variables
#################################################################
variable "module_telemetry_enabled" {
  type        = bool
  description = "toggle the telemetry on/off for this module"
  default     = true
}

variable "guid_telemetry" {
  type        = string
  description = "guid used for telemetry identification. Defaults to module guid, but overrides with root if needed."
  default     = "0f9a8adc-9d37-40b3-aaed-ab34b95cf6dd"
}