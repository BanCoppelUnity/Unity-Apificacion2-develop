output "vms_data" {
  description = "Mapa de objetos con las información de los identificadores de las instancias creadas, las IPs privadas y la IPs públicas (en caso de existir) asociadas a ellas"
  value       = module.module_VM
}
