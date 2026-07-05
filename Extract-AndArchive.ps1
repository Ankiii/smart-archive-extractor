#<#
#.SYNOPSIS
#    Recursively finds .zip, .7z, .gz, and .tgz files, extracts them to their parent folder, 
#    auto-renames duplicates, and moves the original archives to a safekeeping folder.
##>
#
#param (
#    # The folder to scan for compressed files
#    [Parameter(Mandatory=$true)]
#    [string]$TargetDirectory,
#
#    # The safekeeping folder under the root directory (Defaults to C:\Archive_Safekeeping)
#    [Parameter(Mandatory=$false)]
#    [string]$SafekeepingDirectory = "C:\Archive_Safekeeping",
#
#    # Path to the 7-Zip executable (Updated to your specific path)
#    [Parameter(Mandatory=$false)]
#    [string]$SevenZipPath = "E:\VIRTUALIZATION\TOOLS\7z\7-Zip\7z.exe"
#)
#
## 1. Validate 7-Zip Installation
#if (-not (Test-Path $SevenZipPath)) {
#    Write-Error "7-Zip is required for .7z, .gz, and .tgz support but was not found at '$SevenZipPath'. Please check the path."
#    return
#}
#
## 2. Prepare Safekeeping Directory
#if (-not (Test-Path $SafekeepingDirectory)) {
#    New-Item -ItemType Directory -Path $SafekeepingDirectory | Out-Null
#    Write-Host "Created safekeeping directory at: $SafekeepingDirectory" -ForegroundColor Green
#}
#
## 3. Locate Target Archives
#$validExtensions = @('.zip', '.7z', '.gz', '.tgz')
#Write-Host "Scanning '$TargetDirectory' for archives..." -ForegroundColor Cyan
#
## Fetch files recursively and filter by valid extensions
#$archives = Get-ChildItem -Path $TargetDirectory -File -Recurse | Where-Object { 
#    $validExtensions -contains $_.Extension.ToLower() 
#}
#
#if (-not $archives) {
#    Write-Host "No valid compressed files found in the target directory." -ForegroundColor Yellow
#    return
#}
#
#Write-Host "Found $($archives.Count) archives to process.`n" -ForegroundColor Green
#
## 4. Process Each Archive
#foreach ($archive in $archives) {
#    Write-Host "Processing: $($archive.FullName)" -ForegroundColor Cyan
#    $parentDir = $archive.DirectoryName
#
#    # 7-Zip Arguments:
#    # x    : Extract with full paths
#    # -o   : Output directory (Must not have a space after -o)
#    # -aot : Auto-rename existing files (e.g., file.txt becomes file_1.txt)
#    # -y   : Assume 'Yes' on all prompts
#    & $SevenZipPath x $archive.FullName "-o$parentDir" -aot -y | Out-Null
#    
#    if ($LASTEXITCODE -eq 0) {
#        
#        # --- Handle .tgz / .gz double-extraction quirk ---
#        # 7-Zip extracts a .tgz or .tar.gz to a .tar file first. We must extract the resulting .tar.
#        if ($archive.Extension.ToLower() -match '\.(tgz|gz)$') {
#            
#            $expectedTarName = $archive.BaseName
#            if ($archive.Extension.ToLower() -eq '.tgz') {
#                $expectedTarName += ".tar"
#            }
#            
#            $tarPath = Join-Path $parentDir $expectedTarName
#            
#            if (Test-Path $tarPath) {
#                Write-Host "  -> Intermediate TAR found, extracting contents..." -ForegroundColor DarkCyan
#                & $SevenZipPath x $tarPath "-o$parentDir" -aot -y | Out-Null
#                
#                # Clean up the intermediate .tar file if successful
#                if ($LASTEXITCODE -eq 0) {
#                    Remove-Item -Path $tarPath -Force
#                }
#            }
#        }
#
#        # --- Move Original to Safekeeping ---
#        $safeDest = Join-Path $SafekeepingDirectory $archive.Name
#        
#        # Collision handling for the Safekeeping folder (in case two folders had a "data.zip")
#        if (Test-Path $safeDest) {
#            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
#            $newName = "$($archive.BaseName)_$timestamp$($archive.Extension)"
#            $safeDest = Join-Path $SafekeepingDirectory $newName
#            Write-Host "  -> Archive name collision in Safekeeping. Renaming to $newName." -ForegroundColor DarkGray
#        }
#
#        Move-Item -Path $archive.FullName -Destination $safeDest -Force
#        Write-Host "  -> Success: Extracted and moved to Safekeeping." -ForegroundColor Green
#    } else {
#        Write-Error "Failed to extract: $($archive.FullName). 7-Zip exit code: $LASTEXITCODE"
#    }
#}
#
#Write-Host "`nScript execution completed." -ForegroundColor Green

<#
.SYNOPSIS
    Interactive Multi-Pass Archive Extractor with Logging.
    Production Ready.
#>

# --- 1. Interactive User Input ---
Write-Host "=== Smart Archive Extractor App ===" -ForegroundColor Cyan

