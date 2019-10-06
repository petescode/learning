<#
Author: Pete Wood
Purpose: Compute a file hash and compare it with a given hash to verify authenticity

Development:
- FIPS enabled/disabled? Affects which algorithms will work
- First search $env:USERPROFILE, then C:\ drive, then other drives?
    Search algorithm? Needs to be as speedy as possible
#>

# this needs to be a function so we can call it later during switch
Clear-Host
[string]$name = Read-Host "Enter name of file to search for"
$results = Get-ChildItem -Path C:\Users -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue

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
            $results = Get-ChildItem -Path C:\Users -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue
        }
        2{
            $search_from = Read-Host "`nEnter search path to start from (default was C:\Users)"
            
            # verify the entered path is valid
            while(-Not $(Test-Path $search_from)){
                $search_from = Read-Host "`nEnter search path to start from (default was C:\Users)"
            }

            # run the search again from new, validated search path
            $results = Get-ChildItem -Path $search_from -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue
        }
        q{ EXIT }
        default{ $NULL -eq $results } # start the loop over if one of these options is not selected
    }
}

# now make a list to choose from...because searching "debian" could return multiple debian ISOs
$list=@()
[int]$count=0
$results | ForEach-Object{
    $count++
    $object = New-Object System.Object
    $object | Add-Member -Type NoteProperty -Name "Number" -Value $count
    $object | Add-Member -Type NoteProperty -Name "Name" -Value $_.Name
    $list += $object
}

# if only 1 file name match, auto-select it; else (multiple results) call function for menu

if($list.count -gt 1){ # multiple files match the search; we must choose which one
    $list | Out-Host
    [int]$selection=0
    Do{
        Try{ $selection = Read-Host "Select a file" }
        Catch {} # do nothing, including with any error messages
    } Until(($selection -gt 0) -and ($selection -le $list.Length))

    $file = $list[$selection-1].Name
}
else{ # only 1 result for search; this is our file
    $file = $list[0].Name
}

Get-FileHash 


#$true_hash
#$given_hash

# need a menu for which algorithms to choose from
# menu should be a function?

# try again if no file found

# account for whitespace on either side of copy/paste $given_hash (eliminate it)

