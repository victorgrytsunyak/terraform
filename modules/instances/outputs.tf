output "ip_centos" {
  value = google_compute_instance.vm-centos.network_interface.0.network_ip
}

output "ip_ubuntu" {
  value = google_compute_instance.vm-ubuntu.network_interface.0.network_ip
}