# Welcome
    Clear-Host
    Write-Host "This PowerShell script will deploy an AudioCodes VE Session Border Controller in Azure."
    Write-Host "The provisioning process will take up to 10 minutes."
    Read-Host "Please press <Enter> to continue or press <CTRL+C> to quit."
    Write-Host ""

# Allow Remote Signed Policies
	Write-Host "Setting Azure PowerShell variables..." -foreground "green"
	Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Import-Module Az
#   Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

# Login & Select Azure Subscription
	Write-Host "Logging in..." -foreground "green";
    Connect-AzAccount
	$Subscriptions = Get-AzSubscription
    Write-Host ""
	Write-Host "Please select the Azure Subscription you want to deploy the AudioCodes VE SBC to: " -foreground "green"
		For ($i=0; $i -lt $Subscriptions.Count; $i++)  {
			Write-Host "$($i+1): $($Subscriptions[$i].Name)"
		}	
	[int]$number = Read-Host "Select your Azure Subscription: "
    Write-Host ""	
    Write-Host "You've selected $($Subscriptions[$number-1].Name)." -foreground "green"

    $subscriptionId = $Subscriptions
    Select-AzSubscription -SubscriptionName $($Subscriptions[$number-1].Name)

# Define Environment Variables
    $ResourceName = Read-Host "Please enter the prefix for all Audiocodes VE SBC resources"
    $ResourceGroupName = $ResourceName + "-RG-01"
    $VNetName = $ResourceName + "-VNET-01"
    $Subnet1Name = $ResourceName + "-TEAMS-01"
    $Subnet2Name = $ResourceName + "-PSTN-01"
    $VNetAddressSpace = "192.192.0.0/22"
    $SubnetAddressPrefix1 = "192.192.0.0/24"
    $SubnetAddressPrefix2 = "192.192.1.0/24"
	$NSG1 = $ResourceName + "-TEAMS-NSG"
	$NSG2 = $ResourceName + "-PSTN-NSG"
    $VMName1 = $ResourceName + "-ACvSBC-01"
	$Interface11Name = $VMName1 + "-INF-TEAMS"
	$Interface12Name = $VMName1 + "-INF-PSTN"
	$PublicIPName11 = $VMName1 + "-PIP-TEAMS"
	$PublicIPName12 = $VMName1 + "-PIP-PSTN"
    $Location = "SouthAfricaNorth"
    $VMSize = "Standard_B2s"
    $AdminUsername = "acadmin"
    $AdminPassword = "DirectRouting123!@#"

# Display all variables which will be used to configure the AudioCodes VE SBC
    Write-Host "The following Variables will be used to create the AudioCodes VE Session Border Controller in Azure"
    Write-Host "---------------------------------------------------------------------------------------------------"
    Write-Host ""
    Write-Host "Microsoft Azure Subscription                : " $($Subscriptions[$number-1].Name)
    Write-Host "Resource Group Name                         : " $ResourceGroupName
    Write-Host ""
    Write-Host "Virtual Network Name                        : " $VNetName
    Write-Host "Virtual Network Subnet Address              : " $VNetAddressSpace
    Write-Host ""
    Write-Host "Microsoft Teams Subnet Name                 : " $Subnet1Name
    Write-Host "Microsoft Teams Subnet Address              : " $SubnetAddressPrefix1
	Write-Host "Microsoft Teams Interface Name              : " $Interface11Name
    Write-Host "Microsoft Teams Network Security Group Name : " $NSG1
	Write-Host "Microsoft Teams Public IP Name              : " $PublicIPName11
    Write-Host ""
    Write-Host "PSTN/SIP Trunk Subnet Name                  : " $Subnet2Name
    Write-Host "PSTN/SIP Trunk Subnet Address               : " $SubnetAddressPrefix2
    Write-Host "PSTN/SIP Trunk Interface Name               : " $Interface12Name
	Write-Host "PSTN/SIP Trunk Network Security Group Name  : " $NSG2
	Write-Host "PSTN/SIP Trunk Public IP Name               : " $PublicIPName12	
    Write-Host ""
    Write-Host "Virtual Machine Name                        : " $VMName1
    Write-Host "Virtual Machine Location                    : " $Location
    Write-Host ""
    Write-Host "AudioCodes VE SBC Username                  : " $AdminUsername
    Write-Host "AudioCodes VE SBC Password                  : " $AdminPassword
    Write-Host ""
    Read-Host "Press enter to continue with the above variables or <CTRL+C> to quit."

Start-Sleep -s 5

# Create Resource Group
    Write-Host "Creating Resource Group..." -foreground "green";
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location

Start-Sleep -s 5

# Create Virtual Network Configuration
    Write-Host "Creating Virtual Network..." -foreground "green";
    $TeamsSubnet = New-AzVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $SubnetAddressPrefix1
    $PSTNSubnet  = New-AzVirtualNetworkSubnetConfig -Name $Subnet2Name  -AddressPrefix $SubnetAddressPrefix2
    New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressSpace -Subnet $TeamsSubnet,$PSTNSubnet
    $VNet = Get-AZVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName
    $Subnet1 = Get-AzVirtualNetworkSubnetConfig -Name $Subnet1Name -VirtualNetwork $VNet
    $Subnet2 = Get-AzVirtualNetworkSubnetConfig -Name $Subnet2Name -VirtualNetwork $VNet

Start-Sleep -s 5

