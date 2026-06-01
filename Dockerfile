FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    wget \
    ca-certificates \
    ffmpeg \
    sox \
    libsox-dev \
    libsndfile1 \
    portaudio19-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# This fork's recommended installer/startup flow is Conda-based.
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
ENV CONDA_EXE=${CONDA_DIR}/bin/conda

RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p ${CONDA_DIR} \
    && rm -f /tmp/miniconda.sh \
    && conda clean -afy

WORKDIR /app

RUN git clone https://github.com/groxaxo/fish-speech-int4-patch.git /app

ENV ENV_NAME=fish-speech-bnb4
ENV PYTHON_VERSION=3.12

# Create the same kind of dedicated Conda environment expected by this fork,
# but do NOT download model weights into the image. The model is mounted from /data.
RUN conda create -y -n ${ENV_NAME} python=${PYTHON_VERSION} \
    && conda run -n ${ENV_NAME} python -m pip install --upgrade pip setuptools wheel \
    && conda run -n ${ENV_NAME} python -m pip install -e ".[bnb]" --extra-index-url https://download.pytorch.org/whl/cu128 \
    && conda clean -afy

EXPOSE 8880

ENV HOST=0.0.0.0
ENV PORT=8880
ENV CHECKPOINT_DIR=/app/checkpoints/s2-pro
ENV MAX_SEQ_LEN=4096
ENV IDLE_TIMEOUT_SECONDS=300
ENV CUDA_VISIBLE_DEVICES=0
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Use the direct API entrypoint recommended by the model/project docs.
# This avoids the startup script's Conda detection edge cases while keeping the same bnb4/half path.
CMD ["bash", "-lc", "PYTHONPATH=/app conda run --no-capture-output -n ${ENV_NAME} python tools/api_server.py --checkpoint-path ${CHECKPOINT_DIR} --bnb4 --half --host ${HOST} --port ${PORT}"]
