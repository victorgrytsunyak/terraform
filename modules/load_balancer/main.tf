terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_instance_group" "webservers" {
  project     = var.project
  zone        = var.zone
  name        = var.group_name //"terraform-webservers"
  description = "Terraform instance group"

  instances = var.instances  //concat(module.instances_count[*].instance_id, local.foreach_instnaces[*])

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

}

resource "google_compute_global_forwarding_rule" "global_forwarding_http_rule" {
  name       = var.global_forwarding_rule_name //"az-global-forwarding-https-rule"
  project    = var.project
  target     = google_compute_target_https_proxy.target_https_proxy.self_link
  port_range = var.forwarding_port //"443"
}

# used by one or more global forwarding rule to route incoming HTTPS requests to a URL map
resource "google_compute_target_https_proxy" "target_https_proxy" {
  name             = var.proxy_name //"az-proxy"
  project          = var.project
  url_map          = google_compute_url_map.url_map_http.self_link
  ssl_certificates = [google_compute_ssl_certificate.ssl.id]

}

resource "google_compute_ssl_certificate" "ssl" {
  name        = var.ssl_name //"my-certificate"
  private_key = var.privat_key //file("private.key")
  certificate = var.certificate //file("certificate.crt")
}

resource "google_compute_backend_service" "backend_http_service" {
  name          = var.backend_name // "az-http-backend-service"
  project       = var.project
  port_name     = var.backend_port_name //"http"
  protocol      = var.backend_port //"HTTP"
  health_checks = ["${google_compute_health_check.healthcheck.self_link}"]

  backend {
    group                 = google_compute_instance_group.webservers.self_link
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }
}

resource "google_compute_health_check" "healthcheck" {
  name               = var.healthcheck_name //"az-http-healthcheck"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = 80
  }
}

# used to route requests to a backend service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map_http" {
  name            = var.url_map_name //"az-https-load-balancer"
  project         = var.project
  default_service = google_compute_backend_service.backend_http_service.self_link
}