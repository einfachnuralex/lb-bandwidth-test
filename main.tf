# Provider parts
terraform {
  required_providers {
    local     = {
      source = "hashicorp/local"
    }
    null      = {
      source = "hashicorp/null"
    }
    openstack = {
      source = "terraform-providers/openstack"
    }
  }
  required_version = ">= 0.13"
}

provider "openstack" {
  use_octavia = true
}

# Variables
variable "image_id" {
  type        = string
  default     = "7fba82b3-86aa-4a3f-896a-0a9665a68234"
  description = "id of the os-image for nodes (default: ubuntu)"
}

variable "flavor_name" {
  type        = string
  default     = "t1.1"
  description = "flavor of the node instances"
}

variable "key_pair_name" {
  type        = string
  default     = "ske"
  description = "name of an existing key, to access instance via ssh (set via source-file)"
}

variable "user_data" {
  type        = string
  default     = ""
  description = ""
}

# Data
data "openstack_compute_flavor_v2" "flavor" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "floating_net" {
  name = "floating-net"
}

# Security group & rules
resource "openstack_networking_secgroup_v2" "lbtest" {
  name        = "lbtest"
  description = "My neutron security group"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.lbtest.id}"
  remote_group_id   = "${openstack_networking_secgroup_v2.lbtest.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 14562
  port_range_max    = 14562
  remote_ip_prefix  = "193.148.160.0/19"
  security_group_id = "${openstack_networking_secgroup_v2.lbtest.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_3" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.lbtest.id}"
}

# Network
resource "openstack_networking_network_v2" "network" {
  name           = "lbtest"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "lbtest"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = "192.168.42.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_router_v2" "router" {
  name                = "lbtest"
  external_network_id = data.openstack_networking_network_v2.floating_net.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}


# Instances
resource "openstack_compute_instance_v2" "lbtest1" {
  name      = "lbtest1"
  flavor_id = data.openstack_compute_flavor_v2.flavor.id
  key_pair  = var.key_pair_name
  security_groups = ["${openstack_networking_secgroup_v2.lbtest.id}"]
  user_data = var.user_data

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 20
    delete_on_termination = true
  }

  network {
    uuid = "${openstack_networking_network_v2.network.id}"
  }

}

resource "openstack_compute_instance_v2" "lbtest2" {
  name      = "lbtest2"
  flavor_id = data.openstack_compute_flavor_v2.flavor.id
  key_pair  = var.key_pair_name
  security_groups = ["${openstack_networking_secgroup_v2.lbtest.id}"]
  user_data = var.user_data

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 20
    delete_on_termination = true
  }

  network {
    uuid = "${openstack_networking_network_v2.network.id}"
  }

}

resource "openstack_compute_instance_v2" "lbjump" {
  name      = "lbjump"
  flavor_id = data.openstack_compute_flavor_v2.flavor.id
  key_pair  = var.key_pair_name
  security_groups = ["${openstack_networking_secgroup_v2.lbtest.id}"]
  user_data = var.user_data

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 20
    delete_on_termination = true
  }

  network {
    uuid = "${openstack_networking_network_v2.network.id}"
  }
}

# Floating IPs
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = "floating-net"
}

resource "openstack_networking_floatingip_v2" "fip_2" {
  pool = "floating-net"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
  instance_id = "${openstack_compute_instance_v2.lbjump.id}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_2" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_2.address}"
  instance_id = "${openstack_compute_instance_v2.lbtest1.id}"
}