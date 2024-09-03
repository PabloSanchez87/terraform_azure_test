# Creación de grupo de recursos.
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${random_pet.prefix.id}-rg"
}

# Creación de Virtual Network.
resource "azurerm_virtual_network" "my_terraform_network"{
  name                = "${random_pet.prefix.id}-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location     #coge la ubicación del grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name         #coge el nombre del grupo de recursos.
}

# Creación de una subnet.
resource "azurerm_subnet" "my_terraform_subnet"{
  name                 = "${random_pet.prefix.id}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name        #coge el nombre del grupo de recursos.
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name  #indicamos de que red es.
  address_prefixes     = ["10.2.1.0/24"]
}

# Creación de IP pública.
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${random_pet.prefix.id}-public-ip"  
  location            = azurerm_resource_group.rg.location     #coge la ubicación del grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name         #coge el nombre del grupo de recursos.
  allocation_method   =  "Dynamic"
}


# Creación del security group(NSG) y regla para permitir RDP por Port-3389
resource "azurerm_network_security_group" "my_terraform_nsg"{
  name                = "${random_pet.prefix.id}-nsg"
  location            = azurerm_resource_group.rg.location     #coge la ubicación del grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name         #coge el nombre del grupo de recursos.
 
    security_rule {
      name                       = "Allow_RDP"
      priority                   = "1000"                     # Por debajo de 5000.
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"                        #Cualquiera *
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    security_rule {
      name                       = "Allow_Web"
      priority                   = "1001"                      #Por debajo de 5000.
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
}


#Creación de una Tarjeta de Red(adaptador).
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${random_pet.prefix.id}-nic"	
  location            = azurerm_resource_group.rg.location     #coge la ubicación del grupo de recursos.
  resource_group_name = azurerm_resource_group.rg.name         #coge el nombre del grupo de recursos.

     ip_configuration {
       name                          = "my_nic_configuration"
       subnet_id                     = azurerm_subnet.my_terraform_subnet.id	
       private_ip_address_allocation = "Dynamic"
       public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
     }     
}


# Creación de la conexión de la NSG a la tarjeta de Red.
resource "azurerm_network_interface_security_group_association" "nsg_association"{
  network_interface_id        = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id   = azurerm_network_security_group.my_terraform_nsg.id
}


# Creación de Storage Account y el Boot Diagnostic
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"       #Usamos la variable de entorno de diagnóstico	
  location                 = azurerm_resource_group.rg.location     #coge la ubicación del grupo de recursos.
  resource_group_name      = azurerm_resource_group.rg.name         #coge el nombre del grupo de recursos.
  account_tier             = "Standard"    
  account_replication_type = "LRS"
}


# Creación de la Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                     = "${var.prefix}-vm"
  admin_username           = "azureuser"
  admin_password           = random_password.password.result
  location                 = azurerm_resource_group.rg.location     #coge la ubicación del grupo de recursos.
  resource_group_name      = azurerm_resource_group.rg.name         #coge el nombre del grupo de recursos.
  network_interface_ids    = [azurerm_network_interface.my_terraform_nic.id]
  size                     = "Standard_DS1_V2"

  os_disk {
    name                   = "myOsDisk"
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
  }

  source_image_reference {
    publisher              = "MicrosoftWindowsServer"
    offer                  = "WindowsServer"
    sku                    = "2022-datacenter-azure_edition"   #sku, acrónimo de identificador único en el almacen
    version                = "latest"
  }

  boot_diagnostics {
    storage_account_uri    = azurerm_storage_account.my_storage_account.primary_blob_endpoint  #coge el primer endpoint
  }
}


# Installar IIS webserver en la máquina virtual
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = "${random_pet.prefix.id}-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandoToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTool"
    } 
  SETTINGS    
}


# Generar un texto aleatorio para el nombre del Storage Account
resource "random_id" "random_id" {
  keepers = {
    # Generar un nuevo id cuando el nuevo grupo de recursos sea definido.
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
} 

resource "random_password" "password" {
  length          = 20
  min_lower       = 1
  min_upper       = 1
  min_numeric     = 1 
  min_special     = 1
  special         = true
}


resource "random_pet" "prefix"{
  prefix   = var.prefix
  length   = 1       
}


