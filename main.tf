provider "aws" {
  region = "${var.aws_region}"
}

data "aws_ami" "jenkins" {
  most_recent      = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

# Jenkins Master Instance
module "jenkins-master" {
  source                      = "./modules/jenkins-master"

  name                        = "${var.name == "" ? "jenkins-master" : join("-", list(var.name, "jenkins-master"))}"
  instance_type               = "${var.instance_type_master}"
  vpc_id                      = "${var.master_vpc_id == "" ? data.aws_vpc.default.id : var.master_vpc_id}"
  subnet_ids                  = "${var.subnet_ids == "" ? join(" ", data.aws_subnet_ids.default.*.id) : var.subnet_ids}"
  ami_id                      = "${var.master_ami_id == "" ? data.aws_ami.jenkins.image_id : var.master_ami_id}"

  user_data                   = ""
  setup_data                  = "${data.template_file.setup_data_master.rendered}"

  http_port                   = "${var.http_port}"
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = "${var.ssh_key_name}"
  ssh_key_path                = "${var.ssh_key_path}"
}

data "template_file" "setup_data_master" {
  template = "${file("./modules/jenkins-master/setup.tpl")}"
  vars = {
    jnlp_port = "${var.jnlp_port}"
    plugins = "${join(" ", var.plugins)}"
  }
}

# Jenkins Linux Slave Instance(s)
module "jenkins-linux-slave" {
  source                      = "./modules/jenkins-slave"

  count                       = "${var.linux_slave_count}"

  name                        = "${var.name == "" ? "jenkins-linux-slave" : join("-", list(var.name, "jenkins-linux-slave"))}"
  instance_type               = "${var.instance_type_slave}"

  vpc_id                      = "${var.master_vpc_id == "" ? data.aws_vpc.default.id : var.master_vpc_id}"
  subnet_ids                  = "${var.subnet_ids == "" ? join(" ", data.aws_subnet_ids.default.*.id) : var.subnet_ids}"
  ami_id                      = "${var.master_ami_id == "" ? data.aws_ami.jenkins.image_id : var.master_ami_id}"

  jenkins_security_group_id   = "${module.jenkins-master.jenkins_security_group_id}"

  jenkins_master_ip           = "${module.jenkins-master.private_ip}"
  jenkins_master_port         = "${var.http_port}"

  ssh_key_name                = "${var.ssh_key_name}"
  ssh_key_path                = "${var.ssh_key_path}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
}
