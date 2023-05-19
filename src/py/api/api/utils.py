import secrets
from datetime import datetime, timezone


def now_iso_z():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


N_SECRET_BYTES = 32


def gen_secret_value() -> str:
    return secrets.token_urlsafe(N_SECRET_BYTES)
