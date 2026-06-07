# Infra — Finder Kit releases (S3)

Custo estimado: centavos/mês (alguns ZIPs, sem tráfego público).

## Provisionar (uma vez)

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

## Configurar GitHub (repo → Settings → Secrets and variables → Actions → Variables)

| Variável | Valor (saída do `terraform apply`) |
|----------|-------------------------------------|
| `S3_RELEASES_BUCKET` | `bucket_name` |
| `AWS_RELEASE_ROLE_ARN` | `github_release_role_arn` |

Sem essas variáveis, o workflow ainda publica no **GitHub Releases** (grátis).

## Desprovisionar

```bash
terraform destroy
```
