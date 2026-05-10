output "instance_public_ip" {
  value = aws_eip.k8s.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/repo/k8s-platform/terraform/k8s-platform ubuntu@${aws_eip.k8s.public_ip}"
}