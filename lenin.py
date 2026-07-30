from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests
from bs4 import BeautifulSoup
import json
import uvicorn
import os

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class QueryPayload(BaseModel):
    tracking: str
    username: str = None
    pgp_key: str = None

@app.get("/track/{tracking_number}")
async def track_package(tracking_number: str):
    url = f"https://parcelsapp.com/en/tracking/{tracking_number}"
    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        resp = requests.get(url, headers=headers, timeout=10)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")
        items = []
        timeline_nodes = soup.select(".timeline-item")
        if not timeline_nodes:
            return {
                "status": "ok",
                "source": "mock",
                "items": [
                    {"date": "23 Jul 2026", "time": "10:22", "status": "DELIVERED", "location": "Houston, TX, US"},
                    {"date": "23 Jul 2026", "time": "09:40", "status": "OUT FOR DELIVERY TODAY", "location": "Houston, TX, US"},
                    {"date": "23 Jul 2026", "time": "09:20", "status": "LOADED ON DELIVERY VEHICLE", "location": "Houston, TX, US"},
                    {"date": "23 Jul 2026", "time": "08:08", "status": "Processing at UPS Facility", "location": "Houston, TX, US"},
                    {"date": "23 Jul 2026", "time": "08:08", "status": "The recovery intercept was successfully completed. / The address was corrected.", "location": "Houston, TX, US"}
                ]
            }
        for node in timeline_nodes:
            date_el = node.select_one(".date")
            status_el = node.select_one(".status")
            loc_el = node.select_one(".location")
            date_text = date_el.text.strip() if date_el else ""
            status_text = status_el.text.strip() if status_el else ""
            loc_text = loc_el.text.strip() if loc_el else ""
            parts = date_text.split()
            date_part = parts[0] + " " + parts[1] if len(parts) >= 2 else date_text
            time_part = parts[2] if len(parts) >= 3 else ""
            items.append({
                "date": date_part,
                "time": time_part,
                "status": status_text,
                "location": loc_text
            })
        return {"status": "ok", "source": "parcelsapp", "items": items}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict")
async def predict(payload: QueryPayload):
    if not payload.tracking:
        raise HTTPException(status_code=400, detail="Tracking number is required")
    prompt = f"""
    Given shipping tracking number: {payload.tracking}
    User: {payload.username if payload.username else 'anonymous'}
    Predict recipient name and full street address. Return JSON with keys: predicted_name, predicted_address, confidence_score, compiled_id.
    """
    try:
        ollama_url = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
        response = requests.post(
            ollama_url,
            json={"model": "mistral", "prompt": prompt, "stream": False},
            timeout=30
        )
        result_text = response.json().get("response", "{}")
        data = json.loads(result_text)
        data["compiled_id"] = f"WST-{hash(payload.tracking) % 100000:05d}"
        data["auth_user"] = payload.username or "anonymous"
        return data
    except Exception:
        return {
            "status": "error",
            "compiled_id": f"WST-{hash(payload.tracking) % 100000:05d}",
            "predicted_name": "John M. Carter",
            "predicted_address": "742 Evergreen Terrace, Springfield, IL 62701",
            "confidence_score": 0.65,
            "auth_user": payload.username or "anonymous"
        }

@app.get("/")
async def root():
    return {"message": "Ad Intelligence Module API"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)