# =============================================================================
# Deploy Check by CyberDrain - New Edge IT Services
# =============================================================================
# Installs Check on Chrome and Edge, applies New Edge branding, configures
# detection settings, CIPP reporting, BSN phishing training allowlist, and
# false positive webhook via enterprise registry policy.
#
# Deploy via SuperOps as a PowerShell script (Run As: System).
# =============================================================================

# =============================================================================
# PER-CLIENT VARIABLES - Update these for each client deployment
# =============================================================================

$clientName = ""                # e.g. "Acme-Law" (no spaces)
$cippTenantId = ""              # Client's M365 tenant domain or GUID (leave blank to disable CIPP reporting)

# =============================================================================
# Standard Configuration - Same across all clients
# =============================================================================

# --- Extension IDs -----------------------------------------------------------

$chromeExtensionId = "benimdeioplgkhanklclahllklceahbe"
$chromeUpdateUrl = "https://clients2.google.com/service/update2/crx"
$chromeManagedStorageKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\3rdparty\extensions\$chromeExtensionId\policy"
$chromeExtensionSettingsKey = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings\$chromeExtensionId"

$edgeExtensionId = "knepjpocdagponkonnbggpcnhnaikajg"
$edgeUpdateUrl = "https://edge.microsoft.com/extensionwebstorebase/v1/crx"
$edgeManagedStorageKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\3rdparty\extensions\$edgeExtensionId\policy"
$edgeExtensionSettingsKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionSettings\$edgeExtensionId"

# --- Detection ---------------------------------------------------------------

$enablePageBlocking = 1
$domainSquattingEnabled = 1
$updateInterval = 24
$customRulesUrl = ""

# BreachSecureNow phishing simulation domains
$urlAllowlist = @(
    "https://*.it-support.care/*",
    "https://*.customer-portal.info/*",
    "https://*.member-services.info/*",
    "https://*.bankonlinesupport.com/*",
    "https://*.secureaccess.biz/*",
    "https://*.logineverification.com/*",
    "https://*.Iogmein.com/*",
    "https://*.mlcrosoft.live/*",
    "https://*.cloud-service-care.com/*",
    "https://*.packagetrackingportal.com/*",
    "https://*.security-reminders.com/*",
    "https://*.pii-protect.com/*"
)

# --- CIPP Reporting ----------------------------------------------------------

$cippServerUrl = "https://cipp5xz5c.azurewebsites.net/"
if ($cippTenantId -eq "") {
    $enableCippReporting = 0
} else {
    $enableCippReporting = 1
}

# --- False Positive Webhook --------------------------------------------------

$falsePositiveWebhookBaseUrl = "https://default08d35e7466424be2ba2f3f7fff0d98.86.environment.api.powerplatform.com:443/powerautomate/automations/direct/cu/25/workflows/0b4c893f0ca94a9392ce4ded57c838d3/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=D-aW9wTD4C1HJXVz3C5lJDYbY5O242MQ5d7Hh20DrL4"   # Power Automate URL (same for all clients)
$falsePositiveWebhookUrl = "$falsePositiveWebhookBaseUrl&client=$clientName"

# --- User Interface ----------------------------------------------------------

$showNotifications = 1
$enableValidPageBadge = 0
$forceToolbarPin = 0

# --- Logging -----------------------------------------------------------------

$enableDebugLogging = 0

# --- Webhooks ----------------------------------------------------------------

$enableGenericWebhook = 0
$webhookUrl = ""
$webhookEvents = @()

# --- Branding ----------------------------------------------------------------

$companyName = "New Edge IT Services"
$productName = "New Edge - Phishing Protection"
$supportEmail = "support@newedge-it.com"
$supportUrl = ""
$privacyPolicyUrl = "https://newedge-it.com/privacy-policy"
$aboutUrl = "https://newedge-it.com/about"
$primaryColor = "#8DBAE3"
$logoUrl = "https://newedge-itservices.github.io/newedge-branding/ne-icon-128.jpg"

# --- Installation ------------------------------------------------------------

$installationMode = "force_installed"

# =============================================================================
# Deployment Logic - Do not modify below this line
# =============================================================================

