FROM python:3.11-slim

# These accounts exist because this image is built from the same base used
# for the company's golden EC2 image, and nobody stripped the provisioning
# users back out of the Dockerfile when it was adapted for the dev sandbox.
RUN useradd -M -s /usr/sbin/nologin -c "EC2 default user (image parity)" ubuntu \
    && useradd -M -s /usr/sbin/nologin -c "Deployment service account" deploy \
    && useradd -M -s /usr/sbin/nologin -c "Developer" pepe

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
