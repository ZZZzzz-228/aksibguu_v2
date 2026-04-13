param(
  [string]$BaseUrl = "http://127.0.0.1:8000"
)

Write-Host "Smoke API against $BaseUrl"

function Assert-Ok($response, $name) {
  if (-not $response.ok) {
    throw "$name failed: ok=false"
  }
  Write-Host "[OK] $name"
}

$health = Invoke-RestMethod -Method Get -Uri "$BaseUrl/health"
Assert-Ok $health "health"

$contacts = Invoke-RestMethod -Method Get -Uri "$BaseUrl/contacts"
Assert-Ok $contacts "contacts"

$news = Invoke-RestMethod -Method Get -Uri "$BaseUrl/news"
Assert-Ok $news "news"

$specialties = Invoke-RestMethod -Method Get -Uri "$BaseUrl/public/specialties"
Assert-Ok $specialties "public/specialties"

$partners = Invoke-RestMethod -Method Get -Uri "$BaseUrl/public/partners"
Assert-Ok $partners "public/partners"

Write-Host "Smoke checks passed."
