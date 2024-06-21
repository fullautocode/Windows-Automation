# Define the IP addresses to ping
$ipAddress1 = "" # Example "192.168.1.1"
$ipAddress2 = "" 
$ipAddress3 = ""

# Function to ping the IP addresses
function Ping-IPAddress {
    param (
        [string]$ipAddress1,
        [string]$ipAddress2,
        [string]$ipAddress3
    )

    while ($true) {
        $pingResult1 = Test-Connection -ComputerName $ipAddress1 -Count 1 -ErrorAction SilentlyContinue

        if ($pingResult1) {
            Write-Host "$(Get-Date): $ipAddress1 is reachable" -ForegroundColor Green
        } else {
            Write-Host "$(Get-Date): $ipAddress1 is not reachable" -ForegroundColor Red
        }

        $pingResult2 = Test-Connection -ComputerName $ipAddress2 -Count 1 -ErrorAction SilentlyContinue

        if ($pingResult2) {
            Write-Host "$(Get-Date): $ipAddress2 is reachable" -ForegroundColor Green
        } else {
            Write-Host "$(Get-Date): $ipAddress2 is not reachable" -ForegroundColor Red
        }

        $pingResult3 = Test-Connection -ComputerName $ipAddress3 -Count 1 -ErrorAction SilentlyContinue

        if ($pingResult3) {
            Write-Host "$(Get-Date): $ipAddress3 is reachable" -ForegroundColor Green
        } else {
            Write-Host "$(Get-Date): $ipAddress3 is not reachable" -ForegroundColor Red
        }

        Start-Sleep -Seconds 60
    }
}

# Call the function to start pinging
Ping-IPAddress -ipAddress1 $ipAddress1 -ipAddress2 $ipAddress2 -ipAddress3 $ipAddress3


