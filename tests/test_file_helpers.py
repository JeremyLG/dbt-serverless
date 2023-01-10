import unittest
from unittest.mock import MagicMock, mock_open, patch

from dbt_serverless.lib.file_helpers import (
    FileError,
    read_file,
    read_json_file,
    upload_blob,
    write_file,
)


class TestFileHelpers(unittest.TestCase):
    @patch("builtins.open", new_callable=mock_open, read_data="data")
    def test_read_file(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path"
        assert read_file(path) == "data"
        mock_file.assert_called_once_with(path, "r")

    @patch("builtins.open", new_callable=mock_open, read_data="data")
    def test_read_file_error(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path"
        mock_file.side_effect = PermissionError
        self.assertRaises(FileError, read_file, path)
        mock_file.assert_called_once_with(path, "r")

    @patch("builtins.open", new_callable=mock_open, read_data="""{"data": "data"}""")
    def test_read_json_file(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path.json"
        assert read_json_file(path) == {"data": "data"}
        mock_file.assert_called_once_with(path, "r")

    @patch("builtins.open", new_callable=mock_open, read_data="data")
    def test_read_json_file_decode(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path.json"
        self.assertRaises(FileError, read_json_file, path)
        mock_file.assert_called_once_with(path, "r")

    @patch("builtins.open", new_callable=mock_open)
    def test_read_json_file_extension(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path.txt"
        self.assertRaises(FileError, read_json_file, path)
        mock_file.assert_not_called()

    @patch("builtins.open", new_callable=mock_open)
    def test_write_file(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path"
        data = "data"
        write_file(path, data)
        mock_file.assert_called_once_with(path, "w")

    @patch("builtins.open", new_callable=mock_open)
    def test_write_file_error(self, mock_file: MagicMock) -> None:
        path = "/some/arbitrary/path"
        data = "data"
        mock_file.side_effect = PermissionError
        self.assertRaises(FileError, write_file, path, data)
        mock_file.assert_called_once_with(path, "w")

    @patch("google.cloud.storage.Client")
    def test_upload_blob(self, mock_client: MagicMock) -> None:
        # Create a mock bucket and blob
        mock_bucket = mock_client.return_value.get_bucket.return_value
        mock_blob = mock_bucket.blob.return_value

        # Call the function
        upload_blob("my-bucket", "file.txt", "path/to/file.txt")

        # Assert that the mock blob's upload_from_filename method was called
        mock_blob.upload_from_filename.assert_called_once_with("file.txt")

        # Assert that the function call order
        mock_client.assert_called_once_with()
        mock_client.return_value.get_bucket.assert_called_once_with("my-bucket")
        mock_bucket.blob.assert_called_once_with("path/to/file.txt")
