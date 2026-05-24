param(
    [string]$MainSheet = "resources/flight/rider/flight_rider_body_v10_sheet.png",
    [string]$TransitionSheet = "",
    [string]$TransitionDir = "resources/flight/rider/body_v9_transitions",
    [switch]$SkipTransitions,
    [int]$AlphaThreshold = 16
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CellWidth = 256
$CellHeight = 256
$AnchorY = 219
$AnchorTolerance = 2

$V9Actions = @(
    @{ Name = "idle"; MinHeight = 166; MaxHeight = 170 },
    @{ Name = "forward"; MinHeight = 145; MaxHeight = 155 },
    @{ Name = "back"; MinHeight = 150; MaxHeight = 160 },
    @{ Name = "parry"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "unsheath"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_release"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_morph"; MinHeight = 158; MaxHeight = 172 }
)

$V10Actions = @(
    @{ Name = "idle"; MinHeight = 166; MaxHeight = 170 },
    @{ Name = "forward"; MinHeight = 145; MaxHeight = 155 },
    @{ Name = "back"; MinHeight = 150; MaxHeight = 160 },
    @{ Name = "parry"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "sword_control_idle"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_ring_idle"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_fan_idle"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_pierce_idle"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_ring_release"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_fan_release"; MinHeight = 158; MaxHeight = 172 },
    @{ Name = "array_pierce_release"; MinHeight = 158; MaxHeight = 172 }
)

$ExpectedV9Transitions = @(
    "idle_to_forward",
    "forward_to_idle",
    "idle_to_back",
    "back_to_idle",
    "forward_to_back",
    "back_to_forward",
    "idle_to_parry",
    "parry_to_idle",
    "idle_to_unsheath",
    "unsheath_to_idle",
    "idle_to_array_morph",
    "array_morph_to_idle",
    "array_morph_to_array_release",
    "array_release_to_array_morph",
    "array_release_to_idle"
)

$ExpectedV10Transitions = @(
    "idle_to_sword_control",
    "sword_control_to_idle",
    "idle_to_array_ring",
    "array_ring_to_idle",
    "idle_to_array_fan",
    "array_fan_to_idle",
    "idle_to_array_pierce",
    "array_pierce_to_idle",
    "array_ring_to_fan",
    "array_fan_to_ring",
    "array_fan_to_pierce",
    "array_pierce_to_fan",
    "array_pierce_to_ring",
    "array_ring_to_pierce"
)

$mainSheetName = [System.IO.Path]::GetFileName($MainSheet)
$isV13BodyAtlas = $mainSheetName.Contains("_v13_")
$FrameCount = if ($isV13BodyAtlas) { 16 } else { 8 }
$isExpandedBodyAtlas = $mainSheetName.Contains("_v10_") -or $mainSheetName.Contains("_v11_") -or $mainSheetName.Contains("_v12_") -or $isV13BodyAtlas
$Actions = if ($isExpandedBodyAtlas) { $V10Actions } else { $V9Actions }
$ExpectedTransitions = if ($isExpandedBodyAtlas) { $ExpectedV10Transitions } else { $ExpectedV9Transitions }
if (-not $PSBoundParameters.ContainsKey("TransitionSheet") -and $isExpandedBodyAtlas) {
    $TransitionSheet = $MainSheet -replace "_sheet\.png$", "_transitions.png"
}

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Resolve-AssetPath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }
    return (Join-Path (Get-Location) $Path)
}

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message) | Out-Null
    Write-Host "FAIL $Message" -ForegroundColor Red
}

function Add-Warning {
    param([string]$Message)
    $script:warnings.Add($Message) | Out-Null
    Write-Host "WARN $Message" -ForegroundColor Yellow
}

