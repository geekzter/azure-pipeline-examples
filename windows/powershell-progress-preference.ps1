param ( 
    [parameter(Mandatory=$false)][string]$TempDirectory=$([system.io.path]::GetTempPath())
) 

$stopwatch = [system.diagnostics.stopwatch]::StartNew()
for ($i = 1; $i -le 10000; $i++ )
{
  $percentComplete = ($i/100)
  Write-Progress -Activity "Test Progress" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
  Start-Sleep -Milliseconds 1
}
$stopwatch.Elapsed

Invoke-Webrequest -Uri https://speed.hetzner.de/1GB.bin -OutFile (Join-Path $TempDirectory testfile) -UseBasicParsing

$stopwatch.Elapsed