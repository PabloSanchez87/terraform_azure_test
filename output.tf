# Definición de los outputs para la configuración de Terraform

# Output que expone el nombre del grupo de recursos creado
output "resource_group_name" {
    value       = azurerm_resource_group.rg.name  # Referencia al nombre del grupo de recursos creado.
    description = "El nombre del grupo de recursos creado en Azure."  # Descripción del output.
}

# Output que expone la dirección IP pública de la máquina virtual principal
output "public_ip_address" {
    value       = azurerm_windows_virtual_machine.main.public_ip_address    # Referencia a la IP pública de la VM.
    description = "La dirección IP pública de la máquina virtual principal."  # Descripción del output.
}

# Output que expone la contraseña del administrador de la máquina virtual
output "admin_password" {
    sensitive   = true                                  # Indica que este output es sensible y no debe mostrarse en texto plano.
    value       = azurerm_windows_virtual_machine.main.admin_password  # Referencia a la contraseña de administrador de la VM.
    description = "La contraseña del administrador para la máquina virtual principal."  # Descripción del output.
}
