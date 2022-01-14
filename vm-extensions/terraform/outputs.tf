output "tls_private_key" {
    value = tls_private_key.ssh_key.private_key_pem
    sensitive = true
}

output "vm_public_ip" {
    value = azurerm_linux_virtual_machine.myterraformvm.public_ip_address
}
