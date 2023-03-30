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
        write-host -ForegroundColor Orange ("SID {0} is valid" -f $sid)
        return $false
    }
}

$files = Get-ChildItem -Recurse -Path $path
foreach ($file in $files) {
    write-host -ForegroundColor white "Checking file: {0}" -f $file.FullName
    $sids = (Get-Acl $file.FullName).Access | Where-Object { $_.IdentityReference.Value -match "S-1-\d.+" } | Select-Object -ExpandProperty IdentityReference
    foreach ($sid in $sids) {
        write-host -ForegroundColor Yellow ("Checking SID: {0} from file: {1}" -f $sid.Value, $file)
        $sidString = $sid.Value
        $test = IsValidSID($sidString)
        if ($test -eq $true) {
            Write-Host -ForegroundColor Red ("File: {0} has a broken SID" -f $file)
            break
        }
    }
}