[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$path
)
# Define the function to check if a SID is valid
function IsValidSID([string]$sid) {
    try {
        $null = New-Object System.Security.Principal.SecurityIdentifier($sid)
        return $true
    } catch {
        return $false
    }
}

# Define the function to crawl a directory and return files with bad SIDs
function GetFilesWithBadSIDs([string]$path) {
    $files = Get-ChildItem -Path $path -Recurse -File
    $badSIDs = [System.Collections.Concurrent.ConcurrentBag[Object]]::new()
    $maxThreads = 4
    $batchSize = [Math]::Ceiling($files.Count / $maxThreads)
    $threads = @()
    for ($i = 0; $i -lt $maxThreads; $i++) {
        $startIndex = $i * $batchSize
        $batch = $files[$startIndex..($startIndex + $batchSize - 1)]
        $threads += [System.Threading.Thread]::new([System.Threading.ThreadStart]{
            foreach ($file in $batch) {
                $acl = Get-Acl $file.FullName
                foreach ($ace in $acl.Access) {
                    if ($ace.IdentityReference.Value -match "^S-1-") {
                        $isValidSID = IsValidSID $ace.IdentityReference.Value
                        if (-not $isValidSID) {
                            $badSIDs.Add($file)
                        }
                    }
                }
            }})
        $threads[$i].Start()
    }

    foreach ($thread in $threads) {
        $thread.Join()
    }
    return $badSIDs
}

# Define the function to process files with bad SIDs
function ProcessFilesWithBadSIDs([array]$files) {
    foreach ($file in $files) {
        Write-Host "File $($file.File) has bad SID $($file.SID)"}
    #     $result = [PSCustomObject]@{
    #         File = $file.FullName
    #         SID =  $ace.IdentifyReference.Value
    #     }
    #     $results += $result
    # }
    # $results | Export-Csv -Path .\results.csv -NoTypeInformation
}

# Define the main function to run the script
function Main() {
    $files = GetFilesWithBadSIDs $path
    ProcessFilesWithBadSIDs $files
}

# Call the main function
Main
