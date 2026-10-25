output "url_app" {
  value = "http://${aws_instance.app.public_ip}:3000"
}
output "instancia_id" {
  value = aws_instance.app.id
}