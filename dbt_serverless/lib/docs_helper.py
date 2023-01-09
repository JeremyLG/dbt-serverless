import json
import logging

from google.cloud import storage

logger = logging.getLogger(__name__)
search_str = 'o=[i("manifest","manifest.json"+t),i("catalog","catalog.json"+t)]'

gcs = storage.Client()


def merge_dbt_docs() -> None:
    """Merge three dbt docs files in one single html final file."""
    with open("target/index.html", "r") as f:
        content_index = f.read()

    with open("target/manifest.json", "r") as f:
        json_manifest = json.loads(f.read())

    with open("target/catalog.json", "r") as f:
        json_catalog = json.loads(f.read())

    with open("target/index_merged.html", "w") as f:
        new_str = (
            "o=[{label: 'manifest', data: "
            + json.dumps(json_manifest)
            + "},{label: 'catalog', data: "
            + json.dumps(json_catalog)
            + "}]"
        )
        new_content = content_index.replace(search_str, new_str)
        f.write(new_content)


def upload_blob(bucket_name: str, source_file_name: str, destination_blob_name: str) -> None:
    """Uploads a file to the bucket."""
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)


def main() -> None:
    logger.info("Merging dbt docs in one single file")
    merge_dbt_docs()
    bucket = gcs.get_bucket("dbt-static-docs-bucket")
    logger.info("Uploading the file to GCS for static website serving")
    upload_blob(bucket, "target/index_merged.html", "index_merged.html")


if __name__ == "__main__":
    main()
