# Salida que muestra la región en donde se realizaron las pruebas
output "aws_region" {
  description = "Región en la cual se han realizado las pruebas"
  value       = var.region
}

# Salida que muestra las IP's publicas generadas para las VM
output "expected_public_ips" {
  description = "IP's publicas generadas para las VM"
  value = [
    for vm in module.module_VM :
    try(vm.public_ip, "")
  ]
}