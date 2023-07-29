terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.1"
    }
  }
}

provider "digitalocean" {}

resource "digitalocean_app" "website" {
  spec {
    name   = "website"
    region = "nyc"

    domain {
      name = "matthewsanabria.dev"
      type = "PRIMARY"
    }

    alert {
      rule = "DEPLOYMENT_FAILED"
    }

    alert {
      rule = "DOMAIN_FAILED"
    }

    static_site {
      name = "hugo"

      dockerfile_path = "Dockerfile"
      output_dir      = "/app/public"

      github {
        repo           = "sudomateo/website"
        branch         = "main"
        deploy_on_push = true
      }
    }
  }
}

output "app" {
  value = digitalocean_app.website
}
