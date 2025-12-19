
function Find-WritableFiles {
<#
    .SYNOPSIS

        Discover writable/modifiable files based on the currently logged in user and their groups.
        This script is intended to be used from a low privilege account.

        Author: @dcept905
        
    .EXAMPLE

        PS C:\> Find-WritableFiles C:\ .exe

        Return a list of .exe files in c: and all subfolders that the running user can modify.
    
    .EXAMPLE

        PS C:\> Find-WritableFiles C:\users .dll

        Return a list of .dll files in c:\users and all subfolders that the running user can modify.
#>



  [CmdletBinding()]
    Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [String]
    $location,
    [Parameter(Position = 1, Mandatory = $false)]
    [String]
    $fileExt
    )

  # Not using New-Object System.Collections.Generic.List[string]
  # In case we are in a restricted language mode :
  # -> Cannot create type. Only core types are supported in this language mode.
  $allGroups = @{} 
  $whoamiName = whoami
  $allGroups.add(0, $whoamiName)
  $whoGroups = whoami /groups /fo csv
  $csvGroups = $whoGroups | ConvertFrom-CSV
  $totalGroups = 1
  foreach($gp in $csvGroups) {
    $allGroups.add($totalGroups, $gp."Group Name")
    $totalGroups++
  }  

  Write-Output "********************************************************************************"
  Write-Output "**                           Discovered User Groups                           **"
  Write-Output "********************************************************************************"
  Write-Output ""
  $allGroups

  Write-Output ""
  Write-Output "Getting list of $fileExt files in $location. NOTE: Searching entire drives may take a while."
  try {
    $list = get-childitem $location -recurse -ErrorAction silentlycontinue
    if ($fileExt) {
      $list = $list | where {$_.extension -eq $fileExt}
    }
    $list = $list | Select FullName
  }
  catch {}

  Write-Output "********************************************************************************"
  Write-Output "**                           List of Writable Files                           **"
  Write-Output "********************************************************************************"
  Write-Output ""
  
  $totalResults = 0
  #$results = @{} #New-Object System.Collections.Generic.List[string]
  Write-Output "Checking access on files and generating list."
  Write-Output ""
  foreach($path in $list) {
    try {
      $file = Get-Item -LiteralPath $path.FullName -Force
      for($i = 0; $i -lt $totalGroups; $i++) {
        $group = $allGroups.$i
        $rights = @("FullControl", "Write", "Modify")
        $groupRights = (Get-Acl $file).Access | where-object { ($_.IdentityReference -match [Regex]::Escape($group)) }
        :outer foreach($groupRight in $groupRights) {
          foreach($right in $rights) {
            if ($groupRight.FileSystemRights -match $right) {
              Write-Output "[+] $group : '$right' - '$file'"
              #$results.add($totalResults, "$file")
              #$totalResults++
              break outer
            }
          }
        }
      }
    }
    
    catch [Exception] 
    {
      #echo $_.Exception.GetType().FullName, $_.Exception.Message
    }
  }
  
  #for($i = 0; $i -lt $totalResults; $i++) {
  #  $results.$i
  #}


}
