param(
    [string]$url = "https://<opcon server>:<port>/api",  # https://<opcon server>:<port>/api
    [string]$opconUser, # If user is blank, assumes API token is in the $opconPW variable
    [string]$opconPW, # Encrypted global property or token (with "Token ....")
    [string]$exclude, # List of user loginNames to exclude (comma separated)
    [int]$refreshIntervalAppStatus = 60,
    [int]$refreshIntervalEscalations = 60,
    [int]$refreshIntervalSelfService = 60,
    [int]$refreshIntervalSelfServiceExecution = 60,
    [int]$refreshIntervalSelfServiceExecutions = 60,
    [int]$refreshIntervalAgentsGrid = 60,
    [int]$refreshIntervalSummary = 60,
    [int]$refreshIntervalProcessesGrid = 60,
    [int]$refreshIntervalGraph = 60 ,
    [int]$refreshIntervalScheduleBuild = 60,
    [int]$refreshIntervalVision = 60
)

#Used if calling an API that is not local to the machine, **Powershell 3-5 only***
function OpCon_IgnoreSelfSignedCerts
{
    try
    {
        Add-Type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy
        {
             public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem)
             {
                 return true;
            }
        }
"@
      }
    catch
    {
        Write-Host "Error Ignoring Self Signed Certs"
        Exit 102
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

# Start of main script
if($PSVersionTable.PSVersion -lt 6)
{ OpCon_IgnoreSelfSignedCerts }
else 
{     
    try
    { $PSDefaultParameterValues.Add("Invoke-RestMethod:SkipCertificateCheck",$true) }
    catch
    { $null } 
}

if((Invoke-RestMethod -Uri ($url + "/version") -Method GET).opConRestApiProductVersion -lt 20)
{
    Write-Output "Error: OpCon version must be 20.0 or greater!"
    Exit 101
}

Write-Output (Get-Date)
Write-Output "#####################################"

try
{ 
    # Authenticate to OpCon
    if($opconUser)
    { 
        $loginBody = @{"user"=@{"loginName"=$opconUser;"password"=$opconPW};"tokenType"=@{"type"="User"}}
        $token = "Token " + (Invoke-RestMethod -Uri ($url + "/tokens") -Method POST -Body ($loginBody | ConvertTo-Json) -ContentType "application/json").id
    }
    elseif($opconPW)
    { $token = $opconPW }
    else 
    {
        Write-Output "Error: Missing user/userpw!"
        Exit 102
    }
    
    Write-Output "Authenticated to OpCon API"
    
    # Grab users
    $users = Invoke-RestMethod -Uri ($url + "/users") -Method GET -Headers @{"Authorization" = $token}
    
    Write-Output "Grabbed OpCon users"

    # Loop through and set settings for users
    if($null -eq $exclude)
    { $exclude = "" }

    $users | Where-Object{ $_.loginName -notin ($exclude.Split(",")) } | ForEach-Object{  
                                # Grab existing settings (if any)
                                $getCurrent = Invoke-RestMethod -Uri ($url + "/solutionManagerSettings?Name=User&UserId=" + $_.id) -Method GET -Headers @{"Authorization" = $token}
                                
                                # If existing user settings
                                if(!$null -eq $getCurrent)
                                { 
                                    Write-Output "Updating User:"$_.loginName

                                    # Grabs current settings
                                    $getSettings = Invoke-RestMethod -Uri ($url + "/solutionManagerSettings/" + $getCurrent.id) -Method GET -Headers @{"Authorization" = $token}
                                    
                                    # Set refresh intervals
                                    $json = $getSettings.value | ConvertFrom-Json
                                    $json.revision = $json.revision + 1                                    
                                    $json.refreshIntervalAppStatus = $refreshIntervalAppStatus
                                    $json.refreshIntervalEscalations = $refreshIntervalEscalations
                                    $json.selfService.refreshIntervalLive = $refreshIntervalSelfService
                                    $json.selfService.refreshIntervalExecution = $refreshIntervalSelfServiceExecution
                                    $json.selfService.refreshIntervalExecutions = $refreshIntervalSelfServiceExecutions
                                    $json.operations.agents.refreshIntervalGrids = $refreshIntervalAgentsGrid
                                    $json.operations.summary.refreshInterval = $refreshIntervalSummary
                                    $json.operations.processes.refreshIntervalGrids = $refreshIntervalProcessesGrid
                                    $json.operations.graph.refreshInterval = $refreshIntervalGraph
                                    $json.operations.scheduleBuildQueue.refreshInterval = $refreshIntervalScheduleBuild
                                    $json.vision.refreshIntervalLive = $refreshIntervalVision

                                    # Prep the json
                                    $getSettings.value = ($json | ConvertTo-Json -Depth 7)
                                    $body = ($getSettings | ConvertTo-Json -Depth 7).Replace("\r\n","")
                                    
                                    # Updates with new refresh intervals
                                    $update = Invoke-RestMethod -Uri ($url + "/solutionManagerSettings/" + $_.id) -Method PUT -Headers @{"Authorization" = $token} -Body $body -ContentType "application/json"
                                }
                                else # No user settings, creating
                                {
                                    Write-Output "Creating new settings for User:"$_.loginName
                                    
                                    # Push default settings with refresh time
                                    $defaultSettings = '{
                                        "userId": ' + $_.id + ',
                                        "name": "user",
                                        "value": "{\"version\":1,
                                                    \"revision\":1,
                                                    \"debug\":{\"globalSettings\":false,\"logClientLevel\":3,\"logServerSendTrigger\":2,\"logServerLevel\":0,\"logServerApi\":false,\"logServerSendOnValueInterval\":30,\"logServerSendOnValueMaxSize\":3000000,\"logServerSendOnEventLogLevel\":3,\"logServerSendOnEventMaxSize\":500000,\"logDeepObserve\":false,\"apiIgnoreSerializationError\":false},
                                                    \"dateTimeFormats\":{},
                                                    \"refreshIntervalAppStatus\":' + $refreshIntervalAppStatus + ',
                                                    \"refreshIntervalEscalations\":' + $refreshIntervalEscalations + ',
                                                    \"selfService\":{\"refreshIntervalLive\":' + $refreshIntervalSelfService + ',\"refreshIntervalExecution\":' + $refreshIntervalSelfServiceExecution + ',\"refreshIntervalExecutions\":' + $refreshIntervalSelfServiceExecutions + '},
                                                    \"operations\":{\"agents\":{\"refreshIntervalGrids\":' + $refreshIntervalAgentsGrid + ',\"columnVisibilities\":[]},
                                                    \"summary\":{\"refreshInterval\":' + $refreshIntervalSummary + ',\"filterMode\":false},
                                                    \"processes\":{\"refreshIntervalGrids\":' + $refreshIntervalProcessesGrid + ',\"split\":{\"position\":32.006900341479806,\"state\":\"value\"},\"columnVisibilities\":[]},
                                                    \"graph\":{\"maxNodesBeforeDecreaseLayout\":700,\"secondBeforeAcceptAutoRefresh\":15,\"refreshInterval\":' + $refreshIntervalGraph + '},
                                                    \"scheduleBuildQueue\":{\"refreshInterval\":' + $refreshIntervalScheduleBuild + '},
                                                    \"dailyJobDefinition\":{\"menuExtended\":false}},
                                                    \"vision\":{\"refreshIntervalLive\":' + $refreshIntervalVision + '},\"date\":\"2021-08-25T13:07:49.9940000+0000\"}",
                                        "userCanWrite": false,
                                        "public": false
                                    }' 
                                    
                                    $create = Invoke-RestMethod -Uri ($url + "/solutionManagerSettings") -Method POST -Body $defaultSettings -Headers @{"Authorization" = $token} -ContentType "application/json"
                                }
    }
}
catch [Exception]
{
    Write-Output "Error: "$_
    Write-Output "Error:"$_.exception.message
    Write-Output "#####################################"
    Exit 100
}

Write-Output "#####################################"
Write-Output "Solution Manager settings policy completed!"
Write-Output (Get-Date)