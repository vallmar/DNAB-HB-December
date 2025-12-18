$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$bannersRoot = Join-Path $root 'banners'
$arkivRoot = Join-Path $root 'Arkiv'

# Configuration for messages
# Updated 'se-klart' to match the user's example.
# Others are kept simple as I don't have the full copy.
$messages = @(
    @{ 
        key = 'andas-lugnt'; 
        title = 'Andas lugnt'; 
        lines = @(
            @{ text = 'Andas lugnt.'; color = 'white' }
        ); 
        subcopy = 'Vi hjälper dig med din ekonomi.' 
    },
    @{ 
        key = 'hitta-hem'; 
        title = 'Hitta hem'; 
        lines = @(
            @{ text = 'Hitta hem.'; color = 'white' }
        ); 
        subcopy = 'Vi hjälper dig med din ekonomi.' 
    },
    @{ 
        key = 'se-klart'; 
        title = 'Se klart'; 
        lines = @(
            @{ text = 'Se klart.'; color = 'white' },
            @{ text = 'Med långsiktig'; color = 'blue' },
            @{ text = 'Private Banking'; color = 'blue' },
            @{ text = 'nära dig'; color = 'blue' }
        ); 
        subcopy = 'Välkommen att boka<br>ett personligt samtal' 
    },
    @{ 
        key = 'sta-stadigt'; 
        title = 'Stå stadigt'; 
        lines = @(
            @{ text = 'Stå stadigt.'; color = 'white' }
        ); 
        subcopy = 'Vi hjälper dig med din ekonomi.' 
    },
    @{ 
        key = 'tank-storre'; 
        title = 'Tänk större'; 
        lines = @(
            @{ text = 'Tänk större.'; color = 'white' }
        ); 
        subcopy = 'Vi hjälper dig med din ekonomi.' 
    }
)

$formats = @(
    @{ name = '250x600'; width = 250; height = 600; textOnly = $true;  templateDir = Join-Path $arkivRoot '250x600' },
    @{ name = '320x320'; width = 320; height = 320; textOnly = $false; templateDir = $null },
    @{ name = '320x480'; width = 320; height = 480; textOnly = $false; templateDir = Join-Path $arkivRoot '320x480' },
    @{ name = '640x640'; width = 640; height = 640; textOnly = $false; templateDir = Join-Path $arkivRoot '640x640' },
    @{ name = '980x240'; width = 980; height = 240; textOnly = $true;  templateDir = Join-Path $arkivRoot '980x240' },
    @{ name = '980x600'; width = 980; height = 600; textOnly = $false; templateDir = Join-Path $arkivRoot '980x600' }
)

$logoSource = Join-Path $bannersRoot '640x640\HB_Wordmark.svg'
if (-not (Test-Path $logoSource)) { $logoSource = $null }

function Find-ReferenceJpg {
    param([string]$dir, [string]$key)
    if (-not $dir -or -not (Test-Path $dir)) { return $null }
    $pat = "*$key*"
    return Get-ChildItem -LiteralPath $dir -Filter '*.jpg' | Where-Object { $_.Name -like $pat } | Select-Object -First 1 -ExpandProperty FullName
}

