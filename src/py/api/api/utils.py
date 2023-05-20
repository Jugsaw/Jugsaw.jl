from datetime import datetime, timezone


def now_iso_z() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