# Create Network Security Groups for Teams & PSTN Interfaces
	$Teamsrule1 = New-AzNetworkSecurityRuleConfig -Name O365_SIP_Signalling -Description "O365 SIP Signalling Port" -Access Allow -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix 52.114.148.0/32,52.114.132.46/32,52.114.75.24/32,52.114.76.76/32,52.114.7.24/32,52.114.14.70/32 -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5061
	$TeamsRule2 = New-AzNetworkSecurityRuleConfig -Name Media_Ports -Description "Media Ports" -Access Allow -Protocol Udp -Direction Inbound -Priority 101 -SourceAddressPrefix 52.112.0.0/14 -SourcePortRange 10000-10999,49152-53247 -DestinationAddressPrefix * -DestinationPortRange 10000-10999
	$TeamsRule3 = New-AzNetworkSecurityRuleConfig -Name HTTP_Management -Description "HTTP Management of AudioCodes VE SBC" -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443
	$NSGTeams = New-AzNetworkSecurityGroup -Name $NSG1 -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $TeamsRule1,$TeamsRule2,$TeamsRule3
	
	$PSTNRule1 = New-AzNetworkSecurityRuleConfig -Name SIP_Trunk -Description "SIP Trunk Port" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5060
	$PSTNRule2 = New-AzNetworkSecurityRuleConfig -Name HTTP_Management -Description "HTTP Management of AudioCodes VE SBC" -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443
	$NSGPSTN = New-AzNetworkSecurityGroup -Name $NSG2 -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $PSTNRule1,$PSTNRule2

Start-Sleep -s 5

# Define Virtual Machine Configuration
    $VM1 = New-AzVMConfig -VMName $VMName1 -VMSize $VMSize

Start-Sleep -s 5

# Create Teams facing Public IP for VM1
    $PublicIP11 = New-AzPublicIpAddress -Name $PublicIPName11 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static

Start-Sleep -s 5

# Create PSTN facing Public IP for VM1
    $PublicIP12 = New-AzPublicIpAddress -Name $PublicIPName12 -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static

Start-Sleep -s 5

# Create Teams Facing Interface for VM1
    Write-Host "Creating Teams facing Interface for the first VM..." -foreground "green";
    $Interface11 = New-AzNetworkInterface -Name $Interface11Name -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet1.id -PublicIPAddressId $PublicIP11.id
    Add-AzVMNetworkInterface -VM $VM1 -Id $Interface11.Id

Start-Sleep -s 5

# Create PSTN facing Interface for VM1
    Write-Host "Creating PSTN facing Interface for the first VM..." -foreground "green";
    $Interface12 = New-AzNetworkInterface -Name $Interface12Name -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet2.id -PublicIPAddressId $PublicIP12.id
    Add-AzVMNetworkInterface -VM $VM1 -Id $Interface12.Id –Primary

Start-Sleep -s 5

# Define the AudioCodes Source Image
    Write-Host "Setting Azure AudioCodes SBC Image as Source..." -foreground "green";
    Get-AzMarketplaceTerms -Publisher "audiocodes" -Product "mediantsessionbordercontroller" -Name "mediantvirtualsbcazure" | Set-AzMarketplaceTerms -Accept
	Set-AzVMSourceImage -VM $VM1 -PublisherName audiocodes -Offer mediantsessionbordercontroller -Skus mediantvirtualsbcazure -Version latest
	Set-AzVMPlan -VM $VM1 -Name mediantvirtualsbcazure -Publisher audiocodes -Product mediantsessionbordercontroller

Start-Sleep -s 5

# Configure Managed Disks
    Write-Host "Setting Virtual Machine Disk parameters..." -foreground "green";
    $DiskSize = "10"
    $DiskName1 = $VMName1 + "-Disk"
    Set-AzVMOSDisk -VM $VM1 -Name $DiskName1 -DiskSizeInGB $DiskSize -CreateOption fromImage -Linux

Start-Sleep -s 5

# Configure Administrator Credentials
    Write-Host "Setting Azure AudioCodes SBC Administrator parameters..." -foreground "green";
    $Credential = New-Object PSCredential $AdminUsername, ($AdminPassword | ConvertTo-SecureString -AsPlainText -Force)
    Set-AzVMOperatingSystem -VM $VM1 -Linux -ComputerName $VMName1 -Credential $Credential

Start-Sleep -s 5

# Create Virtual Machine
    Write-Host "Creating Azure AudioCodes VE Session Border Controller, please wait..." -foreground "green";
    New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VM1
    
Start-Sleep -s 5

# Assign Network Security Groups to AudioCodes VE SBC
    Write-Host "Applying Teams Network Security Groups to Azure AudioCodes VE SBC ..." -foreground "green";
    $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSG1
    $vNIC = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $Interface11Name
    $vNIC.NetworkSecurityGroup = $nsg
    $vNIC | Set-AzNetworkInterface

    Write-Host "Applying PSTN Network Security Groups to Azure AudioCodes VE SBC ..." -foreground "green";
    $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSG2
    $vNIC = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $Interface12Name
    $vNIC.NetworkSecurityGroup = $nsg
    $vNIC | Set-AzNetworkInterface
    
Start-Sleep -s 5

# Show Public IP Address to connect to the AudioCodes SBC
    Write-Host "The Azure AudioCodes SBC has been created, here are the associated Public IP Addresses" -foreground "green";
    Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName | ft -auto Name, IPAddress
    Write-Host "Please browse to the Public IP Address associated to the PSTN interface"