function Get-HtmlContent {
    param(
        $format,
        $message,
        $hasImage
    )

    $width = $format.width
    $height = $format.height
    $title = "$($message.title) ${width}x${height}"
    
    # CSS Logic
    $cssImage = ""
    if ($hasImage) {
        $cssImage = @"
        .top-image {
            display: block;
            width: $([math]::Round($width * 0.9))px;
            height: $([math]::Round($height * 0.45))px;
            margin: 20px auto 0 auto;
            border-radius: 6px;
            object-fit: cover;
            background-color: #ccc;
            position: relative;
            z-index: 1;
        }
"@
    }

    # Generate lines HTML
    $linesHtml = ""
    foreach ($line in $message.lines) {
        # Using 'pivot' and 'is-x' as base classes. JS will handle the animation reset.
        # Added 'line' class for styling.
        $linesHtml += "            <p class=""line $($line.color) pivot"" data-pivot-group=""headline"">$($line.text)</p>`n"
    }

    return @"
<!DOCTYPE html>
<html lang="sv">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="ad.size" content="width=$width,height=$height">
    <title>$title</title>
    <style>
        @font-face {
            font-family: 'Handelsbanken Serif';
            src: url('../WOFF2/HandelsbankenSerif-Bold.woff2') format('woff2');
            font-weight: bold;
            font-style: normal;
        }
        html {
            width: ${width}px;
            height: ${height}px;
            background: white;
        }
        body {
            margin: 0;
            padding: 0;
            width: ${width}px;
            height: ${height}px;
            font-family: 'Handelsbanken Serif', serif;
            background: #002f4d;
            color: #fff;
            overflow: hidden;
            position: relative;
        }
        $cssImage
        .copy {
            position: absolute;
            left: 24px;
            right: 24px;
            top: $(if($hasImage){ "50%" } else { "24px" });
            z-index: 2;
        }
        .copy p {
            font-size: $(if($width -lt 400){ "30px" } else { "52px" });
            line-height: 1.0;
            margin: 0;
            margin-bottom: 8px;
            display: block;
        }
        .copy p.white { color: #ffffff; }
        .copy p.blue { color: #3CADFF; }

        .subcopy {
            position: absolute;
            left: 24px;
            bottom: 26px;
            font-size: 18px;
            z-index: 2;
        }
        .wordmark {
            position: absolute;
            right: 24px;
            bottom: 24px;
            width: $(if($width -lt 400){ "100px" } else { "150px" });
            z-index: 2;
        }
        .click-layer {
            position: absolute;
            top:0; left:0; width:100%; height:100%;;
            cursor: pointer;
            z-index: 10;
        }

        /* Animation Classes */
        .pivot {
            opacity: 0;
            transform: translate(56px, 0px);
            will-change: transform, opacity;
        }
        .pivot.headline {
            opacity: 0;
            transform: translate(0px, 36px);
            will-change: transform, opacity;
        }
        .pivot.is-y {
            opacity: 1;
            transform: translate(0px, 0px);
            transition: transform 520ms cubic-bezier(0.2, 0.0, 0.0, 1.0), opacity 520ms cubic-bezier(0.2, 0.0, 0.0, 1.0);
        }
        .pivot.is-x {
            transform: translate(0px, 0px);
            opacity: 1;
            transition: transform 420ms cubic-bezier(0.2, 0.0, 0.0, 1.0);
        }
    </style>
</head>
<body>
    <div id="ad">
$(if($hasImage) { '        <img class="top-image" src="image.jpg" alt="">' })
        <div class="copy headline pivot is-y">
$linesHtml
        </div>
        <div class="subcopy pivot is-x" data-pivot-group="subcopy">$($message.subcopy)</div>
        <img class="wordmark pivot is-x" src="HB_Wordmark.svg" alt="Handelsbanken">
        <a href="#" class="click-layer" id="clickArea"></a>
    </div>
    <script>
        var clickTag = "https://www.handelsbanken.se/";
        document.getElementById('clickArea').addEventListener('click', function(e) {
            e.preventDefault();
            window.open(window.clickTag || clickTag, '_blank');
        });

        (function () {
            function onReady(fn) {
                if (document.readyState === 'complete' || document.readyState === 'interactive') {
                    window.setTimeout(fn, 0);
                    return;
                }
                document.addEventListener('DOMContentLoaded', fn, { once: true });
            }

            var prefersReducedMotion = false;
            try {
                prefersReducedMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            } catch (e) {
                prefersReducedMotion = false;
            }

            var Y_DURATION = 520;

            function setInitial(el) {
                el.classList.remove('is-y');
                el.classList.remove('is-x');
            }

            function pivotIn(el, delayMs) {
                var yMovement = el.classList.contains('headline') && el.classList.contains('pivot'); // Check if it's the container
                // Actually, the container has 'headline pivot is-y' in HTML.
                // But we want to detect if we should do Y movement.
                // In the reference code: const yMovement = el.classList.contains('is-y');
                // But setInitial removes is-y. So we need a way to know.
                // The reference code had 'is-y' in HTML for the container.
                // Let's check if it *should* be Y.
                // The container is the only one with 'is-y' in HTML.
                // But wait, setInitial is called at start of pivotIn.
                // So el.classList.contains('is-y') will be true if we haven't removed it yet.
                // Yes, that works.
                
                var isY = el.classList.contains('is-y');
                setInitial(el);

                if (prefersReducedMotion) {
                    el.style.opacity = '1';
                    el.style.transform = 'translate(0px, 0px)';
                    return;
                }

                window.setTimeout(function () {
                    if(isY) {
                        el.classList.add('is-y');
                    } else {
                        el.classList.add('is-x');
                    }
                }, delayMs);
            }

            function run() {
                var headlineLines = Array.prototype.slice.call(document.querySelectorAll('[data-pivot-group="headline"]'));
                var subcopy = document.querySelector('[data-pivot-group="subcopy"]');
                var copyContainer = document.querySelector('.headline.pivot');
                var wordmark = document.querySelector('.wordmark');
                
                if (copyContainer) pivotIn(copyContainer, 100);
                
                for (var i = 0; i < headlineLines.length; i++) {
                    pivotIn(headlineLines[i], 300 + (i * 40));
                }

                if (subcopy) pivotIn(subcopy, 520);
                if (wordmark) pivotIn(wordmark, 520);
            }

            onReady(function () {
                window.requestAnimationFrame(run);
            });
        })();
    </script>
</body>
</html>
"@
}

Write-Host "Generating banners v3 (with animation)..." -ForegroundColor Cyan

foreach ($fmt in $formats) {
    $fmtDir = Join-Path $bannersRoot $fmt.name
    if (-not (Test-Path $fmtDir)) { New-Item -ItemType Directory -Path $fmtDir | Out-Null }

    foreach ($msg in $messages) {
        $variantDir = Join-Path $fmtDir $msg.key
        if (-not (Test-Path $variantDir)) { New-Item -ItemType Directory -Path $variantDir | Out-Null }

        # 1. Copy Logo
        if ($logoSource) { Copy-Item -LiteralPath $logoSource -Destination (Join-Path $variantDir 'HB_Wordmark.svg') -Force }

        # 2. Copy Reference JPG
        $refJpg = Find-ReferenceJpg -dir $fmt.templateDir -key $msg.key
        if ($refJpg) {
            Copy-Item -LiteralPath $refJpg -Destination (Join-Path $variantDir '_reference.jpg') -Force
        }

        # 3. Generate HTML
        $hasImage = -not $fmt.textOnly
        $html = Get-HtmlContent -format $fmt -message $msg -hasImage $hasImage
        [System.IO.File]::WriteAllText((Join-Path $variantDir 'index.html'), $html, [System.Text.Encoding]::UTF8)
        
        # 4. Preserve existing image.jpg if it exists
        # (No action needed, we don't overwrite image.jpg)
    }
}

Write-Host "Done." -ForegroundColor Green
