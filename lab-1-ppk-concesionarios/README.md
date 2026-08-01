# Lab 1 — PPK Concesionarios

Simulación realista de un pentest de caja negra sobre la infraestructura AWS
de una empresa ficticia de venta de vehículos, **PPK Concesionarios**. No es
un CTF: no hay flags, no hay `user.txt`/`root.txt`, no hay usuarios ni
carpetas con nombres de laboratorio. Todo (aplicación, infraestructura,
nombres, documentos) está pensado para parecer una auditoría real sobre una
empresa real.

## Historia

PPK Concesionarios vende vehículos nuevos y de ocasión desde
`ppkconcesionario.com`. Durante la modernización de su portal de gestión se
desplegó un entorno de desarrollo público, `dev.ppkconcesionario.com`, que
nunca se retiró tras finalizar el proyecto. La aplicación de producción es
segura; el entorno de desarrollo no lo es, y una cadena de pequeños errores
en él permite comprometer toda la infraestructura.

Documentación completa:

- [`docs/architecture.md`](docs/architecture.md) — recursos AWS y diagrama de red.
- [`docs/deployment.md`](docs/deployment.md) — cómo desplegar con Terraform y configurar el hosts file.
- [`docs/vulnerabilities.md`](docs/vulnerabilities.md) — explicación técnica de cada fallo.
- [`docs/attack-chain.md`](docs/attack-chain.md) — la cadena de ataque completa, paso a paso.
- [`docs/detection.md`](docs/detection.md) — qué queda registrado en CloudTrail/GuardDuty (lado defensivo).

## Estructura del repositorio

```
lab-1-ppk-concesionarios/
├── app/            # Aplicación FastAPI (Jinja2 + Bootstrap + SQLAlchemy)
├── terraform/       # Infraestructura como código (módulos + entorno dev)
└── docs/            # Documentación del laboratorio
```

## Alcance del pentest

El pentester parte únicamente de:

- la IP pública de la instancia
- los dominios `ppkconcesionario.com` y `dev.ppkconcesionario.com`

Sin usuarios, sin credenciales, sin acceso al código fuente. Todo lo demás
debe descubrirse durante la auditoría.

## Despliegue rápido

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# edita terraform.tfvars: pon tu propia IP pública en allowed_ssh_cidr
terraform init
terraform apply
```

Cuando termine, añade la IP pública de salida (`ec2_public_ip`) a tu archivo
hosts para `ppkconcesionario.com` y `dev.ppkconcesionario.com`. Detalles
completos en [`docs/deployment.md`](docs/deployment.md).

## Aviso

Este proyecto despliega intencionadamente una infraestructura vulnerable en
tu propia cuenta de AWS. Despliégalo solo en una cuenta de laboratorio,
mantenlo el mínimo tiempo posible y destrúyelo con `terraform destroy`
cuando termines (`terraform destroy` en `terraform/environments/dev`).
