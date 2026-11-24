# Prépare la machine pour le dojo et lance Claude Code.
# Relançable sans risque : chaque étape déjà faite est sautée.
# Compatible Windows PowerShell 5.1 (le PowerShell livré avec Windows).
# Ce fichier doit rester en UTF-8 avec BOM, sinon PowerShell 5.1 abîme les accents.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $PSScriptRoot

function Ok($message) { Write-Host "  OK  $message" -ForegroundColor Green }
function Etape($message) { Write-Host ""; Write-Host "-> $message" -ForegroundColor Cyan }
function Erreur($message) {
  Write-Host ""
  Write-Host "  ERREUR  $message" -ForegroundColor Red
  Write-Host "Lève la main, on vient t'aider."
  exit 1
}
function Existe($commande) { [bool](Get-Command $commande -ErrorAction SilentlyContinue) }

function Recharger-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User')
}

# Ajoute un dossier au PATH de l'utilisateur, pour cette session et les prochaines.
function Ajouter-Au-Path($dossier) {
  $pathUtilisateur = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $pathUtilisateur) { $pathUtilisateur = '' }
  if (-not (($pathUtilisateur -split ';') -contains $dossier)) {
    [Environment]::SetEnvironmentVariable('Path', (($pathUtilisateur.TrimEnd(';') + ';' + $dossier).TrimStart(';')), 'User')
  }
  Recharger-Path
}

# Lance un script d'installation officiel dans un PowerShell séparé, pour qu'il ne puisse pas
# arrêter celui-ci.
function Installer-Depuis($url) {
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm $url | iex" | Out-Null
}

Write-Host "Installation du dojo. Ça prend quelques minutes, ne ferme pas cette fenêtre."

Etape "Git"
Recharger-Path
if (Existe git) {
  Ok "déjà installé"
} else {
  if (-not (Existe winget)) {
    Erreur "winget est introuvable. Installe Git depuis https://git-scm.com/downloads/win puis relance."
  }
  Write-Host "Windows va peut-être demander une autorisation : clique sur « Oui »."
  winget install --id Git.Git --exact --source winget --silent --accept-package-agreements --accept-source-agreements | Out-Null
  Recharger-Path
  if (-not (Existe git)) { Erreur "L'installation de Git a échoué." }
  Ok "installé"
}

Etape "Bun"
$bunBin = Join-Path $HOME '.bun\bin'
if (Test-Path $bunBin) { $env:Path = "$bunBin;$env:Path" }
if (Existe bun) {
  Ok "déjà installé ($(bun --version))"
} else {
  Installer-Depuis 'https://bun.sh/install.ps1'
  Ajouter-Au-Path $bunBin
  if (-not (Existe bun)) { Erreur "L'installation de Bun a échoué." }
  Ok "installé ($(bun --version))"
}

Etape "Claude Code"
$localBin = Join-Path $HOME '.local\bin'
if (Test-Path $localBin) { $env:Path = "$localBin;$env:Path" }
if (Existe claude) {
  Ok "déjà installé"
} else {
  Write-Host "Téléchargement en cours, sans barre de progression : patiente."
  Installer-Depuis 'https://claude.ai/install.ps1'
  Ajouter-Au-Path $localBin
  if (-not (Existe claude)) { Erreur "L'installation de Claude Code a échoué." }
  Ok "installé"
}

Etape "Clé OpenRouter"
$reglages = Join-Path $PSScriptRoot '.claude\settings.local.json'

function Cle-Valide($cle) {
  try {
    Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/key' -Headers @{ Authorization = "Bearer $cle" } | Out-Null
    return $true
  } catch {
    return $false
  }
}

$cleExistante = $null
if (Test-Path $reglages) {
  try { $cleExistante = (Get-Content $reglages -Raw | ConvertFrom-Json).env.ANTHROPIC_AUTH_TOKEN } catch { }
}
if ($cleExistante -and (Cle-Valide $cleExistante)) {
  Ok "déjà configurée"
} else {
  $cle = ''
  if (Test-Path .env) {
    $ligne = Get-Content .env | Where-Object { $_ -match '^OPENROUTER_API_KEY=' } | Select-Object -First 1
    if ($ligne) {
      $cle = ($ligne -replace '^OPENROUTER_API_KEY=', '') -replace '["''\s]', ''
      Write-Host "Clé lue dans le fichier .env"
    }
  }
  while ($true) {
    if (-not $cle) {
      $saisie = Read-Host "Colle ta clé OpenRouter (clic droit pour coller, elle ne s'affiche pas) puis appuie sur Entrée" -AsSecureString
      $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($saisie)
      $cle = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) -replace '\s', ''
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    if ($cle -notmatch '^sk-or-[A-Za-z0-9_-]+$') {
      Write-Host "Ça ne ressemble pas à une clé OpenRouter (elle commence par sk-or-). Réessaie."
    } elseif (Cle-Valide $cle) {
      Ok "clé valide"
      break
    } else {
      Write-Host "OpenRouter refuse cette clé. Vérifie-la et réessaie."
    }
    $cle = ''
  }
  $json = "{`n  `"env`": {`n    `"ANTHROPIC_AUTH_TOKEN`": `"$cle`"`n  }`n}`n"
  # UTF-8 sans BOM : Claude Code ne lit pas un JSON qui commence par un BOM.
  [IO.File]::WriteAllText($reglages, $json, (New-Object Text.UTF8Encoding $false))
  Ok "clé enregistrée"
}

Etape "Dépôt git"
if (-not (Test-Path .git)) { git init -q }
if (-not (git config user.name)) {
  git config user.name "Eleve du dojo"
  git config user.email "eleve@dojo.local"
}
git rev-parse --verify -q HEAD | Out-Null
if ($LASTEXITCODE -ne 0) {
  git add -A
  git commit -qm "Point de départ du dojo"
}
Ok "prêt"

Write-Host ""
Write-Host "Tout est prêt ! Pour relancer Claude Code plus tard : double-clique sur installer.cmd." -ForegroundColor Green
Write-Host ""
claude
