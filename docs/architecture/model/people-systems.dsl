// People, and the systems outside the argus trust boundary.
// argus itself and its containers are defined in containers.dsl.

member = person "Member" "Sends end-to-end-encrypted messages, joins groups and makes 1:1 audio calls from the PWA. Joins only by redeeming an admin-minted invite code, then registers a passkey."
tenantAdmin = person "Tenant Admin" "Mints and revokes invite codes, lists members and devices, reads the audit log. Sees metadata only -- never message content." "Staff"
breakglassOperator = person "Breakglass Operator" "Recovers administrative access when no passkey works, through a Cloudflare-Access-gated username and password login." "Staff"
opsEngineer = person "Ops Engineer" "Watches dashboards, alerts and error reports. Reaches Grafana and GlitchTip through Cloudflare Access, not through an argus account." "Staff"
releaseApprover = person "Release Approver" "Approves each tagged release in the prod GitHub Environment before it reaches the VM." "Staff"

cloudflare = softwareSystem "Cloudflare" "Terminates public TLS, applies WAF and rate limiting, and carries every HTTP request into the VM over an outbound-only tunnel. No inbound HTTP port is open." "External"
cloudflareAccess = softwareSystem "Cloudflare Access" "Identity gate in front of the breakglass login, Grafana and GlitchTip. Issues the JWT the API verifies against its JWKS." "External"
b2Attachments = softwareSystem "Backblaze B2 (attachments)" "S3-compatible object store, EU eu-central-003, holding encrypted attachment blobs. Browsers upload and download directly against presigned URLs; the API never proxies the bytes." "External"
b2Backups = softwareSystem "Backblaze B2 (backups)" "Separate private EU bucket holding age-encrypted nightly database dumps under Object Lock (WORM, Compliance mode)." "External"
keyVault = softwareSystem "Azure Key Vault" "Holds every runtime secret. The VM reads them with its Managed Identity and writes them to tmpfs credential files; secrets never enter the environment." "External"
azureControlPlane = softwareSystem "Azure control plane" "Runs the deploy script on the VM via az vm run-command, and issues Managed Identity tokens through IMDS. There is no SSH path and no open management port." "External"
githubActions = softwareSystem "GitHub Actions and GHCR" "Builds, scans (Trivy), SBOMs (syft) and keyless-signs (cosign) the container images, then triggers the rollout over OIDC." "External"
webPush = softwareSystem "Browser push services" "FCM, Mozilla autopush and Apple. Deliver content-free VAPID web-push notifications to a subscriber's browser." "External"
alertReceiver = softwareSystem "Alert receiver" "The webhook Alertmanager posts firing alerts to. Its URL is a secret and its identity is not recorded in this repository." "External"

member -> cloudflare "Loads the PWA and sends encrypted messages through" "HTTPS, WSS" "Person"
tenantAdmin -> cloudflare "Administers the tenant through" "HTTPS" "Person"
breakglassOperator -> cloudflareAccess "Proves identity to" "OIDC" "Person"
opsEngineer -> cloudflareAccess "Proves identity to" "OIDC" "Person"
releaseApprover -> githubActions "Approves the release in" "GitHub Environment" "Person"
cloudflareAccess -> cloudflare "Gates the protected hostnames of" "Access policy"
githubActions -> azureControlPlane "Starts the rollout through" "az vm run-command, OIDC"
