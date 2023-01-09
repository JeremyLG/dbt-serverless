# `dbt-serverless` User Guide

!!! info

    For more information on how this was built and deployed, as well as other Python best
    practices, see [`dbt-serverless`](https://github.com/JeremyLG/dbt-serverless).

!!! info

    This user guide is purely an illustrative example that shows off several features of 
    [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) and included Markdown
    extensions[^1].

[^1]: See `dbt-serverless`'s `mkdocs.yml` for how to enable these features.

## Installation

First, [install Poetry](https://python-poetry.org/docs/#installation):

=== "Linux/macOS"

    ```bash
    curl -sSL https://install.python-poetry.org | python3 -
    ```

=== "Windows"

    ```powershell
    (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
    ```

Then install the `fact` package and its dependencies:

```bash
poetry install
```

Activate the virtual environment created automatically by Poetry:

```bash
poetry shell
```
