<#
Author: Pete Wood
Purpose: Compute a file hash and compare it with a given hash to verify authenticity
Notes:
    - Developed in Windows PowerShell 5.1
    - Get-FileHash requires PowerShell 4.0+

Development:
- FIPS enabled/disabled? Affects which algorithms will work
- First search $env:USERPROFILE, then C:\ drive, then other drives?
    Search algorithm? Needs to be as speedy as possible
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
$results = Get-ChildItem -Path C:\Users -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select FullName

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
    #$object | Add-Member -Type NoteProperty -Name "Name" -Value $_.Name
    $object | Add-Member -Type NoteProperty -Name "Name" -Value $(Split-Path -Path $_.FullName -Leaf)
    $object | Add-Member -Type NoteProperty -Name "FullName" -Value $_.FullName
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
}
else{ # only 1 result for search; this is our file
    $file_name = $list[0].Name
    $file = $list[0].FullName
}

Clear-Host
Write-Host "File selected is: " -NoNewline; Write-Host "$file_name" -ForegroundColor Cyan
Get-Algorithm

Clear-Host
Write-Host "Calculating $algorithm hash for $file_name..." -NoNewline
$true_hash = Get-FileHash -LiteralPath $file -Algorithm $algorithm | Select -Expand Hash
#$true_hash | Out-Host
Write-Host "done"
# waiting message...size of file?

[string]$given_hash = Read-Host "`nEnter hash given to you"
# now validate not empty, trim whitespace, etc

# THIS IS NOT WORKING YET
while($NULL -eq $given_hash){
    Write-Warning "Null value entered! Try again"
    [string]$given_hash = Read-Host "Enter hash given to you"
}

[string]$given_hash = $given_hash.Trim()
#$given_hash | Out-Host

# compare the hashes
if($true_hash -eq $given_hash){
    Write-Host "yay they match"
    # something green here
}
else{ 
    Write-Host "oh no they don't match"
    # something red here
}
