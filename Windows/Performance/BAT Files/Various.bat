:: Boot Parameters
bcdedit.exe /timeout 0 >nul
bcdedit.exe /set hypervisorlaunchtype Auto >nul
bcdedit.exe /set debug No >nul
bcdedit.exe /set sos Yes >nul
bcdedit.exe /set ems No >nul
bcdedit.exe /set noumex Yes >nul
bcdedit.exe /set bootems No >nul
bcdedit.exe /set perfmem 0 >nul
bcdedit.exe /set onecpu No >nul
bcdedit.exe /set nolowmem Yes >nul
bcdedit.exe /set MSI Default >nul
bcdedit.exe /set vsmlaunchtype Off >nul
bcdedit.exe /set nx AlwaysOff >nul
bcdedit.exe /set pae ForceEnable >nul
bcdedit.exe /set extendedinput Yes >nul
bcdedit.exe /set highestmode Yes >nul
bcdedit.exe /set forcefipscrypto No >nul
bcdedit.exe /set halbreakpoint No >nul
bcdedit.exe /set tpmbootentropy ForceDisable >nul
bcdedit.exe /set linearaddress57 OptOut >nul
bcdedit.exe /set usephysicaldestination No >nul
bcdedit.exe /set increaseuserva 3072 >nul
bcdedit.exe /set bootmenupolicy Legacy >nul
bcdedit.exe /set recoveryenabled NO >nul
bcdedit.exe /set vsmlaunchtype off >nul
bcdedit.exe /set graphicsmodedisabled No >nul
bcdedit.exe /set useplatformclock false >nul
bcdedit.exe /set tscsyncpolicy Enhanced >nul
bcdedit.exe /set disabledynamictick yes >nul
bcdedit.exe /set useplatformtick Yes >nul
bcdedit.exe /set NOINTEGRITYCHECKS OFF >nul
bcdedit.exe /set TESTSIGNING OFF >nul
bcdedit.exe /set x2apicpolicy enable >nul
bcdedit.exe /set firstmegabytepolicy UseAll >nul
wmic path Win32_PnPEntity where "name='High precision event timer'" call disable
wmic path Win32_PnPEntity where "name='Microsoft Hyper-V Virtualization Infrastructure Driver'" call disable
:--------------------------------------

:--------------------------------------
:: cleaning Windows AuditPol Logging
echo Cleaning Windows auditpol log...
Auditpol.exe /set /category:* /Success:disable /failure:disable >nul
Auditpol.exe /remove /allusers >nul
Auditpol.exe /clear /y >nul
:--------------------------------------

:--------------------------------------
:: Unsplit Services
for /f %%a in ('Reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\InstallService\Stubification /v "EnableAppOffloading" /s ^| findstr  "HKEY"') do (
for /f %%i in ('Reg query "%%a" /v "EnableAppOffloading" ^| findstr "HKEY"') do (Reg add "%%i" /v "EnableAppOffloading" /t Reg_DWORD /d "0" /f) >nul)
for /f "tokens=2 delims==" %%i in ('wmic os get TotalVisibleMemorySize /format:value') do set mem=%%i
set /a ram=%mem% + 1024000
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "%ram%" /f
:--------------------------------------

:: Autotuning Internet Speed and making it persistent
netsh.exe interface tcp set global autotuning = experimental >nul
netsh.exe interface tcp set heuristics disabled >nul

:: Setting the Congestion Provider for better Internet Speeds and Latency, to CTCP

netsh.exe interface tcp set supplemental Internet congestionprovider=ctcp >nul
netsh.exe interface tcp set supplemental InternetCustom congestionprovider=ctcp >nul

:: Reducing CPU for veryfast Internet Connections
netsh.exe int isatap set state disable
netsh.exe interface tcp set global rsc=disabled >nul
netsh.exe interface tcp set global ecncapability=enabled >nul
netsh.exe interface tcp set global timestamps=disabled >nul
netsh.exe interface tcp set global nonsackrttresiliency=disabled >nul
netsh.exe interface tcp set global maxsynretransmissions=2 >nul
netsh.exe interface tcp set supplemental template=custom icw=10 >nul
netsh.exe interface tcp set global fastopen=enabled >nul
netsh.exe interface tcp set global fastopenfallback=enabled >nul
netsh.exe interface tcp set security mpp=disabled >nul
netsh.exe interface tcp set security profiles=disabled >nul
netsh.exe interface udp set global uro=enabled >nul
netsh.exe int 6to4 set state state=disabled >nul
netsh.exe interface ip set global multicastforwarding=disabled >nul
netsh.exe interface tcp set security mpp=disabled profiles=disabled >nul
netsh.exe interface ip set global icmpredirects=disabled >nul
netsh.exe interface tcp set global rss=enabled >nul
netsh interface ip set global neighborcachelimit=4096 defaultcurhoplimit=64 taskoffload=enabled >nul
netsh interface tcp set global hystart=disabled >nul
netsh interface tcp set global fastopen=enabled >nul
:: some powershell.exe commands which apply to all present network adapters (optimizations for I/O Overhead and getting better ping in worse internet connections)
powershell.exe -command "Disable-NetAdapterChecksumOffload -Name "*"" >nul
powershell.exe -command "Disable-NetAdapterLso -Name "*"" >nul
powershell.exe -command "Set-NetOffloadGlobalSetting -PacketCoalescingFilter disabled" >nul
powershell.exe -command "Disable-NetAdapterRsc -Name "*"" >nul
powershell.exe -command Disable-NetAdapterBinding -Name "*" -ComponentID ms_pacer
powershell.exe -command "ForEach($adapter In Get-NetAdapter){Disable-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction SilentlyContinue}" >nul

