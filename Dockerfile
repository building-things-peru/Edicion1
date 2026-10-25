FROM python:3.12-slim-trixie

# ffmpeg corta, hace zoom y dibuja los subtítulos
RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# Hugging Face corre los Spaces con el usuario 1000
RUN useradd -m -u 1000 user
ENV HOME=/home/user \
    HF_HOME=/home/user/.cache/huggingface \
    DATA_DIR=/tmp/autoedit-jobs \
    PYTHONUNBUFFERED=1
WORKDIR /home/user/app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

USER user
# Descarga el modelo de voz al construir, así el primer video no espera.
ARG WHISPER_MODEL=small
ENV WHISPER_MODEL=${WHISPER_MODEL}
RUN python -c "from faster_whisper import WhisperModel as W; W('${WHISPER_MODEL}', device='cpu', compute_type='int8')"

COPY --chown=user . .
EXPOSE 7860
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
