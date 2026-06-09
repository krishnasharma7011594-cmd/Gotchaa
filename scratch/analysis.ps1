$libDir = "c:\Gotchaa\lib"
$files = Get-ChildItem -Path $libDir -Recurse -Filter *.dart

$setStateCount = 0
$streamBuilderCount = 0
$futureBuilderCount = 0
$hardcodedStrings = @()
$missingDispose = @()
$apiKeys = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $lineNum = 1
    
    $hasAnimationController = $false
    $hasDispose = $false
    $hasTimer = $false
    $hasStreamSubscription = $false
    
    foreach ($line in $content) {
        if ($line -match "setState\(") { $setStateCount++ }
        if ($line -match "StreamBuilder") { $streamBuilderCount++ }
        if ($line -match "FutureBuilder") { $futureBuilderCount++ }
        
        # Hardcoded strings in Text widgets (very naive check)
        if ($line -match "Text\(['`"]([a-zA-Z ]+)['`"]\)") {
            $hardcodedStrings += "$($file.Name):$lineNum - $($matches[1])"
        }
        
        # API Keys
        if ($line -match "api[_-]?key|secret|password") {
            if ($line -notmatch "import|class|String|final|const|widget") {
                $apiKeys += "$($file.Name):$lineNum - $line"
            }
        }
        
        if ($line -match "AnimationController") { $hasAnimationController = $true }
        if ($line -match "Timer\(") { $hasTimer = $true }
        if ($line -match "StreamSubscription") { $hasStreamSubscription = $true }
        if ($line -match "void dispose\(\)") { $hasDispose = $true }
        
        $lineNum++
    }
    
    if (($hasAnimationController -or $hasTimer -or $hasStreamSubscription) -and -not $hasDispose) {
        $missingDispose += $file.Name
    }
}

Write-Output "setState count: $setStateCount"
Write-Output "StreamBuilder count: $streamBuilderCount"
Write-Output "FutureBuilder count: $futureBuilderCount"
Write-Output "Missing dispose: $($missingDispose.Count)"
Write-Output "Hardcoded strings sample: $($hardcodedStrings[0..5] -join ', ')"
Write-Output "API Keys sample: $($apiKeys[0..5] -join ', ')"
