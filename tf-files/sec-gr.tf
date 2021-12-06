resource "aws_security_group" "server-sg" {
  name = "WebServerSecurityGroup"
  vpc_id = "vpc-0328947e"  # or data.aws_vpc.selected.id
  tags = {
    "Name" = "TF_WebServerSecurityGroup"
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb-sg.id]  #alb nin sec grubundan geleni al
    to_port = 80
  }
  ingress {
    from_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    to_port = 22
  }
  egress {
    from_port = 0
    protocol = -1    # tum protokolleri al
    cidr_blocks = ["0.0.0.0/0"]
    to_port = 0
  }
}
resource "aws_security_group" "alb-sg" {
  name = "ALBSecurityGroup"
  vpc_id = "vpc-0328947e"    # or data.aws_vpc.selected.id
  tags = {
    "Name" = "TF_ALBSecurityGroup"
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    to_port = 80
  }
  egress {
    from_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    to_port = 0
  }
}
resource "aws_security_group" "db-sg" {
  name = "RDSSecurityGroup"
  vpc_id = "vpc-0328947e"    # or data.aws_vpc.selected.id
  tags = {
    "Name" = "TF_RDSSecurityGroup"
  }
  ingress {
    from_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.server-sg.id]   # ec2larin sec gruptan gelen
    to_port = 3306
  }
  egress {
    from_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    to_port = 0
  }
}