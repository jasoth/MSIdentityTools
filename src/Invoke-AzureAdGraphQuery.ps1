<#
.SYNOPSIS
    Query Azure AD Graph API
.EXAMPLE
    PS C:\>Invoke-AzureAdGraphQuery -ClientApplication '00000000-0000-0000-0000-000000000000' -Scopes 'User.ReadBasic.All' -RelativeUri 'users'
    Return query results for first page of users.
.EXAMPLE
    PS C:\>Invoke-AzureAdGraphQuery -ClientApplication '00000000-0000-0000-0000-000000000000' -TenantId tenant.onmicrosoft.com -Scopes 'User.ReadBasic.All' -RelativeUri 'users' -ApiVersion beta -ReturnAllResults
    Return query results for all users in tenant.onmicrosoft.com using the beta API.
#>
function Invoke-AzureAdGraphQuery {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        #
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $ClientApplication,
        #
        [Parameter(Mandatory = $false)]
        [string[]] $Scopes,
        #
        [Parameter(Mandatory = $false)]
        [switch] $NewTokenCache,
        #
        [Parameter(Mandatory = $false)]
        [string] $TenantId = 'myorganization',
        #
        [Parameter(Mandatory = $true)]
        [string] $RelativeUri,
        #
        [Parameter(Mandatory = $false)]
        [hashtable] $QueryParameters,
        #
        [Parameter(Mandatory = $false)]
        [string] $ApiVersion = '1.6',
        #
        [Parameter(Mandatory = $false)]
        [switch] $ReturnAllResults,
        #
        [Parameter(Mandatory = $false)]
        [uri] $GraphBaseUri = 'https://graph.windows.net/'
    )

    $MsalClientApplication = Resolve-MsalClientApplication $ClientApplication -NewTokenCache:$NewTokenCache

    [hashtable] $paramInvokeRestMethod = @{
        ClientApplication = $MsalClientApplication
        UseBasicParsing   = $true
    }
    if ($Scopes) {
        for ($i = 0; $i -lt $Scopes.Count; $i++) {
            if ($Scopes[$i] -notlike ("*{0}*" -f $GraphBaseUri.Host)) {
                $Scopes[$i] = $GraphBaseUri.AbsoluteUri + $Scopes[$i]
            }
        }
        $paramInvokeRestMethod.Add('Scopes', $Scopes)
    }

    $uriQueryEndpoint = New-Object System.UriBuilder -ArgumentList ([IO.Path]::Combine($GraphBaseUri.AbsoluteUri, $TenantId, $RelativeUri))

    if (!$QueryParameters -and $uriQueryEndpoint.Query) { [hashtable] $QueryParameters = ConvertFrom-QueryString $uriQueryEndpoint.Query -AsHashtable }
    else { [hashtable] $QueryParameters = @{ } }
    if (!$QueryParameters.ContainsKey('api-version')) { $QueryParameters.Add('api-version', $ApiVersion) }
    $uriQueryEndpoint.Query = ConvertTo-QueryString $QueryParameters

    $results = Invoke-RestMethodWithBearerAuth -Method Get -Uri $uriQueryEndpoint.Uri.AbsoluteUri @paramInvokeRestMethod
    Write-Output $results

    if ($ReturnAllResults) {
        while ($results.PSObject.Properties['odata.nextLink']) {
            $uriQueryEndpoint = New-Object System.UriBuilder -ArgumentList ([IO.Path]::Combine($GraphBaseUri.AbsoluteUri, $TenantId, $results.'odata.nextLink'))
            $uriQueryEndpoint.Query = ConvertTo-QueryString ((ConvertFrom-QueryString $uriQueryEndpoint.Query -AsHashtable) + $QueryParameters)
            $results = Invoke-RestMethodWithBearerAuth -Method Get -Uri $uriQueryEndpoint.Uri.AbsoluteUri @paramInvokeRestMethod
            Write-Output $results
        }
    }
}
