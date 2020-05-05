Set-ExecutionPolicy Bypass -Scope Process -Force

iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install notepadplusplus -y

$WVDAgentDloadUri = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$WVDAgentDloadFileName = 'WVDARMAgent.msi'

$WVDBootloaderDloadUri = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDBootloaderDloadFileName = 'WVDARMBootloader.msi'

cd \

mkdir WVDARMInstall

Invoke-WebRequest -UseBasicParsing -Uri $WVDAgentDloadUri -OutFile $WVDAgentDloadFileName
Invoke-WebRequest -UseBasicParsing -Uri $WVDBootloaderDloadUri -OutFile $WVDBootloaderDloadFileName

$WVDHostPoolRegistrationToken = {}

$WVDAgentDloadFileName REGISTRATIONTOKEN='$WVDHostPoolRegistrationToken' /quiet /qn /norestart /passive
$WVDBootloaderDloadFileName /quiet /qn /norestart /passive
