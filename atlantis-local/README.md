# Atlantis (locally hosted)

Atlantis runs on a machine outside the AKS cluster, so destroying and
recreating the cluster doesn't take Atlantis with it. Azure DevOps reaches it
through an ngrok tunnel on a static domain:
`https://quarrel-skydiver-outsource.ngrok-free.dev`.

- Plans run automatically on PRs that touch the units listed in `/atlantis.yaml`.
- Apply by commenting `atlantis apply -p <project>` on the PR. The PR must be
  mergeable (set server-side in `repos.yaml`, so a PR can't change it).
- Azure access is the `az login` of the user running the services, not a
  dedicated identity.

## Setting it up on a machine

Prerequisites on `PATH`: `az` (logged in), `terraform`, `terragrunt`,
`kubelogin`, `git`, `curl`, `unzip`.

1. Sign in to https://dashboard.ngrok.com, copy the authtoken, and run
   `ngrok config add-authtoken <token>` (install.sh installs ngrok if needed,
   so run it once first if ngrok isn't there yet).
2. Run `./install.sh`. The first run creates `~/.config/atlantis/secrets.env`
   from `secrets.env.example` and stops. Fill in the three values, then run
   it again. It finishes by checking `/healthz` through the tunnel.
3. For services to keep running after logout and start at boot:
   `sudo loginctl enable-linger $USER`.

If the ngrok domain ever changes, update it in `config.yaml`,
`ngrok-atlantis.service`, `install.sh`, and in the Azure DevOps webhooks.

## Azure DevOps webhooks

Project settings → Service hooks → Web Hooks, one subscription per event, each
filtered to the `shopnest-ado` repository:

| Event | Resource version |
|---|---|
| Pull request created | 1.0 |
| Pull request updated | 1.0 |
| Pull request commented on | 2.0 |

URL `https://quarrel-skydiver-outsource.ngrok-free.dev/events`, Basic username
`atlantis`, password = `ATLANTIS_AZUREDEVOPS_WEBHOOK_PASSWORD`. The built-in
Test button returns 400 even when this is correct: its sample payload has a
date Atlantis can't parse. A real PR is the reliable check.

## Operating it

- Logs: `journalctl --user -u atlantis -u ngrok-atlantis -f`
- Restart after editing config: `systemctl --user restart atlantis`
- Web UI: the URL above, user `admin`, password `ATLANTIS_WEB_PASSWORD`.
- Destroy a unit: comment `atlantis plan -p <project> -- -destroy`, check the
  plan says "to destroy", then `atlantis apply -p <project>`. For several
  units, go one at a time in reverse dependency order (ingress-nginx,
  cert-manager, keyvault, aks, networking, resource-group).
- Plans failing with an Azure auth error after a long idle period means the
  CLI login expired: run `az login`.
