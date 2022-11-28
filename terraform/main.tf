#Create a VPC
resource "aws_vpc" "my-vpc"{
    cidr_block= "10.0.0.0/16"
    Tags{
        Name= "demo_VPC"
    }
}

#Create web Public Subnet
resource "aws_subnet" "web-subnet-1"{
    vpc_id= aws_vpc.my-vpc.id
    cidr_block= "10.0.1.0/24"
    availability_zone= "us-east-1a"
    map_public_ip_on_launch= true
Tags{
    Name= "Web-1a"
}
}

resource "aws_subnet" "web-subnet-2" {
    vpc_id= aws-vpc.my-vpc.id
    cidr_block= "10.0.2.0/24"
availability_zone= "us-east-1b"
map_public_ip_on_launch= true
tags{
    Name= "Web-2b"
}  
}

#Create Application Public Subnet
resource "aws_subnet" "application-subnet-1" {
    vpc_id= aws_vpc.my-vpc.id
    cidr_block= "10.0.11.0/24"
    availability_zone= "us-east-1a"
    map_public_ip_on_launch= false
    tags{
        Name= "Application-1a"
    }
}

resource "aws_subnet" "application-subnet-2" {
    vpc_id= aws_vpc.my-vpc.id
    cidr_block= "10.0.12.0/24"
  availabilty_zone= "us-east-1b"
  map_public_ip_on_launch= false
  tags{
    Name= "Application-2b"
  }
}

#Create databasr private Subnet
resource "aws_subnet" "database-subnet-1" {
  vpc_id= aws_vpc.my-vpc.id
  cidr_block= "10.0.21.0/24"
  availability_zone= "us-east-1a"
  tags{
    Name= "Database-1a"
  }
}

resource "aws_subnet" "database-subnet-2" {
    vpc_id= aws_vpc.my-vpc.id
cidr_block= "10.0.22.0/24"
availability_zone= "us-east-1b"
tags{
    Name= "Database-2b"
}  
}

resource "aws_subnet" "database-subnet" {
    vpc_id= aws_vpc.my-vpc.id
cidr_block= "10.0.3.0/24" 
availability_zone= "us-east-1a"
tags{
    Name= "Database"
} 
}

#Create Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id= aws_vpc.my-vpc.id
tags{
    Name= "Demo IGW"
}
}

#Create Web layer route
resource "aws_route_table" "web-rt" {
    vpc_id= aws_vpc.my-vpc.id
route{
    cidr_block= "0.0.0.0/0"
    gateway_id= aws_internet_gateway.igw.id
}
tags{
    Name= "WebRT"
}
}

#create web subnet association with web route table
resource "aws_route_table_association" "a" {
    subnet_id= aws_subnet.web-subnet-1.route_table_id
    route_table_id= aws_route_table.web-rt.web-route_table_id
}

resource "aws_main_route_table_association" "b" {
    subnet_id= aws_subnet.web-subnet-2.route_table_id
    route_table_id= aws_route_table.web-rt.route_table_id
}

#Creating EC2 instance
resource "aws_instance" "webserver1" {
  ami= "ami-id"
  instance_type= "t2.micro"
  availability_zone= "us-east-1a"
  vpc_security_group_ids= [aws_subnet_group.webserver-sg.vpc_security_group_ids]
  subnet_id= aws_subnet.web-subnet-1.subnet_id
  user_data= file("install_apace.sh")
  tags{
    Name= "webserver"
  }
}

resource "aws_instance" "webserver2" {
  ami= "ami-id"
  instance_type= "t2.micro"
  availability_zone= "us-east-1b"
  vpc_security_group_ids= [aws_subnet_group.webserver-sg.vpc_security_group_ids]
  subnet_id= aws_subnet.web-subnet-2.subnet_id
  user_data= file("install_apace.sh")
  tags{
    Name= "webserver"
}
}

#Create web SecurityGroup
resource "aws_security_group" "web-sg" {
    name= "web-SG"
    description= "Allow HTTP inbound traffic"
    vpc_id= aws_vpc.my-vpc.vpc_id

ingress{
    description= "HTTP from VPC"
    from_port= 80
    to_port=80
    protocol="tcp"
    cidr_block= ["0.0.0.0/0"]
}  
}
egress{
    from_port=0
    to_port=0
    protocol= -1
    cidr_block= ["0.0.0.0/0"]
}
tags{
    Name="Web-SG"
}

#Creating Application Security Group
resource "aws_security_group" "webserver-sg" {
    name= "webserver-SG"
    description="Allow inbound traffic from ALB"
    vpc_id= aws_vpc.my-vpc.vpc_id

    ingress{
        description= "Allow traffic from web layer"
        from_port= 80
        to_port= 80
        protocol= "tcp"
        security_groups= [aws_security_group.web-sg.id]
    }
        
        egress{
            from_port=0
            to_port=0
            protocol= "-1"
            cidr_block=["0.0.0.0/0"]
        }
        tags{
            Name= "Webserver-SG"
        }
    }
    
    

    #Create Database Security Group
    resource "aws_security_group" "database-sg"{
name="database-SG"
description= "Allow inbound traffic from application layer"
vpc_id= aws_vpc.my-vpc.vpc_id

ingress{
    description= "All traffic from application layer"
    from_port= 3306
    to_port= 3306
    protocol= "tcp"
    security_groups= [aws_security_group.webserver-sg.id]
}

egress{
    from_port= 32768
    to_port= 65535
    protocl= "tcp"
    cidr_block= ["0.0.0.0/0"]
}
tags{
    Name= "database-SG"
}
}
resourse "aws_lb_target_group" "extrenal-elb"{
    name="ALB-TG"
    port=80
    protocol="HTTP"
    vpc_id=aws_vpc.my-vpc.id
}
  resource "aws_lb_target_group_attachment" "external-elb1" {
    target_group_arn= aws_lb_target_group.external-elb.arn
    target_id= aws_instance.webserver1.id
    port= 80
    depends_on = [
      aws_instance.webserver1,
    ]
    }
    resource "aws_lb_target_group_attachment" "external-elb2" {
        target_group_arn= aws_lb_target_group.external-elb2.arn
        target_id= aws_instance.webserver2.id
        port= 80
        depends_on = [
          aws_instance.webserver2,
        ]
      
    }
resource "aws_lb_listener" "external-elb" {
    load_balancer_arn= aws_lb.external-elb.arn
port= 80
protocol= "HTTP"
default_action{
    type= "forward"
    target_group_arn= aws_lb_target_group.external-elb.arn
}  
}
resource "aws_db_instance" "default" {
allocated_storage= 10
db_subnet_group_name= aws_db_subnet_group.default.identifier
engine= "mysql"
engine_version= "8.0.20"
instance_class= "db.t2.micro"
multi_az= true
name= "mydb"
username= "username"
password= "password"
skip_final_snapshot= true
vpc_security_group_ids= [aws_security_group.database-sg.id] 
}
resource "aws_lb_subnet_group" "default" {
    name="main"
subnet_ids= [aws_subnet.database-subnet-1.id,aws_subnet.database-subnet-2.id] 
tags{
    Name= "My DB subnet group"
}
} 
