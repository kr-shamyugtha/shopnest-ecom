# ShopNest — AWS infrastructure

The AWS half of the ShopNest stack. It is a deliberate mirror of
`terraform/azure`: same Terragrunt layout, same environments, same
application chart, same GitOps delivery model. Where a concept exists in
both clouds the naming is kept identical so the two trees can be read
side by side; where AWS has no equivalent, the difference is called out
below and commented at the point it matters in the code.

```
terraform/aws/
  bootstrap/            S3 state bucket (run once, by hand)
  modules/              The reusable pieces
  live/                 One directory per environment/region/component
    shared/ap-southeast-2/  resource-group, ci-identity, ecr
    dev/ap-southeast-2/     12 units
    staging/eu-west-1/      10 units (not deployable on the Free plan, see below)
    prod/us-east-1/         10 units (not deployable on the Free plan, see below)
```

## Running on the AWS Free plan

The account this is deployed to is on the AWS **Free plan** (a "project"
account inside an AWS-managed organization). Its service control policy
shapes the code in three ways:

| Free plan restriction | What the code does instead |
|---|---|
| Only **`ap-southeast-2`** is allowed; every other region is denied. | `shared` and `dev` live in `ap-southeast-2`, and so does the state bucket. `staging`/`prod` keep their original regions and can't be applied in this account. |
| **`iam:*OpenIDConnectProvider*` is denied**, so neither IRSA nor GitHub OIDC federation can exist. | Pods get AWS roles through **EKS Pod Identity** (a managed agent plus `aws_eks_pod_identity_association`), which needs no OIDC provider. GitHub Actions signs in as the narrowly-scoped **`shopnest-ci` IAM user** (`ci-identity`), with its key in repository secrets. |
| Spend comes out of a fixed credit balance. | Kubernetes **1.35** (in standard support; 1.31 would bill at the extended-support rate, 6x the control-plane price), one NAT gateway, two t3.large nodes. Roughly $10/day for `dev`; `terragrunt run --all destroy` in `dev` when it isn't needed. |

EKS itself is allowed. The services a Free plan account cannot use
(Marketplace, Reserved Instances, Savings Plans and similar) aren't part of
this stack.

## How the two clouds line up

