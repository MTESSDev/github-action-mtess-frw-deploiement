#$sourceDir = Get-VstsInput -name "sourceDir"
#$apiSiteWeb = Get-VstsInput -name "apiSiteWeb"
#$noPublicSystemeAutorise = Get-VstsInput -name "noPublicSystemeAutorise"
#$apiKey = Get-VstsInput -name "apiKey"

# Pour tester localement
param
(
        [String]$sourceDir,
        [String]$apiSiteWeb = 'QA',
        [String]$noPublicSystemeAutorise = 'B4CF56AE-8F79-413C-939C-71F1DA4BC807', 
        [String]$apiKey = 'JFEsvQ6ALUzLbhsVaJUM9MtMbLnLUpcfYd7NS5GLYXDuRWpFZNw5rKt45J3L'
)

Write-Host "==================================="
Write-Host "= Utilitaire de deploiement FRW   ="
Write-Host "= Copyright MTESS 2022            ="
Write-Host "==================================="
Write-Host "Repertoire source: $sourceDir"

if(-not (Test-Path $sourceDir))
{
    throw("Le repertoire source '$sourceDir' est introuvable. Arret du traitement...")
}

$tempPath = $env:AGENT_TEMPDIRECTORY
if (-not $tempPath){
	$tempPath = $env:RUNNER_TEMP
}
if (-not $tempPath){
	$tempPath = $env:TEMP
}

$guid = [guid]::NewGuid()
$tempZipFilename = Join-Path $tempPath $guid
$tempZipFilename = $tempZipFilename + '.zip'

Write-Output "Fichier Zip: $tempZipFilename"
Write-Output "Compression des fichiers..."

Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceDir, $tempZipFilename, $compressionLevel, $false)

Write-Output "Compression terminee."
Write-Output "Deploiement des formulaires vers FRW..."

Write-Output "Convertir Base64"
Write-Output "Powershell version: " + $PSVersionTable.PSversion.Major

if($PSVersionTable.PSversion.Major -eq 6)
{
    $zip = [convert]::ToBase64String((Get-Content -path $tempZipFilename -AsByteStream -Raw))
}else{
    $zip = [convert]::ToBase64String((Get-Content -path $tempZipFilename -Encoding byte -Raw))
}

Write-Output "Base64 fait... $($zip.Length) bytes"

$Uri = ""

if(-not $apiSiteWeb)
{
    $apiSiteWeb = "QA"
}

switch (($apiSiteWeb).ToUpper()) {
    DEBUG { $Uri = "https://localhost:44341/api/v1/SIS/DeployerSysteme" }
    QA { $Uri = "https://formulaires.it.mtess.gouv.qc.ca/api/v1/SIS/DeployerSysteme" }
    PROD { $Uri = "https://formulaires.mtess.gouv.qc.ca/api/v1/SIS/DeployerSysteme" }
    Default { $Uri = $apiSiteWeb }
}

$headers = @{
    "X-ApiKey" = $apiKey
    "X-NoPublicSystemeAutorise" = $noPublicSystemeAutorise
}

$contentType = "application/json"

Write-Output "Convertir en json..."

$body = @{
    zip = $zip
} | ConvertTo-Json

Write-Output "Transmettre au service web..."

try {
    #Force Tls1.2 parce que notre serveur est très sécurisé
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $result = Invoke-RestMethod -Method Post -Uri $Uri -ContentType $contentType -Headers $headers -Body $body -ErrorVariable oErr
}
catch
{
    if($oErr)
    {
        Write-Error "Message: $oErr"
    }
    Write-Host "Echec du transfert."
	Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $responseBody = $reader.ReadToEnd();
    Write-Error "Message: $responseBody"

    if ($null -ne $PSCmdlet){
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

Write-Output "Termine."
#Write-VstsSetResult -Result "Succeeded" -message "DONE"