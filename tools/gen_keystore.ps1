# Genere la cle de signature RELEASE pour le Play Store.
# La cle est creee DANS TON DOSSIER UTILISATEUR (jamais dans le depot Git).
# A executer UNE SEULE FOIS. Conserve precieusement le fichier .keystore + le
# mot de passe : sans eux, tu ne pourras PLUS mettre a jour l'appli sur le Store.
#
# Usage :  pwsh -File tools/gen_keystore.ps1 -Password "TON_MOT_DE_PASSE_FORT"

param(
    [string]$Password = "",
    [string]$Alias = "eclipse",
    [string]$KeystorePath = "$env:USERPROFILE\runaway-release.keystore"
)

if ([string]::IsNullOrWhiteSpace($Password)) {
    Write-Host "ERREUR : fournis un mot de passe, ex :" -ForegroundColor Red
    Write-Host '  pwsh -File tools/gen_keystore.ps1 -Password "MonMotDePasseFort123!"'
    exit 1
}

if (Test-Path $KeystorePath) {
    Write-Host "Un keystore existe deja : $KeystorePath" -ForegroundColor Yellow
    Write-Host "Supprime-le manuellement si tu veux le regenerer (ATTENTION : tu perdrais l'acces aux MAJ Store)."
    exit 1
}

# keytool est fourni par le JDK (JAVA_HOME). On le localise.
$keytool = "keytool"
if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\keytool.exe")) {
    $keytool = "$env:JAVA_HOME\bin\keytool.exe"
}

& $keytool -genkeypair -v `
    -keystore $KeystorePath `
    -alias $Alias `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass $Password -keypass $Password `
    -dname "CN=RUNAWAY, OU=Eclipse, O=Eclipse, L=Meknes, S=Meknes, C=MA"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Echec de keytool. Verifie que le JDK 17 est installe et JAVA_HOME defini." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Keystore cree : $KeystorePath" -ForegroundColor Green
Write-Host ""
Write-Host "Definition des variables d'environnement (persistantes, niveau utilisateur)..."
[Environment]::SetEnvironmentVariable("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", $KeystorePath, "User")
[Environment]::SetEnvironmentVariable("GODOT_ANDROID_KEYSTORE_RELEASE_USER", $Alias, "User")
[Environment]::SetEnvironmentVariable("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", $Password, "User")
Write-Host "Fait. REDEMARRE Godot (et le terminal) pour qu'il lise ces variables." -ForegroundColor Green
Write-Host ""
Write-Host "Godot utilisera automatiquement cette cle pour l'export release (APK/AAB)."
