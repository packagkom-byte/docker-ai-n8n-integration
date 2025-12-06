from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import docker
import ollama
import json
import os
import requests
from pathlib import Path

app = FastAPI(title="Docker AI Agent with n8n Integration")
docker_client = docker.from_env()

# Configurazione
SHARED_DIR = Path("/app/shared")
SHARED_DIR.mkdir(exist_ok=True)
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL", "http://host.docker.internal:5678")

class ChatRequest(BaseModel):
    message: str

class WebhookPayload(BaseModel):
    event: str
    data: dict

# ===== DOCKER TOOLS =====
def list_containers():
    """Elenca tutti i container Docker"""
    containers = docker_client.containers.list(all=True)
    return [{"name": c.name, "status": c.status, "id": c.short_id, "image": c.image.tags[0] if c.image.tags else "unknown"} for c in containers]

def start_container(container_name: str):
    """Avvia un container Docker"""
    try:
        container = docker_client.containers.get(container_name)
        container.start()
        return f"Container {container_name} avviato"
    except Exception as e:
        return f"Errore: {str(e)}"

def stop_container(container_name: str):
    """Ferma un container Docker"""
    try:
        container = docker_client.containers.get(container_name)
        container.stop()
        return f"Container {container_name} fermato"
    except Exception as e:
        return f"Errore: {str(e)}"

def list_shared_files():
    """Elenca file nella directory condivisa"""
    return [f.name for f in SHARED_DIR.iterdir() if f.is_file()]

# ===== TOOLS DEFINITION =====
tools = [
    {
        "type": "function",
        "function": {
            "name": "list_containers",
            "description": "Elenca tutti i container Docker disponibili",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "start_container",
            "description": "Avvia un container Docker specifico",
            "parameters": {
                "type": "object",
                "properties": {
                    "container_name": {"type": "string", "description": "Nome del container"}
                },
                "required": ["container_name"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "stop_container",
            "description": "Ferma un container Docker",
            "parameters": {
                "type": "object",
                "properties": {
                    "container_name": {"type": "string", "description": "Nome del container"}
                },
                "required": ["container_name"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_shared_files",
            "description": "Elenca i file nella directory condivisa",
            "parameters": {"type": "object", "properties": {}}
        }
    }
]

# ===== API ENDPOINTS =====
@app.get("/")
async def root():
    return {"message": "Docker AI Agent with n8n Integration", "status": "running"}

@app.post("/chat")
async def chat(request: ChatRequest):
    """Endpoint principale per chat con l'agente"""
    try:
        response = ollama.chat(
            model="llama3.1",
            messages=[{"role": "user", "content": request.message}],
            tools=tools
        )
        
        if response["message"].get("tool_calls"):
            results = []
            for tool_call in response["message"]["tool_calls"]:
                func_name = tool_call["function"]["name"]
                args = tool_call["function"].get("arguments", {})
                
                if func_name == "list_containers":
                    result = list_containers()
                elif func_name == "start_container":
                    result = start_container(args["container_name"])
                elif func_name == "stop_container":
                    result = stop_container(args["container_name"])
                elif func_name == "list_shared_files":
                    result = list_shared_files()
                else:
                    result = "Funzione non trovata"
                
                results.append({"function": func_name, "result": result})
            
            # Risposta finale con i risultati
            final_response = ollama.chat(
                model="llama3.1",
                messages=[
                    {"role": "user", "content": request.message},
                    response["message"],
                    {"role": "tool", "content": json.dumps(results)}
                ]
            )
            
            # Invia notifica a n8n
            try:
                requests.post(f"{N8N_WEBHOOK_URL}/webhook/agent-action", json={
                    "event": "tool_executed",
                    "message": request.message,
                    "results": results
                }, timeout=5)
            except:
                pass
            
            return {"response": final_response["message"]["content"], "tool_results": results}
        
        return {"response": response["message"]["content"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/files/upload")
async def upload_file(file: UploadFile = File(...)):
    """Carica un file nella directory condivisa"""
    try:
        file_path = SHARED_DIR / file.filename
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # Notifica n8n
        try:
            requests.post(f"{N8N_WEBHOOK_URL}/webhook/file-uploaded", json={
                "filename": file.filename,
                "size": len(content),
                "path": str(file_path)
            }, timeout=5)
        except:
            pass
        
        return {"message": f"File {file.filename} caricato", "path": str(file_path)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/files/{filename}")
async def download_file(filename: str):
    """Scarica un file dalla directory condivisa"""
    file_path = SHARED_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File non trovato")
    return FileResponse(file_path)

@app.get("/files")
async def list_files():
    """Lista tutti i file nella directory condivisa"""
    files = [{"name": f.name, "size": f.stat().st_size} for f in SHARED_DIR.iterdir() if f.is_file()]
    return {"files": files}

@app.post("/webhook/n8n")
async def receive_n8n_webhook(payload: WebhookPayload):
    """Riceve webhook da n8n"""
    return {"received": True, "event": payload.event, "data": payload.data}

@app.get("/health")
async def health():
    return {"status": "healthy", "n8n_url": N8N_WEBHOOK_URL}
