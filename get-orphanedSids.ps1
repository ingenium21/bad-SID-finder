[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$path
)

function IsValidSID([String]$sid){
    if ((get-ADUser -Filter "SID -eq '$sid'") -eq $null) {
        write-host -ForegroundColor Red ("SID {0} is orphaned" -f $sid)
        return $true
    }
    else {
        return $false
    }
}

$files = Get-ChildItem -Recurse -Path $path
foreach ($file in $files) {
    $sids = (Get-Acl $file_path).Access | Where-Object { $_.IdentityReference.Value -match "^S-1-5-21-\d{1,10}-\d{1,10}-\d{1,10}-\d{1,10}-\d{1,10}$" } | Select-Object -ExpandProperty IdentityReference
    foreach ($sid in $sids) {
        $sidString = $sid.Value
        $test = IsValidSID($sidString)
        if ($test -eq $true) {
            Write-Host -ForegroundColor Red ("File: {0} has a broken SID" -f $file)
            break
        }
    }
}