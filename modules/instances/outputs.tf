output "instance_id" {
  description = "List of self-links for compute instances"
  value       = google_compute_instance.vms.id
}

# output "vm_id" {
#   value = { for instance_id, instances in google_compute_instance.vms.id :
#     instance_id => instances.instance_id
#   }
# }