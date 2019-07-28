<#
.SYNOPSIS
   Convert Json Web Signature (JWS) structure to PowerShell object.
.EXAMPLE
    PS C:\>$MsalToken.IdToken | ConvertFrom-JsonWebSignature
    Convert OAuth IdToken JWS to PowerShell object.
.INPUTS
    System.String
#>
function ConvertFrom-JsonWebSignature {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # JSON Web Signature (JWS)
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string] $InputObject,
        # Content Type of the Payload
        [Parameter(Mandatory=$false)]
        [ValidateSet('text/plain','application/json','application/octet-stream')]
        [string] $ContentType = 'application/json'
    )
    [string[]] $JwsComponents = $InputObject.Split('.')
    switch ($ContentType) {
        'application/octet-stream' { [byte[]] $JwsPayload = $JwsComponents[1] | ConvertFrom-Base64String -Base64Url -RawBytes }
        'text/plain' { [string] $JwsPayload = $JwsComponents[1] | ConvertFrom-Base64String -Base64Url }
        'application/json' { [PSCustomObject] $JwsPayload = $JwsComponents[1] | ConvertFrom-Base64String -Base64Url | ConvertFrom-Json }
        Default { [string] $JwsPayload = $JwsComponents[1] | ConvertFrom-Base64String -Base64Url }
    }
    [PSCustomObject] $JwsDecoded = New-Object PSCustomObject -Property @{
        Header = $JwsComponents[0] | ConvertFrom-Base64String -Base64Url | ConvertFrom-Json
        Payload = $JwsPayload
        Signature = $JwsComponents[2] | ConvertFrom-Base64String -Base64Url -RawBytes
    }
    return $JwsDecoded
}