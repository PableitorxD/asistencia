param location string = 'canadacentral'
param prefix string = 'srv'
param adminUsername string = 'azureuser'

@secure()
param adminPassword string = 'Password1234!'

// 1. Red Virtual y Subred
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-diplomado'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-principal'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// 2. IP Pública y Red para cada uno de los 3 servidores
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = [for i in range(1, 3): {
  name: 'pip-${prefix}-${i}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}]

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = [for i in range(1, 3): {
  name: 'nic-${prefix}-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIP[i - 1].id
          }
        }
      }
    ]
  }
}]

// 3. Despliegue de los 3 Servidores (Máquinas Virtuales Ubuntu)
resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = [for i in range(1, 3): {
  name: '${prefix}-node-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: '${prefix}-node-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i - 1].id
        }
      ]
    }
  }
}]
