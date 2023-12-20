variable "kubeadm_key_name" {
  type = string
  description = "name of keypair"
  default = "kubeadm_key"
}

variable "kubeadm_ami" {
  description = "ami id for ubuntu image"
  default = "" #admi ubuntu server 
}