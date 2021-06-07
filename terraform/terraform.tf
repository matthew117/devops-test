terraform {

  required_version = ">= 0.15.0"

  # Pull down the Azure ARM provider
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }

  # Use an Azure storage account to store the terraform state as a blob
  # Run with
  # -backend-config="storage_account_name=<storage account name>"
  # -backend-config="access_key=<storage account key>"
  # since backends are configured too early in the TF pipeline to grab TF_VARs
  backend "azurerm" {
    storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
    access_key           = "__terraformstoragekey__"

    features {}
  }

}

# Use a service principle to only allow terraform specific permissions.
provider "azurerm" {
  subscription_id = var.azurermSubscriptionId
  client_id       = var.azurermClientId
  client_secret   = var.azurermClientSecret
  tenant_id       = var.azurermTenantId

  features {}
}

locals {
  tags = {
    department = "development"
    managed_by = "terraform"
  }
}

# Create a resource group to manage the development environment.
resource "azurerm_resource_group" "dev" {
  name = "dev-rg"
  location = "North Europe"

  tags = local.tags
}

# Create the VNET
resource "azurerm_virtual_network" "dev" {
  name                = "dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  tags = local.tags
}

# Create the SubNet
resource "azurerm_subnet" "dev" {
    name                 = "apps"
    address_prefixes     = ["10.0.1.0/24"]
    virtual_network_name = azurerm_virtual_network.dev.name
    resource_group_name  = azurerm_resource_group.dev.name
}

# Create the network interface
resource "azurerm_network_interface" "dev" {
  name                = "${azurerm_virtual_network.dev.name}-nic00"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "${azurerm_virtual_network.dev.name}-ipconf00"
    subnet_id                     = azurerm_subnet.dev.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.dev.id
  }
}

# Create a public IP address
resource "azurerm_public_ip" "dev" {
  name                    = "${azurerm_virtual_network.dev.name}-ip00"
  location                = azurerm_resource_group.dev.location
  resource_group_name     = azurerm_resource_group.dev.name

  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = local.tags
}

# Output the assigned IP address so that we can all the service to ensure that
# it's configured
output "ip_address" {
  value = azurerm_public_ip.dev.ip_address
}

# Configure the NSG
resource "azurerm_network_security_group" "dev" {
  name                = "dev-nsg"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  security_rule {
    name                  = "allow-inbound-http"
    description           = "Allow HTTP/HTTPS traffic inbound"
    priority              = 3000
    direction             = "Inbound"
    access                = "Allow"
    protocol              = "TCP"
    source_address_prefix = "*"
    source_port_range = "*"
    destination_address_prefix = azurerm_subnet.dev.address_prefix
    destination_port_ranges = [
      5000,
      5001,
      80
    ]
  }

  security_rule {
    name                       = "allow-inbound-ssh"
    description                = "Allow SSH traffic inbound"
    priority                   = 3001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    # Should be the egress point of the company VPN really
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = azurerm_subnet.dev.address_prefix
    destination_port_range     = "22"
  }

  tags = local.tags
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "dev" {
    network_interface_id      = azurerm_network_interface.dev.id
    network_security_group_id = azurerm_network_security_group.dev.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "dev" {
    name                  = "en1dev00"
    location              = azurerm_resource_group.dev.location
    resource_group_name   = azurerm_resource_group.dev.name
    network_interface_ids = [azurerm_network_interface.dev.id]
    size                  = "Standard_B1s"

    os_disk {
        name              = "en1dev00"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "en1dev00"
    admin_username = var.adminUsername
    admin_password = var.adminPassword

    disable_password_authentication = true

    admin_ssh_key {
        username       = var.adminUsername
        public_key     = file(var.sshPublicKeyPath)
    }

    tags = local.tags
}