# Builds, packs, and signs the Windows MSIX package.
#
# Why this script exists rather than just `dart run msix:create`: the `msix`
# package's own bundled MakeAppx.exe/signtool.exe (under
# <pub-cache>/msix-<version>/lib/assets/MSIX-Toolkit/Redist.x64) fail on this
# machine with "Diese Anwendung konnte nicht gestartet werden, da die
# Side-by-Side-Konfiguration ungueltig ist" - confirmed via the Windows
# Application event log (SideBySide source) to be a genuine, pre-existing
# assembly-identity mismatch in that bundled toolkit
# (Microsoft.Windows.Build.Appx.AppxPackaging.dll's embedded manifest
# requests version 0.0.0.0 in a way the bundled sidecar manifest can't
# satisfy), not something introduced by this project or fixable by swapping
# in newer binaries side-by-side (tried; made no difference - the identity
# resolution itself is what's broken for that specific bundle). The Windows
# SDK's own copies of the same tools (installed alongside the Visual Studio
# Build Tools this project already needs for `flutter build windows`) work
# correctly, so this script uses `dart run msix:build` (lays out the
# manifest/assets/payload only - no packing) and then packs/signs with the
# SDK tools directly.
#
# Run from the project root: powershell -ExecutionPolicy Bypass -File windows\build_msix.ps1
#
# First-time setup on a new machine: after this script runs once, trust the
# generated test certificate machine-wide (needs an elevated/Administrator
# PowerShell - this script does not attempt to self-elevate):
#   certutil -addstore Root build\windows\x64\runner\Release\test_cert.cer
# Without that, `Add-AppxPackage` fails with HRESULT 0x800B0109 ("the root
# certificate of the signature ... must be trusted").

$ErrorActionPreference = "Stop"

$sdkVersion = (Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Directory |
    Where-Object { $_.Name -match '^10\.' } | Sort-Object Name -Descending | Select-Object -First 1).Name
$sdk = "C:\Program Files (x86)\Windows Kits\10\bin\$sdkVersion\x64"
if (-not (Test-Path "$sdk\makeappx.exe")) {
    throw "Windows SDK makeappx.exe not found under $sdk - is the Windows SDK installed?"
}

$releaseDir = "build\windows\x64\runner\Release"
$msixPath = "$releaseDir\training_app.msix"
$pfxPath = "$releaseDir\test_cert.pfx"
$cerPath = "$releaseDir\test_cert.cer"
$certPassword = "trainingapp"
# Must exactly match msix_config's default test-certificate subject in
# pubspec.yaml (no `publisher`/`certificate_path` override is set there) -
# AppxManifest.xml's own Publisher= attribute has to match the signing
# certificate's Subject exactly, or signing/validation fails.
$certSubject = "CN=Msix Testing, O=Msix Testing Corporation, S=Some-State, C=US"

Write-Host "Building unpackaged MSIX layout (flutter build windows + msix:build)..."
dart run msix:build
if ($LASTEXITCODE -ne 0) { throw "msix:build failed" }

Write-Host "Packing with the Windows SDK's makeappx.exe..."
if (Test-Path $msixPath) { Remove-Item $msixPath }
& "$sdk\makeappx.exe" pack /o /d $releaseDir /p $msixPath
if ($LASTEXITCODE -ne 0) { throw "makeappx pack failed" }

Write-Host "Generating a fresh self-signed test certificate..."
$cert = New-SelfSignedCertificate -Type Custom -Subject $certSubject -KeyUsage DigitalSignature `
    -FriendlyName "TrainingApp MSIX Test Cert" -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
$securePassword = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath $pfxPath -Password $securePassword | Out-Null
Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"
Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation "Cert:\CurrentUser\TrustedPeople" -Password $securePassword | Out-Null
Export-Certificate -Cert "Cert:\CurrentUser\TrustedPeople\$($cert.Thumbprint)" -FilePath $cerPath | Out-Null

Write-Host "Signing with the Windows SDK's signtool.exe..."
& "$sdk\signtool.exe" sign /fd SHA256 /a /f $pfxPath /p $certPassword $msixPath
if ($LASTEXITCODE -ne 0) { throw "signtool sign failed" }

Write-Host ""
Write-Host "Done: $msixPath"
Write-Host "Certificate exported to: $cerPath (trust it - see this script's header comment - before Add-AppxPackage)"
