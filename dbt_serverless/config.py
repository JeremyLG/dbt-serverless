from pydantic import BaseSettings


class Settings(BaseSettings):
    app_name: str = "ZeroDTE"

    PROJECT_ID: str
    DBT_DATASET: str
    DBT_PROJECT: str
    DBT_PROFILES_YML: str

    class Config:
        env_file = ".env"
        case_sensitive = False
