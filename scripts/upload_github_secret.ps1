# ============================================================
# Upload FIREBASE_SERVICE_ACCOUNT_JSON to GitHub Secrets
# Usage: Run this in PowerShell from any directory
# ============================================================

# --- CONFIG ---
$GITHUB_OWNER = "krishnasharma7011594-cmd"
$GITHUB_REPO  = "Gotchaa"
$SECRET_NAME  = "FIREBASE_SERVICE_ACCOUNT_JSON"

# Paste your GitHub PAT here (needs repo/secrets write permission)
# Generate at: https://github.com/settings/tokens/new
# Scopes needed: repo (full control)
$GITHUB_PAT = Read-Host "Paste your GitHub Personal Access Token (PAT)" -AsSecureString
$PAT = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($GITHUB_PAT)
)

# --- SECRET VALUE ---
$SECRET_VALUE = @'
{
  "type": "service_account",
  "project_id": "studio-1284397718-50704",
  "private_key_id": "006c1a3e4cdc0734602252ef9e2a5051348e0a39",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDL6iIrgP/UMzrH\n69xTrWxauI7s1ShHWPJSQ1XhETdoQheHlEe5fDb75BczVpalbgHOuQ1QdUFuSnef\nVGByk5wYQ4RIIk4n1BZZL0iMIjRVcEVDnMHU+GT3NB+x09XBzYxhjqN9SHvQTz+J\n/6VlRnTk407Vq5/Up7Pl/RAlQCe47a/ZT7kMt93WY9De6gZC+H/f4hCFy//FPRNr\nuTBg/sbA8Vn2HOD8aqxzn1ZXdGuWLiZ7a06n5wVGS8SEaI1t/g9L2hUgEcxE/Kyl\ndnITz0j0s3I3CDJO06OKY2t8SCh7jvc6SkPiwH+p65CVZ/pfP72CX6zS2Jkd4BIN\nBzCbjw5TAgMBAAECggEARvARqQ68cQbNaSVNRbLsIfdYiV1yILf5vNJ9+skxfEyZ\nwOm9tfJXcnOb+pkh2TUW3eKUlivkckjnqn8A+nsNb4d1al68z7BBgg8n7tArYpmn\nDulmqP8sqK7yY7us/jnSn1Gu4HOp1wLquMg9sqi7G7FUCJMnDCS3Ocg6qKrT5sny\nEnq5Ku7GlT336tRlUiEGD4DxZ1Lwp2GEM3KJGTf3WArzFdHT3i5iLmIiVWa9lFFC\naIxNCUPeAyWbpXhyhkhsseggmDYSt1gWEnRrJzDOCgIVQBhIqh5qUkW4sSiL9vY3\n5Ke6ra8B0NVM3UOkbLyrwXtO84mcF3XWNsAneQXTAQKBgQDxLoX38/4T0134b0Yj\nkZXf8LCq6Wr/j+u9VgnBcdEAvUpgIzTjeLHaQN4YQ/Y5hQZ1lR35w/Juz5VKob39\n4+oTEAOyH32zLmr4+72PG2iGCKjKmhuhqQLHEZR4OnRNfQU9siNkY3lyEpBeSl9Q\n0SIA57ZkQvJCKY1NmgNTN++6gQKBgQDYcXI1imeC+s79/Ja8NOyLBVXsqj4JCqLT\nntV7FhuFULAozocuXrLVCq0z4sV5hmIPZr+13X0le1T991Nkt3bov5tL4PwtJh94\nDkHbZTqnLajzvZq75UdfrmEfwd0626j211nkUiGLSRpjeqYC/IOqAgfbVRboSO5r\n3yz7NdFW0wKBgEr+JlX1HjnX7U5Ee1CwAiRB2Q0ry0Nv4uNaj2oBE/Xg5fGCwP1C\nGDs/FFADQdqczGdfWJTDIuzlywwLwuHhLnWC80M9m35NnqGQ1V5cLWIP6zwkMxdP\nUDfJ9Zp0wpkdmLWYYHzkmWyo7Q8EnSKqBKK3afU/A8ki1nccvo/vwrEBAoGAGCOG\n1jvKUYxBO4hJE1Jfsx10OMG/y2hZQnqrWl/bz+Fw1Aw8fUpobWQUbv3yghwfoZIW\n/WRnSZ/Ymb5UmZ3wcAK2gh7kYPCof84vQBWpFe38srpJoHzwmdYr1MvdLWxECst3\npgQW457Sh5etHhYlZPd3AtoZhOxlUriAHsAgyasCgYA2mcSXqNc+q85j9E1VW7lC\nvwjsmod79p795K9NF3esan18U3zCp98uLfQp2gqshz1LGyMPdGyw4N4xv1vJ58Im\nODTzsJ9vZBTfjpWMs17NfBVNRwjcOEZS0m44T+N+O2exO9/SsFqj4T3/xXtxXPNV\nLBuU6260OJ9lxWBorF10Tg==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@studio-1284397718-50704.iam.gserviceaccount.com",
  "client_id": "113234962179032820483",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40studio-1284397718-50704.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
'@

# --- STEP 1: Get repo public key for secret encryption ---
$headers = @{
  "Authorization" = "Bearer $PAT"
  "Accept"        = "application/vnd.github+json"
  "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host "`nFetching repo public key..." -ForegroundColor Cyan
$keyUrl = "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/secrets/public-key"
$keyResponse = Invoke-RestMethod -Uri $keyUrl -Headers $headers -Method Get
$publicKeyId  = $keyResponse.key_id
$publicKeyB64 = $keyResponse.key
Write-Host "Got key_id: $publicKeyId" -ForegroundColor Green

# --- STEP 2: Encrypt secret using libsodium (via .NET) ---
# GitHub requires secrets to be encrypted with the repo's public key using libsodium
# We'll use the sodium-core NuGet package approach via PowerShell
# Simpler: use the pre-built sodium DLL if available, otherwise use Python

$pythonAvailable = $null
try { $pythonAvailable = (python --version 2>&1) } catch {}

if ($pythonAvailable) {
  Write-Host "Using Python to encrypt secret..." -ForegroundColor Cyan

  $encryptScript = @"
import base64, sys
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PublicKey
from nacl.public import PublicKey, SealedBox

pub_key_bytes = base64.b64decode('$publicKeyB64')
pub_key = PublicKey(pub_key_bytes)
box = SealedBox(pub_key)
secret_bytes = '''$SECRET_VALUE'''.encode('utf-8')
encrypted = box.encrypt(secret_bytes)
print(base64.b64encode(encrypted).decode('utf-8'))
"@

  # Try with pynacl
  $encryptedValue = python -c $encryptScript 2>&1
  
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing pynacl..." -ForegroundColor Yellow
    pip install pynacl -q
    $encryptedValue = python -c $encryptScript
  }

  # --- STEP 3: Upload secret ---
  Write-Host "Uploading secret to GitHub..." -ForegroundColor Cyan
  $secretUrl = "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/actions/secrets/$SECRET_NAME"
  $body = @{
    encrypted_value = $encryptedValue.Trim()
    key_id          = $publicKeyId
  } | ConvertTo-Json

  $result = Invoke-RestMethod -Uri $secretUrl -Headers $headers -Method Put -Body $body -ContentType "application/json"
  Write-Host "`n✅ Secret '$SECRET_NAME' uploaded successfully!" -ForegroundColor Green
  Write-Host "GitHub Actions will now use it on the next deploy run." -ForegroundColor Green

} else {
  Write-Host "`n⚠️  Python not found. Cannot auto-encrypt the secret." -ForegroundColor Yellow
  Write-Host "Please add the secret manually via GitHub UI:" -ForegroundColor Yellow
  Write-Host "  1. Go to: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/settings/secrets/actions" -ForegroundColor White
  Write-Host "  2. Click 'New repository secret'" -ForegroundColor White
  Write-Host "  3. Name: $SECRET_NAME" -ForegroundColor White
  Write-Host "  4. Value: paste the full JSON content from the service account file" -ForegroundColor White
}
