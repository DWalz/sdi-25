output "server_ip" {
  description = "IP of the server"
  value       = hcloud_server.exercise_22.ipv4_address
}

output "server_datacenter" {
  description = "Datacenter of the server"
  value       = hcloud_server.exercise_22.datacenter
}

output "volume_device" {
  description = "Linux device name of the volume"
  value       = hcloud_volume.volume_exercise_22.linux_device
}

