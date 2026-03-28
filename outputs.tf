output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "hello_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/hello"
}