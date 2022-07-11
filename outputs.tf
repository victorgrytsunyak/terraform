# output "instances_foreach_id" {
#   value = values({ for instance_id, instances_foreach_id in module.instances :
#     instance_id => instances_foreach_id.instance_id
#   })
# }

# output "vm_count_id" {
#   value = values({ for instance_id, instances_count_id in module.instances_count :
#     instance_id => instances_count_id.instance_id
#   })
# }

# output "ip_address" {
#   value = module.lb.ip_address
# }

# output "global_ip_address" {
#   value = google_compute_global_address.lb_global_ip.address
# }

output "network" {
  value = module.network.network_id
}

output "bastion_ip" {
  value       = google_compute_instance.bastion.network_interface.0.network_ip
  description = "The IP address of the Bastion instance."
}

output "ssh" {
  description = "GCloud ssh command to connect to the Bastion instance."
  value       = "gcloud compute ssh ${google_compute_instance.bastion.name} --project ${var.project} --zone ${google_compute_instance.bastion.zone}"
}