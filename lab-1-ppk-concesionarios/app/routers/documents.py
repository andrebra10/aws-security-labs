import io
import os

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from auth import require_login
from config import settings
from database import get_db
from models import User
from templating import render

router = APIRouter()

# The "commercial documentation" feature only ever needs the marketing
# brochures stored under this prefix - it never lists or reads anything
# else in the bucket. The IAM role, however, is scoped to the whole bucket
# (see terraform/modules/iam), which is the actual security gap.
BROCHURES_PREFIX = "brochures/"


def _s3_client():
    return boto3.client("s3", region_name=settings.AWS_REGION)


@router.get("/documentos")
def list_documents(request: Request, user: User = Depends(require_login)):
    documents = []
    if settings.S3_BUCKET_NAME:
        try:
            client = _s3_client()
            response = client.list_objects_v2(
                Bucket=settings.S3_BUCKET_NAME, Prefix=BROCHURES_PREFIX
            )
            documents = [
                obj["Key"] for obj in response.get("Contents", []) if obj["Key"] != BROCHURES_PREFIX
            ]
        except (BotoCoreError, ClientError):
            documents = []
    return render(request, "documents.html", documents=documents, user=user)


@router.get("/documentos/{key:path}")
def download_document(key: str, user: User = Depends(require_login)):
    filename = os.path.basename(key)
    safe_key = f"{BROCHURES_PREFIX}{filename}"

    try:
        client = _s3_client()
        obj = client.get_object(Bucket=settings.S3_BUCKET_NAME, Key=safe_key)
    except (BotoCoreError, ClientError):
        raise HTTPException(status_code=404, detail="Documento no encontrado")

    return StreamingResponse(
        io.BytesIO(obj["Body"].read()),
        media_type=obj.get("ContentType", "application/octet-stream"),
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
