# Proxmox with OpenTofu/Terraform using SOPs to encrypt secrets

## Log in to proxmox node and create user for provisioning

Create terraform provisioning user

```bash
pveum user add terraform-prov@pve
```

Create TerraformProv role

```bash
pveum role add TerraformProv -privs "Datastore.AllocateSpace \
Datastore.AllocateTemplate Datastore.Audit Pool.Allocate \
Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit \
VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU \
VM.Config.Disk VM.Config.HWType VM.Config.Memory \
VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor \
VM.PowerMgmt SDN.Use Mapping.Use"
```

Create user and add to TerraformProv role

```bash
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

Create token for user

```bash
pveum user token add terraform-prov@pve mytoken
```

## Use opentofu to implement config

Create an alias to run opentofu from container

```bash
alias tofu='docker run -it -e PM_API_TOKEN_ID="terraform-prov@pve!mytoken" -e PM_API_TOKEN_SECRET="<secret-key>" -v $HOME/.config/sops/age/keys.txt:/root/.config/sops/age/keys.txt -v ${PWD}:/app -w /app ghcr.io/opentofu/opentofu:latest '
```

Run tofu init
```bash
tofu init
```

Run tofu plan
```bash
tofu plan
```

Apply plan
```bash
tofu apply
```
