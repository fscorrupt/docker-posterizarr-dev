function ScriptSchedule {
    # Posterizarr File Watcher for Tautulli Recently Added Files
    $inputDir = '/config/watcher'
    $Scriptargs = "-Tautulli"
    $Directory = Get-ChildItem -Name $inputDir

    if (!$env:RUN_TIME) {
        $env:RUN_TIME = "05:00"  # Set default value if not provided
    }

    $NextScriptRun = $env:RUN_TIME -split ',' | Sort-Object

    Write-Host "File Watcher Started..."
    # Next Run
    while ($true) {
        $elapsedTime = $(get-date) - $StartTime
        $totalTime = $elapsedTime.Days.ToString() + ' Days ' + $elapsedTime.Hours.ToString() + ' Hours ' + $elapsedTime.Minutes.ToString() + ' Min ' + $elapsedTime.Seconds.ToString() + ' Sec'
        $NextScriptRun = $env:RUN_TIME -split ',' | ForEach-Object {
            $Hour = $_.split(':')[0]
            $Minute = $_.split(':')[1]
            $NextTrigger = Get-Date -Hour $Hour -Minute $Minute
            $CurrentTime = Get-Date
            if ($NextTrigger -lt $CurrentTime) {
                $NextTrigger = $NextTrigger.AddDays(1)
            }
            $offset = $NextTrigger - $CurrentTime
            [PSCustomObject]@{
                RunTime = $_
                Offset = $offset.TotalSeconds
            }
        } | Sort-Object -Property Offset | Select-Object -First 1
    
        # Use the nearest scheduled run time
        $NextScriptRunTime = $NextScriptRun.RunTime
        $NextScriptRunOffset = $NextScriptRun.Offset
        if (!$alreadydisplayed){
            write-host ""
            write-host "Container is running since: " -NoNewline
            write-host "$totalTime" -ForegroundColor Cyan
            CompareScriptVersion
            write-host ""
            Write-Host "Next Script Run is at: $NextScriptRunTime"
            $alreadydisplayed = $true
        }
        if ($NextScriptRunOffset -le '60') {
            $alreadydisplayed = $null
            Start-Sleep $NextScriptRunOffset 
            # Calling the Posterizarr Script
            if ((Get-Process | Where-Object commandline -like 'pwsh')) {
                Write-Warning "There is currently running another Process of Posterizarr, skipping this run."
            }
            Else {
                pwsh Posterizarr.ps1
            }
        }
        If ($Directory) 
        {
            $TautulliTriggers = Get-ChildItem $inputDir -Recurse | Where-Object -FilterScript {
                $_.Extension -match 'posterizarr'
            }
    
            foreach($item in $TautulliTriggers)
            {
                write-host "Found .posterizarr file..."
                
                # Get trigger Values
                $triggerargs = Get-Content $item
                
                # Replace args
                foreach ($line in $triggerargs) {
                    if ($line -match '^\[(.+)\]: (.+)$') {
                        $arg_name = $matches[1]
                        $arg_value = $matches[2]
                        $Scriptargs += " -$arg_name $arg_value"
                    }
                }
            
                write-host "Building trigger args..."
                write-host "Calling Posterizarr with this args: $Scriptargs"

                # Call Posterizarr with Args
                pwsh -Command "./Posterizarr.ps1 $Scriptargs"

                # Reset scriptargs
                $Scriptargs = "-Tautulli"
                write-host ""
                write-host "Tautulli Recently added finished, removing trigger file: $($item.Name)"
                write-host ""
                write-host "Container is running since: " -NoNewline
                write-host "$totalTime" -ForegroundColor Cyan
                CompareScriptVersion
                write-host ""
                Write-Host "Next Script Run is at: $NextScriptRunTime"
                Remove-Item "$inputDir/$($item.Name)" -Force -Confirm:$false
            }
    
            $Directory = Get-ChildItem -Name $inputDir
        }
        if (!$Directory)
        {
            Start-Sleep -Seconds 30
            $Directory = Get-ChildItem -Name $inputDir
        }
    }
}
function GetLatestScriptVersion {
    try {
        return Invoke-RestMethod -Uri "https://github.com/fscorrupt/Posterizarr/raw/main/Release.txt" -Method Get -ErrorAction Stop
    }
    catch {
        Write-Entry -Subtext "Could not query latest script version, Error: $($_.Exception.Message)" -Path $global:ScriptRoot\Logs\Scriptlog.log -Color Red -log Error
        return $null
    }
}
function CompareScriptVersion {
    # Current Imagemagick Version
    $magick = 'magick'
    $CurrentImagemagickversion = & $magick -version
    $CurrentImagemagickversion = [regex]::Match($CurrentImagemagickversion, 'Version: ImageMagick (\d+(\.\d+){1,2}-\d+)')
    $CurrentImagemagickversion = $CurrentImagemagickversion.Groups[1].Value.replace('-', '.')
    
    # Latest Imagemagick Version
    $Url = "https://pkgs.alpinelinux.org/package/edge/community/x86_64/imagemagick"
    $response = Invoke-WebRequest -Uri $url
    $htmlContent = $response.Content
    $regexPattern = '<th class="header">Version<\/th>\s*<td>\s*<strong>\s*<a[^>]*>([^<]+)<\/a>\s*<\/strong>\s*<\/td>'
    $Versionmatching = [regex]::Matches($htmlContent, $regexPattern)

    if ($Versionmatching.Count -gt 0) {
        $LatestImagemagickversion = $Versionmatching[0].Groups[1].Value.split('-')[0]
    }
    # Use Select-String to find the line containing the variable assignment
    $lineContainingVersion = Select-String -Path "./Posterizarr.ps1" -Pattern '^\$CurrentScriptVersion\s*=\s*"([^"]+)"' | Select-Object -ExpandProperty Line
    $LatestScriptVersion = GetLatestScriptVersion
    if ($lineContainingVersion) {
        # Extract the version from the line
        write-host ""
        $version = $lineContainingVersion -replace '^\$CurrentScriptVersion\s*=\s*"([^"]+)".*', '$1'
        write-host "Current Script Version: $version | Latest Script Version: $LatestScriptVersion" -ForegroundColor Green 
    }
    if ($CurrentImagemagickversion -and $LatestImagemagickversion) {
        write-host "Current Imagemagick Version: $CurrentImagemagickversion | Latest Imagemagick Version: $LatestImagemagickversion"
    }
}
function Test-And-Download {
    param(
        [string]$url,
        [string]$destination
    )

    if (!(Test-Path $destination)) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
        } catch {
            Write-Host "Failed to download $url to $destination. Error: $_"
        }
    } 
}
# Check if PUID and PGID environment variables are set
$puid = $env:PUID
$pgid = $env:PGID

