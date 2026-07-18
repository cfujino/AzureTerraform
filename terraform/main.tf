
resource "azurerm_resource_group" "ollama_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "ollama_vnet" {
  name                = "ollama-vnet"
  location            = azurerm_resource_group.ollama_rg.location
  resource_group_name = azurerm_resource_group.ollama_rg.name

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.ollama_rg.name
  virtual_network_name = azurerm_virtual_network.ollama_vnet.name

  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.ollama_rg.name
  virtual_network_name = azurerm_virtual_network.ollama_vnet.name

  address_prefixes = ["10.0.2.0/26"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.ollama_rg.location
  resource_group_name = azurerm_resource_group.ollama_rg.name
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

resource "azurerm_network_interface" "vm_nic" {

  name                = "ollama-nic"
  location            = azurerm_resource_group.ollama_rg.location
  resource_group_name = azurerm_resource_group.ollama_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_assoc" {

  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "bastion_pip" {

  name                = "bastion-pip"
  location            = azurerm_resource_group.ollama_rg.location
  resource_group_name = azurerm_resource_group.ollama_rg.name

  allocation_method = "Static"

  sku = "Standard"
}

resource "azurerm_bastion_host" "bastion" {

  name                = "ollama-bastion"
  location            = azurerm_resource_group.ollama_rg.location
  resource_group_name = azurerm_resource_group.ollama_rg.name

  sku = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

network_interface_ids = [
    azurerm_network_interface.vm_nic.id
]



