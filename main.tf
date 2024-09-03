# Creación de grupo de recursos.
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location                      # Ubicación del grupo de recursos, usando la variable definida.
  name     = "${random_pet.prefix.id}-rg"                     # Nombre del grupo de recursos, generado dinámicamente.
} 

# Creación de Virtual Network.
# NOTE: address_space podría ser una variable si se prevé que esto pueda cambiar en el futuro.
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${random_pet.prefix.id}-vnet"        # Nombre de la red virtual, generado dinámicamente.
  address_space       = ["10.2.0.0/16"]                       # Espacio de direcciones de la red virtual.
  location            = azurerm_resource_group.rg.location    # Ubicación, misma que el grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name        # Nombre del grupo de recursos.

}

# Creación de una subnet.
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${random_pet.prefix.id}-subnet"                   # Nombre de la subnet, generado dinámicamente.
  resource_group_name  = azurerm_resource_group.rg.name                     # Nombre del grupo de recursos.
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name  # Nombre de la red virtual.
  address_prefixes     = ["10.2.1.0/24"]                                    # Prefijo de direcciones de la subnet.
}

# Creación de IP pública.
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${random_pet.prefix.id}-public-ip"     # Nombre de la IP pública, generado dinámicamente.
  location            = azurerm_resource_group.rg.location      # Ubicación, misma que el grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name          # Nombre del grupo de recursos.
  allocation_method   = "Dynamic"                               # Método de asignación de IP, en este caso dinámico.
}


# Creación del security group(NSG) y regla para permitir RDP por Port-3389
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${random_pet.prefix.id}-nsg"  # Nombre del NSG, generado dinámicamente.
  location            = azurerm_resource_group.rg.location  # Ubicación, misma que el grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name  # Nombre del grupo de recursos.
  
  # Regla de seguridad para permitir RDP
  security_rule {
    name                       = "Allow_RDP"
    priority                   = "1000"       # Prioridad de la regla.
    direction                  = "Inbound"    # Dirección del tráfico permitido.
    access                     = "Allow"      # Tipo de acceso, en este caso, permitido.
    protocol                   = "Tcp"        # Protocolo utilizado, en este caso TCP.
    source_port_range          = "*"          # Rango de puertos de origen.
    destination_port_range     = "3389"       # Rango de puertos de destino (RDP).
    source_address_prefix      = "*"          # Prefijo de direcciones de origen.
    destination_address_prefix = "*"          # Prefijo de direcciones de destino.
  }
}



# Creación de la Interfaz de Red para la Máquina Virtual
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${random_pet.prefix.id}-nic"       # Nombre de la interfaz de red, generado dinámicamente.
  location            = azurerm_resource_group.rg.location  # Ubicación, misma que el grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name      # Nombre del grupo de recursos.

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id         # ID de la subnet asociada.
    private_ip_address_allocation = "Dynamic"                                     # Asignación de IP privada, en este caso dinámica.
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id   # ID de la IP pública asociada.
  }
}


# Creación de la conexión del NSG a la Interfaz de Red
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id        = azurerm_network_interface.my_terraform_nic.id       # ID de la interfaz de red.
  network_security_group_id   = azurerm_network_security_group.my_terraform_nsg.id  # ID del NSG.
}


# Creación de Storage Account para Boot Diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"     # Nombre del Storage Account, usando un ID aleatorio.
  location                 = azurerm_resource_group.rg.location   # Ubicación, misma que el grupo de recursos.
  resource_group_name      = azurerm_resource_group.rg.name       # Nombre del grupo de recursos.
  account_tier             = "Standard"                           # Nivel de la cuenta de almacenamiento.
  account_replication_type = "LRS"                                # Tipo de replicación de la cuenta de almacenamiento (Local Redundant Storage).
}


# Creación de la Máquina Virtual (Windows)
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${random_pet.prefix.id}-vm"                      # Nombre de la VM, generado dinámicamente.
  location              = azurerm_resource_group.rg.location                # Ubicación, misma que el grupo de recursos.
  resource_group_name   = azurerm_resource_group.rg.name                    # Nombre del grupo de recursos.
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]   # Interfaz de red de la VM.
  size                  = "Standard_DS1_V2"                                 # Tamaño de la VM.

  # Configuración del usuario administrador
  admin_username = "adminuser"                      # Nombre del usuario administrador.
  admin_password = random_password.password.result  # Contraseña del usuario administrador, generada aleatoriamente.

  # Configuración del disco del sistema operativo
  os_disk {
    name                = "myOsDisk"          # Nombre del disco del sistema operativo.
    caching             = "ReadWrite"         # Caché del disco.
    storage_account_type = "Premium_LRS"      # Tipo de almacenamiento.
  }

  # Referencia a la imagen del sistema operativo
  source_image_reference {
    publisher = "MicrosoftWindowsServer"          # Publicador de la imagen.
    offer     = "WindowsServer"                   # Oferta de la imagen.
    sku       = "2022-datacenter-azure_edition"   # SKU de la imagen.
    version   = "latest"                          # Versión de la imagen.
  }

  # Configuración de diagnósticos de arranque
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint  # URI de la cuenta de almacenamiento para diagnósticos.
  }
}


# Instalar IIS webserver en la máquina virtual
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "${random_pet.prefix.id}-wsi"            # Nombre de la extensión.
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id  # ID de la VM.
  publisher                  = "Microsoft.Compute"                      # Publicador de la extensión.
  type                       = "CustomScriptExtension"                  # Tipo de la extensión.
  type_handler_version       = "1.8"                                    # Versión del manejador de la extensión.
  auto_upgrade_minor_version = true                                     # Actualización automática de versiones menores.

  # Comando
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}


# Generar un texto aleatorio para el nombre del Storage Account
resource "random_id" "random_id" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name  # Genera un nuevo ID cuando se define un nuevo grupo de recursos.
  }
  byte_length = 8  # Longitud en bytes del ID generado.
}

# Generar una contraseña aleatoria para el administrador de la máquina virtual
resource "random_password" "password" {
  length      = 20    # Longitud de la contraseña generada.
  min_lower   = 1     # Mínimo de letras minúsculas.
  min_upper   = 1     # Mínimo de letras mayúsculas.
  min_numeric = 1     # Mínimo de números.
  min_special = 1     # Mínimo de caracteres especiales.
  special     = true  # Incluir caracteres especiales.
}


# Generar un prefijo aleatorio para los nombres de recursos
resource "random_pet" "prefix" {
  prefix = var.prefix   # Prefijo para el nombre aleatorio.
  length = 1            # Longitud del sufijo generado.
}


