$WVDAgentDloadUri = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$WVDAgentDloadFileName = 'WVDARMAgent.msi'

$WVDBootloaderDloadUri = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDBootloaderDloadFileName = 'WVDARMBootloader.msi'

cd \

mkdir WVDARMInstall

Invoke-WebRequest -UseBasicParsing -Uri $WVDAgentDloadUri -OutFile $WVDAgentDloadFileName
Invoke-WebRequest -UseBasicParsing -Uri $WVDBootloaderDloadUri -OutFile $WVDBootloaderDloadFileName

.\WVDARMAgent.msi "REGISTRATIONTOKEN=$WVDHostPoolRegistrationToken" /quiet /qn /norestart /passive
.\WVDARMBootloader.msi /quiet /qn /norestart /passive
