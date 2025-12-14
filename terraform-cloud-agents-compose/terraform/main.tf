terraform {
  required_version = ">= 1.6.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.14"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "sample" {
  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_record_name
  type    = var.cloudflare_record_type
  content = var.cloudflare_record_value
  ttl     = var.cloudflare_record_ttl
  proxied = var.cloudflare_record_proxied
}

output "record_fqdn" {
  value = cloudflare_record.sample.name
}