| Azure | AWS | Notes |
|---|---|---|
| Resource group | `aws_resourcegroups_group` (tag-based) | AWS has no container object; region is a provider setting, grouping is by tag. The module exists to keep the tree shaped the same and to be the one place the region is declared. |
| VNet + 1 subnet + NSG | VPC + public/private subnets per AZ + NACL + security groups | EKS needs ≥2 AZs, and the VPC CNI gives pods **real subnet IPs** (no overlay), so subnets are `/20`s rather than one `/24`. |
| NSG (stateful) | Network ACL (**stateless**) + security groups | The NACL needs explicit ephemeral-port return rules that an NSG never does. This is the single most likely "worked on Azure, silently broken on AWS" difference. |
| ACR (one registry, many repos) | ECR (one repo per image) | No registry object, so the "registry" is a name prefix. No admin credential to disable — ECR is IAM-only. Needs explicit lifecycle policies; ECR has no storage cap. |
| Key Vault | Secrets Manager | No vault object; the "vault" is the path prefix `shopnest/<env>/`. |
| AKS | EKS | See below — this is where most of the extra work is. |
| Managed identity + federated credential | IAM role + EKS Pod Identity association | The federated credential's subject (this service account, this namespace, this cluster) becomes the association. IRSA would be the usual choice, but the Free plan denies the OIDC provider it needs. The pod-level `azure.workload.identity/use` label is only rendered on Azure. |
| `admin_group_object_ids` (Entra group) | `admin_principal_arns` (IAM role/user ARNs) | EKS access entries take a role/user ARN, not a group. With no IAM Identity Center on the Free plan, `dev` names the admin IAM user directly. |
| ADO service connection (auto-provisioned SP) | `ci-identity` module | An IAM user limited to ECR push and reading the backend role's ARN. A GitHub OIDC role would avoid the long-lived key, but the Free plan denies the OIDC provider. |
| `argocd` unit | `argocd` unit | Same bootstrap: Argo CD, the Grafana admin secret (kept in Secrets Manager instead of Key Vault), and the `argocd-apps` chart. No repo credential, because the GitHub repo is public. |
| `cert-manager-issuers` unit | `cert-manager-issuers` unit | The same self-signed and Let's Encrypt ClusterIssuers, applied after cert-manager so the CRD exists at plan time. |
| Static public IP on the AKS LoadBalancer | Elastic IPs pinned to the NLB (`ingress-nginx`) | Gives `argocd.`/`grafana.`/`prometheus.<ip>.nip.io` hostnames that survive an NLB rebuild, the same way the Azure ones rely on the static IP. |
| Azure Storage + blob leases | S3 + `use_lockfile` | Native S3 conditional-write locking, so no DynamoDB table to keep in sync. |
| `CanNotDelete` management lock | per-resource protection | AWS has no lock that cascades over a whole group. `enable_delete_lock` is threaded down to the resources that *do* support it (ECR `force_delete`, Secrets Manager recovery windows, KMS deletion windows, the state bucket's `prevent_destroy`). |

### What AKS gave us for free that EKS does not

These are extra `live/` units with **no Azure counterpart**. They are not
optional extras — without them, things the Azure stack already relies on
quietly stop working:

| Unit | Why it exists |
|---|---|
| `metrics-server` | AKS bundles it. Without it **every HPA in the chart reads `<unknown>` and never scales**, while otherwise looking healthy. |
| `cluster-autoscaler` | On AKS, `enable_auto_scaling` on the node pool *is* the feature. An EKS node group's min/max are only bounds — nothing moves between them unless this runs. |
| `aws-load-balancer-controller` | On AKS a bare `LoadBalancer` Service got a public IP from the built-in cloud provider. On EKS the in-tree path yields a legacy Classic LB; this is what produces a real NLB with `ip` targets. |
| `secrets-store-csi` | On AKS this is the `key_vault_secrets_provider` block *inside* the cluster resource. On EKS the driver and its AWS provider must be installed, or the backend pod hangs at `ContainerCreating` on a `FailedMount`. |
| EBS CSI add-on (in `eks`) | AKS ships a default StorageClass. Without this the monitoring stack's four PVCs stay `Pending` forever. |

## Apply order

The state bucket is `shopnest-tfstate-<account id>` in `ap-southeast-2`
(`live/terragrunt.hcl` derives the name from the account). In the current
account it was created by hand with versioning, AES256 encryption and public
access blocked; `bootstrap/` creates the same thing in a new account:

```bash
cd terraform/aws/bootstrap
terraform init
terraform apply -var "state_bucket_name=shopnest-tfstate-$(aws sts get-caller-identity --query Account --output text)" -var region=ap-southeast-2
```

Then `shared` before `dev` — `dev/eks` reads the CI user's ARN from
`shared/ci-identity`, and the pipeline needs ECR before it can push.
Terragrunt resolves the order inside each environment:

```bash
export TF_PLUGIN_CACHE_DIR=/tmp/tfplugins   # one provider copy, not one per unit
mkdir -p $TF_PLUGIN_CACHE_DIR
cd terraform/aws/live/shared/ap-southeast-2 && terragrunt run --all apply
cd ../../dev/ap-southeast-2                 && terragrunt run --all apply
```

A unit can't be *planned* until the units it depends on have been applied
(their outputs don't exist yet), so a first-time rollout goes in waves:
networking, then eks, then the add-ons, then secrets-manager /
cert-manager-issuers / argocd.

## After the first apply

1. **CI key** — create it outside Terraform so the secret never lands in
   state, and store it as the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
   repository secrets. `SONAR_TOKEN` is the only other secret.
   ```bash
   aws iam create-access-key --user-name shopnest-ci
   ```
2. **Secret values** — Terraform creates the Secrets Manager entries but
   deliberately never their values (that would put them in state). Seed them
   from the backend's `.env`, which uses the same names with `_` for `-`:
   ```bash
   aws secretsmanager put-secret-value \
     --secret-id shopnest/dev/MONGO-URI --secret-string '...'
   ```
3. **Hostnames** — `argocd/install-values-aws.yaml` and
   `argocd/values-monitoring-aws.yaml` need the NLB's Elastic IP in their
   nip.io hostnames (`terragrunt output public_ips` in `dev/.../ingress-nginx`).
4. **MongoDB Atlas** — allow the NAT gateway's Elastic IP, which is where
   all pod egress leaves the VPC.
5. **`public_access_cidrs`** — the EKS API endpoint defaults to `0.0.0.0/0`
   (IAM-authenticated, but reachable). Narrow it once the CI and admin
   ranges are known.

## Deliberate deviations from the Azure stack

- **CIDRs do not match.** Azure uses `10.10/10.20/10.30`; AWS uses
  `10.110/10.120/10.130`. Keeping them disjoint means a VPN or peering
  between the two clouds during a migration needs no renumbering first.
- **Node upgrades need no spare quota.** The Azure staging/prod units carry
  a warning that a Kubernetes upgrade needs a temporary extra node the
  regional vCPU quota cannot fit. EKS managed node groups replace nodes
  in place (`max_unavailable`), so that trap does not carry over.
- **Egress is unrestricted, on purpose.** Same conclusion the Azure NSG
  comments reached, for the same reason: the app talks to MongoDB Atlas,
  Cloudinary, Razorpay and Gmail on hosts a CIDR list cannot pin down, and
  nodes bootstrap against endpoints that move. FQDN filtering needs AWS
  Network Firewall in front of it — do not re-add restriction without it.
- **Immutable image tags.** ACR's defaults allowed a tag to be repointed;
  ECR here is `IMMUTABLE`, which is what makes the GitOps tag a real pin.
