


#VPC作成
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_env}-vpc"
  }
}

#Subnet 作成

resource "aws_subnet" "dev_pub_subnet1" {

    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "${var.project_env}-public-subnet-a1"
    }
  
}
resource "aws_subnet" "dev_pub_subnet2" {

    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "${var.project_env}-public-subnet-1c"
    }
  
}
resource "aws_subnet" "dev_pri_subnet1" {

    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "${var.project_env}-pri-appsubnet-1a"
    }
  
}
resource "aws_subnet" "dev_pri_subnet2" {

    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "${var.project_env}-pri-appsubnet-1c"
    }
}
resource "aws_subnet" "dev_pri_subnet3" {

    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "${var.project_env}-pri-RDSsubnet-1a"
    }
  
}

resource "aws_subnet" "dev_pri_subnet4" {

    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = "10.0.5.0/24"
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "${var.project_env}-pri-RDSsubnet-1c"
    }
  
}

#igw作成

resource "aws_internet_gateway" "dev_igw" {
    vpc_id = aws_vpc.dev_vpc.id

    tags = {
        Name = "${var.project_env}-igw"
    }

  
}

#nat_gateway作成

resource "aws_eip" "dev_nat" {
    domain = "vpc"
    tags = {
        Name = "${var.project_env}-eip"
    }
  
}
resource "aws_nat_gateway" "nat_pub1" {
    allocation_id = aws_eip.dev_nat.id
    subnet_id = aws_subnet.dev_pub_subnet1.id
    tags = {
        Name ="${var.project_env}-nat-pub1"
    }
    depends_on = [ aws_internet_gateway.dev_igw ]
  
}

#route_table作成

#パブリックサブネット用ルートテーブル
resource "aws_route_table" "dev_pub_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
  Name = "${var.project_env}-pub-rt"}
}

resource "aws_route" "dev_internet_access" {
  route_table_id = aws_route_table.dev_pub_rt.id
  destination_cidr_block = "0.0.0.0/0" 
  gateway_id = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_pub1" {
    subnet_id = aws_subnet.dev_pub_subnet1.id
    route_table_id = aws_route_table.dev_pub_rt.id
  
}
resource "aws_route_table_association" "dev_pub2" {
    subnet_id = aws_subnet.dev_pub_subnet2.id
    route_table_id = aws_route_table.dev_pub_rt.id
  
}

#プライベートサブネットNATゲートウェイ用ルートテーブル

resource "aws_route_table" "dev_pri_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "${var.project_env}-pri-rt"}
  
}
resource "aws_route" "dev_pri_nat_access" {
  route_table_id = aws_route_table.dev_pri_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_pub1.id
  
}
resource "aws_route_table_association" "dev_pri1" {
  subnet_id = aws_subnet.dev_pri_subnet1.id
  route_table_id = aws_route_table.dev_pri_rt.id
  
}
resource "aws_route_table_association" "dev_pri2" {
  subnet_id = aws_subnet.dev_pri_subnet2.id
  route_table_id = aws_route_table.dev_pri_rt.id
  
}

#RDS配置プライベートサブネット用ルートテーブル

resource "aws_route_table" "dev_pri3_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "${var.project_env}-pri3-rt"}
  
}

resource "aws_route_table_association" "dev_pri3" {
  subnet_id = aws_subnet.dev_pri_subnet3.id
  route_table_id = aws_route_table.dev_pri3_rt.id
  
}
resource "aws_route_table_association" "dev_pri4" {
  subnet_id = aws_subnet.dev_pri_subnet4.id
  route_table_id = aws_route_table.dev_pri3_rt.id
  
}

#セキュリティグループ
# resource "aws_security_group" "alb_sg" {
#     vpc_id = aws_vpc.dev_vpc.id
#     name = "alb_sg"

#     tags = {
#         Name = "${var.project_env}-web-sg"}
#     }
  
# resource "aws_vpc_security_group_ingress_rule" "web_http" {
#     security_group_id = aws_security_group.alb_sg.id

#     cidr_ipv4 = "0.0.0.0/0"
#     from_port = 80
#     ip_protocol = "tcp"
#     to_port = 80

# }

# resource "aws_vpc_security_group_ingress_rule" "web_https" {
#     security_group_id = aws_security_group.alb_sg.id

#     cidr_ipv4 = "0.0.0.0/0"
#     from_port = 443
#     ip_protocol = "tcp"
#     to_port = 443
 
# }
# resource "aws_vpc_security_group_egress_rule" "web_egress_all" {
#   security_group_id = aws_security_group.alb_sg.id

#   cidr_ipv4   = "0.0.0.0/0"
#   ip_protocol = "-1"
# }
