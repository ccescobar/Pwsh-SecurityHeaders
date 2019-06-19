<#
    .SYNOPSIS
        Simple Script designed to parse data output from SecurityHeaders.com
    .DESCRIPTION
        This is a simple script designed to parse data output from SecurityHeaders.com for a given site. An array of objects with header details is provided as output.
    .PARAMETER Site
        Url of a site to test
    .PARAMETER File
        Location of a file containing a newline separated list of sites to test
    .PARAMETER Json
        Optionally provide the output as JSON
    
    #The following parameters have been enabled by default inside the URL. 
    # .PARAMETER FollowRedirects
    #     Whether or not the site should follow redirects
    # .PARAMETER HideResults
    #     Option to hide results from SecurityHeaders.com main page

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
        https://github.com/ccescobar/Pwsh-SecurityHeaders.git
#>

Param(
    [Parameter(ParameterSetName = "Site")]
    [String]$Site,

    [Parameter(ParameterSetName = "File")]
    [String]$Path,


    [Switch]$Json

)
#Stablishing a secure network connection. 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;  

function checkSite
{
    Param(
        [Parameter(Mandatory = $true, Position=0)]
        [String]$Site
    )
    $sitedata = Invoke-WebRequest "https://securityheaders.com/?q=$site&hide=on&followRedirects=on"

    $reports = $sitedata.ParsedHtml.body.getElementsByClassName("reportSection")

    $outObjects = @()
    
    if ($sitedata.RawContent | ForEach-Object { $_ -like "*Sorry*" })
    {

        Write-Warning "The site provided does not have results.`
        Please verify the url is correct, and run the script again."
        break;
    }
    else
    { 
        [hashtable]$JsonProperties = @{ }

        $reports | ForEach-Object {
            $title = ($_.getElementsByClassName("reportTitle") | Select-Object innerhtml).innerhtml
            #Write-Host "Got the title: $title"
            if ($title -like "*Support*" )
            {
                #Do nothing for this case.
            }
            else
            {
                $JsonProperties.Add($title, $null) #may not need.

                $cells = ($_.getElementsByTagName("table")[0].cells | Select-Object innertext).innertext

                $hash = @{ }
              #  $hash.add("Title",$title)
            
                for ($i = 0; $i -lt $cells.Count; $i = $i + 2)
                {
                    #Progress Bar
                    Write-Progress -Activity "Getting Data" -Status "$i% Complete:" -PercentComplete $i;
                    
                    if ($hash.ContainsKey($cells[$i]))
                    {
                        $a = $hash.Keys -like "$($cells[$i])*"
                        $num = 1
                        if ($a.Count -ne 1)
                        {
                            # parse last num used
                            $a = $a | Sort-Object
                            $num = [int]$a[$a.Count - 1].Remove(0, $a[$a.Count - 1].LastIndexOf(" ") + 1).replace("(", "").replace(")", "")
                        }
                        $hash.Add($($cells[$i] + " ($($num+1))"), $cells[$i + 1])
                    }
                    else
                    {
                        $hash.Add($cells[$i], $cells[$i + 1])
                    }
                }
                 #   $JsonProperties.$title += $hash
                If ($title -like "*Summary*")
                {
                    $hash.add("Grade", $siteData.Headers.'X-Grade')
                }
                
                $JsonProperties.$title += $hash
            }
            
        }
        $outObjects += New-Object PSObject -Property $JsonProperties
        return $outObjects
    }
}


#Parameter Set Name handler.
if ($PSCmdlet.ParameterSetName -eq "Site")
{
    if ($Json)
    {
        #start a timer to show progress 
        return checkSite -Site $Site | ConvertTo-Json
    }
    else
    {
        # #start a timer to show progress 
        # $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
        return checkSite -Site $Site
    }
}
else
{
    $out = @()
    forEach ($site in $(Get-Content $Path))
    {
        $out += checkSite -Site $site
    }
    if ($Json)
    {
        return $out | ConvertTo-Json
    }
    else { return $out }
}
