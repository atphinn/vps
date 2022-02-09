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

resource "azurerm_resource_group" "seetoothVPS" {
  name     = var.resource_group_name
  location = var.location
}


resource "azurerm_virtual_network" "seetoothVPS" {
  name                = var.resource_group_name
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.seetoothVPS.location
  resource_group_name = azurerm_resource_group.seetoothVPS.name
}


resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.seetoothVPS.name
  virtual_network_name = azurerm_virtual_network.seetoothVPS.name
  address_prefixes     = ["10.0.2.0/24"]
}

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

resource "azurerm_linux_virtual_machine" "seetoothVPS" {
  name                            = var.resource_group_name
  resource_group_name             = azurerm_resource_group.seetoothVPS.name
  location                        = azurerm_resource_group.seetoothVPS.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "*******"
  admin_password                  = "************************"
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
