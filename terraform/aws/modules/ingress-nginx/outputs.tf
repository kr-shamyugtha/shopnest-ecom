output "public_ips" {
  description = "The NLB's fixed addresses. Any of them works for <name>.<ip>.nip.io hostnames."
  value       = aws_eip.nlb[*].public_ip
}
