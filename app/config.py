"""Application configuration management."""

from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Application
    app_name: str = "TravelMeetup API"
    environment: str = "development"
    debug: bool = True
    
    # Database
    database_url: str
    
    # JWT Configuration
    jwt_secret_key: str
    jwt_refresh_secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    
    # CORS - comma-separated string that will be parsed
    cors_origins: str = "http://localhost:3000,http://localhost:8000"
    
    # Azure Key Vault (optional)
    azure_key_vault_url: str = ""
    use_azure_key_vault: bool = False
    
    # Application Insights (optional)
    appinsights_connection_string: str = ""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins from comma-separated string."""
        return [origin.strip() for origin in self.cors_origins.split(",")]


# Global settings instance
settings = Settings()
