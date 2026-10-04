import json
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

PROJECT_ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    google_service_account_json: str | None = None
    service_account_path: str | None = None

    model_config = SettingsConfigDict(
        env_file=PROJECT_ROOT / ".env",
        extra="ignore",
    )

    def get_service_account_dict(self) -> dict:
        if self.google_service_account_json:
            return json.loads(self.google_service_account_json)
        if self.service_account_path:
            path = Path(self.service_account_path)
            if not path.is_absolute():
                path = PROJECT_ROOT / path
            return json.loads(path.read_text(encoding="utf-8"))
        raise ValueError(
            "Set GOOGLE_SERVICE_ACCOUNT_JSON or SERVICE_ACCOUNT_PATH in .env"
        )


settings = Settings()
