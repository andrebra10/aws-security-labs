# Detección: qué vería el equipo azul

El laboratorio despliega también CloudTrail y GuardDuty (módulo
`terraform/modules/logging`), para poder repetir la misma cadena de ataque
y revisarla después desde el lado defensivo. Ninguno de los dos recursos
forma parte de la cadena de explotación; existen únicamente para observarla.

## Qué se despliega

- **CloudTrail**: un trail de la región (`is_multi_region_trail = false`,
  suficiente para este laboratorio de una sola región), con eventos de
  gestión de lectura y escritura, entregados a:
  - un bucket S3 dedicado y privado (`<project>-cloudtrail-xxxxxx`), para el
    histórico completo;
  - un log group de CloudWatch Logs (`/ppk/<project>-trail`), para
    consultarlo casi en tiempo real desde la consola sin esperar a la
    entrega en S3 (que puede tardar hasta ~15 minutos).
- **GuardDuty**: un detector a nivel de cuenta/región, con publicación de
  hallazgos cada 15 minutos (el intervalo más corto disponible), para que
  las alertas aparezcan lo antes posible durante una demo.

Outputs relevantes tras `terraform apply`: `cloudtrail_log_group_name`,
`cloudtrail_bucket_name`, `guardduty_detector_id`.

## Qué queda registrado en cada paso de la cadena de ataque

| Paso | ¿CloudTrail lo ve? | ¿GuardDuty lo ve? |
|---|---|---|
| Recon HTTP, LFI, filtración del `.env` | No. Son peticiones HTTP a la aplicación, no llamadas a la API de AWS. | No, por la misma razón. |
| Login SSH como `pepe`, escalada con `sudo less` | No. CloudTrail solo registra llamadas a la API de AWS, no actividad dentro del sistema operativo. | No directamente. Si `guardduty:EnableRuntimeMonitoring`/el agente de runtime estuviera activo podría detectar la ejecución de un shell inusual, pero **no está incluido en este laboratorio** (ver "Qué no cubre" más abajo). |
| Lectura del rol IAM desde el servicio de metadatos (`169.254.169.254`) | No hay llamada a la API de AWS todavía en este paso, solo una petición HTTP local dentro de la instancia. | No directamente, aunque GuardDuty sí monitoriza patrones de acceso al servicio de metadatos (IMDS) en algunos hallazgos de tipo `UnauthorizedAccess:EC2/MetadataDNSRebind` u otros relacionados con IMDS, no aplicables tal cual a este escenario. |
| Uso de `aws s3 ls` / `aws s3 cp` **desde la propia instancia EC2** | **Sí.** Cada llamada (`ListBucket`, `GetObject`) queda en CloudTrail, con el ARN del rol asumido (`ppk-ec2-role`) y la IP de origen (la de la propia instancia). Es una señal débil: el origen es el mismo que siempre usa ese rol. | Débil/nulo: GuardDuty no suele marcar tráfico S3 legítimo del propio rol si se origina desde la instancia esperada, salvo que el patrón de acceso (buckets, horario, volumen) se aleje mucho de lo habitual. |
| Uso de las credenciales temporales del rol **desde fuera de AWS** (por ejemplo, si el atacante las exporta a su propia máquina y ejecuta `aws s3 cp` desde allí) | **Sí**, en CloudTrail aparece el mismo `access_key_id` de sesión que la instancia, pero con una IP de origen que no es la de la instancia. | **Sí — este es el hallazgo estrella del laboratorio**: `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS`. GuardDuty detecta específicamente que credenciales emitidas a una instancia EC2 se están usando desde fuera de la red de AWS, que es exactamente lo que ocurre si el atacante saca las credenciales del rol fuera de la máquina comprometida. |

## Qué no cubre este laboratorio

- **VPC Flow Logs**: no se despliegan. Añadirlos permitiría ver el tráfico
  SSH/HTTP a nivel de red, pero no aportan nada nuevo sobre lo que ya
  cuenta esta guía a nivel de aplicación/API.
- **GuardDuty Runtime Monitoring / AWS Systems Manager**: no están
  desplegados. Con el agente de runtime activo, la ejecución de
  `sudo less` seguida de un shell (`/bin/sh`) podría generar hallazgos de
  ejecución de proceso sospechoso; queda fuera del alcance de este
  laboratorio para no añadir complejidad de agentes adicionales.
- **AWS Config**: no se despliega; no es necesario para observar esta
  cadena de ataque, cuyo impacto es de lectura de datos, no de cambios de
  configuración de infraestructura.

## Cómo revisarlo tras ejecutar el ataque

```bash
# Eventos de S3 sobre el bucket comprometido, vía CloudTrail (CLI)
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetObject \
  --max-results 20

# Hallazgos de GuardDuty
aws guardduty list-detectors
aws guardduty list-findings --detector-id <detector-id>
aws guardduty get-findings --detector-id <detector-id> --finding-ids <finding-id>
```

O directamente en la consola: **CloudWatch > Registros de logs >
`/ppk/<project>-trail`** para el histórico casi en tiempo real, y
**GuardDuty > Findings** para las alertas.
