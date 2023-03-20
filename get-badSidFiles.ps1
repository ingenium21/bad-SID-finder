[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$path
)

function IsValidSID([string]$sid) {
    if ((get-ADUser -Filter "SID -eq '$sid'") -eq $null) {
        write-host -ForegroundColor Red ("SID {0} is orphaned" -f $sid)
        return $true
    }
    else {
        return $false
    }
}


function GetFilesWithBadSIDs([string]$path) {
    Write-Host "checking files..."
    $files = Get-ChildItem -Path $path -Recurse -File
    $badSids = @()
    foreach ($file in $files) {
        $sids = (Get-Acl $file).Access | Where-Object { $_.IdentityReference.Value -match "^S-1-5-21-\d{1,10}-\d{1,10}-\d{1,10}-\d{1,10}-\d{1,10}$" } | Select-Object -ExpandProperty IdentityReference
        foreach ($sid in $sids) {
            $sidString = $sid.Value
            $test = IsValidSID($sidString)
            if ($test -eq $true) {
                Write-Host -ForegroundColor Red ("File: {0} has a broken SID" -f $file)
            }
            $fileTup = @($file,$sidString)
            $badSids += $fileTup
        }
    }
    return $badSIDs
}


function ProcessFilesWithBadSIDs([array]$files) {
    write-host $files.Length
    if ($files.Length -gt 0) {
        foreach ($file in $files) {
            Write-Host "File $($file[0]) has bad SID: $($file[1])"}
        #     $result = [PSCustomObject]@{
        #         File = $file.FullName
        #         SID =  $ace.IdentifyReference.Value
        #     }
        #     $results += $result
        # }
        # $results | Export-Csv -Path .\results.csv -NoTypeInformation'
    }
    else {
        Write-Host -ForegroundColor Green "No bad files!"
    }
}


function Main() {
    $files = GetFilesWithBadSIDs $path
    ProcessFilesWithBadSIDs $files
}


Main
