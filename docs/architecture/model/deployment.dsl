// Two environments, and the difference between them matters.
//
// Azure is the production TARGET. Its Terraform, prod Compose stack, secret
// delivery and signed-image rollout all exist, but vars.ENABLE_DEPLOY is off,
// so a tagged release does not reach it. The AWS box is an experiment carrying
// no real data, and it is the environment that actually runs today. A single
// view labelled "production" would therefore be false, so both are modelled
// and each says what it is.
//
// The environment names are single tokens on purpose. check_docs_consistency's
// view-register regex reads a deployment view's key with \S+ for the
// environment name, so a name containing spaces makes the view invisible to
// the register check -- it would silently go unregistered. The armed/not-armed
// distinction lives in each view's description instead, which is where a
// reader sees it anyway. (Worth reporting upstream.)

// ── Azure: the production target, not yet armed ─────────────────────────────
deploymentEnvironment "Azure" {

    azureBrowser = deploymentNode "Member device" "Any modern browser with WebAuthn and a platform authenticator." "Browser" {
        containerInstance argus.webPwa
    }

    azureRegion = deploymentNode "Azure germanywestcentral" "EU region, chosen to pair with the eu-central B2 buckets for data residency." "Azure region" {

        azureVm = deploymentNode "argus-vm" "Single VM. Encryption at host on, key-only SSH, and a firewall whose only inbound Allow rules are the TURN ports -- no 22, 80 or 443." "Standard_B2ms, Ubuntu 24.04 LTS" {

            azureCompose = deploymentNode "Docker Compose (argus-prod)" "Every service; not one publishes a host port. CI asserts that, and that coturn is the only host-network service." "Docker Compose" {
                containerInstance argus.cloudflared
                containerInstance argus.ingress
                containerInstance argus.api
                azurePostgres = containerInstance argus.postgres
                containerInstance argus.redis
                containerInstance argus.prometheus
                containerInstance argus.alertmanager
                containerInstance argus.grafana
                containerInstance argus.loki
                containerInstance argus.alloy
                containerInstance argus.tempo
                containerInstance argus.pyroscope
                containerInstance argus.glitchtip
                containerInstance argus.exporters
            }

            azureHostNet = deploymentNode "Host network" "coturn alone runs outside the Compose network, because a relay must see real client addresses." "Linux host networking" {
                containerInstance argus.coturn
            }

            azureSystemd = deploymentNode "systemd" "Native units, not containers. They reach PostgreSQL over the container's local socket, since no database port is published." "systemd" {
                azureSecrets = containerInstance argus.secretsUnit
                containerInstance argus.backupTimer
                containerInstance argus.retentionTimer
            }

            azureDisk = deploymentNode "Managed data disk" "Separate from the OS disk." "Azure managed disk, 64 GiB, caching off" {
                azureVolumes = infrastructureNode "Docker volumes" "pgdata plus every observability and GlitchTip volume. One disk: these all share a failure domain." "Docker named volumes"
            }
        }

        azureIdentity = infrastructureNode "System-assigned Managed Identity" "Granted Key Vault Secrets User. The VM's only credential, and it is not a stored secret -- there is nothing to leak from a file." "Azure Managed Identity"
    }

    // !identifiers hierarchical: reference a nested identifier by its full path.
    azureRegion.azureVm.azureCompose.azurePostgres -> azureRegion.azureVm.azureDisk.azureVolumes "Persists its data files to" "Docker volume mount"
    azureRegion.azureVm.azureSystemd.azureSecrets -> azureRegion.azureIdentity "Obtains a Key Vault token from" "IMDS"
}

// ── AWS: the experiment that actually runs ──────────────────────────────────
deploymentEnvironment "AWS" {

    awsBrowser = deploymentNode "Member device" "The same PWA build; this box carries no real data." "Browser" {
        containerInstance argus.webPwa
    }

    awsRegion = deploymentNode "AWS eu-central-1" "EU region. Its own tag namespace and its own ENABLE_DEPLOY_AWS kill-switch, separate from Azure's." "AWS region" {

        awsEc2 = deploymentNode "EC2 instance" "Runs the same cloud-agnostic infra/stack/ as the Azure VM -- that portability is the point of the experiment." "t3.medium, Ubuntu" {

            awsCompose = deploymentNode "Docker Compose (argus-prod)" "The same Compose stack, from the same signed images." "Docker Compose" {
                containerInstance argus.cloudflared
                containerInstance argus.ingress
                containerInstance argus.api
                containerInstance argus.postgres
                containerInstance argus.redis
            }

            awsHostNet = deploymentNode "Host network" "coturn, as on Azure." "Linux host networking" {
                containerInstance argus.coturn
            }

            awsSystemd = deploymentNode "systemd" "The same native units as on Azure." "systemd" {
                awsSecrets = containerInstance argus.secretsUnit
            }
        }

        awsArc = infrastructureNode "Azure Arc agent" "Projects an Azure identity onto the EC2 box so it can read the same Key Vault. The experiment borrows Azure's secret store rather than copying secrets into AWS." "Azure Arc connected machine agent"
    }

    awsRegion.awsEc2.awsSystemd.awsSecrets -> awsRegion.awsArc "Obtains a Key Vault token from" "Arc-projected identity"
}
