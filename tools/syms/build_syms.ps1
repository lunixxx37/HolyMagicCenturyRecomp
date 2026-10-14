<#
.SYNOPSIS
  Rebuilds HolyMagicCenturyRecompSyms\hmc.<version>.syms.toml from the US function list of
  Rainchus/Quest64Syms.

      .\tools\syms\build_syms.ps1 [-Version en|de] [-Rom <rom>] [-Quest64Syms <dump.toml>] [-N64Sym <n64sym.exe>]

  Needs Python with recomp-toolkit installed and n64sym. Without parameters, the paths of the
  author's workspace are used (set by its devshell.ps1 through RECOMP_WORKSPACE).

  Steps: RAM image of the main segment -> n64sym libultra signatures -> port the US function list
  (recomp_toolkit.port_funcs) -> refine it with the signatures, call targets and overrides.<version>.toml
  (recomp_toolkit.refine_funcs). Reports and intermediate files go to tools\syms\out.
#>
param(
    [ValidateSet('en', 'de')][string]$Version = 'en',
    [string]$Rom,
    [string]$Quest64Syms,
    [string]$N64Sym
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ws = $env:RECOMP_WORKSPACE
if (-not $Rom) {
    $Rom = @{ en = "$ws\_roms\Holy Magic Century (Europe).n64"; de = "$ws\_roms\Holy Magic Century (Germany).n64" }[$Version]
}
if (-not $Quest64Syms) { $Quest64Syms = "$ws\_refs\Quest64Syms\dump.toml" }
if (-not $N64Sym) { $N64Sym = "$ws\_tools\n64sym\n64sym.exe" }
foreach ($path in @($Rom, $Quest64Syms, $N64Sym)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Not found: $path (pass it as a parameter)" }
}

# Size of the main segment (code + data up to BSS), read from each build's entry code.
$mainSize = @{ en = 0x731E0; de = 0x73580 }[$Version]
$symbolLists = "$repo\lib\N64ModernRuntime\N64Recomp\src\symbol_lists.cpp"
$out = Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Invoke-Step([string]$what, [scriptblock]$cmd) {
    & $cmd
    if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE)" }
}

Push-Location $PSScriptRoot
try {
    Invoke-Step 'ram_image' { python -I -m recomp_toolkit.ram_image $Rom "$out\ram.$Version.bin" --rom 0x1000 --vram 0x80000400 --size ('0x{0:X}' -f (0x50 + $mainSize)) }
    Invoke-Step 'n64sym' { & $N64Sym "$out\ram.$Version.bin" -s -f default -o "$out\n64sym.$Version.txt" | Out-Null }
    Invoke-Step 'port_funcs' {
        python -I -m recomp_toolkit.port_funcs $Quest64Syms $Rom "layout.$Version.toml" `
            -o "$out\ported.$Version.syms.toml" --map "$out\map.$Version.csv" --report "$out\report.$Version.txt" | Out-Null
    }
    Invoke-Step 'refine_funcs' {
        python -I -m recomp_toolkit.refine_funcs "$out\map.$Version.csv" $Rom "layout.$Version.toml" `
            --anchors "$out\n64sym.$Version.txt" --canonical $symbolLists --overrides "overrides.$Version.toml" `
            -o "$repo\HolyMagicCenturyRecompSyms\hmc.$Version.syms.toml" --map "$out\final.$Version.csv" --report "$out\refine.$Version.txt" `
            --comment "Holy Magic Century ($Version) function syms, ported from Rainchus/Quest64Syms (US) by recomp-toolkit (tools/syms/build_syms.ps1)." | Out-Null
    }
    "wrote $repo\HolyMagicCenturyRecompSyms\hmc.$Version.syms.toml (report: $out\refine.$Version.txt)"
} finally {
    Pop-Location
}
