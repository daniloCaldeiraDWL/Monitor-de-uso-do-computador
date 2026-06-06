# RegistrarEvento.ps1
# Chamado pelo Agendador de Tarefas com -Tipo ATIVACAO ou INATIVACAO
# Roda completamente em segundo plano, sem janela.

param(
    [Parameter(Mandatory)]
    [ValidateSet("ATIVACAO","INATIVACAO")]
    [string]$Tipo
)

# ---------------------------------------------------------------------------
# Caminhos
# ---------------------------------------------------------------------------
$raiz    = Split-Path $PSScriptRoot -Parent
$cfgFile = Join-Path $raiz "config.ini"

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
$cfg = @{ NomeArquivo = "registro"; PastaRelatorios = "relatorios" }

if (Test-Path $cfgFile) {
    Get-Content $cfgFile -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^\s*([^#=]+?)\s*=\s*(.+?)\s*$') {
            $cfg[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

$pasta = $cfg.PastaRelatorios
if (-not [IO.Path]::IsPathRooted($pasta)) { $pasta = Join-Path $raiz $pasta }
if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Path $pasta -Force | Out-Null }

$logPath    = Join-Path $pasta "$($cfg.NomeArquivo).log"
$alertaPath = Join-Path $raiz "queda_energia.log"

# ---------------------------------------------------------------------------
# Funcoes de I/O — append com FileShare.ReadWrite
# Funciona mesmo com o arquivo aberto em qualquer editor
# ---------------------------------------------------------------------------
function Append-Linha {
    param([string]$Arquivo, [string]$Linha)
    $fs = [IO.File]::Open(
        $Arquivo,
        [IO.FileMode]::Append,
        [IO.FileAccess]::Write,
        [IO.FileShare]::ReadWrite
    )
    $sw = New-Object IO.StreamWriter($fs, [Text.Encoding]::UTF8)
    try   { $sw.WriteLine($Linha) }
    finally { $sw.Flush(); $sw.Close(); $fs.Close() }
}

function Ler-UltimaLinha {
    param([string]$Arquivo)
    if (-not (Test-Path $Arquivo)) { return $null }
    $fs  = [IO.File]::Open($Arquivo,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    $sr  = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
    $txt = $sr.ReadToEnd()
    $sr.Close(); $fs.Close()
    $linhas = $txt -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    return $linhas | Select-Object -Last 1
}

# ---------------------------------------------------------------------------
# Logica principal
# ---------------------------------------------------------------------------
$agora = Get-Date
$data  = $agora.ToString("dd/MM/yyyy")
$hora  = $agora.ToString("HH:mm:ss")

# Le o ultimo registro para detectar inconsistencia
$ultima = Ler-UltimaLinha -Arquivo $logPath

$motivo = if ($Tipo -eq "ATIVACAO") { "Desbloqueio" } else { "Bloqueio" }

if ($ultima -ne $null) {
    # Formato da linha: "dd/MM/yyyy HH:mm:ss | ATIVACAO | Desbloqueio"
    $partes     = $ultima -split "\|"
    $ultimoTipo = if ($partes.Count -ge 2) { $partes[1].Trim() } else { "" }

    if ($ultimoTipo -eq $Tipo) {
        # Dois eventos iguais em sequencia — houve interrupcao nao registrada
        if ($Tipo -eq "ATIVACAO") {
            # Faltou INATIVACAO -> queda de energia ou desligamento forcado
            # Recupera timestamp da ultima ativacao para a linha retroativa
            $tsUltima = if ($partes.Count -ge 1) { $partes[0].Trim() } else { $data + " " + $hora }
            Append-Linha -Arquivo $logPath  -Linha "$tsUltima | INATIVACAO | Queda de Energia (inferida)"
            Append-Linha -Arquivo $alertaPath -Linha "[$data $hora] Queda de energia detectada. Ultima ativacao: $tsUltima. INATIVACAO retroativa inserida."
            $motivo = "Retomada apos Queda de Energia"
        }
        else {
            # Dupla INATIVACAO — raro, registra alerta mas continua
            Append-Linha -Arquivo $alertaPath -Linha "[$data $hora] Aviso: dupla INATIVACAO detectada. Verifique os gatilhos."
        }
    }
}

Append-Linha -Arquivo $logPath -Linha "$data $hora | $Tipo | $motivo"
