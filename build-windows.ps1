param(
    [string]$BuildDirectory = '',
    [string]$DependencyRoot = '',
    [string]$KangleDirectory = ''
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path $PSScriptRoot -Parent
$kangleSource = Join-Path $workspace 'kangle'
if (!$BuildDirectory) { $BuildDirectory = Join-Path $PSScriptRoot 'build' }
if (!$DependencyRoot) { $DependencyRoot = Join-Path $kangleSource 'deps/windows-x64' }
if (!$KangleDirectory) { $KangleDirectory = Join-Path $kangleSource 'build/install' }
if (!(Test-Path -LiteralPath (Join-Path $KangleDirectory 'include/ksapi.h') -PathType Leaf)) {
    throw "Build Kangle first or pass -KangleDirectory with its SDK path: $KangleDirectory"
}
$KangleDirectory = (Resolve-Path -LiteralPath $KangleDirectory).Path
$DependencyRoot = (Resolve-Path -LiteralPath $DependencyRoot).Path
if (!(Test-Path -LiteralPath (Join-Path $DependencyRoot 'lib/zs.lib') -PathType Leaf)) {
    throw "Missing zlib in Windows x64 SDK: $DependencyRoot"
}

$command = Get-Command cmake.exe -ErrorAction SilentlyContinue
if ($command) {
    $cmake = $command.Source
} else {
    $cmake = 'C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe'
}
if (!(Test-Path -LiteralPath $cmake -PathType Leaf)) {
    throw 'Install Visual Studio 2022 C++ x64 Build Tools, Windows SDK and CMake.'
}

$configure = @(
    '-S', $PSScriptRoot, '-B', $BuildDirectory, '-G', 'Visual Studio 17 2022', '-A', 'x64',
    '-DCMAKE_CONFIGURATION_TYPES=Release', '-DCMAKE_CXX_FLAGS=/utf-8 /EHsc /MP4', "-DZLIB_LIBRARY_RELEASE=$DependencyRoot/lib/zs.lib",
    "-DCMAKE_PREFIX_PATH=$DependencyRoot",
    "-DKANGLE_DIR=$KangleDirectory", "-DKANGLE_SOURCE_DIR=$kangleSource"
)
& $cmake @configure
if ($LASTEXITCODE -ne 0) { throw 'kwaf CMake configuration failed' }
& $cmake --build $BuildDirectory --config Release --target kwaf --parallel
if ($LASTEXITCODE -ne 0) { throw 'kwaf compilation failed' }
Write-Output (Join-Path $BuildDirectory 'Release/kwaf.dll')
