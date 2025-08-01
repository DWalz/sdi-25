resource "hcloud_volume" "volume_exercise_21" {
  count    = var.server_count
  name     = "volume-exercise-21-${count.index}"
  size     = 10
  location = var.location
  format   = "xfs"
}
