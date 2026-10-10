import json
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

PROJECT_ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    google_service_account_json: str | None = None
    service_account_path: str | None = None
    mobile_service_account_json: str | None = None
    mobile_service_account_path: str | None = None
    admin_username: str = "rafay"
    admin_password: str | None = None
    groq_api_key: str | None = None
    groq_chat_model: str = "qwen/qwen3.8-27b"
    groq_speech_model: str = "whisper-large-v3"

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

    def get_mobile_service_account_dict(self) -> dict:
        if self.mobile_service_account_json:
            return json.loads(self.mobile_service_account_json)
        if self.mobile_service_account_path:
            path = Path(self.mobile_service_account_path)
            if not path.is_absolute():
                path = PROJECT_ROOT / path
            return json.loads(path.read_text(encoding="utf-8"))
        raise ValueError(
            "Set MOBILE_SERVICE_ACCOUNT_JSON or MOBILE_SERVICE_ACCOUNT_PATH in .env"
        )


settings = Settings()
