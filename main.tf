resource "alicloud_vpc" "vpc" {
  name       = var.vpc_name
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/21"
  availability_zone = "cn-beijing-b"
}

resource "alicloud_security_group" "default" {
  name   = "default"
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = var.ip_protocol
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
}

module "tf-instances" {  
 source                      = "./modules/ecs"
 region                      = var.region
 number_of_instances         = var.instance_number  
 vswitch_id                  = alicloud_vswitch.vsw.id  
 group_ids                   = [alicloud_security_group.default.id]  
 private_ips                 = ["172.16.0.10", "172.16.0.11", "172.16.0.12"]  
 image_ids                   = ["ubuntu_18_04_64_20G_alibase_20190624.vhd"]  
 instance_type               = var.instance_type   
 internet_max_bandwidth_out  = 10
 associate_public_ip_address = true  
 instance_name               = "my_module_instances_"  
 host_name                   = "sample"  
 internet_charge_type        = "PayByTraffic"   
 password                    = "User@123" 
 system_disk_category        = var.system_disk_category
 data_disks = [    
  {      
    disk_category = "cloud_ssd"      
    disk_name     = "my_module_disk"      
    disk_size     = "50"    
  } 
 ]
}

module "slb" {
  source  = "./modules/slb"
  spec = "slb.s2.small"
  servers_of_default_server_group = [
    {
      server_ids = join(",", module.tf-instances.this_instance_id)
      weight     = "100"
      type       = "ecs"
    },
  ]
}
