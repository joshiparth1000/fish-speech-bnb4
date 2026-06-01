FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ffmpeg \
    sox \
    libsox-dev \
    portaudio19-dev \
    python3.12 \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/groxaxo/fish-speech-int4-patch.git /app

RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip wheel setuptools
RUN pip install uv

# Use the fork’s own dependency setup where possible.
# If the repo script changes, inspect install_bnb4_3060.sh and mirror it here.
RUN chmod +x ./install_bnb4_3060.sh && ./install_bnb4_3060.sh || true

EXPOSE 8880

ENV GPU_INDEX=0
ENV PORT=8880
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

CMD ["bash", "-lc", "./start_bnb4_3060.sh"]
