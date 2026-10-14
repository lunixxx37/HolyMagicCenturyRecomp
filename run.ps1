<#
.SYNOPSIS
  Starts Holy Magic Century: Recompiled from the portable run folder.

      .\run.ps1           # launcher: settings, controls, mods
      .\run.ps1 -Direct   # start the game right away

  Config, saves (the Controller Pak image) and the ROM copy live in run\.
  The first time, run\ needs portable.txt, an assets junction, recompcontrollerdb.txt
  and the ROM as holy_magic_century_eu_en.z64 (see BUILDING.md).
#>
param([switch]$Direct)

$exe = Join-Path $PSScriptRoot 'out\build\workspace-release\HolyMagicCenturyRecompiled.exe'
$run = Join-Path $PSScriptRoot 'run'
if (-not (Test-Path -LiteralPath $exe)) { throw "Build first: $exe not found" }

if ($Direct) {
    Start-Process -FilePath $exe -ArgumentList '--game', 'hmc_en' -WorkingDirectory $run
} else {
    Start-Process -FilePath $exe -WorkingDirectory $run
}