function Configure-ExtensionSettings {
    param (
        [string]$ExtensionId,
        [string]$UpdateUrl,
        [string]$ManagedStorageKey,
        [string]$ExtensionSettingsKey
    )

    # Create managed storage key
    if (!(Test-Path $ManagedStorageKey)) {
        New-Item -Path $ManagedStorageKey -Force | Out-Null
    }

    # Detection and extension settings
    New-ItemProperty -Path $ManagedStorageKey -Name "enablePageBlocking" -PropertyType DWord -Value $enablePageBlocking -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "showNotifications" -PropertyType DWord -Value $showNotifications -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "enableValidPageBadge" -PropertyType DWord -Value $enableValidPageBadge -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "updateInterval" -PropertyType DWord -Value $updateInterval -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "customRulesUrl" -PropertyType String -Value $customRulesUrl -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "enableDebugLogging" -PropertyType DWord -Value $enableDebugLogging -Force | Out-Null

    # CIPP reporting
    New-ItemProperty -Path $ManagedStorageKey -Name "enableCippReporting" -PropertyType DWord -Value $enableCippReporting -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "cippServerUrl" -PropertyType String -Value $cippServerUrl -Force | Out-Null
    New-ItemProperty -Path $ManagedStorageKey -Name "cippTenantId" -PropertyType String -Value $cippTenantId -Force | Out-Null

    # False positive webhook
    New-ItemProperty -Path $ManagedStorageKey -Name "falsePositiveWebhookUrl" -PropertyType String -Value $falsePositiveWebhookUrl -Force | Out-Null

    # Domain squatting
    $domainSquattingKey = "$ManagedStorageKey\domainSquatting"
    if (!(Test-Path $domainSquattingKey)) {
        New-Item -Path $domainSquattingKey -Force | Out-Null
    }
    New-ItemProperty -Path $domainSquattingKey -Name "enabled" -PropertyType DWord -Value $domainSquattingEnabled -Force | Out-Null

    # URL allowlist
    $urlAllowlistKey = "$ManagedStorageKey\urlAllowlist"
    if (!(Test-Path $urlAllowlistKey)) {
        New-Item -Path $urlAllowlistKey -Force | Out-Null
    }
    Remove-ItemProperty -Path $urlAllowlistKey -Name * -Force -ErrorAction SilentlyContinue | Out-Null
    for ($i = 0; $i -lt $urlAllowlist.Count; $i++) {
        $propertyName = ($i + 1).ToString()
        New-ItemProperty -Path $urlAllowlistKey -Name $propertyName -PropertyType String -Value $urlAllowlist[$i] -Force | Out-Null
    }

    # Branding
    $customBrandingKey = "$ManagedStorageKey\customBranding"
    if (!(Test-Path $customBrandingKey)) {
        New-Item -Path $customBrandingKey -Force | Out-Null
    }
    New-ItemProperty -Path $customBrandingKey -Name "companyName" -PropertyType String -Value $companyName -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "productName" -PropertyType String -Value $productName -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "supportEmail" -PropertyType String -Value $supportEmail -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "supportUrl" -PropertyType String -Value $supportUrl -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "privacyPolicyUrl" -PropertyType String -Value $privacyPolicyUrl -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "aboutUrl" -PropertyType String -Value $aboutUrl -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "primaryColor" -PropertyType String -Value $primaryColor -Force | Out-Null
    New-ItemProperty -Path $customBrandingKey -Name "logoUrl" -PropertyType String -Value $logoUrl -Force | Out-Null

    # Generic webhook
    $genericWebhookKey = "$ManagedStorageKey\genericWebhook"
    if (!(Test-Path $genericWebhookKey)) {
        New-Item -Path $genericWebhookKey -Force | Out-Null
    }
    New-ItemProperty -Path $genericWebhookKey -Name "enabled" -PropertyType DWord -Value $enableGenericWebhook -Force | Out-Null
    New-ItemProperty -Path $genericWebhookKey -Name "url" -PropertyType String -Value $webhookUrl -Force | Out-Null

    $webhookEventsKey = "$genericWebhookKey\events"
    if (!(Test-Path $webhookEventsKey)) {
        New-Item -Path $webhookEventsKey -Force | Out-Null
    }
    Remove-ItemProperty -Path $webhookEventsKey -Name * -Force -ErrorAction SilentlyContinue | Out-Null
    for ($i = 0; $i -lt $webhookEvents.Count; $i++) {
        $propertyName = ($i + 1).ToString()
        New-ItemProperty -Path $webhookEventsKey -Name $propertyName -PropertyType String -Value $webhookEvents[$i] -Force | Out-Null
    }

    # Extension install policy
    if (!(Test-Path $ExtensionSettingsKey)) {
        New-Item -Path $ExtensionSettingsKey -Force | Out-Null
    }
    New-ItemProperty -Path $ExtensionSettingsKey -Name "installation_mode" -PropertyType String -Value $installationMode -Force | Out-Null
    New-ItemProperty -Path $ExtensionSettingsKey -Name "update_url" -PropertyType String -Value $UpdateUrl -Force | Out-Null

    Write-Output "Configured Check extension for $ExtensionId"
}

# Deploy to both browsers
Configure-ExtensionSettings -ExtensionId $chromeExtensionId -UpdateUrl $chromeUpdateUrl -ManagedStorageKey $chromeManagedStorageKey -ExtensionSettingsKey $chromeExtensionSettingsKey
Configure-ExtensionSettings -ExtensionId $edgeExtensionId -UpdateUrl $edgeUpdateUrl -ManagedStorageKey $edgeManagedStorageKey -ExtensionSettingsKey $edgeExtensionSettingsKey

Write-Output "Check deployment complete - New Edge IT Services [$clientName]"
