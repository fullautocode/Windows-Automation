# Define the IP address to ping
$ipAddress = " " # Ex: 192.168.0.1

# Function to ping the IP address
function Ping-IPAddress {
    param (
        [string]$ipAddress
    )

    while ($true) {
        $pingResult = Test-Connection -ComputerName $ipAddress -Count 1 -ErrorAction SilentlyContinue

        if ($pingResult) {
            Write-Host "$(Get-Date): $ipAddress is reachable" -ForegroundColor Green
        } else {
            Write-Host "$(Get-Date): $ipAddress is not reachable" -ForegroundColor Red
        }

        Start-Sleep -Seconds 60
    }
}

# Call the function to start pinging
Ping-IPAddress -ipAddress $ipAddress
