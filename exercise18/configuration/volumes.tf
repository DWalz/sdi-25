resource "hcloud_volume" "volume_exercise_18" {
  name     = "volume-exercise-18"
  size     = 10
  location = var.location
  format   = "xfs"
}
