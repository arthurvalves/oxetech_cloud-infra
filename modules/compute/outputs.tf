output "ec2_public_ip"   { value = aws_instance.web.public_ip }
output "api_gateway_url" { value = aws_apigatewayv2_stage.default.invoke_url }