variable "kubeadm_key_name" {
  type = string
  description = "name of keypair"
  default = "kubeadm_key"
}

variable "kubeadm_ami" {
  description = "ami id for ubuntu image"
  default = "ami-0014ce3e52359afbd" #admi ubuntu server 
}

variable "kudeadm_instance_count" {
  type = numberdes
  description = "Number of worker nodes in the cluster"
  default = 2
}
