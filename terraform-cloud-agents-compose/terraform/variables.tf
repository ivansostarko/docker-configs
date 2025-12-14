variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions for the target zone."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID."
  type        = string
}

variable "cloudflare_record_name" {
  description = "DNS record name (relative to zone), e.g. 'app' or 'terraform-agent-demo'."
  type        = string
}

variable "cloudflare_record_type" {
  description = "DNS record type, e.g. A, AAAA, CNAME, TXT."
  type        = string
  default     = "A"
}

variable "cloudflare_record_value" {
  description = "Record content/value."
  type        = string
}

variable "cloudflare_record_ttl" {
  description = "TTL in seconds. 1 may represent 'automatic' for some record types."
  type        = number
  default     = 300
}

variable "cloudflare_record_proxied" {
  description = "Whether Cloudflare proxy (orange cloud) is enabled."
  type        = bool
  default     = false
}
