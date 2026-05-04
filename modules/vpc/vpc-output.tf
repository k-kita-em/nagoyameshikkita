output "vpc_id" {
    value = aws_vpc.dev_vpc.id
  
}
output "ecs_subnet1a" {
    value = aws_subnet.dev_pri_subnet1.id
  
}
output "ecs_subnet1c" {
    value = aws_subnet.dev_pri_subnet2.id
  
}
# output "alb_security_group" {
#     value = aws_security_group.dev_vpc_sg.id
  
# }
output "public_subnet1a" {
    value = aws_subnet.dev_pub_subnet1.id
  
}
output "public_subnet1c" {
    value = aws_subnet.dev_pub_subnet2.id
  
}

output "db_subnet1a" {
    value = aws_subnet.dev_pri_subnet3.id
  
}
output "db_subnet1c" {
    value = aws_subnet.dev_pri_subnet4.id
  
}