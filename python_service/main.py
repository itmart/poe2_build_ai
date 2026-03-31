from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class BuildScoreRequest(BaseModel):
    archetype: dict
    patch_impacts: list
    character_snapshot: dict | None = None

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/score_archetype")
def score_archetype(req: BuildScoreRequest):
    score = sum(item.get("impact_score", 0) for item in req.patch_impacts)
    return {
        "league_start_score": score,
        "confidence": 0.65
    }
