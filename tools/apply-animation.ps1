$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bannersRoot = Join-Path $root 'banners'

# 1. Read Reference Content
$refFile = Join-Path $bannersRoot '320x480\se-klart\index.html'
if (-not (Test-Path $refFile)) { throw "Reference file not found: $refFile" }
$refContent = Get-Content -LiteralPath $refFile -Raw -Encoding UTF8

# Extract CSS (Animation parts)
# We'll just use the known CSS block to ensure we get exactly what we want
$animationCss = @"
        .pivot.line {
            opacity: 1;
        }
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
"@

# Extract JS
# We'll use a regex to grab the script content from the reference, or just hardcode the known good JS
# Hardcoding is safer to avoid regex issues with the file content
$animationJs = @"
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
                // Keep base .pivot styles for initial state
            }

            function pivotIn(el, delayMs) {
                // console.log(delayMs);
                const yMovement = el.classList.contains('is-y');
                setInitial(el);
                // if (prefersReducedMotion) {
                //     el.style.opacity = '1';
                //     el.style.transform = 'translate(0px, 0px)';
                //     return;
                // }

                // Phase 1: Vertical move (Y) + fade in. X stays constant.
                window.setTimeout(function () {
                    if(yMovement) {
                        el.classList.add('is-y');
                        
                // console.log(yMovement);
                    }
                    else{

                        // Phase 2: Horizontal move (X only). Y stays at 0.
                        window.setTimeout(function () {
                            el.classList.add('is-x');
                        }, Y_DURATION);
                        
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
                    pivotIn(headlineLines[i], 300 +(i * 40));
                }

                if (subcopy) {
                    pivotIn(subcopy, 520);
                }
                if (wordmark) {
                    pivotIn(wordmark, 520);
                }
            }
            onReady(function () {
                // Defer one frame so layout styles apply before we toggle classes.
                window.requestAnimationFrame(run);
            });
        })();
    </script>
"@

# 2. Iterate and Apply
$files = Get-ChildItem -Path $bannersRoot -Recurse -Filter 'index.html'

foreach ($file in $files) {
    if ($file.FullName -eq $refFile) { continue } # Skip the reference file itself

    Write-Host "Processing $($file.FullName)..."
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    # A. Inject CSS
    # Check if animation CSS is already there
    if ($content -notmatch '\.pivot\.is-y') {
        # Insert before </style>
        $content = $content -replace '</style>', "$animationCss`n    </style>"
    }

    # B. Replace JS
    # Replace the existing <script>...</script> block with the new one
    # Assuming one main script block at the end
    $content = $content -replace '(?s)<script>.*?</script>', $animationJs

    # C. Update HTML Classes
    
    # 1. Container: <div class="copy"> -> <div class="copy headline pivot is-y">
    if ($content -match '<div class="copy">') {
        $content = $content -replace '<div class="copy">', '<div class="copy headline pivot is-y">'
    }

    # 2. Headline Item: <h1 class="headline"> -> <h1 class="line pivot is-x" data-pivot-group="headline">
    # Note: We replace class="headline" with class="line..." to avoid conflict with container selector .pivot.headline
    if ($content -match '<h1 class="headline">') {
        $content = $content -replace '<h1 class="headline">', '<h1 class="line pivot is-x" data-pivot-group="headline">'
    }
    # Also handle p tags if any (from previous edits)
    if ($content -match '<p class="headline">') {
        $content = $content -replace '<p class="headline">', '<p class="line pivot is-x" data-pivot-group="headline">'
    }

    # 3. Subcopy: <div class="subcopy"> -> <div class="subcopy pivot is-x" data-pivot-group="subcopy">
    if ($content -match '<div class="subcopy">') {
        $content = $content -replace '<div class="subcopy">', '<div class="subcopy pivot is-x" data-pivot-group="subcopy">'
    }

    # 4. Wordmark: <img class="wordmark" -> <img class="wordmark pivot is-x"
    if ($content -match '<img class="wordmark"') {
        $content = $content -replace '<img class="wordmark"', '<img class="wordmark pivot is-x"'
    }

    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
}

Write-Host "Animation applied to all banners." -ForegroundColor Green