function Get-FrameBounds {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$OriginX,
        [int]$OriginY,
        [int]$Width,
        [int]$Height,
        [int]$Threshold
    )

    $minX = $Width
    $minY = $Height
    $maxX = -1
    $maxY = -1
    $count = 0

    for ($y = 0; $y -lt $Height; $y++) {
        for ($x = 0; $x -lt $Width; $x++) {
            $pixel = $Bitmap.GetPixel($OriginX + $x, $OriginY + $y)
            if ($pixel.A -gt $Threshold) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
                $count++
            }
        }
    }

    if ($count -eq 0) {
        return [pscustomobject]@{
            Empty = $true
            MinX = 0
            MinY = 0
            MaxX = -1
            MaxY = -1
            Width = 0
            Height = 0
            CenterX = 0.0
            CenterY = 0.0
            PixelCount = 0
        }
    }

    return [pscustomobject]@{
        Empty = $false
        MinX = $minX
        MinY = $minY
        MaxX = $maxX
        MaxY = $maxY
        Width = $maxX - $minX + 1
        Height = $maxY - $minY + 1
        CenterX = ($minX + $maxX) / 2.0
        CenterY = ($minY + $maxY) / 2.0
        PixelCount = $count
    }
}

function Test-RowsIdentical {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$RowA,
        [int]$RowB
    )

    $originA = $RowA * $CellHeight
    $originB = $RowB * $CellHeight
    for ($y = 0; $y -lt $CellHeight; $y++) {
        for ($x = 0; $x -lt ($CellWidth * $FrameCount); $x++) {
            $a = $Bitmap.GetPixel($x, $originA + $y)
            $b = $Bitmap.GetPixel($x, $originB + $y)
            if ($a.A -ne $b.A -or $a.R -ne $b.R -or $a.G -ne $b.G -or $a.B -ne $b.B) {
                return $false
            }
        }
    }
    return $true
}

function Assert-FrameAnchor {
    param(
        [string]$Label,
        [pscustomobject]$Bounds
    )

    if ($Bounds.Empty) {
        Add-Failure "$Label is empty."
        return
    }
    $bottomDelta = [Math]::Abs($Bounds.MaxY - $AnchorY)
    if ($bottomDelta -gt $AnchorTolerance) {
        Add-Failure "$Label bottom y=$($Bounds.MaxY), expected $AnchorY +/- $AnchorTolerance."
    }
}

function Test-MainSheet {
    param([string]$Path)

    $resolved = Resolve-AssetPath $Path
    if (-not (Test-Path -LiteralPath $resolved)) {
        Add-Failure "Main sheet not found: $Path"
        return $null
    }

    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::FromFile($resolved)
    $metricsByAction = @{}

    try {
        $expectedWidth = $CellWidth * $FrameCount
        $expectedHeight = $CellHeight * $Actions.Count
        if ($bitmap.Width -ne $expectedWidth -or $bitmap.Height -ne $expectedHeight) {
            Add-Failure "Main sheet size is $($bitmap.Width)x$($bitmap.Height), expected ${expectedWidth}x${expectedHeight}."
            return $metricsByAction
        }

        Write-Host "Main sheet: $Path ($($bitmap.Width)x$($bitmap.Height))" -ForegroundColor Cyan

        for ($row = 0; $row -lt $Actions.Count; $row++) {
            $action = $Actions[$row]
            $name = [string]$action.Name
            $rowMetrics = New-Object System.Collections.Generic.List[object]
            $heights = New-Object System.Collections.Generic.List[int]

            for ($frame = 0; $frame -lt $FrameCount; $frame++) {
                $bounds = Get-FrameBounds -Bitmap $bitmap -OriginX ($frame * $CellWidth) -OriginY ($row * $CellHeight) -Width $CellWidth -Height $CellHeight -Threshold $AlphaThreshold
                $rowMetrics.Add($bounds) | Out-Null
                Assert-FrameAnchor "$name frame $frame" $bounds
                if (-not $bounds.Empty) {
                    $heights.Add([int]$bounds.Height) | Out-Null
                    if ($bounds.Height -lt [int]$action.MinHeight -or $bounds.Height -gt [int]$action.MaxHeight) {
                        Add-Failure "$name frame $frame height=$($bounds.Height), expected $($action.MinHeight)-$($action.MaxHeight)."
                    }
                }
            }

            if ($heights.Count -gt 0) {
                $minHeight = ($heights | Measure-Object -Minimum).Minimum
                $maxHeight = ($heights | Measure-Object -Maximum).Maximum
                if (($maxHeight - $minHeight) -gt 3) {
                    Add-Warning "$name row height range is $minHeight-$maxHeight; target row variation is <= 3px."
                }
                Write-Host ("{0,-14} height {1}-{2}" -f $name, $minHeight, $maxHeight)
            }
            $metricsByAction[$name] = $rowMetrics
        }

        if (-not $isExpandedBodyAtlas -and (Test-RowsIdentical -Bitmap $bitmap -RowA 5 -RowB 6)) {
            Add-Failure "array_release row and array_morph row are pixel-identical."
        }
        if ($isExpandedBodyAtlas) {
            if (Test-RowsIdentical -Bitmap $bitmap -RowA 5 -RowB 6) {
                Add-Failure "array_ring_idle row and array_fan_idle row are pixel-identical."
            }
            if (Test-RowsIdentical -Bitmap $bitmap -RowA 6 -RowB 7) {
                Add-Failure "array_fan_idle row and array_pierce_idle row are pixel-identical."
            }
        }
    }
    finally {
        $bitmap.Dispose()
    }

    return $metricsByAction
}

