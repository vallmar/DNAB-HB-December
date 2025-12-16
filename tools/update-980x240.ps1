$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bannersRoot = Join-Path $root 'banners'
$targetFormat = '980x240'

$files = Get-ChildItem -Path (Join-Path $bannersRoot $targetFormat) -Recurse -Filter 'index.html'

foreach ($file in $files) {
    Write-Host "Updating $($file.FullName)..."
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    # 1. Inject Image Element if missing
    if ($content -notmatch 'class="top-image"') {
        # Insert before <div class="copy...
        $content = $content -replace '(<div class="copy)', '<img class="top-image" src="image.jpg" alt="">
        $1'
    }

    # 2. Update CSS
    # We will append a new style block at the end of the <style> section to override previous rules
    # This is safer than regex-replacing complex CSS blocks
    $newCss = @"
        /* 980x240 Specific Overrides */
        .top-image {
            display: block;
            position: absolute;
            right: 41px;
            top: 0;
            width: 542px;
            height: 100%; /* Assuming full height cover */
            object-fit: cover;
            border-radius: 0; /* Reset radius if any */
            margin: 0;
            background-color: #ccc;
        }
        .wordmark {
            left: 41px;
            bottom: 41px;
            width: 480px;
            right: auto;
        }
        .copy {
            top: 70px;
            left: 41px;
            right: auto;
        }
        .headline, .copy p {
            font-size: 54px !important;
            line-height: 1.0;
        }
        .subcopy {
            display: none; /* Hide subcopy as it likely conflicts with the large logo */
        }
"@
    
    if ($content -notmatch '980x240 Specific Overrides') {
        $content = $content -replace '</style>', "$newCss`n    </style>"
    }

    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
}

Write-Host "Updated 980x240 layout." -ForegroundColor Green
