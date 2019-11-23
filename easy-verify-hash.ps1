<#
Author: Pete Wood
Purpose: Compute a file hash and compare it with a given hash to verify authenticity
Notes:
    - Developed in Windows PowerShell 5.1
    - Get-FileHash requires PowerShell 4.0+

    - Must work in contrained lanugage mode
      - This has required sweeping changes to almost every aspect of the code
      - For example, we cannot use:
        - [PSCustomObject]
        - New-Object System.Object
        - [math]::Round()
      - Had to resort to ordered hash tables in lieu of custom objects/arrays

Development:
- Still need to do testing on FIPS enabled machine
- Write a warning when choosing broken algorithms?

- When just pressing enter to search for file, script gets every file on system (need to make case for NULL)
   - Same case for entering hash provided to you (NULL)
#>

function Get-Algorithm {
    # zeroize $selection as it's been used by the time this function is called
    [int]$selection=0
    [int]$count=0
    
    # check for FIPS here, modify menu options based on result
    $fips_reg = get-itemproperty -path HKLM:\System\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy\ | Select -Expand Enabled
    if($fips_reg -eq 0){
        #Write-Host "FIPS not enabled`n"

        $choices = "MD5","SHA1","SHA256","SHA384","SHA512"
        ForEach($i in $choices){
            $count++
            $hashtable=[ordered]@{}
            $hashtable.Num = $count
            $hashtable.Algorithm = $i
            $sneaky_object = New-Object -TypeName psobject -Property $hashtable
            [array]$available_algorithms += $sneaky_object
        }
    }
    else{
        # FIPS registry key is 1 so FIPS is enabled
        #Write-Host "FIPS enabled`n"

        $choices = "SHA1","SHA256","SHA384","SHA512"
        ForEach($i in $choices){
            $count++
            $hashtable=[ordered]@{}
            $hashtable.Num = $count
            $hashtable.Algorithm = $i
            $sneaky_object = New-Object -TypeName psobject -Property $hashtable
            [array]$available_algorithms += $sneaky_object
        }
    }
    $available_algorithms | Out-Host

    Do{
        Try{ $selection = Read-Host "Choose an algorithm" }
        Catch {} # do nothing, including with any error messages
    } Until(($selection -gt 0) -and ($selection -le $available_algorithms.Length))

    # setting scope of this variable to "script" so it is useable outside this function
    $script:algorithm = $available_algorithms[$selection-1].Algorithm
}

# default path unless user switches it later
$path = "C:\Users"

# this needs to be a function so we can call it later during switch
Clear-Host
[string]$name = Read-Host "`nEnter name of file to search for"
$results = Get-ChildItem -Path $path -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select-Object Length,Name,FullName

# this while loop only kicks in if there are no files found by the entered name at the default path
while($NULL -eq $results){
    Clear-Host
    Write-Host "`nSearched for: '$name'"
    Write-Host "`nNo file found!`n"
    Write-Host "What would you like to do?"
    Write-Host "1. Change search name"
    Write-Host "2. Change search path"
    Write-Host "Q. Quit"

    $selection = Read-Host "`nChoose an option"

    switch($selection){
        1{ 
            Clear-Host
            [string]$name = Read-Host "`nEnter name of file to search for"
            $results = Get-ChildItem -Path $path -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select-Object Length,Name,FullName
        }
        2{
            Do{
                Try{ 
                    [string]$path = Read-Host "`nEnter search path to start from (default was C:\Users)"
                    $test = Test-Path $path
                    
                    if($test -eq $false){ Write-Warning "Path is invalid! Try again" }
                }
                Catch{ Write-Warning "Path is null! Try again" } # test-path will error if path is $NULL
            } Until($test -eq $TRUE)

            # run the search again from new, validated search path
            $results = Get-ChildItem -Path $path -Recurse -File -Include "*$name*" -ErrorAction SilentlyContinue | Select-Object Length,Name,FullName
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
    $object = New-Object psobject -Property @{
        Number   = $count
        Name     = $(Split-Path -Path $_.FullName -Leaf)
        FullName = $_.FullName
        Size     = $_.Length
        Path     = $(Split-Path -Path $_.FullName)
    }
    $list += $object
}

# if only 1 file name match, auto-select it; else (multiple results) call function for menu

if($list.count -gt 1){ # multiple files match the search; we must choose which one
    $list | Select-Object Number,Name | Out-Host
    [int]$selection=0
    Do{
        Try{ $selection = Read-Host "Select a file" }
        Catch {} # do nothing, including with any error messages
    } Until(($selection -gt 0) -and ($selection -le $list.Length))

    $file_name = $list[$selection-1].Name
    $file = $list[$selection-1].FullName
    $file_size_in_bytes = $list[$selection-1].Size
    $file_path = $list[$selection-1].Path
}
else{ # only 1 result for search; this is our file
    $file_name = $list[0].Name
    $file = $list[0].FullName
    $file_size_in_bytes = $list[$selection-1].Size
    $file_path = $list[$selection-1].Path
}


# convert file size from bytes to appropriate human-readable output
if($file_size_in_bytes -ge 1073741824){
    # this is at least 1GB in size
    $file_size_in_gb = '{0:0.##}' -f $(($file_size_in_bytes / 1024 / 1024 / 1024),2)
    Set-Variable -Name file_size -Value "$file_size_in_gb GB"
}   
elseif(($file_size_in_bytes -lt 1073741824) -and ($file_size_in_bytes -ge 1048576)){
    # this should be in MB
    $file_size_in_mb = '{0:0.##}' -f $(($file_size_in_bytes / 1024 / 1024),2)
    Set-Variable -Name file_size -Value "$file_size_in_mb MB"
}
elseif(($file_size_in_bytes -lt 1048576) -and ($file_size_in_bytes -ge 1024)){
    # this should be in KB
    $file_size_in_kb = '{0:0.##}' -f $(($file_size_in_bytes / 1024),2)
    Set-Variable -Name file_size -Value "$file_size_in_kb KB"
}
elseif($file_size_in_bytes -lt 1024){
    Set-Variable -Name file_size -Value "$file_size_in_bytes Bytes"
}


Clear-Host
Write-Host "`nFile selected is: " -NoNewline; Write-Host "$file_name" -ForegroundColor Cyan
Get-Algorithm

# create a file info table for reporting purposes
$file_info = New-Object psobject -Property @{
    Path      = $file_path
    File      = $file_name
    Size      = $file_size
    Algorithm = $algorithm
}

Clear-Host
$file_info | Format-List | Out-Host
Write-Host "Computing hash..." -NoNewline
$true_hash = Get-FileHash -LiteralPath $file -Algorithm $algorithm | Select-Object -Expand Hash
Write-Host "done" -ForegroundColor Cyan


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
}
else{ 
    Clear-Host
    Write-Host "`nCheck FAILED: hashes DO NOT match!" -ForegroundColor Red
    Write-Host "______________________________________"
    Write-Host "Computed hash: $true_hash"
    Write-Host "Provided hash: $given_hash"
}
$file_info | Format-List | Out-Host
