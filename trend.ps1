mkdir c:\buildArtifacts
echo Azure-Image-Builder-Was-Here  > c:\buildArtifacts\azureImageBuilder.txt

$url= "https://files.trendmicro.com/products/deepsecurity/en/10.0/Agent-Windows-10.0.0-2797.x86_64.zip"
$zipfile= "C:\Windows\temp\deep_security_agent.zip"
$outpath= "C:\Windows\temp\deep_security_agent"
$registeragent = "C:\Windows\temp\enable_dsa.bat"

Write-Host "Downloading Deep Security Agent"
(New-Object System.Net.WebClient).DownloadFile($url, $zipfile)

Write-Host "Unzipping Deep Security Agent"
Expand-Archive -LiteralPath $zipfile -DestinationPath $outpath

Write-Host "Installing Deep Security Agent"
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\Windows\Temp\deep_security_agent\Agent-Core-Windows-10.0.0-2797.x86_64.msi /quiet'

# Show scheduled task history
$logName = 'Microsoft-Windows-TaskScheduler/Operational'
$log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
$log.IsEnabled=$true
$log.SaveChanges()

Write-Host "Adding Enable Deep Security Agent Task"
$trigger = New-ScheduledTaskTrigger -AtStartup
Write-Host "1"
$trigger.Delay = 'PT1M'
Write-Host "2"
$batchcommands = @'
cmd /c "C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd" -r
cmd /c "C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd" -a dsm://TrendDSM-DS-DSMELB-6BXKCUVFMX54-1124567102.us-east-1.elb.amazonaws.com:4120/
'@
Write-Host "3"
Set-Content -Path $registeragent -Value $batchcommands -Encoding ASCII
Write-Host "4"
$action = New-ScheduledTaskAction -Execute $registeragent
Write-Host "5"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType S4U -RunLevel Highest
Write-Host "6"
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
Write-Host "7"
Register-ScheduledTask -TaskName "Enable Deep Security Agent" -InputObject $task
Write-Host "8"
#If you have a script that will cause a reboot, then install applications and run scripts, you can schedule the reboot using a Windows Scheduled Task, or use tools such as DSC, Chef, or Puppet extensions.
$Params = @{
    Action = (New-ScheduledTaskAction -Execute "powershell" -Argument "-NoProfile Restart-Computer -force")
    Trigger = (New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(120))
    Principal = $principal
    TaskName = 'Trend Restart'
    Description = 'Restart to complete Trend configuration'
  }
  Write-Host "9"
  Register-ScheduledTask @Params
  Write-Host "10"
