param ($WVDHostPoolRegistrationToken)

$WVDAgentDloadUri = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$WVDAgentDloadFileName = 'WVDARMAgent.msi'

$WVDBootloaderDloadUri = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDBootloaderDloadFileName = 'WVDARMBootloader.msi'

cd \

mkdir WVDARMInstall

cd WVDARMInstall

Invoke-WebRequest -UseBasicParsing -Uri $WVDAgentDloadUri -OutFile $WVDAgentDloadFileName
Invoke-WebRequest -UseBasicParsing -Uri $WVDBootloaderDloadUri -OutFile $WVDBootloaderDloadFileName

Start-Process .\WVDARMAgent.msi -ArgumentList "REGISTRATIONTOKEN=$WVDHostPoolRegistrationToken","/quiet","/qn","/norestart","/passive"
Start-Sleep -Seconds 30
Start-Process .\WVDARMBootloader.msi -ArgumentList "/quiet","/qn","/norestart","/passive"