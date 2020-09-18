provider "aws" {
  profile                 = var.profile
  region                  = var.aws_region
  shared_credentials_file = var.shared_credentials_file
}

# Setup a specific VPC
resource "aws_vpc" "ex-vpc" {
  cidr_block = var.aws_vpc_cidr_block

  # gives you an internal domain name
  enable_dns_support = "true"

  # gives you an internal host name
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  # instance_tenancy: if it is true, your ec2 will be the only instance in an AWS physical hardware. Sounds good but expensive.
  instance_tenancy = "default"

  tags = {
    Name = format("%s-vpc", var.tag)
  }
}

resource "aws_subnet" "ex-subnet-public-1" {
  vpc_id                  = aws_vpc.ex-vpc.id
  cidr_block              = var.aws_vpc_subnet_cidr_block
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone       = var.aws_az

  tags = {
    Name = format("%s-vpc-subnet", var.tag)
  }
}

resource "aws_internet_gateway" "ex-igw" {
  vpc_id = aws_vpc.ex-vpc.id

  tags = {
    Name = format("%s-ig", var.tag)
  }
}

resource "aws_route_table" "ex-public-crt" {
  vpc_id = aws_vpc.ex-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.ex-igw.id
  }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.ex-subnet-public-1.id
  route_table_id = aws_route_table.ex-public-crt.id
}


# AWS Account ID: 136693071363
# debian-10-amd64-20200803-347
# aws ec2 describe-images --region ap-southeast-1 --owners 136693071363 --query 'sort_by(Images, &CreationDate)[].[CreationDate,Name,ImageId]' --output table --profile vtky
data "aws_ami" "debian10" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-10-amd64-20200803-347"]
  }
}

resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.ex-vpc.id

  name        = "allow_all"
  description = "Allow all traffic"

  ingress {
    description      = "Allow all inbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = format("%s-sg-allow_all", var.tag)
  }
}


# ssh-keygen -t rsa -b 4096 -f tf-rsa-key -C ""
resource "aws_key_pair" "tfkey" {
  key_name   = "tfkey"
  public_key = file("tf-rsa-key.pub")
}

resource "aws_instance" "clients" {
  count                  = var.client_instance_count
  ami                    = data.aws_ami.debian10.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.tfkey.key_name
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  subnet_id = aws_subnet.ex-subnet-public-1.id

  tags = {
    Name = format("%s-ec2-clients-%d", var.tag, count.index + 1)
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("tf-rsa-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo '{thisisth3Fl4g}' | sudo tee /root/flag.txt",
      "sudo apt update && sudo apt -y install gnupg wget curl vim nfs-common rpcbind",
      # "echo 'deb http://http.kali.org/kali kali-rolling main non-free contrib' | sudo tee -a /etc/apt/sources.list",
      "echo 'deb http://mirror.aktkn.sg/kali kali-rolling main non-free contrib' | sudo tee -a /etc/apt/sources.list",
      "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6",
      "sudo apt update",
      "sudo DEBIAN_FRONTEND=noninteractive apt -y install nmap tcpdump metasploit-framework",
      "bash -c 'for i in {1..5}; do sudo useradd -s /bin/bash -m s$i; echo s$i:password | sudo chpasswd; sudo usermod -a -G sudo s$i; done'",
      "echo 'Hello World' | sudo tee /home/s1/hello.txt /home/s2/hello.txt /home/s3/hello.txt /home/s4/hello.txt /home/s5/hello.txt",
      "sudo chmod 664 /home/s1/hello.txt /home/s2/hello.txt /home/s3/hello.txt /home/s4/hello.txt /home/s5/hello.txt",
      "bash -c 'for i in {1..5}; do sudo chown s$i:s$i /home/s$i/hello.txt; done'",
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
      "sudo /etc/init.d/ssh restart"
    ]
  }
}



resource "aws_instance" "server" {
  count                  = var.server_instance_count
  ami                    = data.aws_ami.debian10.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.tfkey.key_name
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  subnet_id = aws_subnet.ex-subnet-public-1.id

  tags = {
    Name = format("%s-ec2-server-%d", var.tag, count.index + 1)
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("tf-rsa-key")
    host        = self.public_ip
  }

  # # nginx installation
  # provisioner "file" {
  #     source = "nginx.sh"
  #     destination = "/tmp/nginx.sh"
  # }
  # provisioner "remote-exec" {
  #     inline = [
  #          "chmod +x /tmp/nginx.sh",
  #          "sudo /tmp/nginx.sh"
  #     ]
  # }


  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt -y install gnupg wget git curl vim build-essential gcc-multilib lib32z1 xinetd rsh-server rpcbind nfs-common nfs-kernel-server",
      # "echo '+ +' | sudo tee -a /root/.rhosts",
      # "sudo chmod 700 /root/.rhosts",
      # "echo 'rsh' | sudo tee -a /etc/securetty",
      "git clone https://github.com/vtky/tf-pt-lab.git",
      "cd $HOME/tf-pt-lab/assets",
      "tar xf vsftpd-2.3.4.tar.gz",
      "tar xf Unreal3.2.8.1.tar.gz",
      "sudo mkdir -p /usr/local/man/man8/",
      "sudo mkdir -p /usr/local/man/man5/",
      "sudo mkdir -p /usr/share/empty",
      "cd vsftpd-2.3.4 && CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS='-m32 -lcrypt' make",
      "sudo make install",
      "sudo cp -f $HOME/tf-pt-lab/assets/vsftpd.conf /etc/vsftpd.conf",
      "sudo cp $HOME/tf-pt-lab/assets/xinetd_vsftpd /etc/xinetd.d/vsftpd",
      "sudo useradd -s /bin/empty -m ftp",
      "sudo systemctl restart xinetd",
      # "cd $HOME/tf-pt-lab/assets/Unreal3.2"
      # "./configure",
      "echo '/       *(rw,sync,no_root_squash,no_subtree_check)' | sudo tee -a /etc/exports",
      "sudo exportfs -a",
      "sudo systemctl restart nfs-kernel-server"

    ]
  }
}

#Retrieve route53 zone ID  
data "aws_route53_zone" "dnszone" {
    name = var.zoneid
}


#create route53 records for client machines
resource "aws_route53_record" "clientsURL" {
    zone_id = data.aws_route53_zone.dnszone.zone_id
    type    = "A"
    ttl     = "300"
    count   =  var.client_instance_count
    name    = "client${count.index+1}"
    records = ["${element(aws_instance.clients.*.public_ip, count.index)}"]
}

#create route53 records for server machines
resource "aws_route53_record" "serversURL" {
  zone_id = data.aws_route53_zone.dnszone.zone_id
  type    = "A"
  ttl     = "300"
  count   = var.server_instance_count
  name    = "server${count.index+1}"
  records = ["${element(aws_instance.server.*.public_ip, count.index)}"]
}
