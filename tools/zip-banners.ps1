$sourceDir = Join-Path $PSScriptRoot "..\banners"
$destDir = Join-Path $PSScriptRoot "..\delivery"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

# Get format directories (assuming they start with a digit, e.g., 250x600)
$formats = Get-ChildItem -Path $sourceDir -Directory | Where-Object { $_.Name -match "^\d+x\d+$" }

foreach ($format in $formats) {
    $banners = Get-ChildItem -Path $format.FullName -Directory

    foreach ($banner in $banners) {
        # Name format: foldername_[format].zip
        $zipName = "$($banner.Name)_$($format.Name).zip"
        $zipPath = Join-Path $destDir $zipName
        
        Write-Host "Zipping $($banner.FullName) to $zipPath"
        
        if (Test-Path $zipPath) {
            Remove-Item $zipPath
        }

        # Compress the contents of the banner folder so index.html is at the root of the zip
        Compress-Archive -Path "$($banner.FullName)\*" -DestinationPath $zipPath
    }
}

Write-Host "All banners zipped to $destDir"
