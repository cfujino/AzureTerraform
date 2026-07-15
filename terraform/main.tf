resource "azurerm_resource_group" "main" {
  name     = "devsecops-test-rg-prod"
  location = "East US"
}

resource "azurerm_resource_group" "main"{
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name = "ollama-vnet"
  address_space = [
    "10.0.0.0/16"
  ]
  location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtial_network.main.name
  address_prefixes = [
    "10.0.1.0/24"
  ]
}

resource "azurerm_network_security_group" "main" {
  name = "ollama-nsg"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {

    name = "AllowSSH"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "main" {

  name = "ollama-public-ip"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_network_interface" "main" {
  
  name = "ollama-nic"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {

    name = "internal"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id = azurerm_network_interface.main.id
  network_security_group = azurerm_network_security_group.main.id
}





