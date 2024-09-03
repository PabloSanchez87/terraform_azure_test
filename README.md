
# Terraform Azure Infrastructure

Este repositorio contiene la configuración de Terraform para desplegar una infraestructura en Azure. Los principales componentes incluyen la creación de un grupo de recursos, una red virtual, subredes, un grupo de seguridad de red (NSG), máquinas virtuales, y almacenamiento asociado para diagnósticos.

## Contenido del repositorio

- **`provider.tf`**: Configura los proveedores necesarios, en este caso, Azure Resource Manager (`azurerm`) y el proveedor `random` para generar valores aleatorios.
- **`variables.tf`**: Define las variables utilizadas en la configuración, incluyendo la ubicación del grupo de recursos y un prefijo para los nombres de los recursos.
- **`main.tf`**: Contiene la definición principal de la infraestructura, incluyendo:
  - Grupo de recursos (`azurerm_resource_group`)
  - Red virtual y subredes (`azurerm_virtual_network`, `azurerm_subnet`)
  - IP pública (`azurerm_public_ip`)
  - Grupo de seguridad de red (NSG) y reglas (`azurerm_network_security_group`)
  - Interfaz de red (`azurerm_network_interface`)
  - Asociación del NSG a la interfaz de red (`azurerm_network_interface_security_group_association`)
  - Cuenta de almacenamiento para diagnósticos de arranque (`azurerm_storage_account`)
  - Máquina virtual Windows (`azurerm_windows_virtual_machine`)
  - Instalación de IIS en la máquina virtual (`azurerm_virtual_machine_extension`)
- **`output.tf`**: Define los outputs que exponen información importante como el nombre del grupo de recursos, la dirección IP pública de la máquina virtual y la contraseña del administrador.
  
## Prerrequisitos

- Tener [Terraform](https://www.terraform.io/downloads.html) instalado en tu máquina.
- Una cuenta de Azure con privilegios suficientes para crear los recursos.
- Configuración del CLI de Azure (`az login`) para autenticarte con tu cuenta de Azure.

## Instrucciones para ejecutar el despliegue

1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/PabloSanchez87/terraform_azure_test
   cd terraform_azure_test
   ```

2. **Inicializar el entorno de Terraform**:
   ```bash
   terraform init -upgrade
   ```

   Este comando descarga los proveedores especificados en `provider.tf` y prepara el entorno de trabajo.

3. **Validar la configuración**:
    ```bash	
    terraform validate
    ```

4. **Previsualizar los cambios**:
   ```bash
   terraform plan -out main.tfplan
   ```
    Este comando genera un archivo de plan (`main.tfplan`) que describe los cambios que Terraform va a realizar en el entorno.
   

5. **Aplicar la configuración para crear la infraestructura**:
   ```bash
   terraform apply main.tfplan
   ```
   Terraform aplicará los cambios descritos en el archivo de plan (`main.tfplan`) y creará los recursos en Azure. Al final del proceso, mostrará los outputs que expone la configuración, como la dirección IP pública de la máquina virtual y el nombre del grupo de recursos.

6. **Obtener los outputs**:
   Una vez que la infraestructura haya sido desplegada, puedes ver los outputs definidos ejecutando:
   ```bash
   terraform output [nombre_del_output]
   ```
   Esto te mostrará valores importantes como la IP pública de la máquina virtual y la contraseña del administrador.
    
## Destrucción de la infraestructura

Para eliminar toda la infraestructura creada y evitar incurrir en costos, ejecuta:

```bash
terraform destroy 
```

Esto eliminará todos los recursos desplegados en Azure.

## Contribuciones

Las contribuciones son bienvenidas. Si tienes alguna sugerencia o mejora, no dudes en abrir un issue o enviar un pull request.

## Seminario de Terraform y Azure
- Infraestrutura como código en Azure con Terraform (19/08/2024)
    - [Centro de Novas Tecnoloxías de Galicia (CNTG)](https://cntg.xunta.gal/web/cntg)
    - Descripción:  
        ```
        Terraform es una herramienta de IaC ("infraestructura como código") de código abierto para aprovisionar y gestionar una infraestructura en la nube. Codifica la infraestructura en archivos de configuración que describen el estado deseado para la topología. Terraform permite la gestión de cualquier infraestructura, como nubes públicas, nubes privadas y servicios SaaS.
        ```
    - Temario:    
        - IaC e Terraform 
        - Terraform en Azure: patróns de autenticación    
        - AzureRM  
        - Expresións    
        - Interpolación 
        - Espazos de traballo de Terraform 
        - Módulos en Terraform    
        - CI-CD