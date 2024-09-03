# Definición de variables para la configuración de Terraform

# Variable para especificar la ubicación del grupo de recursos en Azure
variable "resource_group_location" {
    default     = "eastus"  # Valor predeterminado, se usa 'eastus' como región.
    description = "Location of the resource group"  # Descripción de la variable.

    # Validación para asegurar que la ubicación sea una región válida de Azure.
    validation {
        condition     = contains(["eastus", "westus", "centralus", "westeurope", "northeurope"], var.resource_group_location)
        error_message = "La ubicación debe ser una de las siguientes: eastus, westus, centralus, westeurope, northeurope."
    }
}

# Variable para definir un prefijo que se usará en los nombres de los recursos
variable "prefix" {
    type        = string                            # Tipo de la variable, en este caso, un string.
    default     = "win-vm-iis"                      # Prefijo predeterminado para los nombres de recursos.
    description = "Prefix of the resource name"     # Descripción de la variable.

    # Validación para asegurar que el prefijo no esté vacío y cumpla con una longitud mínima.
    validation {
        condition     = length(var.prefix) > 0
        error_message = "El prefijo no puede estar vacío."
    }
}

