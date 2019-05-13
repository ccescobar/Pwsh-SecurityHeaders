# Pwsh-SecurityHeaders

This script aims to pull and parse the data from SecurityHeaders.com so that the data is usable in scripting scenarios.

## Usage

By default, this works by taking either a single site or a file containing a list of sites separated by newlines

```powershell
# Single Site
.\Get-SecurityHeaders.ps1 -Site google.com

# List of sites
.\Get-SecurityHeaders.ps1 -Path C:\sitelist.txt

# Optional JSON Output Switch
.\Get-SecurityHeaders.ps1 -Site google.com -Json
```

## Todo

* PowerShell Core Support
* Complex object output instead of array of objects
* Verbose Output