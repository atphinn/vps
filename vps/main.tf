#configure the azure provider

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 1.1.0"
}


provider "azurerm" {
  features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "seetoothVPS" {
  name     = var.resource_group_name
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "seetoothVPS" {
  name                = var.resource_group_name
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.seetoothVPS.location
  resource_group_name = azurerm_resource_group.seetoothVPS.name
}

# Create subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.seetoothVPS.name
  virtual_network_name = azurerm_virtual_network.seetoothVPS.name
  address_prefixes     = ["10.0.2.0/24"]
}


# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.seetoothVPS.name
  allocation_method   = "Static"

  tags = {
    environment = "VPS"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.seetoothVPS.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "VPS"
  }
}


# Create network interface
resource "azurerm_network_interface" "seetoothVPS" {
  name                = var.resource_group_name
  resource_group_name = azurerm_resource_group.seetoothVPS.name
  location            = azurerm_resource_group.seetoothVPS.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.seetoothVPS.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}


# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "seetoothVPS" {
  name                            = var.resource_group_name
  resource_group_name             = azurerm_resource_group.seetoothVPS.name
  location                        = azurerm_resource_group.seetoothVPS.location
  size                            = "Standard_D2s_v3"
  admin_username                  = ""
  admin_password                  = ""
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.seetoothVPS.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
