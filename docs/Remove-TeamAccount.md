﻿# Remove-TeamAccount

## SYNOPSIS
Clears your default project, account name and personal access token.

## SYNTAX

### Parameter Set 1
```
Remove-TeamAccount [-Force] [-Level <String>]
```

## DESCRIPTION
Clears the environment variables that hold your default project, account and personal access token.
You have to run Add-TeamAccount again before calling any other functions.

To remove from the Machine level you must be running PowerShell as administrator.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
PS C:\\\>
```powershell
Remove-TeamAccount
```

This will clear your account name and personal access token.

## PARAMETERS

### Level
On Windows allows you to clear your account information at the Process, User or Machine levels.

```yaml
Type: String
Parameter Sets: Parameter Set 1
Aliases: 

Required: false
Position: named
Default Value: 
Pipeline Input: false
Dynamic: true
```

### Force
Forces the command without confirmation

```yaml
Type: SwitchParameter
Parameter Sets: Parameter Set 1
Aliases: 

Required: false
Position: named
Default Value: False
Pipeline Input: false
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Add-TeamAccount]()


*Generated by: PowerShell HelpWriter 2017 v2.1.36*