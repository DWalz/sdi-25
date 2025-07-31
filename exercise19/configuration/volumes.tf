resource "hcloud_volume" "volume_exercise_19" {
  name     = "volume-exercise-19"
  size     = 10
  location = var.location
  format   = "xfs"
}
