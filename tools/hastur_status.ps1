[CmdletBinding()]
param(
    [string]$BaseUrl = "http://localhost:5302"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tokenPath = Join-Path $scriptDir "hastur-operation-plugin\.hastur-auth-token"

$health = Invoke-RestMethod -Uri "$BaseUrl/api/health" -TimeoutSec 3

if (Test-Path $tokenPath) {
    $token = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
    $executors = Invoke-RestMethod `
        -Uri "$BaseUrl/api/executors" `
        -Headers @{ Authorization = "Bearer $token" } `
        -TimeoutSec 3
} else {
    $executors = @{
        success = $false
        error = "Token file not found: $tokenPath"
    }
}

@{
    health = $health
    executors = $executors
} | ConvertTo-Json -Depth 32
