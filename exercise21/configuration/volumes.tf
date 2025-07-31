resource "hcloud_volume" "volume_exercise_20" {
  count    = var.server_count
  name     = "volume-exercise-20-${count.index}"
  size     = 10
  location = var.location
  format   = "xfs"
}
