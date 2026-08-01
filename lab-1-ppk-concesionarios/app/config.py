import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    APP_MODE: str = os.environ.get("APP_MODE", "production")
    SECRET_KEY: str = os.environ.get("SECRET_KEY", "dev-only-insecure-secret")

    DATABASE_URL: str = os.environ.get("DATABASE_URL", "sqlite:///./ppk_local.db")

    S3_BUCKET_NAME: str = os.environ.get("S3_BUCKET_NAME", "")
    AWS_REGION: str = os.environ.get("AWS_REGION", "eu-west-1")

    # Only meaningful when APP_MODE == "development": seeds a working login
    # for the portal and is also the Linux password for the 'pepe' account.
    DEV_USERNAME: str | None = os.environ.get("DEV_USERNAME")
    DEV_PASSWORD: str | None = os.environ.get("DEV_PASSWORD")

    @property
    def is_dev(self) -> bool:
        return self.APP_MODE == "development"

    @property
    def version_label(self) -> str:
        return "2.x-dev" if self.is_dev else "2.4.1"


settings = Settings()
