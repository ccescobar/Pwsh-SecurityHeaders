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
        [Parameter(Mandatory = $true)]
        [String]$Site
    )
    #Base url with variable for url
    $sitedata = Invoke-WebRequest "https://securityheaders.com/?q=$site&hide=on&followRedirects=on"
    
    #store the report table 
    $reports = $sitedata.ParsedHtml.body.getElementsByClassName("reportSection")

    $outObjects = @()
    
    #error handling if site is not found.
    if ($sitedata.RawContent | ForEach-Object { $_ -like "*Sorry*" })
    {

        write-warning "Uh-Oh The site provided does not have results.`nPlease verify the url is correct, and run the script again." 
        break;
    }
    else
    { 
        [hashtable]$JsonProperties = @{ }

        $reports | ForEach-Object {
            $title = ($_.getElementsByClassName("reportTitle") | Select-Object innerhtml).innerhtml
         
            if ($title -like "*Support*" )
            {
        
            }
            else
            {
                $JsonProperties.Add($title, $null) #may not need.

                $cells = ($_.getElementsByTagName("table")[0].cells | Select-Object innertext).innertext

                $hash = @{ }
                
                #cicle throught each cell and add data to the object.
                for ($i = 0; $i -lt $cells.Count; $i = $i + 2)
                {
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
        return checkSite -Site $Site | ConvertTo-Json
    }
    else
    {
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
