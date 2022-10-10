
<h1 align="center">
  <br>
  <img src="https://avatars.githubusercontent.com/u/46386673?v=4" alt="wes214" width="200"></a>
  <br>
  wes214
  <br>
</h1>

<h4 align="center">An Active Directory termination script for running against a single or multiple users.</h4>

## Key Features

* Uses employeeNumber field for unique ID (Change for your enviroment)
* Diable User Account
* Create file containing existing groups of user
* Output manager to file created 
* Remove all groups from user
* Set random password
* Add description onto the account that the script was run also username and date of person who ran it
* Move user object into specified directory

## How To Use

* use -Verbose for script running output

```bash
# Running againt multiple users or file
$ 12345, 54321 | ./ad-term.ps1

# run against single user
$ ./ad-term.ps1 -EmployeeNumber 12345
```
