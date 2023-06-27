# Install required modules if not already installed
$modules = ("MSOnline")
foreach ($module in $modules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Force
    }
}

# Import the required module
Import-Module -Name MSOnline -ErrorAction Stop

# Check if there is an existing session
$existingSession = $null
try {
    $existingSession = Get-MsolDomain -ErrorAction Stop
} catch {
    # Ignore errors when no session exists
}

if (-not $existingSession) {
    # Connect to Azure AD
    Connect-MsolService
}

# Prompt for user email addresses
$emails = Read-Host "Enter user email addresses (comma-separated)"

# Split the email addresses into an array
$emailArray = $emails -split ','

# Get devices for each user
$devices = foreach ($email in $emailArray) {
    # Get the user based on the email address
    $user = Get-MsolUser -UserPrincipalName $email

    if ($user) {
        # Get the devices assigned to the user
        $userDevices = Get-MsolDevice -RegisteredOwnerUpn $email

        if ($userDevices) {
            foreach ($device in $userDevices) {
                # Create a custom object with device details
                [PSCustomObject]@{
                    UserDisplayName = $user.DisplayName
                    UserEmail = $user.UserPrincipalName
                    DeviceDisplayName = $device.DisplayName
                    DeviceId = $device.DeviceId
                    DeviceTrustType = $device.DeviceTrustType
                    ApproximateLastLogonTimestamp = $device.ApproximateLastLogonTimestamp
                }
            }
        }
    }
}

# Display device details
if ($devices) {
    $devices | Format-Table -AutoSize
} else {
    Write-Host "No devices found for the specified email addresses."
}
