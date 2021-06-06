variable "azurermSubscriptionId" {
  type = string
  description = "The Azure subscription in which to deploy the terraform resources."
}
variable "azurermClientId" {
  type = string
  description = "The service principle used by terraform to manage resources."
}
variable "azurermClientSecret" {
  type = string
  description = "The secret associated with the service principle defined by azurermClientId."
  sensitive = true
}
variable "azurermTenantId" {
  type = string
  description = "The Azure AD tenant linked to the subscription."
}
variable "adminUsername" {
  type = string
  description = "The admin username of created virtual machines."
  default = "admin"
}
variable "adminPassword" {
  type = string
  description = "The admin password of created virtual machines."
  sensitive = true
}
variable "sshPublicKeyPath" {
  type = string
  description = "The path to the admin ssh public key."
  default = "~/.ssh/id_rsa.pub"
}