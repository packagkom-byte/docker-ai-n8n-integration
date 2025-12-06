FROM python:3.11-slim

WORKDIR /app

# Installa le dipendenze
RUN pip install --no-cache-dir \
    docker \
    ollama \
    fastapi \
    uvicorn \
    python-multipart \
    requests

# Crea directory per i file condivisi
RUN mkdir -p /app/shared

# Copia il codice
COPY main.py .

# Esponi la porta
EXPOSE 8000

# Avvia l'applicazione
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
