output "ecs_security_group" {
    value = aws_security_group.dev_ecs_sg.id
  
}
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}
output "alb_security_group" {
  value = aws_security_group.alb_sg
  
}