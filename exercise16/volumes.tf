resource "hcloud_volume" "volume_exercise_16" {
  name     = "volume-exercise-16"
  size     = 10
  location = var.location
  format   = "xfs"
}
