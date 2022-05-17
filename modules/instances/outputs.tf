output "instance_id" {
  description = "List of self-links for compute instances"
  value       = google_compute_instance.vms.id
}