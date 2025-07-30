output "server_ip" {
  description = "IP of the server"
  value       = hcloud_server.exercise_17.ipv4_address
}

output "server_datacenter" {
  description = "Datacenter of the server"
  value       = hcloud_server.exercise_17.datacenter
}

output "volume_device" {
  description = "Linux device name of the volume"
  value       = hcloud_volume.volume_exercise_17.linux_device
}

