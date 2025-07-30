resource "hcloud_volume" "volume_exercise_17" {
  name     = "volume-exercise-17"
  size     = 10
  location = var.location
  format   = "xfs"
}
