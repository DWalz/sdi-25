output "server_ip" {
  description = "IP of the server created in exercise 13"
  value       = hcloud_server.exercise_14.ipv4_address
}

output "server_datacenter" {
  description = "Datacenter of the server created in exercise 13"
  value       = hcloud_server.exercise_14.datacenter
}

