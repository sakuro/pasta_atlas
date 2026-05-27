# frozen_string_literal: true

namespace :terraform do
  namespace :local do
    chdir = "terraform/environments/local"

    desc "Run terraform plan for local"
    task(:plan) { sh "terraform -chdir=#{chdir} plan" }

    desc "Run terraform apply for local"
    task(:apply) { sh "terraform -chdir=#{chdir} apply" }
  end

  namespace :production do
    chdir = "terraform/environments/production"
    env = {"AWS_ENDPOINT_URL" => nil, "AWS_PROFILE" => "terraform"}

    desc "Run terraform plan for production"
    task(:plan) { sh env, "terraform -chdir=#{chdir} plan" }

    desc "Run terraform apply for production"
    task(:apply) { sh env, "terraform -chdir=#{chdir} apply" }
  end
end
