# Configuración de Terraform para los proveedores necesarios
terraform {
    # Declaramos los proveedores requeridos
    required_providers {
        # Proveedor de Azure Resource Manager (azurerm)
        azurerm = {
        source  = "hashicorp/azurerm"       # Especificamos el origen del proveedor
        version = "~>3.0"                   # Utilizamos cualquier versión mayor igual a 3.0
        }

    # Proveedor Random (random) - usado para generar valores aleatorios
    random = {
        source  = "hashicorp/random"        # Especificamos el origen del proveedor 
        version = "~>3.0"                   # Utilizamos cualquier versión mayor igual a 3.0
        }
    }
}

# Configuración del proveedor de Azure Resource Manager (azurerm)
provider "azurerm" {
    # El bloque "features" es requerido aunque no contenga opciones específicas
    # Permite habilitar características adicionales del proveedor.
    features {}
}
