# GerarRelatorio.ps1
# Calcula tempo ativo por dia e exibe resumo.

param(
    [string]$ConfigPath = "$PSScriptRoot\..\config.ini"
)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$raiz = Split-Path $ConfigPath -Parent
$cfg  = @{ NomeArquivo = "registro"; PastaRelatorios = "relatorios" }

if (Test-Path $ConfigPath) {
    Get-Content $ConfigPath -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^\s*([^#=]+?)\s*=\s*(.+?)\s*$') {
            $cfg[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

$pasta = $cfg.PastaRelatorios
if (-not [IO.Path]::IsPathRooted($pasta)) { $pasta = Join-Path $raiz $pasta }

$logPath    = Join-Path $pasta "$($cfg.NomeArquivo).log"
$alertaPath = Join-Path $raiz "queda_energia.log"

# ---------------------------------------------------------------------------
# Leitura thread-safe
# ---------------------------------------------------------------------------
if (-not (Test-Path $logPath)) {
    Write-Host ""
    Write-Host "[ERRO] Arquivo nao encontrado: $logPath" -ForegroundColor Red
    Write-Host "       Instale o monitor e aguarde o primeiro evento ser registrado." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para fechar"
    exit 1
}

$fs  = [IO.File]::Open($logPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
$sr  = New-Object IO.StreamReader($fs,[Text.Encoding]::UTF8)
$txt = $sr.ReadToEnd()
$sr.Close(); $fs.Close()

# ---------------------------------------------------------------------------
# Parse das linhas
# ---------------------------------------------------------------------------
$registros = $txt -split "`r?`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
    $p = $_ -split "\|"
    if ($p.Count -ge 3) {
        $ts = $p[0].Trim()
        try {
            $dt = [datetime]::ParseExact($ts,"dd/MM/yyyy HH:mm:ss",$null)
            [PSCustomObject]@{
                DateTime  = $dt
                Data      = $dt.ToString("dd/MM/yyyy")
                Hora      = $dt.ToString("HH:mm:ss")
                Tipo      = $p[1].Trim()
                Motivo    = $p[2].Trim()
            }
        } catch { $null }
    }
} | Where-Object { $_ -ne $null }

# ---------------------------------------------------------------------------
# Calculo por dia
# ---------------------------------------------------------------------------
$porDia     = $registros | Group-Object -Property Data
$resultados = foreach ($g in $porDia) {
    $evs    = $g.Group | Sort-Object DateTime
    $ativo  = [TimeSpan]::Zero
    $inicio = $null

    foreach ($ev in $evs) {
        if ($ev.Tipo -eq "ATIVACAO")   { $inicio = $ev.DateTime }
        elseif ($ev.Tipo -eq "INATIVACAO" -and $null -ne $inicio) {
            $ativo += ($ev.DateTime - $inicio)
            $inicio = $null
        }
    }

    $diaSemana = (Get-Culture).DateTimeFormat.GetDayName(
        ([datetime]::ParseExact($g.Name,"dd/MM/yyyy",$null)).DayOfWeek
    )

    [PSCustomObject]@{
        Data       = $g.Name
        DiaSemana  = $diaSemana
        TempoAtivo = $ativo
        Formatado  = "{0}h {1:D2}min" -f [int]$ativo.TotalHours, $ativo.Minutes
        Eventos    = $g.Group.Count
    }
}

# ---------------------------------------------------------------------------
# Exibicao
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Monitor de Uso  --  Relatorio"               -ForegroundColor Cyan
Write-Host "   Gerado: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host ("{0,-13} {1,-14} {2,-12} {3}" -f "Data","Dia","Tempo Ativo","Eventos") -ForegroundColor White
Write-Host ("{0,-13} {1,-14} {2,-12} {3}" -f "----","---","-----------","-------") -ForegroundColor DarkGray

$resultados | Sort-Object Data | ForEach-Object {
    Write-Host ("{0,-13} {1,-14} {2,-12} {3}" -f $_.Data, $_.DiaSemana, $_.Formatado, $_.Eventos)
}

$total = [TimeSpan]::Zero
$resultados | ForEach-Object { $total += $_.TempoAtivo }
$media = if ($resultados.Count -gt 0) {
    [TimeSpan]::FromTicks([long]($total.Ticks / $resultados.Count))
} else { [TimeSpan]::Zero }

Write-Host ""
Write-Host ("Total : {0}h {1:D2}min  |  Media diaria: {2}h {3:D2}min  |  {4} dias" -f `
    [int]$total.TotalHours, $total.Minutes,
    [int]$media.TotalHours, $media.Minutes,
    $resultados.Count) -ForegroundColor Green

if (Test-Path $alertaPath) {
    Write-Host ""
    Write-Host "[!] Alertas de queda de energia registrados em: queda_energia.log" -ForegroundColor Yellow
}

# Salva resumo TXT
$resumoPath = Join-Path $pasta "$($cfg.NomeArquivo)_resumo.txt"
$linhas = @(
    "================================================"
    "   Monitor de Uso  --  Relatorio"
    "   Gerado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    "================================================"
    ""
    ("{0,-13} {1,-14} {2,-12} {3}" -f "Data","Dia","Tempo Ativo","Eventos")
    ("{0,-13} {1,-14} {2,-12} {3}" -f "----","---","-----------","-------")
)
$resultados | Sort-Object Data | ForEach-Object {
    $linhas += "{0,-13} {1,-14} {2,-12} {3}" -f $_.Data,$_.DiaSemana,$_.Formatado,$_.Eventos
}
$linhas += ""
$linhas += "Total : {0}h {1:D2}min  |  Media diaria: {2}h {3:D2}min  |  {4} dias" -f `
    [int]$total.TotalHours,$total.Minutes,[int]$media.TotalHours,$media.Minutes,$resultados.Count

$linhas | Set-Content -Path $resumoPath -Encoding UTF8
Write-Host ""
Write-Host "Resumo salvo em: $resumoPath" -ForegroundColor DarkCyan
Write-Host ""
Read-Host "Pressione Enter para fechar"
