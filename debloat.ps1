# Run as Administrator

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction Stop
        Write-Host "Successfully set $Name to $Value at $Path"
    } catch {
        Write-Host "Failed to set $Name at $Path. Error: $_"
    }
}

function Stop-And-Disable-Service {
    param (
        [string]$ServiceName
    )
    try {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Host "Successfully stopped service $ServiceName"
    } catch {
        Write-Host "Failed to stop service $ServiceName. Error: $_"
    }
    try {
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
        Write-Host "Successfully disabled service $ServiceName"
    } catch {
        Write-Host "Failed to disable service $ServiceName. Error: $_"
    }
}

function Remove-AppxPackageByName {
    param (
        [string]$PackageName
    )
    try {
        Get-AppxPackage -Name $PackageName | Remove-AppxPackage -ErrorAction Stop
        Write-Host "Successfully removed app $PackageName"
    } catch {
        Write-Host "Failed to remove app $PackageName. Error: $_"
    }
}

function Remove-OptionalFeature {
    param (
        [string]$FeatureName
    )
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
        Write-Host "Successfully removed $FeatureName feature"
    } catch {
        Write-Host "Failed to remove $FeatureName feature. Error: $_"
    }
}

# Part 1: Maximize Privacy Settings

# Disable Telemetry
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Disable Advertising ID
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

# Disable Feedback
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feedback" -Name "DisableWindowsFeedback" -Value 1

# Disable Location Tracking
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableWindowsLocationProvider" -Value 1

# Disable Cortana
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0

# Disable Background Apps
Get-AppxPackage | Where-Object {$_.IsFramework -ne $true} | ForEach-Object {
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name ($_.Name + "BackgroundAccessPolicy") -Value "Deny"
}

# Disable Diagnostics Tracking Service
Stop-And-Disable-Service -ServiceName "DiagTrack"

# Disable Wi-Fi Sense
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value 0

# Disable Windows Customer Experience Improvement Program (CEIP)
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0

# Part 2: Debloat Windows

# List of apps to remove
$appsToRemove = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MSPaint",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.MixedReality.Portal",
    "Microsoft.YourPhone",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.WindowsCommunicationsApps",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.WindowsCommunicationsApps",
    "Microsoft.MicrosoftEdge",
    "Microsoft.WindowsStore",
    "Microsoft.BingNews",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.OneConnect",
    "Microsoft.Wallet",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.YourPhone",
    "Microsoft.ZuneVideo",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.XboxGameOverlay",
    "Microsoft.MicrosoftEdgeDevToolsClient",
    "Microsoft.Teams"
)

# Remove each app
foreach ($app in $appsToRemove) {
    Remove-AppxPackageByName -PackageName $app
}

# Remove Xbox features
try {
    Get-WindowsCapability -Online | Where-Object { $_.Name -like "*XBOX*" } | ForEach-Object { 
        Remove-WindowsCapability -Online -Name $_.Name -ErrorAction Stop
        Write-Host "Successfully removed Xbox feature $($_.Name)"
    }
} catch {
    Write-Host "Failed to remove Xbox feature. Error: $_"
}

# Remove other unnecessary features
Remove-OptionalFeature -FeatureName "XPS-Viewer"

# Disable unnecessary services
$servicesToDisable = @(
    "DiagTrack", 
    "dmwappushservice",
    "MapsBroker",
    "XblAuthManager",
    "XblGameSave",
    "XboxNetApiSvc",
    "XboxGipSvc",
    "RetailDemo",
    "SysMain",
    "Connected User Experiences and Telemetry",
    "Fax",
    "Parental Controls",
    "Remote Desktop Services",
    "Windows Error Reporting Service",
    "Touch Keyboard and Handwriting Panel Service",
    "Distributed Link Tracking Client"
)

foreach ($service in $servicesToDisable) {
    Stop-And-Disable-Service -ServiceName $service
}

# Part 3: Check and Install Windows Updates

# Ensure the PSWindowsUpdate module is installed
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
}

# Import the module
Import-Module PSWindowsUpdate

# Check for updates
try {
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -ErrorAction Stop
    if ($updates -ne $null) {
        Write-Host "The following updates were installed:" -ForegroundColor Green
        $updates | Format-Table -Property Title, KBArticle, Size, InstalledOn
    } else {
        Write-Host "No updates available or required." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to check or install updates. Error: $_"
}

# Ensure the PendingReboot module is installed
if (-not (Get-Module -ListAvailable -Name PendingReboot)) {
    Install-Module -Name PendingReboot -Force -SkipPublisherCheck
}

# Import the module
Import-Module PendingReboot

# List any pending reboots
$rebootRequired = $false
if (Test-PendingReboot) {
    Write-Host "A system reboot is required to complete the updates." -ForegroundColor Red
    $rebootRequired = $true
} else {
    Write-Host "No reboot required." -ForegroundColor Green
}

# Remove additional apps from Start Menu and Taskbar

# Unpin items from Start Menu
$startLayout = @(
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsNotepad",
    "Microsoft.Paint",
    "SpotifyAB.SpotifyMusic",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.YourPhone",
    "Microsoft.GetHelp",
    "Microsoft.Windows.Photos",
    "Microsoft.Clipchamp",
    "Microsoft.Todos",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.LinkedIn",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Office.OneNote",
    "Microsoft.Xbox.TCUI"
)

foreach ($app in $startLayout) {
    try {
        Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction Stop
        Write-Host "Successfully removed app $app"
    } catch {
        Write-Host "Failed to remove app $app. Error: $_"
    }
}

# Unpin from taskbar
function Unpin-Taskbar {
    param (
        [string]$AppName
    )
    try {
        $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
        $taskbarApps = (Get-ItemProperty -Path $keyPath).Favorites
        $updatedApps = $taskbarApps -replace ".*$AppName.*", ""
        Set-ItemProperty -Path $keyPath -Name Favorites -Value $updatedApps -ErrorAction Stop
        Write-Host "Successfully unpinned $AppName from the taskbar"
    } catch {
        Write-Host "Failed to unpin $AppName from the taskbar. Error: $_"
    }
}

# Example to unpin specific apps
$appsToUnpin = @(
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsNotepad",
    "Microsoft.Paint",
    "SpotifyAB.SpotifyMusic",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.YourPhone",
    "Microsoft.GetHelp",
    "Microsoft.Windows.Photos",
    "Microsoft.Clipchamp",
    "Microsoft.Todos",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.LinkedIn",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Office.OneNote",
    "Microsoft.Xbox.TCUI"
)

foreach ($app in $appsToUnpin) {
    Unpin-Taskbar -AppName $app
}

Write-Host "Script execution completed. Please review the output." -ForegroundColor Green

if ($rebootRequired) {
    Write-Host "A system reboot is required to complete the updates." -ForegroundColor Red
} else {
    Write-Host "No reboot required." -ForegroundColor Green
}
