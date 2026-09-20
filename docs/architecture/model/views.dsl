// Eight views, each answering one question for one audience. The register in
// docs/architecture/README.md records which is which; check_docs_consistency.py
// fails when the two disagree.
// Every view uses autoLayout: no maintained coordinates, no manual finishing.

systemContext argus "SystemContext" "Who uses argus and which outside systems it depends on. Start here." {
    include *
    autoLayout tb
}

container argus "Containers" "The running pieces and how a message travels between them. Observability and maintenance are left out so the message path reads clearly -- see Observability and Delivery for those." {
    include *
    exclude argus.prometheus argus.alertmanager argus.grafana argus.loki argus.alloy argus.tempo argus.pyroscope argus.glitchtip argus.exporters
    exclude argus.secretsUnit argus.backupTimer argus.retentionTimer
    exclude opsEngineer breakglassOperator releaseApprover githubActions azureControlPlane keyVault b2Backups alertReceiver
    autoLayout tb
}

container argus "AccessPaths" "The three ways in, and where each is authenticated. The member path, the admin path and the breakglass path are gated differently, and that difference is the most misread part of this system." {
    include member tenantAdmin breakglassOperator cloudflare cloudflareAccess argus.cloudflared argus.ingress argus.api argus.webPwa argus.coturn argus.postgres
    autoLayout tb
}

container argus "Observability" "How a failure becomes a signal someone acts on. Nothing here is reachable from the internet except through the two Cloudflare-Access-gated hostnames." {
    include argus.api argus.postgres argus.redis argus.coturn argus.ingress argus.prometheus argus.alertmanager argus.grafana argus.loki argus.alloy argus.tempo argus.pyroscope argus.glitchtip argus.exporters alertReceiver opsEngineer
    autoLayout lr
}

container argus "Maintenance" "The scheduled jobs that are not containers, and the two object stores they touch. These run as native systemd units on the host." {
    include argus.secretsUnit argus.backupTimer argus.retentionTimer argus.postgres argus.api keyVault b2Backups b2Attachments azureControlPlane
    autoLayout lr
}

dynamic argus "MessageFlow" "Sending one message. Every step the server takes is on bytes it cannot read." {
    member -> argus.webPwa "Types a message, which the PWA encrypts to the MLS group before anything leaves the device"
    argus.webPwa -> argus.ingress "POSTs the ciphertext envelope"
    argus.ingress -> argus.api "Routes it to the API"
    argus.api -> argus.postgres "Stores the envelope as opaque bytes"
    argus.api -> argus.redis "Publishes a delivery event to the recipient's live connection"
    argus.api -> webPush "Sends a content-free notification for devices that are offline"
    autoLayout tb
}

dynamic argus "CallSetup" "Starting a 1:1 audio call. Signalling travels as ciphertext over the existing message socket, and media never goes peer-to-peer." {
    member -> argus.webPwa "Starts a call"
    argus.webPwa -> argus.ingress "Asks for short-lived relay credentials, then sends the encrypted offer over the message socket"
    argus.ingress -> argus.api "Routes both to the API, which mints HMAC credentials and forces relay-only transport"
    argus.api -> argus.redis "Fans the encrypted signal out to the callee's connection"
    argus.webPwa -> argus.coturn "Relays the media stream, so neither party learns the other's address"
    autoLayout lr
}

container argus "Delivery" "How a change reaches the running system, and the two human gates on the way. Nothing here has a standing credential on the VM: the images are signed and verified on arrival, and the rollout runs through the cloud control plane rather than over SSH." {
    include releaseApprover githubActions azureControlPlane argus.ingress argus.api argus.secretsUnit keyVault
    autoLayout lr
}

deployment argus "Azure" "AzureDeployment" "Where production is meant to run. Everything shown exists as code; the rollout switch is off, so nothing is running here yet." {
    include *
    autoLayout tb
}

deployment argus "AWS" "AwsDeployment" "The box that actually runs today. It carries no real data; it exists to prove the stack is portable and to surface runtime problems before Azure is armed." {
    include *
    autoLayout tb
}
