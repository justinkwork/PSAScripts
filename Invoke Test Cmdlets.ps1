Param (
    [Parameter(Mandatory=$true,Position=0)][string]$GUID
)

TRY {

    $Path = "C:\ScriptLibrary\testcmdlets.ps1"
    
    if ( Test-Path -Path $Path ) {
            
        . $Path $GUID
        
    }

    else {

        Write-Output FAILED

    }
    
}

CATCH {

    Write-Output "SOMETHING WENT WRONG"
    Write-Output $($Error[0].Exception.Message)
    
}