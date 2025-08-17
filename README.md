
# AWS POC - Marketing Streaming (Terraform + Ansible + Publisher)

Conteúdo:
- `terraform/` : arquivos para criar Kinesis, S3, Redshift Serverless (exemplo).
- `ansible/` : playbook para criar tabela e view no Redshift.
- `publisher.py` : script que publica eventos simulados no Kinesis.


## Instruções rápidas (manual)
1. Configure suas credenciais AWS: `aws configure`
2. Ajuste `terraform/variables.tf` ou use `terraform.tfvars` para `s3_bucket` e `rs_admin_password`.
3. Rode:
   ```bash
   cd terraform
   terraform init
   terraform apply -var='s3_bucket=your-unique-bucket-name' -auto-approve
   ```
4. Exporte o endpoint do Redshift para uso pelo Ansible:
   ```bash
   export REDSHIFT_ENDPOINT="$(terraform output -raw redshift_endpoint)"
   export REDSHIFT_USER=adminuser
   export REDSHIFT_PASSWORD=ChangeMe123!
   ```
5. Suba o Glue script para o bucket e configure o job (opcional, manual for POC).
6. Rode o publisher localmente para encher o stream:
   ```bash
   pip install boto3
   AWS_REGION=sa-east-1 KINESIS_STREAM=marketing-events python3 publisher.py
   ```
7. Use QuickSight ou conecte-se ao Redshift Serverless para criar dashboards sobre `vw_daily_kpis` (criada pelo Ansible).

## Notas
- Os recursos Redshift Serverless podem gerar custos. Limpe com `terraform destroy` quando finalizar.
- Substitua senhas e nomes padrão por valores seguros antes de usar em produção.
