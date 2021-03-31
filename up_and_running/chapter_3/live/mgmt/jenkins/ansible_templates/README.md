# EC2 inventory calculation

The inventory list is calculated by the `aws_ec2` plugin for Ansible. It uses the inventory_aws/tf_aws_ec2.yml to calculate that list using the tags applied to each EC2 resource. 

Each tag value is prefixed with "tag_". Furthermore, when the inventory script encounters an EC2 resource with tags that have a "Name" attribute, it will append "Name_" followed by the value of the name tag. For example, if an EC2 has a tag with a Name that has a value of "foobar", then you could refer to it in an Ansible playbook like this: "tag_Name_foobar", and Ansible would automagically figure out it's IP address and other information necessary to connect to it.

In a Terraform provisioner, you would typically specify it like this (assuming you want to refer to the same EC2 resource where the provisioner resides) ...

`tag_Name_${self.tags.Name}`

Obviously in that case, the tag_Name_<value> doesn't exist until the EC2 actually exists. Which is why each provisioner should wait for the EC2 to exist before trying to run the playbook against it. For example, 

```
aws --profile ${var.profile} ec2 wait instance-status-ok -region ${var.worker_region} --instance-ids ${self.id}
```

# Playbooks

The list of playbooks currently available is as follows:

jenkins_primary_example.yml
jenkins_worker_example.yml
install_jenkins.yaml
install_worker.yaml

Each one requires the inventory to be passed in using a variable `passed_in_hosts`. For example, 

```
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}
```

Other values can be passed into the playbook, followed by the relative path to the playbook file itself. For example, 

```
ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} primary_ip=${self.tags.Primary_Private_IP}' ansible_templates/install_worker.yaml
```

# Jinja Templates

Jinja is a templating language for python.

All templating happens on the Ansible controller before the task is sent out to targets. Jinja is not required to be installed on the target nodes.

Jinja files end with ".j2'. Usually variables to be substituted will be surrounded by double curly braces

```
{{ the_variable }}
```

Jinja templating can also be used inside a play as well as .j2 files.

# Other useful commands

You can use the `--syntax-check` command to check the validity of the syntax of a playbook like this:

```
ansible-playbook --syntax-check <path to playbook>
```

You can also check to see if that worked with `$ echo $?` which checks the return status of the previous command.