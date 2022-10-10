<#
.SYNOPSIS
Terminates a user in AD
.DESCRIPTION
Terminates a user provided the employee number - steps that are provided in the termination checklist
.PARAMETER EmployeNumber
Unqiue ID for user
.EXAMPLE
# You can run this against multiple employees by doing a pipeline into the script
12345, 54321 | ./ad-term.ps1
.EXAMPLE
# If you are only running against a single user
./ad-term.ps1 -EmployeeNumber 12345
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(00000, 99999)]
    [int]$EmployeeNumber
)
begin {}
process {
    function Get-User {
        param (
            [int]$EmployeeNumber
        )
        if ($userExists = get-aduser -f "EmployeeNumber -eq '$($EmployeeNumber)'" -Properties * ) {
            Write-Host "Found Employee Number: $($EmployeeNumber)" -ForegroundColor Green
            return $userExists
        }
        else {
            Write-Host "User not found for Employee Number: $($EmployeeNumber)" -ForegroundColor Red
            return $false
        }
    }

     # check to see if the user exists
     $user = Get-User $EmployeeNumber

    # Generate random password as powershell core does .net function
    function New-RandomPassword() {
        param(
            [int]$maxChars = 18
        )
        #specifies a new empty password
        $newPassword = ""
        #defines random function
        $rand = New-Object System.Random
        #generates random password
        0..$maxChars | ForEach-Object { $newPassword += [char]$rand.Next(33, 126) }
        return $newPassword
    }

    function Disable-User {
        [cmdletbinding(SupportsShouldProcess)]
        param (
            [Microsoft.ActiveDirectory.Management.ADUser]$user
        )

        if ($PSCmdlet.ShouldProcess($user.Name, "Disable Account")) {   
            # disabling the account
            Disable-ADAccount -Identity $user.SamAccountName -Confirm:$false
            Write-Verbose "Disabling the Account of $($user.name)"

            $path =  "\\UNC Path\$($user.department)\$($user.name) $($user.EmployeeNumber).txt"
            if (Test-Path -Path $path) {
                Write-Host "$($user.name) groups file already exists" -ForegroundColor Red
            }
            else {
                
                # Adding manager to output file and clearing
                $manager = Get-ADUser -Identity $user.Manager | Select-Object name -ExpandProperty name
                Set-Content -Path $path -Value "Manager - $($manager)" -Confirm:$false
                Add-Content -Path $path -Value "-------------------------" -Confirm:$false
                
                # clearing the manager
                Set-ADUser -Identity $user.SamAccountName -clear manager -Confirm:$false
                Write-Verbose "Clearing manager"
                
                # outputting the groups into a file
                $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName
                $groups.name | Add-Content $path -Confirm:$false
                Write-Verbose "Outputting all groups from $($user.name)"
                
                #removing groups from the user
                Get-ADPrincipalGroupMembership -Identity $user.SamAccountName | Where-Object { $_.name -ne "Domain Users" } | Remove-ADGroupMember -Members $user.SamAccountName -Confirm:$false
                Write-Verbose "Removing groups from user"
            }
            
            # set a random password for the account
            Set-ADAccountPassword -Identity $user.SamAccountName -NewPassword (ConvertTo-SecureString -AsPlainText New-RandomPassword -Force) -Confirm:$false
            Write-Verbose "Random password was generated and set"
            
            # setting the user description with date and notice they are terminated
            Set-ADUser -Identity $user.SamAccountName -Description "AD Term Script - Account disabled and pwsd reset on $($(get-date -DisplayHint Date)) by $($env:USERNAME)" -Confirm:$false
            Write-Verbose "Setting the description with date and user who executed this program"
            
            # move user object into appropriate disabled OU
            Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Accounts,OU=Users,OU=Company,DC=Company,DC=yourcompany,DC=org" -Confirm:$false
            Write-Verbose "AD Object moved to Terminated Accounts OU"
        }
    }
    if ($user) {
        try {
            Disable-User $user -Confirm
        }
        catch {
            Write-Host $_.Exception -ForegroundColor Red
        }
    }
}