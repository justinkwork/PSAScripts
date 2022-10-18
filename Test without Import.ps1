Param (
    [Parameter(Mandatory=$true,Position=0)][string]$GUID
)

#BEGIN {

    #TRY {
        Write-Output 'Begin'
        #Import-Module 'C:\Program Files\Microsoft System Center\Service Manager\Powershell\System.Center.Service.Manager.psd1'
        Import-Module smlets -Force

        $CIRelationship = Get-SCSMRelationship -Name System.WorkItemRelatesToConfigItem
        $ManagerRelationship = Get-SCSMRelationship -name System.UserManagesUser

        $SRO = Get-SCSMObject -Id $GUID
        $SRI = Get-SCSMClassInstance -Id $GUID        
        Write-Output 'End Begin' 
    #}

    #CATCH {

     #   Write-Output "$(($SRO).ID)|$($GUID)"
      #  Write-Output "[BEGIN] SOMETHING WENT WRONG"
       # Write-Output "$($Error[0].Exception.Message)"    
    #}

#}# End o BEGIN

#PROCESS {

    #TRY {
        Write-Output 'Process'
        Write-Output $(whoami)
        $pass = Get-Content "c:\pass.txt" | ConvertTo-SecureString -AsPlainText -Force
        $creds = New-Object System.Management.Automation.PSCredential -ArgumentList "justin.admin", $pass
        $sro
        if ($sro -and $sri) {
            Import-Module activedirectory
            Get-ADUser justinkworkman -Credential $creds
        }
        Write-Output 'End Process'

#    }

#    CATCH {
    
       # Write-Output "$(($SRO).ID)|$($GUID)"
        #Write-Output "[PROCESS] SOMETHING WENT WRONG"
        #Write-Output "$($Error[0].Exception.Message)"
    
 #   }

#}# End of PROCESS

#END {

    Write-Output "$(($SRO).ID)|$($GUID)"
    Remove-Variable * -ErrorAction SilentlyContinue
    Remove-Module System.Center.Service.Manager,smlets,activedirectory -Force

#}# End of END
