terraform {
  backend "gcs" {
    bucket = "azimuthtv10-bucket"
    prefix = "terraform"
  }
}