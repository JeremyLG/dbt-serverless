ARG build_for=linux/amd64

FROM --platform=$build_for python:3.10-slim-bullseye AS python_builder

ENV POETRY_VERSION 1.3.1
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONBUFFERED 1
ENV PIP_NO_CACHE_DIR 1

WORKDIR /usr/app

RUN pip install "poetry==${POETRY_VERSION}"

ENV VIRTUAL_ENV /opt/venv
RUN python -m venv ${VIRTUAL_ENV}
ENV PATH "${VIRTUAL_ENV}/bin:${PATH}"

COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root

# Copy in source files.
COPY README.md ./
COPY dbt_serverless dbt_serverless

# Manually build/install the package.
RUN poetry build && \
    pip install dist/*.whl

## Final Image
# The image used in the final image MUST match exactly to the python_builder image.
FROM python:3.10-slim-bullseye

# dbt System setup
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    ssh-client \
    software-properties-common \
    make \
    build-essential \
    ca-certificates \
    libpq-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONBUFFERED 1
ENV PIP_NO_CACHE_DIR 1
ENV VIRTUAL_ENV /opt/venv

ENV HOME /home/user
ENV APP_HOME ${HOME}/app

# Create the home directory for the new user.
RUN mkdir -p ${HOME}

# Create the user so the program doesn't run as root. This increases security of the container.
RUN groupadd -r user && \
    useradd -r -g user -d ${HOME} -s /sbin/nologin -c "Docker image user" user

# Setup application install directory.
RUN mkdir ${APP_HOME}

WORKDIR ${APP_HOME}

# Copy and activate pre-built virtual environment.
COPY --from=python_builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}
ENV PATH "${VIRTUAL_ENV}/bin:${PATH}"

COPY profiles.yml dbt_project dbt_project/

RUN chown -R user:user ${HOME}

ENTRYPOINT ["uvicorn", "dbt_serverless.main:app", "--host", "0.0.0.0", "--port", "8080"]
