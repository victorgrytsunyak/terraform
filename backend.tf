terraform {
  backend "gcs" {
    bucket = "azimuth-bucket"
    prefix = "terraform"
  }
}