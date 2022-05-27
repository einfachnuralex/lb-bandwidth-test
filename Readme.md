# Prepare

There are 3 variables:

* image_id: ID of OS image to use (default to Ubuntu 20.04)
* flavor_name: Flavor name to use (default t1.1) 
* key_pair_name: Key name to use, must be there beforehand (default ske)

# Build

Source Openstack credentials

```bash
source ./openrc.sh
```

```bash
terraform init
terraform plan
terraform apply
```

# Run test

Configure your ssh client to forward agent to jumphost and use ubuntu user in `~/.ssh/config`

```
Host <fip jumphost>
  User ubuntu
  ForwardAgent yes
```

SSH to jumphost and connect to other instances.

```bash
ssh <fip jumphost> 
```

Install `iperf3`

```bash
sudo apt update && sudo apt install -y iperf3
```

On lbtest1 run iperf server

```bash
sudo iperf3 -s -p 14562 -f g
```

on lbtest2 run iperf client

```bash
iperf3 -f g -p 14562 -c <private ip of lbtest1>
iperf3 -f g -p 14562 -c <public ip of lbtest1>
```
