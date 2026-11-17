# Encontra o executável do Godot (modo console). Usado pelos outros scripts.
# Ordem: variável GODOT_BIN, comando no PATH, instalação do winget.
function Get-GodotExe {
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) { return $env:GODOT_BIN }
    foreach ($name in 'godot_console', 'godot') {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    if ($env:LOCALAPPDATA) {
        $exe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "Godot_v4*_win64_console.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if ($exe) { return $exe }
    }
    return $null
}
