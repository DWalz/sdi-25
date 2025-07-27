output "server_ip" {
  description = "IP of the server created in exercise 12"
  value       = hcloud_server.exercise_12.ipv4_address
}

output "server_datacenter" {
  description = "Datacenter of the server created in exercise 12"
  value       = hcloud_server.exercise_12.datacenter
}

