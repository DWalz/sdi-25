resource "hcloud_volume" "volume_exercise_15" {
  name      = "volume-exercise-15"
  size      = 10
  server_id = hcloud_server.exercise_15.id
  automount = true
  format    = "xfs"
}
