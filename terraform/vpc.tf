
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  
  #required for eks. Enable dns support
  enable_dns_support = true
  enable_dns_hostnames = true
  
    tags = {
      Name = "main"
    }
}
output "vpc_id" {
    value = aws_vpc.main.id     
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
resource "aws_subnet" "public1" {
    vpc_id = aws_vpc.main.id
    availability_zone = var.availability_zone1
    cidr_block = "192.168.0.0/18"
    map_public_ip_on_launch = true

    tags = {
        Name = "public-us-east-1a"
        #this required to eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

resource "aws_subnet" "public2" {
    vpc_id = aws_vpc.main.id
    availability_zone = var.availability_zone2
    cidr_block = "192.168.64.0/18"
    map_public_ip_on_launch = true

    tags = {
        Name = "public-us-east-1b"
        #this required to eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}
resource "aws_subnet" "private1" {
    vpc_id = aws_vpc.main.id
    availability_zone = var.availability_zone1
    cidr_block = "192.168.128.0/18"
    map_public_ip_on_launch = false

    tags = {
        Name = "private-us-east-1a"
        #this required to eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

resource "aws_subnet" "private2" {
    vpc_id = aws_vpc.main.id
    availability_zone = var.availability_zone2
    cidr_block = "192.168.192.0/18"
    map_public_ip_on_launch = false

    tags = {
        Name = "private-us-east-1b"
        #this required to eks
        "kubernetes.io/cluster/eks" = "shared"
        "kubernetes.io/role/elb" = 1
    }
}

#resource "aws_eip" "nat1" {
#  depends_on = [
#    aws_internet_gateway.main
#  ]
#}

#resource "aws_nat_gateway" "gw1" {
#    allocation_id = aws_eip.nat1.id
#    subnet_id = aws_subnet.public1.id         
#}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route  {
    cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.main.id 
 
  }
    tags = {
      Name = "main"
    }

}
#resource "aws_route_table" "private" {
#    vpc_id = aws_vpc.main.id
#    route {
#        cidr_block = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.gw1.id
#    }
#}
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
#resource "aws_route_table_association" "pirvate1" {
#  subnet_id      = aws_subnet.private1.id
#  route_table_id = aws_route_table.private.id
#}

#resource "aws_route_table_association" "private2" {
#  subnet_id      = aws_subnet.private2.id
#  route_table_id = aws_route_table.private.id
#}
resource "aws_security_group" "mysql" {
  vpc_id = aws_vpc.main.id 
  name = "mysql"
   ingress {
    description      = "mysqlports"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}