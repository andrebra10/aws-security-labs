# Guía de despliegue

## Requisitos previos

- Cuenta de AWS (usa una cuenta de laboratorio, no de producción) con
  credenciales configuradas localmente (`aws configure` o variables de
  entorno `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`).
- Terraform >= 1.5.
- Tu propia IP pública (`curl ifconfig.me`), para restringir el acceso SSH.
- Acceso de escritura a `/etc/hosts` (Linux/macOS) o
  `C:\Windows\System32\drivers\etc\hosts` (Windows) en tu máquina de ataque.

El User Data de la instancia clona el código de la aplicación directamente
desde este repositorio público de GitHub
(`https://github.com/andrebra10/aws-security-labs.git`), así que no necesitas
subir nada tú mismo aparte de tener `terraform apply` en marcha.

## Pasos

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` y ajusta al menos `allowed_ssh_cidr` a tu propia IP
en formato CIDR (por ejemplo `198.51.100.23/32`). Nunca uses `0.0.0.0/0`.

```bash
terraform init
terraform plan
terraform apply
```

El `apply` tarda unos minutos: la creación de la instancia RDS es lo que más
tiempo consume. Una vez termine, Terraform mostrará varios outputs:

- `ec2_public_ip` — IP pública de la instancia.
- `hosts_file_entries` — las dos líneas listas para copiar a tu hosts file.
- `admin_ssh_command` — cómo entrar por SSH con el keypair generado (acceso
  de administración del laboratorio, no forma parte del pentest).
- `rds_endpoint` — endpoint interno de RDS (no accesible desde fuera de la VPC).
- `s3_bucket_name` — nombre real del bucket (con sufijo aleatorio).

## Configurar la resolución de nombres

Añade las líneas de `hosts_file_entries` a tu archivo hosts, por ejemplo:

```
34.201.xx.xx ppkconcesionario.com
34.201.xx.xx dev.ppkconcesionario.com
```

En Windows (PowerShell como administrador):

```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "34.201.xx.xx ppkconcesionario.com`n34.201.xx.xx dev.ppkconcesionario.com"
```

## Verificar que todo arrancó

El User Data instala Docker, clona el repositorio, genera los `.env` y
levanta `docker compose`. La aplicación puede tardar 3-5 minutos adicionales
en estar disponible mientras RDS termina de aceptar conexiones (los
contenedores reintentan la conexión a la base de datos automáticamente).

Con el keypair de administrador puedes revisar el progreso:

```bash
ssh -i generated/ppk-admin-key.pem ubuntu@<ec2_public_ip>
sudo tail -f /var/log/user-data.log
sudo docker compose -f /opt/ppk-portal/docker-compose.yml ps
```

Cuando `http://ppkconcesionario.com` responda con la landing page, el
laboratorio está listo para auditar.

## Destruir el laboratorio

```bash
cd terraform/environments/dev
terraform destroy
```