:: Firewall Rules

netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul
netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul
netsh.exe advfirewall firewall set rule group="Delivery Optimization" new enable=No >nul
netsh.exe advfirewall firewall set rule group="Microsoft Family Safety" new enable=No >nul


:: Adding NetBios Options
for /f %%k in ('reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces') do (
reg add %%k /v NetbiosOptions /t reg_dword /d 2 /f
) >nul


:: Adding Network Adapters Options (can be modified in Advanced Device Options from Device Manager)

for /f "tokens=3*" %%a in ('reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\NetworkCards" /k /v /f "Description" /s /e ^| findstr /ri "REG_SZ"') do (
	for /f %%g in ('reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /f "%%b" /d ^| findstr /C:"HKEY"') do (
		reg add "%%g" /v "MIMOPowerSaveMode" /t REG_SZ /d "3" /f
		reg add "%%g" /v "PowerSavingMode" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*EEE" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnableConnectedPowerGating" /t REG_DWORD /d "0" /f
		reg add "%%g" /v "EnableDynamicPowerGating" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f
		reg add "%%g" /v "PnPCapabilities" /t REG_SZ /d "24" /f
		reg add "%%g" /v "*NicAutoPowerSaver" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*FlowControl" /t REG_SZ /d "0" /f
		reg add "%%g" /v "ULPMode" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnablePME" /t REG_SZ /d "0" /f
		reg add "%%g" /v "AlternateSemaphoreDelay" /t REG_SZ /d "0" /f
		reg add "%%g" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f
		reg add "%%g" /v "S5WakeOnLan" /t REG_SZ /d "0" /f
		reg add "%%g" /v "AutoDisableGigabit" /t REG_SZ /d "0" /f
		reg add "%%g" /v "GigaLite" /t REG_SZ /d "0" /f
		reg add "%%g" /v "NumRssQueues" /t REG_SZ /d "4" /f
		reg add "%%g" /v "*RSS" /t REG_SZ /d "1" /f
		reg add "%%g" /v "*IPChecksumOffloadIPv4" /t REG_SZ /d "3" /f
		reg add "%%g" /v "WakeOnLinkChange" /t REG_SZ /d "0" /f
		reg add "%%g" /v "ModernStandbyWoLMagicPacket" /t REG_SZ /d "0" /f
		reg add "%%g" /v "InterruptModeration" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*PMNSOffload" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*PMARPOffload" /t REG_SZ /d "1" /f
		reg add "%%g" /v "*JumboPacket" /t REG_SZ /d "9014" /f
		reg add "%%g" /v "*ReceiveBuffers" /t REG_SZ /d "512" /f
		reg add "%%g" /v "*TransmitBuffers" /t REG_SZ /d "128" /f
		reg add "%%g" /v "NumRssQueues" /t REG_SZ /d "4" /f
		reg add "%%g" /v "*LsoV2IPv6" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*LsoV2IPv4" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*SpeedDuplex" /t REG_SZ /d "6" /f
		reg add "%%g" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f
		reg add "%%g" /v "*WakeOnPattern" /t REG_SZ /d "0" /f
		reg add "%%g" /v "*WakeOnMagicPacket" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnablePME" /t REG_SZ /d "0" /f
		reg add "%%g" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f
		reg add "%%g" /v "ULPMode" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnablePowerManagement" /t REG_SZ /d "0" /f
		reg add "%%g" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f
		)
	)

:: Disabling Nagle's Algorithm for better Gaming Latency
for /f %%r in ('Reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /f "1" /d /s^|Findstr HKEY_') do (
Reg add %%r /v "TCPNoDelay" /t Reg_DWORD /d "1" /f
Reg add %%r /v "TcpAckFrequency" /t Reg_DWORD /d "1" /f
Reg add %%r /v "TcpDelAckTicks" /t Reg_DWORD /d "0" /f
) >nul

:--------------------------------------


:--------------------------------------
:: Disable Hibernation (and Hiberboot), ReserveStorage to get free up to >10GB of Windows Storage
powercfg -h off & DISM /Online /Set-ReservedStorageState /State:Disabled & reagentc /disable >nul
:--------------------------------------


:--------------------------------------
CLS & echo Please wait...
"powershell.exe" Enable-WindowsOptionalFeature -Online -FeatureName LegacyComponents -all -NoRestart
"powershell.exe" Enable-WindowsOptionalFeature -Online -FeatureName DirectPlay -all -NoRestart
:--------------------------------------