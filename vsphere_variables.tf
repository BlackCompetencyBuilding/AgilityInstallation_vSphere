variable "vsphere_user" {
  description = "The User ID for Vsphere."
  default = "vsphere_username"
}
variable "vsphere_password" {
    description = "Password for Vsphere."
    default = "vsphere_password"
} 
variable "vsphere_host" {
    description = "The Host address for Vsphere"
    default = "vsphere_ip"
}
variable "vsphere_datacenter" {
    description = "The Datacenter Name"
    default = "lab"
}
variable "vsphere_datastore" {
    description = "The Datastore Name"
    default = "datastore2"
}
variable "vsphere_network" {
    description = "The Vsphere Network Name"
    default = "VM Network"
}
variable "plugin_install" {
    description = "The Vsphere Network Name"
    default = "yes"
}