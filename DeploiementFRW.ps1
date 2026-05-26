param
(
    [String]$sourceDir,
    [String]$apiSiteWeb = 'QA',
    [String]$noPublicSystemeAutorise,
    [String]$apiKey
)

# Variables d'environnement prioritaires (GitHub Actions via env: dans action.yml)
if ($env:FRWDEPLOY_SOURCE_DIR)   { $sourceDir = $env:FRWDEPLOY_SOURCE_DIR }
if ($env:FRWDEPLOY_ENVIRONNEMENT) { $apiSiteWeb = $env:FRWDEPLOY_ENVIRONNEMENT }
if ($env:FRWDEPLOY_NO_PUBLIC)    { $noPublicSystemeAutorise = $env:FRWDEPLOY_NO_PUBLIC }
if ($env:FRWDEPLOY_API_KEY)      { $apiKey = $env:FRWDEPLOY_API_KEY }

Write-Host "==================================="
Write-Host "= Utilitaire de deploiement FRW   ="
Write-Host "= Copyright MTESS 2022 - 2023     ="
Write-Host "==================================="
Write-Host "Repertoire source: $sourceDir"

if(-not (Test-Path $sourceDir))
{
    throw("Le repertoire source '$sourceDir' est introuvable. Arret du traitement...")
}

$tempPath = $env:AGENT_TEMPDIRECTORY
if (-not $tempPath) { $tempPath = $env:RUNNER_TEMP }
if (-not $tempPath) { $tempPath = $env:TEMP }

$guid = [guid]::NewGuid()
$tempZipFilename = Join-Path $tempPath "$guid.zip"

Write-Output "Fichier Zip: $tempZipFilename"
Write-Output "Compression des fichiers..."

Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceDir, $tempZipFilename, $compressionLevel, $false)

Write-Output "Compression terminee."
Write-Output "Deploiement des formulaires vers FRW..."
Write-Output "Powershell version: $($PSVersionTable.PSVersion.Major)"

if($PSVersionTable.PSVersion.Major -ge 6)
{
    $zip = [convert]::ToBase64String((Get-Content -path $tempZipFilename -AsByteStream -Raw))
}else{
    $zip = [convert]::ToBase64String((Get-Content -path $tempZipFilename -Encoding byte -Raw))
}

Write-Output "Base64 fait... $($zip.Length) bytes"

if(-not $apiSiteWeb) { $apiSiteWeb = "QA" }

switch (($apiSiteWeb).ToUpper()) {
    DEBUG   { $Uri = "https://localhost:44341/api/v1/SIS/DeployerSysteme" }
    QA      { $Uri = "https://formulaires.it.mtess.gouv.qc.ca/api/v1/SIS/DeployerSysteme" }
    PROD    { $Uri = "https://formulaires.mtess.gouv.qc.ca/api/v1/SIS/DeployerSysteme" }
    Default { $Uri = $apiSiteWeb }
}

$headers = @{
    "X-ApiKey"                   = $apiKey
    "X-NoPublicSystemeAutorise"  = $noPublicSystemeAutorise
}

$body = @{ zip = $zip } | ConvertTo-Json

Write-Output "Transmettre au service web: $Uri"

try {
    # Force TLS 1.2 pour compatibilité serveur
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $result = Invoke-RestMethod -Method Post -Uri $Uri -ContentType "application/json" -Headers $headers -Body $body
}
catch
{
    Write-Host "Echec du transfert."
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    $responseBody = $null
    $responseStream = if ($_.Exception.Response) { $_.Exception.Response.GetResponseStream() } else { $null }
    if ($responseStream) {
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseBody = $reader.ReadToEnd()
        $reader.Close()
    }
    if ($responseBody) {
        Write-Error "Reponse serveur: $responseBody"
    }
    Write-Error "Exception: $($_.Exception.Message)"
}
finally
{
    Remove-Item $tempZipFilename -ErrorAction SilentlyContinue
}

Write-Output "Termine."
