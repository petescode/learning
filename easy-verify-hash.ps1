<#
Author: Pete Wood
Purpose: Compute a file hash and compare it with a given hash to verify authenticity
Notes:
    - Developed in Windows PowerShell 5.1
    - Get-FileHash requires PowerShell 4.0+

Development:
- FIPS enabled/disabled? Affects which algorithms will work
#>

function Get-Algorithm {
    # since we have already gotten the user used to selecting from an array of objects,
    # let's keep going with that theme

    # zeroize $selection as it's been used by the time this function is called
    [int]$selection=0

    # this method of array building with custom objects is supported as far back as PowerShell 3
    $available_algorithms=@(
        [PSCustomObject]@{Number = 1; Algorithm = "MD5"},
        [PSCustomObject]@{Number = 2; Algorithm = "SHA1"},
        [PSCustomObject]@{Number = 3; Algorithm = "SHA256"},
        [PSCustomObject]@{Number = 4; Algorithm = "SHA384"},
        [PSCustomObject]@{Number = 5; Algorithm = "SHA512"}
    )
    $available_algorithms | Out-Host

    Do{
        Try{ $selection = Read-Host "Choose an algorithm" }
        Catch {} # do nothing, including with any error messages
    } Until(($selection -gt 0) -and ($selection -le $available_algorithms.Length))

    # setting scope of this variable to "script" so it is useable outside this function
    $script:algorithm = $available_algorithms[$selection-1].Algorithm
}

function Get-FIPSAlgorithm {
    
}


# this needs to be a function so we can call it later during switch
Clear-Host
[string]$name = Read-Host "Enter name of file to search for"
$results = Get-ChildItem -Path C:\Users -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select Length,Name,FullName
#$results | Out-Host

# this while loop only kicks in if there are no files found by the entered name at the default path
while($NULL -eq $results){
    Clear-Host
    Write-Host "Searched for: '$name'"
    Write-Host "`nNo file found!`n"
    Write-Host "What would you like to do?"
    Write-Host "1. Try again"
    Write-Host "2. Refine search"
    Write-Host "Q. Quit"

    $selection = Read-Host "`nChoose an option"

    switch($selection){
        1{ 
            Clear-Host
            [string]$name = Read-Host "Enter name of file to search for"
            $results = Get-ChildItem -Path C:\Users -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select FullName
        }
        2{
            $search_from = Read-Host "`nEnter search path to start from (default was C:\Users)"
            
            # verify the entered path is valid
            while(-Not $(Test-Path $search_from)){
                $search_from = Read-Host "`nEnter search path to start from (default was C:\Users)"
            }

            # run the search again from new, validated search path
            $results = Get-ChildItem -Path $search_from -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select FullName
        }
        q{ EXIT }
        default{ $NULL -eq $results } # start the loop over if one of these options is not selected
    }
}
#$results | Out-Host

# now make a list to choose from...because searching "debian" could return multiple debian ISOs
$list=@()
[int]$count=0
$results | ForEach-Object{
    $count++
    $object = New-Object System.Object
    $object | Add-Member -Type NoteProperty -Name "Number" -Value $count
    $object | Add-Member -Type NoteProperty -Name "Name" -Value $(Split-Path -Path $_.FullName -Leaf)
    $object | Add-Member -Type NoteProperty -Name "FullName" -Value $_.FullName
    $object | Add-Member -Type NoteProperty -Name "Size" -Value $_.Length
    $list += $object
}

# if only 1 file name match, auto-select it; else (multiple results) call function for menu

if($list.count -gt 1){ # multiple files match the search; we must choose which one
    $list | Select Number,Name | Out-Host
    [int]$selection=0
    Do{
        Try{ $selection = Read-Host "Select a file" }
        Catch {} # do nothing, including with any error messages
    } Until(($selection -gt 0) -and ($selection -le $list.Length))

    $file_name = $list[$selection-1].Name
    $file = $list[$selection-1].FullName
    $file_size_in_bytes = $list[$selection-1].Size
}
else{ # only 1 result for search; this is our file
    $file_name = $list[0].Name
    $file = $list[0].FullName
    $file_size_in_bytes = $list[$selection-1].Size
}


# convert file size from bytes to appropriate human-readable output
if($file_size_in_bytes -ge 1073741824){
    # this is at least 1GB in size
    $file_size_in_gb = [math]::Round($($file_size_in_bytes / 1024 / 1024 / 1024),2)
    Set-Variable -Name file_size -Value "$file_size_in_gb GB"
}   
elseif(($file_size_in_bytes -lt 1073741824) -and ($file_size_in_bytes -ge 1048576)){
    # this should be in a MB
    $file_size_in_mb = [math]::Round($($file_size_in_bytes / 1024 / 1024),2)
    Set-Variable -Name file_size -Value "$file_size_in_mb MB"
}
elseif(($file_size_in_bytes -lt 1048576) -and ($file_size_in_bytes -ge 1024)){
    # this should be in KB
    $file_size_in_kb = [math]::Round($($file_size_in_bytes / 1024),2)
    Set-Variable -Name file_size -Value "$file_size_in_kb KB"
}
elseif($file_size_in_bytes -lt 1024){
    Set-Variable -Name file_size -Value "$file_size_in_bytes Bytes"
}


Clear-Host
Write-Host "File selected is: " -NoNewline; Write-Host "$file_name" -ForegroundColor Cyan
Get-Algorithm

Clear-Host
Write-Host "Calculating $algorithm hash for $file_name..." -NoNewline
$true_hash = Get-FileHash -LiteralPath $file -Algorithm $algorithm | Select -Expand Hash
Write-Host "done"
# waiting message...size of file?

[string]$given_hash = Read-Host "`nEnter hash given to you"

# THIS IS NOT WORKING YET
while($NULL -eq $given_hash){
    Write-Warning "Null value entered! Try again"
    [string]$given_hash = Read-Host "Enter hash given to you"
}

[string]$given_hash = $given_hash.Trim()

# compare the hashes
if($true_hash -eq $given_hash){
    Clear-Host
    Write-Host "`nCheck SUCCEEDED: hashes match!" -ForegroundColor Green
    Write-Host "______________________________________"
    Write-Host "Computed hash: $true_hash"
    Write-Host "Provided hash: $given_hash"
    Write-Host "`n`nYour algorithm was: $algorithm"
    Write-Host "Your file was: $file_name`n" 
}
else{ 
    Clear-Host
    Write-Host "`nCheck FAILED: hashes DO NOT match!" -ForegroundColor Red
    Write-Host "______________________________________"
    Write-Host "Computed hash: $true_hash"
    Write-Host "Provided hash: $given_hash"
    Write-Host "`n`nYour algorithm was: $algorithm"
    Write-Host "Your file was: $file_name`n" 
}
#>
