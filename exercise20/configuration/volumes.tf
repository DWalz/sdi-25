resource "hcloud_volume" "volume_exercise_20" {
  name     = "volume-exercise-20"
  size     = 10
  location = var.location
  format   = "xfs"
}
