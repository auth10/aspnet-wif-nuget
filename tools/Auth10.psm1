function Set-FederationParameters {
param(        
    [Parameter(Mandatory=$true, HelpMessage="This is the logical identifier of the application that could be sometimes the URL of the application (e.g.: urn:myapp or http://myapp.com)")][string]$realm,
	[Parameter(Mandatory=$true, HelpMessage="This is the URL of the STS (e.g.: https://login.company.com/adfs/ls/)")][System.Uri]$issuerUrl,
    [Parameter(Mandatory=$true, HelpMessage="This is the certificate thumbprint (e.g.: 6E4CE9CDEFF51BB8C06E8BE45CE4B779A0528662")][string]$thumbprint,
    [Parameter(Mandatory=$false, HelpMessage="This is a friendly name for your sts (e.g.: mysts")][string]$issuerName
)

if (-not $issuerName) { $issuerName = $issuerUrl; }

$project = get-project

# find the Web.config file
$config = $project.ProjectItems | where {$_.Name -eq "Web.config"}

# find its path on the file system
$localPath = $config.Properties | where {$_.Name -eq "LocalPath"}

[xml]$conf = [io.file]::readalltext($localPath.Value)

$conf.configuration.'microsoft.identityModel'.service.audienceUris.add.value = $realm;
$conf.configuration.'microsoft.identityModel'.service.issuerNameRegistry.trustedIssuers.add.thumbprint = $thumbprint;
$conf.configuration.'microsoft.identityModel'.service.issuerNameRegistry.trustedIssuers.add.name = $issuerName;
$conf.configuration.'microsoft.identityModel'.service.federatedAuthentication.wsFederation.issuer = $issuerUrl.ToString();
$conf.configuration.'microsoft.identityModel'.service.federatedAuthentication.wsFederation.realm = $realm;
 	
$conf.Save($localPath.Value);
 
}


function Set-FederationParametersFromAccessControlService {
param(        
    [Parameter(Mandatory=$true, HelpMessage="This is the logical identifier of the application that could be sometimes the URL of the application (e.g.: urn:myapp or http://myapp.com)")][string]$realm,
	[Parameter(Mandatory=$true, HelpMessage="This is your service namespace")][string]$serviceNamespace
)

# https://[serviceNamespace].accesscontrol.windows.net/FederationMetadata/2007-06/FederationMetadata.xml

$webclient = New-Object System.Net.WebClient
$url = "https://$serviceNamespace.accesscontrol.windows.net/FederationMetadata/2007-06/FederationMetadata.xml"

Write-host "Downloading federation metadata from $url"

$data = $webclient.DownloadData($url);
$ms = new-object io.memorystream(,$data);
$ms.Flush();
$ms.Position = 0;
$fedMetadata = new-object XML
$fedMetadata.Load($ms)
$certb64 = $fedMetadata.EntityDescriptor.RoleDescriptor[0].KeyDescriptor.KeyInfo.X509Data.X509Certificate
$cert = new-object Security.Cryptography.X509Certificates.X509Certificate2(,[convert]::frombase64string($certb64))
$thumbrpint = $cert.Thumbprint;

Write-host "Identity Provider Thumbprint: $thumbrpint"

$issuerUrl = $fedMetadata.EntityDescriptor.RoleDescriptor[0].PassiveRequestorEndpoint.EndpointReference.Address;
$issuerName = $fedMetadata.EntityDescriptor.entityID;

Write-host "Identity Provider Url: $issuerUrl"

Set-FederationParameters -realm $realm -issuerUrl $issuerUrl -thumbprint $thumbrpint -issuerName $issuerName

}

Export-ModuleMember Set-FederationParameters
Export-ModuleMember Set-FederationParametersFromAccessControlService
