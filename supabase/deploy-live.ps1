<# 
.SYNOPSIS
    Deploy Kashkool Supabase migrations and storage to live project.
.DESCRIPTION
    Links to live Supabase project, pushes all migrations, creates private 'receipts' bucket with RLS policies.
.PARAMETER ProjectRef
    Supabase project reference ID (from dashboard Settings > General > Reference ID)
.PARAMETER AccessToken
    Supabase personal access token (from Settings > Access Tokens)
.EXAMPLE
    .\deploy-live.ps1 -ProjectRef "abcdefghijklmnopqrst" -AccessToken "sb_abcdef1234567890..."
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRef,

    [Parameter(Mandatory=$true)]
    [string]$AccessToken
)

$ErrorActionPreference = "Stop"

Write-Host "=== Kashkool Supabase Live Deploy ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectRef" -ForegroundColor Gray

# Set access token for this session
$env:SUPABASE_ACCESS_TOKEN = $AccessToken

# 1. Link to live project
Write-Host "`n[1/4] Linking to project..." -ForegroundColor Yellow
supabase link --project-ref $ProjectRef

# 2. Push all migrations
Write-Host "`n[2/4] Pushing migrations..." -ForegroundColor Yellow
supabase db push

# 3. Create private 'receipts' storage bucket
Write-Host "`n[3/4] Creating private 'receipts' bucket..." -ForegroundColor Yellow
supabase storage buckets create receipts --public=false

# 4. Create RLS policies for receipts bucket
Write-Host "`n[4/4] Creating storage policies..." -ForegroundColor Yellow

# Student can upload their own receipts
supabase storage policies create receipts `
    --name "student-upload" `
    --operation insert `
    --definition 'auth.role() = "authenticated" AND (bucket_id = "receipts")'

# Student can read their own receipts
supabase storage policies create receipts `
    --name "student-read-own" `
    --operation select `
    --definition 'auth.role() = "authenticated" AND (bucket_id = "receipts") AND (owner = auth.uid())'

# Staff (teacher/secretary/admin) can read all receipts in their tenant
supabase storage policies create receipts `
    --name "staff-read-all" `
    --operation select `
    --definition 'auth.role() = "authenticated" AND (bucket_id = "receipts") AND EXISTS (
        SELECT 1 FROM profiles p 
        WHERE p.id = auth.uid() 
        AND p.tenant_id = (SELECT tenant_id FROM payment_submissions WHERE receipt_url LIKE "%" || name || "%")
        AND p.role IN ("teacher", "secretary", "admin")
    )'

Write-Host "`n=== Deploy Complete ===" -ForegroundColor Green
Write-Host "Verify at: https://supabase.com/dashboard/project/$ProjectRef/storage/buckets/receipts" -ForegroundColor Cyan