# Check if PUID and PGID are provided
if ($puid -and $pgid) {
    Write-Host "Adjusting user and group to PUID: $puid and PGID: $pgid..."

    # Modify group ID
    $GroupCmd = "groupadd -g $pgid posterizarr 2>/dev/null"
    $UserCmd = " useradd -u $puid -g $pgid -M posterizarr 2>/dev/null"

    # Apply the commands as root
    Invoke-Expression $GroupCmd
    Invoke-Expression $UserCmd
} else {
    Write-Host "PUID or PGID not provided, using root user by default."
}

# Check temp dir if there is a Currently running file present
$CurrentlyRunning = "/config\temp\Posterizarr.Running"

# Continue with the rest of your script...
# Clear Running File
if (Test-Path $CurrentlyRunning) {
    Invoke-Expression "chown posterizarr:posterizarr /config/temp/Posterizarr.Running 2>/dev/null"
    try {
        Remove-Item -LiteralPath $CurrentlyRunning -Force | out-null
        if (!Test-Path $CurrentlyRunning) {
            Write-Host "Cleared .running file..." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Failed to delete '$CurrentlyRunning' file. Error: $_"
    }
}

# Download latest Script file
$ProgressPreference = 'SilentlyContinue'
Test-And-Download -url "https://github.com/fscorrupt/Posterizarr/raw/main/overlay.png" -destination /config\overlay.png
Test-And-Download -url "https://github.com/fscorrupt/Posterizarr/raw/main/backgroundoverlay.png" -destination /config\backgroundoverlay.png
Test-And-Download -url "https://github.com/fscorrupt/Posterizarr/raw/main/Rocky.ttf" -destination /config\Rocky.ttf
Test-And-Download -url "https://github.com/fscorrupt/Posterizarr/raw/main/Colus-Regular.ttf" -destination /config\Colus-Regular.ttf
Test-And-Download -url "https://github.com/fscorrupt/Posterizarr/raw/main/Comfortaa-Medium.ttf" -destination /config\Comfortaa-Medium.ttf
Invoke-WebRequest -uri "https://github.com/fscorrupt/Posterizarr/raw/main/Posterizarr.ps1" -OutFile $PSScriptRoot\Posterizarr.ps1
Invoke-WebRequest -uri "https://github.com/fscorrupt/Posterizarr/raw/main/config.example.json" -OutFile /config\config.example.json
$ProgressPreference = 'Continue'

if ($puid -and $pgid) {
    # Use chown and chmod to adjust ownership and permissions
    $chown = "chown -R posterizarr:posterizarr /config /assets /home/posterizarr"
    $chmod = "chmod -R 755 /config /assets"
    Write-Host "Changing ownership of /config and /assets to posterizarr:posterizarr ..."

    # Run chown command
    Invoke-Expression $chown
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Chown failed with exit code $LASTEXITCODE, likely due to permission issues."
        Write-Host "    Please manually change ownership of the directories or ensure proper permissions."
        Write-Host "    PUID: $puid | PGID: $pgid"

        # Retry loop
        while ($LASTEXITCODE -ne 0) {
            Write-Host "Sleeping for 5 minutes before retrying..."
            Start-Sleep 300  # Sleep for 5 minutes
            Invoke-Expression $chown
        }
    } else {
        Invoke-Expression $chmod
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Ownership and permissions changed successfully."
        }
    }
} else {
    Write-Host "PUID or PGID not set, skipping ownership change."
}

# Create Folders
$folders = @("Logs", "temp", "watcher", "test")
foreach ($folder in $folders) {
    $path = Join-Path "/config" $folder
    if (-not (Test-Path $path)) {
        $null = New-Item -Path $path -ItemType Directory -ErrorAction SilentlyContinue
        if ($puid -and $pgid) {
            # Change ownership of the newly created directory
            Invoke-Expression "chown posterizarr:posterizarr $path"
        }
    }
}

# Checking Config file
if (-not (test-path "/config\config.json")) {
    Write-Host "Creating folder structure for you..."
    Write-Host ""
    Write-Host "Could not find a 'config.json' file" -ForegroundColor Red
    Write-Host "Please edit the config.example.json according to GH repo and save it as 'config.json'" -ForegroundColor Yellow 
    Write-Host "    After that restart the container..."
    Write-Host "Exiting now"
    do {
        Start-Sleep 600
    } until (
        test-path "/config\config.json"
    )
}

# Show integraded Scripts
$StartTime = Get-Date
write-host "Container Started..." -ForegroundColor Green
ScriptSchedule