function Split-TransitionName {
    param([string]$Name)

    $parts = $Name -split "_to_"
    if ($parts.Count -ne 2) {
        return $null
    }
    return [pscustomobject]@{
        Source = $parts[0]
        Target = $parts[1]
    }
}

function Test-TransitionSheet {
    param(
        [string]$Path,
        [string]$TransitionName,
        [hashtable]$MainMetrics
    )

    $resolved = Resolve-AssetPath $Path
    if (-not (Test-Path -LiteralPath $resolved)) {
        Add-Failure "Transition sheet not found: $Path"
        return
    }

    $bitmap = [System.Drawing.Bitmap]::FromFile($resolved)
    try {
        $expectedWidth = $CellWidth * $FrameCount
        if ($bitmap.Width -ne $expectedWidth -or $bitmap.Height -ne $CellHeight) {
            Add-Failure "$TransitionName size is $($bitmap.Width)x$($bitmap.Height), expected ${expectedWidth}x${CellHeight}."
            return
        }

        $transitionMetrics = New-Object System.Collections.Generic.List[object]
        $heights = New-Object System.Collections.Generic.List[int]
        for ($frame = 0; $frame -lt $FrameCount; $frame++) {
            $bounds = Get-FrameBounds -Bitmap $bitmap -OriginX ($frame * $CellWidth) -OriginY 0 -Width $CellWidth -Height $CellHeight -Threshold $AlphaThreshold
            $transitionMetrics.Add($bounds) | Out-Null
            Assert-FrameAnchor "$TransitionName frame $frame" $bounds
            if (-not $bounds.Empty) {
                $heights.Add([int]$bounds.Height) | Out-Null
                if ($bounds.Height -lt 130 -or $bounds.Height -gt 172) {
                    Add-Warning "$TransitionName frame $frame height=$($bounds.Height); expected broad transition range 130-172."
                }
            }
        }

        if ($heights.Count -gt 0) {
            $minHeight = ($heights | Measure-Object -Minimum).Minimum
            $maxHeight = ($heights | Measure-Object -Maximum).Maximum
            Write-Host ("{0,-40} height {1}-{2}" -f $TransitionName, $minHeight, $maxHeight)
        }

        $split = Split-TransitionName $TransitionName
        if ($null -ne $split -and $null -ne $MainMetrics) {
            if ($MainMetrics.ContainsKey($split.Source) -and $MainMetrics.ContainsKey($split.Target)) {
                $sourceFrame = $MainMetrics[$split.Source][0]
                $targetFrame = $MainMetrics[$split.Target][0]
                $first = $transitionMetrics[0]
                $last = $transitionMetrics[$FrameCount - 1]
                if (-not $first.Empty -and -not $sourceFrame.Empty) {
                    if ([Math]::Abs($first.Height - $sourceFrame.Height) -gt 12 -or [Math]::Abs($first.CenterX - $sourceFrame.CenterX) -gt 14) {
                        Add-Warning "$TransitionName first frame bbox differs strongly from $($split.Source) frame 0; visually inspect the entry."
                    }
                }
                if (-not $last.Empty -and -not $targetFrame.Empty) {
                    if ([Math]::Abs($last.Height - $targetFrame.Height) -gt 12 -or [Math]::Abs($last.CenterX - $targetFrame.CenterX) -gt 14) {
                        Add-Warning "$TransitionName last frame bbox differs strongly from $($split.Target) frame 0; visually inspect the exit."
                    }
                }
            }
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

function Test-TransitionAtlas {
    param(
        [string]$Path,
        [array]$TransitionNames
    )

    $resolved = Resolve-AssetPath $Path
    if (-not (Test-Path -LiteralPath $resolved)) {
        Add-Failure "Transition atlas not found: $Path"
        return
    }

    $bitmap = [System.Drawing.Bitmap]::FromFile($resolved)
    try {
        $expectedWidth = $CellWidth * $FrameCount
        $expectedHeight = $CellHeight * $TransitionNames.Count
        if ($bitmap.Width -ne $expectedWidth -or $bitmap.Height -ne $expectedHeight) {
            Add-Failure "Transition atlas size is $($bitmap.Width)x$($bitmap.Height), expected ${expectedWidth}x${expectedHeight}."
            return
        }

        Write-Host "Transition atlas: $Path ($($bitmap.Width)x$($bitmap.Height))" -ForegroundColor Cyan

        for ($row = 0; $row -lt $TransitionNames.Count; $row++) {
            $transitionName = [string]$TransitionNames[$row]
            $heights = New-Object System.Collections.Generic.List[int]
            for ($frame = 0; $frame -lt $FrameCount; $frame++) {
                $bounds = Get-FrameBounds -Bitmap $bitmap -OriginX ($frame * $CellWidth) -OriginY ($row * $CellHeight) -Width $CellWidth -Height $CellHeight -Threshold $AlphaThreshold
                Assert-FrameAnchor "$transitionName frame $frame" $bounds
                if (-not $bounds.Empty) {
                    $heights.Add([int]$bounds.Height) | Out-Null
                    if ($bounds.Height -lt 130 -or $bounds.Height -gt 172) {
                        Add-Warning "$transitionName frame $frame height=$($bounds.Height); expected broad transition range 130-172."
                    }
                }
            }
            if ($heights.Count -gt 0) {
                $minHeight = ($heights | Measure-Object -Minimum).Minimum
                $maxHeight = ($heights | Measure-Object -Maximum).Maximum
                Write-Host ("{0,-32} height {1}-{2}" -f $transitionName, $minHeight, $maxHeight)
            }
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

$mainMetrics = Test-MainSheet -Path $MainSheet

if (-not $SkipTransitions) {
    if ($TransitionSheet -ne "") {
        Test-TransitionAtlas -Path $TransitionSheet -TransitionNames $ExpectedTransitions
    }
    else {
        $transitionRoot = Resolve-AssetPath $TransitionDir
        if (-not (Test-Path -LiteralPath $transitionRoot)) {
            Add-Failure "Transition directory not found: $TransitionDir"
        }
        else {
            foreach ($transition in $ExpectedTransitions) {
                $fileName = "body_v9_transition_${transition}_8.png"
                $path = Join-Path $transitionRoot $fileName
                Test-TransitionSheet -Path $path -TransitionName $transition -MainMetrics $mainMetrics
            }
        }
    }
}

Write-Host ""
Write-Host "Validation summary: $($failures.Count) failure(s), $($warnings.Count) warning(s)."

if ($failures.Count -gt 0) {
    exit 1
}

exit 0
