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
    shared/eu-central-1/    resource-group, ci-oidc, ecr
    dev/eu-central-1/       10 units
    staging/eu-west-1/      10 units
    prod/us-east-1/         10 units
```

## How the two clouds line up

| Azure | AWS | Notes |
|---|---|---|
| Resource group | `aws_resourcegroups_group` (tag-based) | AWS has no container object; region is a provider setting, grouping is by tag. The module exists to keep the tree shaped the same and to be the one place the region is declared. |
| VNet + 1 subnet + NSG | VPC + public/private subnets per AZ + NACL + security groups | EKS needs ≥2 AZs, and the VPC CNI gives pods **real subnet IPs** (no overlay), so subnets are `/20`s rather than one `/24`. |
| NSG (stateful) | Network ACL (**stateless**) + security groups | The NACL needs explicit ephemeral-port return rules that an NSG never does. This is the single most likely "worked on Azure, silently broken on AWS" difference. |
| ACR (one registry, many repos) | ECR (one repo per image) | No registry object, so the "registry" is a name prefix. No admin credential to disable — ECR is IAM-only. Needs explicit lifecycle policies; ECR has no storage cap. |
| Key Vault | Secrets Manager | No vault object; the "vault" is the path prefix `shopnest/<env>/`. |
| AKS | EKS | See below — this is where most of the extra work is. |
| Managed identity + federated credential | IAM role + IRSA trust policy | Same statement, different syntax. The pod-level `azure.workload.identity/use` label has no AWS counterpart. |
| `admin_group_object_ids` (Entra group) | `admin_principal_arns` (IAM role ARNs) | EKS access entries take a role/user ARN, not a group. An IAM Identity Center permission set is the closest equivalent to the Entra group. |
| ADO service connection (auto-provisioned SP) | `ci-oidc` module | Nothing auto-provisions this on AWS, so the GitHub OIDC trust is declared in Terraform instead of pasted in as a GUID. |
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

Bootstrap once per account:

```bash
cd terraform/aws/bootstrap
terraform init
terraform apply -var 'state_bucket_name=shopnest-tfstate-2026'
```

Then, per environment — Terragrunt resolves the ordering from the
`dependency` blocks, so a whole environment can go in one command:

```bash
cd terraform/aws/live/shared/eu-central-1 && terragrunt run --all apply
cd ../../dev/eu-central-1                 && terragrunt run --all apply
```

`shared` must come first: `dev/eks` reads the CI role ARN from
`shared/ci-oidc`, and the pipeline needs ECR to exist before it can push.

## Things that must be filled in before a real apply

Everything below ships with an obvious placeholder rather than a wrong
value, so a mistake fails loudly instead of silently targeting the wrong
account.

1. **State bucket name** — `live/terragrunt.hcl` `remote_state.config.bucket`
   must match what `bootstrap` created (S3 names are globally unique).
2. **Admin IAM role** — `shopnest-eks-admins` (dev/staging) and
   `shopnest-eks-admins-prod` must exist and be assumable by the humans who
   need cluster-admin. The account ID is resolved live via
   `get_aws_account_id()`, so there is no account number to keep in sync —
   but it does mean these units need valid credentials even to *render*.
3. **GitHub repository** — `shared/ci-oidc` pins `github_repository`. Only
   that repo, on `refs/heads/main`, can assume the CI role.
4. **`AWS_CI_ROLE_ARN`** — set as a **repository variable** in GitHub from
   the `ci-oidc` unit's `role_arn` output. `SONAR_TOKEN` stays a secret.
5. **Secret values** — Terraform creates the Secrets Manager entries but
   deliberately never their values (that would put them in state). Seed each
   one once:
   ```bash
   aws secretsmanager put-secret-value \
     --secret-id shopnest/dev/MONGO-URI --secret-string '...'
   ```
6. **Image repository host** — `helm/shopnest/values-aws.yaml` ships a
   placeholder account ID. The pipeline overwrites it in the per-environment
   file on every run; set it by hand only for a manual `helm install`.
7. **`public_access_cidrs`** — the EKS API endpoint defaults to `0.0.0.0/0`
   (IAM-authenticated, but reachable). Narrow it to the CI and office/VPN
   ranges once they are known.

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
