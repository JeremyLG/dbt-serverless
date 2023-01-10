import json
import os
from typing import Any

from google.cloud import storage


class FileError(Exception):
    pass


def read_file(path: str) -> str:
    try:
        with open(path, "r") as f:
            return f.read()
    except (FileNotFoundError, PermissionError):
        raise FileError(f"Failed to read file: {path}")


def read_json_file(path: str) -> Any:
    _, file_extension = os.path.splitext(path)
    if file_extension != ".json":
        raise FileError(f"Unsupported file format: {file_extension}")
    content = read_file(path)
    try:
        return json.loads(content)
    except json.decoder.JSONDecodeError:
        raise FileError(f"Failed to parse JSON: {path}")


def write_file(path: str, data: str) -> None:
    try:
        with open(path, "w") as f:
            f.write(data)
    except (FileNotFoundError, PermissionError):
        raise FileError(f"Failed to write file: {path}")


def upload_blob(bucket_name: str, source_file_name: str, destination_blob_name: str) -> None:
    """Uploads a file to the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_name)
