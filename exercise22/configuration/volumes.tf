resource "hcloud_volume" "volume_exercise_22" {
  name     = "volume-exercise-22"
  size     = 10
  location = var.location
  format   = "xfs"
}
