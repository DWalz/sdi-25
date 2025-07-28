output "server_ip" {
  description = "IP of the server created in exercise 13"
  value       = hcloud_server.exercise_13.ipv4_address
}

output "server_datacenter" {
  description = "Datacenter of the server created in exercise 13"
  value       = hcloud_server.exercise_13.datacenter
}

