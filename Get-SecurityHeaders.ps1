<#

.SYNOPSIS
Simple Script designed to parse data output from SecurityHeaders.com

.DESCRIPTION
This is a simple script designed to parse data output from SecurityHeaders.com for a given site. An array of objects with header details is provided as output.

.PARAMETER Site
Url of a site to test

.PARAMETER Path
Location of a file containing a newline separated list of sites to test

.PARAMETER FollowRedirects
Whether or not the site should follow redirects

.PARAMETER HideResults
Option to hide results from SecurityHeaders.com main page

.PARAMETER Json
Optionally provide the output as JSON

.EXAMPLE
# Single Site
.\Get-SecurityHeaders.ps1 -Site google.com

# List of sites
.\Get-SecurityHeaders.ps1 -Path C:\sitelist.txt

# Optional JSON Output Switch
.\Get-SecurityHeaders.ps1 -Site google.com -Json

.NOTES
Written by Cody Ernesti and Christian Escobar

.LINK
https://github.com/SoarinFerret/Pwsh-SecurityHeaders

#>
Param(
    [Parameter(ParameterSetName="Site",Mandatory=$true)]
    [String]$Site,
    [Parameter(ParameterSetName="File",Mandatory=$true)]
    [String]$Path,
    [boolean]$FollowRedirects = $true,
    [boolean]$HideResults = $true,
    [Switch]$Json
)

function checkSite{
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Site,
        [boolean]$FollowRedirects = $true,
        [boolean]$HideResults = $true
    )

    # Set URL Params
    $redirect="on"
    $hide="on"
    if(!$FollowRedirects){$redirect = "off"}
    if(!$hide){$hide = "off"}

    # Get Data from site
    $sitedata = Invoke-WebRequest "https://securityheaders.com/?q=$site&hide=$hide&followRedirects=$redirct"

    # Begin parsing
    $reports = $sitedata.ParsedHtml.body.getElementsByClassName("reportSection")

    $outObjects = @()
    $reports | %{
        # Grab Title for section
        $title = ($_.getElementsByClassName("reportTitle") | select innerhtml).innerhtml
        
        # Skip Support Section
        if($title -notlike "*Support*" ){
            $cells = ($_.getElementsByTagName("table")[0].cells | select innertext).innertext
            $hash = @{}

            $hash.add("Title",$title)
            
            # Check if item already exists in hash, and if so, append a number at the end with format: (x)
            for($i = 0; $i -lt $cells.Count; $i= $i + 2){
                if($hash.ContainsKey($cells[$i])){
                    $a = $hash.Keys -like "$($cells[$i])*"
                    $num = 1
                    if($a.Count -ne 1){
                        # parse last num used
                        $a = $a | sort
                        $num = [int]$a[$a.Count-1].Remove(0,$a[$a.Count-1].LastIndexOf(" ")+1).replace("(","").replace(")","")
                    }
                    $hash.Add($($cells[$i]+" ($($num+1))"), $cells[$i+1])
                }else{
                    $hash.Add($cells[$i], $cells[$i+1])
                }
            }

            # If this is the summary table, add an entry for the Grade from the header
            If($title -like "*Summary*"){
                $hash.add("Grade",$siteData.Headers.'X-Grade')
            }

            $outObjects += New-Object PSObject -Property $hash
        }
    }
    return $outObjects
}

# Single Site
if($PSCmdlet.ParameterSetName -eq "Site"){
    if($Json){
        return checkSite -Site $Site -FollowRedirects $FollowRedirects -HideResults $HideResults | ConvertTo-Json
    }
    else{
        return checkSite -Site $Site -FollowRedirects $FollowRedirects -HideResults $HideResults
    }
}
# Sites from File
else{
    $out = @()
    forEach($site in $(Get-Content $Path)){
       $out += checkSite -Site $site -FollowRedirects $FollowRedirects -HideResults $HideResults
    }
    if($Json){
        return $out | ConvertTo-Json
    }else{ return $out }
}