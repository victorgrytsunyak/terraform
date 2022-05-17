output "instances_foreach_id" {
  value = values({ for instance_id, instances_foreach_id in module.instances :
    instance_id => instances_foreach_id.instance_id
  })
}

output "vm_count_id" {
  value = values({ for instance_id, instances_count_id in module.instances_count :
    instance_id => instances_count_id.instance_id
  })
}

output "ip_address" {
    value = module.lb.ip_address
}