# Ask for Target Directory
do {
    $TargetDirectory = Read-Host "Enter the Target Directory to scan (e.g., E:\WSL\data\work)"
    # Clean up accidental trailing slashes
    $TargetDirectory = $TargetDirectory.TrimEnd('\') 
    
    if (-not (Test-Path $TargetDirectory)) {
        Write-Host "Directory does not exist. Please try again." -ForegroundColor Red
    }
} while (-not (Test-Path $TargetDirectory))

# Ask for Safekeeping Directory (Default provided if left blank)
$SafekeepingDirectory = Read-Host "Enter Safekeeping Directory [Default: C:\Archive_Safekeeping]"
if ([string]::IsNullOrWhiteSpace($SafekeepingDirectory)) {
    $SafekeepingDirectory = "C:\Archive_Safekeeping"
}
$SafekeepingDirectory = $SafekeepingDirectory.TrimEnd('\')

# Ask for 7-Zip Executable Path (Your specific path provided as default if left blank)
$SevenZipPath = Read-Host "Enter 7z.exe Path [Default: E:\VIRTUALIZATION\TOOLS\7z\7-Zip\7z.exe]"
if ([string]::IsNullOrWhiteSpace($SevenZipPath)) {
    $SevenZipPath = "E:\VIRTUALIZATION\TOOLS\7z\7-Zip\7z.exe"
}

# --- 2. Setup Log File ---
$LogFile = Join-Path $TargetDirectory "extraction_log.txt"
function Write-Log ($Message, $Color = "White") {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    
    # Print to screen
    Write-Host $Message -ForegroundColor $Color
    # Save to file
    $LogMessage | Out-File -FilePath $LogFile -Append -Encoding utf8
}

# Initialize Log
"=== EXTRACTION LOG INITIATED ON $(Get-Date) ===" | Out-File -FilePath $LogFile -Encoding utf8
Write-Log "Target Directory set to: $TargetDirectory" "Cyan"
Write-Log "Safekeeping Directory set to: $SafekeepingDirectory" "Cyan"
Write-Log "7-Zip Path set to: $SevenZipPath" "Cyan"

# --- 3. Validate 7-Zip Installation ---
if (-not (Test-Path $SevenZipPath)) {
    Write-Log "ERROR: 7-Zip was not found at '$SevenZipPath'. Execution aborted." "Red"
    Read-Host "`nPress Enter to exit"
    return
}

# --- 4. Prepare Safekeeping Directory ---
if (-not (Test-Path $SafekeepingDirectory)) {
    New-Item -ItemType Directory -Path $SafekeepingDirectory | Out-Null
    Write-Log "Created safekeeping directory at: $SafekeepingDirectory" "Green"
}

$validExtensions = @('.zip', '.7z', '.gz', '.tgz')
$passNumber = 1

# --- 5. Multi-Pass Extraction Loop ---
do {
    # Fetch archives, EXCLUDING the Safekeeping folder itself to prevent infinite loops
    $archives = @(Get-ChildItem -Path $TargetDirectory -File -Recurse | Where-Object { 
        ($validExtensions -contains $_.Extension.ToLower()) -and 
        ($_.FullName -notmatch "^$([regex]::Escape($SafekeepingDirectory))")
    })
    
    if ($archives.Count -eq 0) {
        if ($passNumber -eq 1) {
            Write-Log "No valid compressed files found in the target directory." "Yellow"
        } else {
            Write-Log "No more nested archives found. Extraction fully complete!" "Green"
        }
        break
    }

    if ($passNumber -eq 1) {
        Write-Log "`n=== PASS 1: Processing Top-Level Archives ($($archives.Count) found) ===" "Green"
    } else {
        Write-Log "`n=== PASS $passNumber: Processing Nested Archives ($($archives.Count) found) ===" "DarkYellow"
    }

    foreach ($archive in $archives) {
        Write-Log "Processing: $($archive.FullName)" "Cyan"
        $parentDir = $archive.DirectoryName

        # Extract archive
        & $SevenZipPath x $archive.FullName "-o$parentDir" -aot -y | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            
            # --- Handle .tgz / .gz double-extraction quirk ---
            if ($archive.Extension.ToLower() -match '\.(tgz|gz)$') {
                $expectedTarName = $archive.BaseName
                if ($archive.Extension.ToLower() -eq '.tgz') { $expectedTarName += ".tar" }
                
                $tarPath = Join-Path $parentDir $expectedTarName
                if (Test-Path $tarPath) {
                    Write-Log "  -> Intermediate TAR found, extracting contents..." "DarkCyan"
                    & $SevenZipPath x $tarPath "-o$parentDir" -aot -y | Out-Null
                    if ($LASTEXITCODE -eq 0) { Remove-Item -Path $tarPath -Force }
                }
            }

            # --- Safekeeping vs Deletion Logic ---
            if ($passNumber -eq 1) {
                $safeDest = Join-Path $SafekeepingDirectory $archive.Name
                if (Test-Path $safeDest) {
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    $newName = "$($archive.BaseName)_$timestamp$($archive.Extension)"
                    $safeDest = Join-Path $SafekeepingDirectory $newName
                    Write-Log "  -> Archive name collision in Safekeeping. Renaming to $newName." "DarkGray"
                }
                Move-Item -Path $archive.FullName -Destination $safeDest -Force
                Write-Log "  -> Success: Extracted and MOVED to Safekeeping." "Green"
            } else {
                Remove-Item -Path $archive.FullName -Force
                Write-Log "  -> Success: Extracted nested archive and DELETED it." "DarkYellow"
            }
        } else {
            Write-Log "ERROR: Failed to extract: $($archive.FullName). 7-Zip exit code: $LASTEXITCODE" "Red"
        }
    }
    
    $passNumber++
} while ($true)

# Final notification to user
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Execution completed successfully!" -ForegroundColor Green
Write-Host "A full log file has been saved to: $LogFile" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

# Keep window open if running as EXE
Read-Host "`nPress Enter to exit"