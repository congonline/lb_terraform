output "proj_sharedvpc_id" {
  value = google_project.vpc_host_proj.project_id
}

output "vpc_network" {
  value = module.vpc.network
}

output "vpc_network_selflink" {
  value = module.vpc.network_self_link
}

output "vpc_subnets" {
  value = module.vpc.subnets
}
