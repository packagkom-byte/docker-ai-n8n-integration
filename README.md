# 🐳 Docker AI Agent con Integrazione n8n

Agente AI per controllare Docker attraverso linguaggio naturale con integrazione n8n per scambio file e comunicazione webhook.

## ✨ Caratteristiche

- 🤖 **AI-Powered**: Usa Ollama con LLaMA 3.1 per interpretare comandi in linguaggio naturale
- 🐋 **Controllo Docker**: Gestisci container Docker tramite chat
- 📁 **Scambio File**: Upload/download file con directory condivisa
- 🔗 **Integrazione n8n**: Webhook bidirezionali per automazione
- 🚀 **API REST**: Endpoint completi per tutte le funzionalità

## 📋 Prerequisiti

- Docker e Docker Compose installati
- Almeno 8GB di RAM liberi (per Ollama)
- Connessione internet per scaricare i modelli

## 🚀 Installazione Rapida

### 1. Clona il Repository
```bash
git clone https://github.com/packagkom-byte/docker-ai-n8n-integration.git
cd docker-ai-n8n-integration
```

### 2. Configura Variabili d'Ambiente (Opzionale)
```bash
# Crea file .env
echo "N8N_WEBHOOK_URL=http://tuo-n8n-url:5678" > .env
```

### 3. Avvia i Container
```bash
docker compose up -d
```

### 4. Scarica il Modello LLaMA
```bash
docker exec -it ollama ollama pull llama3.1
```

### 5. Verifica l'Installazione
```bash
curl http://localhost:8000/health
```

## 💬 Utilizzo

### Chat con l'Agente
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Mostrami tutti i container Docker"}'
```

### Upload File
```bash
curl -X POST http://localhost:8000/files/upload \
  -F "file=@/path/to/file.txt"
```

### Download File
```bash
curl http://localhost:8000/files/nomefile.txt -o file-scaricato.txt
```

### Lista File Condivisi
```bash
curl http://localhost:8000/files
```

## 🔌 Integrazione con n8n

### Ricevere Notifiche dall'Agent

L'agent invia automaticamente webhook a n8n quando:
- Viene eseguito un tool Docker
- Viene caricato un file

Endpoint n8n da configurare:
- `POST /webhook/agent-action` - Notifica esecuzione comandi
- `POST /webhook/file-uploaded` - Notifica upload file

### Inviare Comandi a Agent da n8n

Usa il nodo HTTP Request in n8n:

```json
{
  "method": "POST",
  "url": "http://docker-ai-agent:8000/chat",
  "body": {
    "message": "{{$json.command}}"
  }
}
```

## 📡 API Endpoints

| Endpoint | Metodo | Descrizione |
|----------|--------|-------------|
| `/` | GET | Info generali |
| `/health` | GET | Health check |
| `/chat` | POST | Chat con l'agente |
| `/files` | GET | Lista file condivisi |
| `/files/upload` | POST | Upload file |
| `/files/{filename}` | GET | Download file |
| `/webhook/n8n` | POST | Ricevi webhook da n8n |

## 🛠️ Comandi Docker Supportati

- "Mostrami tutti i container"
- "Avvia il container [nome]"
- "Ferma il container [nome]"
- "Elenca i file condivisi"

## 📂 Struttura del Progetto

```
docker-ai-n8n-integration/
├── docker-compose.yml       # Configurazione servizi
├── agent/
│   ├── Dockerfile          # Immagine Python
│   └── main.py            # Applicazione FastAPI
└── README.md              # Questo file
```

## 🔧 Configurazione Avanzata

### Variabili d'Ambiente

- `OLLAMA_HOST`: URL del servizio Ollama (default: http://ollama:11434)
- `N8N_WEBHOOK_URL`: URL base per webhook n8n (default: http://host.docker.internal:5678)

### Volumi Docker

- `ollama-data`: Dati persistenti di Ollama
- `shared-files`: Directory condivisa per scambio file

## 🐛 Troubleshooting

### L'agent non risponde
```bash
# Verifica lo stato dei container
docker ps

# Controlla i log
docker logs docker-ai-agent
docker logs ollama
```

### Modello non trovato
```bash
# Scarica nuovamente il modello
docker exec -it ollama ollama pull llama3.1
```

### Webhook n8n non funzionano
- Verifica che n8n sia raggiungibile dall'agent
- Controlla la variabile `N8N_WEBHOOK_URL`
- Verifica i log: `docker logs docker-ai-agent`

## 🤝 Contribuire

I contributi sono benvenuti! Sentiti libero di aprire issue o pull request.

## 📝 Licenza

Questo progetto è open source e disponibile sotto licenza MIT.

## 🎯 Roadmap

- [ ] Supporto per più modelli LLM
- [ ] Dashboard web per gestione
- [ ] Autenticazione e sicurezza
- [ ] Più tool Docker (logs, stats, ecc.)
- [ ] Supporto per Docker Swarm/Kubernetes

## 💡 Esempi d'Uso

### Workflow n8n di Esempio

1. **Trigger**: Webhook riceve richiesta
2. **HTTP Request**: Invia comando all'agent
3. **Code**: Elabora risposta
4. **Action**: Esegui azione basata sul risultato

---

**Creato con ❤️ per automatizzare Docker con AI**
