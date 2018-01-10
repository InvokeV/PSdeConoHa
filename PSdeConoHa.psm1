$apiUser = "gncu12345678" 
$password = "paSSword123456#$%" 
$tenantId = "487727e3921d44e3bfe7ebb337bf085e" 
$script:token = "" 

Function Get-cTokenHeader(){
    $body = '{"auth":{"passwordCredentials":{"username":"' + $apiUser + '","password":"' + $password+'"},"tenantId":"' + $tenantId+'"}}'
    $tokenUrl = "https://identity.tyo1.conoha.io/v2.0/tokens"

    If($script:token){
        $expiresTime = Get-Date -Date $script:token.access.token.expires
        If ($expiresTime -lt (Get-Date)){
            $script:token = Invoke-RestMethod $tokenUrl -Method POST -Body $body        
        }    
    }Else{
        $script:token = Invoke-RestMethod $tokenUrl -Method POST -Body $body    
    }
    $tokenId = $script:token.access.token.id
    Return @{"X-Auth-Token" = $tokenId}
}

Function Get-cFlavor($flavorId){    
    $tokenHeader = Get-cTokenHeader
    $requestUrl = "https://compute.tyo1.conoha.io/v2/$tenantId/flavors/$flavorId"
    $result = Invoke-RestMethod $requestUrl -Headers $tokenHeader -Method GET
    Return $result.flavor
}

Function Get-cVM(){  
    Param(        
        $Name
    )
    $tokenHeader = Get-cTokenHeader
    $requestUrl = "https://compute.tyo1.conoha.io/v2/$tenantId/servers/detail"    
    $result = Invoke-RestMethod $requestUrl -Headers $tokenHeader -Method GET
    $servers = $result.servers

    $objAry = @()
    ForEach($server in $servers){
        $id = $server.id
        $tagName = $server.metadata.instance_name_tag
        $state = $server.status
        $flavorId = $server.flavor.id
        $flavor = Get-cFlavor $flavorId
        $vcpu = $flavor.vcpus
        $ram = $flavor.ram / 1024
        $disk = $flavor.disk
        $ip = ($server.addresses.($server.addresses.PSObject.Properties.name) | ? version -eq 4).addr

        $objPs = New-Object PSCustomObject
        $objPs | Add-Member -NotePropertyMembers @{ID = $id}
        $objPs | Add-Member -NotePropertyMembers @{Name = $tagName}
        $objPs | Add-Member -NotePropertyMembers @{State = $state}
        $objPs | Add-Member -NotePropertyMembers @{vCPU = $vcpu}
        $objPs | Add-Member -NotePropertyMembers @{Disk = $disk}
        $objPs | Add-Member -NotePropertyMembers @{Memory = $ram}
        $objPs | Add-Member -NotePropertyMembers @{IPAddress = $ip}
        $objAry += ($objPs | Select-Object ID, Name, State, Memory, Disk, vCPU, IPAddress)       
    }	  
    
    $VM = $objAry
    If($Name -ne $null){
        $VM = $VM | ? Name -eq $Name
    } 
    If($VM -eq $null){  
        Write-Host ("""$Name"" という名前の仮想マシンが見つかりません。") -ForegroundColor Red
    }Else{
        Return $VM
    } 
}

Function Start-cVM(){
    Param(        
        [Parameter(ValueFromPipeline=$true)]$VM
    )
    Process{ 
        Switch($VM.GetType().Name){
            "PSCustomObject"{
                $serverId = $VM.ID
            }
            "String"{
                $serverId = (Get-cVM $VM).ID
            }           
        } 
        $tokenHeader = Get-cTokenHeader
        $requestUrl = "https://compute.tyo1.conoha.io/v2/$tenantId/servers/$serverId/action"
        $body = '{"os-start": null}'
        Invoke-RestMethod $requestUrl -Headers $tokenHeader -Method POST -Body $body
    }
}

Function Stop-cVM(){
    Param(        
        [Parameter(ValueFromPipeline=$true)]$VM
    )
    Process{ 
        Switch($VM.GetType().Name){
            "PSCustomObject"{
                $serverId = $VM.ID
            }
            "String"{
                $serverId = (Get-cVM $VM).ID
            }           
        } 
        $tokenHeader = Get-cTokenHeader
        $requestUrl = "https://compute.tyo1.conoha.io/v2/$tenantId/servers/$serverId/action"
        $body = '{"os-stop": null}'
        Invoke-RestMethod $requestUrl -Headers $tokenHeader -Method POST -Body $body
    }    
}
