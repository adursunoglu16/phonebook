//data "aws_vpc" "selected" {
//  default = true
//} eger manuel ekleme yerine vpc id yi otomatik olarak cekmek istersen

//data "aws_subnets" "example" {
  //filter {
    //name = "vpc-id"
    //values = [data.aws_vpc.selected.id]
  //}
//} alb olusturuken tum subnetleri eklememiz lazim. manuel olarak ekleme disinda otomatize de edebiliriz boylece

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
resource "aws_launch_template" "asg-lt" {
  name = "phonebook-lt"
  image_id = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = "pablokeys"
  vpc_security_group_ids = [aws_security_group.server-sg.id]
  user_data = filebase64("user-data.sh")
  depends_on = [github_repository_file.dbendpoint]
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "Web Server of Phonebook App"
    }
  }
}
resource "aws_alb_target_group" "app-lb-tg" {
  name = "phonebook-lb-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = "vpc-0328947e" //data.aws_vpc.selected.id
  target_type = "instance"
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}
resource "aws_alb" "app-lb" {
  name = "phonebook-lb-tf"
  ip_address_type = "ipv4"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = ["subnet-847bccb5", "subnet-e28de3c3", "subnet-9b3b58fd","subnet-3627147b","subnet-566a0609","subnet-b3795cbd"]
            //data.aws_subnets.example.ids
}
resource "aws_alb_listener" "app-listener" {
    load_balancer_arn = aws_alb.app-lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.app-lb-tg.arn
    }
}
resource "aws_autoscaling_group" "app-asg" {
  name = "phonebook-asg"
  desired_capacity = 2
  max_size = 3
  min_size = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  target_group_arns = [aws_alb_target_group.app-lb-tg.arn]
  vpc_zone_identifier = aws_alb.app-lb.subnets
  launch_template {
    id = aws_launch_template.asg-lt.id
    version = aws_launch_template.asg-lt.latest_version
  }
}
resource "aws_db_instance" "db-server" {
  instance_class = "db.t2.micro"
  allocated_storage = 20
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade = true
  backup_retention_period = 0 
  identifier = "phonebook-app-db"
  name = "phonebook"  // must be same with db values in the phonebook-app.py
  engine = "mysql"
  engine_version = "8.0.20"
  username = "admin" // must be same with db values in the phonebook-app.py
  password = "Dursun_1" // must be same with db values in the phonebook-app.py
  multi_az = false
  port = 3306  // must be same with db values in the phonebook-app.py
  publicly_accessible = false
  skip_final_snapshot = true //not taking final snapshot when we terminate
  monitoring_interval = 0
}
resource "github_repository_file" "dbendpoint" {
  content = aws_db_instance.db-server.address
  file = "dbserver.endpoint"  // must be same with db values in the phonebook-app.py
  repository = "phonebook"    // must be same with my repo for this project
  overwrite_on_create = true
  branch = "master"      // check your repo 'master' or 'main'
}

// burada oncelikle terraform apply deyince rds icin bir dbendpoint oluscak ve o github repoya gitcek. 
//ec2lar olusurken launch template phonebook-app.py kullanarak bu db endpoint ile ec2lari iletisime gecircek.
//Launch template e bakarsan zaten github i depends on yaptik yani once github file oluscak sonra lt harekete geccek