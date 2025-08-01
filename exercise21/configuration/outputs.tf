output "server_ip" {
  description = "IP of the server"
  value       = [for server in hcloud_server.exercise_21 : server.ipv4_address]
}

output "server_datacenter" {
  description = "Datacenter of the server"
  value       = [for server in hcloud_server.exercise_21 : server.datacenter]
}

output "volume_device" {
  description = "Linux device name of the volume"
  value       = [for volume in hcloud_volume.volume_exercise_21 : volume.linux_device]
}

