[CmdletBinding(DefaultParameterSetName = "Inline")]
param(
    [Parameter(ParameterSetName = "Inline", Mandatory = $true)]
    [string]$Code,

    [Parameter(ParameterSetName = "File", Mandatory = $true)]
    [string]$CodeFile,

    [string]$ExecutorId,
    [string]$ProjectName = "SwordCultivator",
    [string]$ProjectPath,
    [ValidateSet("editor", "game")]
    [string]$Type = "editor",
    [string]$BaseUrl = "http://localhost:5302"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tokenPath = Join-Path $scriptDir "hastur-operation-plugin\.hastur-auth-token"

if (-not (Test-Path $tokenPath)) {
    throw "Hastur token file not found. Start the broker first with tools/start_hastur_broker.ps1."
}

if ($PSCmdlet.ParameterSetName -eq "File") {
    $Code = Get-Content -LiteralPath $CodeFile -Raw
}

$body = @{
    code = $Code
    type = $Type
}

if ($ExecutorId) {
    $body.executor_id = $ExecutorId
} elseif ($ProjectPath) {
    $body.project_path = $ProjectPath
} else {
    $body.project_name = $ProjectName
}

$token = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
$response = Invoke-RestMethod `
    -Uri "$BaseUrl/api/execute" `
    -Method Post `
    -Headers @{ Authorization = "Bearer $token" } `
    -ContentType "application/json" `
    -Body ($body | ConvertTo-Json -Depth 8)

$response | ConvertTo-Json -Depth 32
