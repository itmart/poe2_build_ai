from fastapi import FastAPI
from pydantic import BaseModel
from typing import Any, Dict, List, Optional


app = FastAPI()


class BuildScoreRequest(BaseModel):
    archetype: Dict[str, Any]
    patch_impacts: List[Dict[str, Any]]
    character_snapshot: Optional[Dict[str, Any]] = None


class UpgradePlanItem(BaseModel):
    slot: str
    reason: str
    target_stats: List[str]


class UpgradePriorityRequest(BaseModel):
    archetype: Dict[str, Any]
    character_snapshot: Dict[str, Any]
    general_issues: List[Dict[str, Any]]
    archetype_issues: List[Dict[str, Any]]
    weakest_slots: List[Dict[str, Any]]
    upgrade_plan: List[UpgradePlanItem]
    problem_focus: Optional[str] = None


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/score_archetype")
def score_archetype(req: BuildScoreRequest):
    base_score = sum(float(item.get("impact_score", 0)) for item in req.patch_impacts)

    archetype_name = (req.archetype or {}).get("name", "")

    bias = 0.0
    if "Deadeye" in archetype_name:
        bias += 0.25
    if "Pathfinder" in archetype_name:
        bias += 0.15
    if "Minion" in archetype_name:
        bias += 0.10

    final_score = round(base_score + bias, 2)

    return {
        "league_start_score": final_score,
        "confidence": 0.65 if req.patch_impacts else 0.45
    }


@app.post("/score_upgrade_plan")
def score_upgrade_plan(req: UpgradePriorityRequest):
    focus = (req.problem_focus or "").lower()
    archetype_name = (req.archetype or {}).get("name", "")

    scored = []

    for item in req.upgrade_plan:
        slot = item.slot
        score = 0.0

        if slot == "weapon":
            score += 100
        elif slot == "quiver":
            score += 55
        elif slot in {"ring1", "ring2", "amulet"}:
            score += 45
        elif slot in {"gloves", "boots", "belt", "helmet", "chest"}:
            score += 35
        else:
            score += 20

        if any("Weapon looks weak" in issue.get("message", "") for issue in req.general_issues):
            if slot == "weapon":
                score += 40

        if any("Elemental resistances are not capped" in issue.get("message", "") for issue in req.general_issues):
            if slot in {"ring1", "ring2", "boots", "gloves", "belt", "helmet", "chest"}:
                score += 20

        if any("Life is low" in issue.get("message", "") for issue in req.general_issues):
            if slot in {"ring1", "ring2", "boots", "gloves", "belt", "helmet", "chest"}:
                score += 15

        if focus == "damage":
            if slot in {"weapon", "quiver", "ring1", "ring2", "amulet", "gloves"}:
                score += 20
        elif focus == "bossing":
            if slot in {"weapon", "quiver", "amulet", "ring1", "ring2"}:
                score += 20
        elif focus == "survivability":
            if slot in {"boots", "gloves", "belt", "helmet", "chest", "ring1", "ring2"}:
                score += 25
        elif focus == "clear":
            if slot in {"weapon", "quiver", "boots", "gloves"}:
                score += 15
        elif focus == "mana":
            if slot in {"amulet", "ring1", "ring2", "belt"}:
                score += 20

        if archetype_name == "Lightning Bow Deadeye":
            if slot == "weapon":
                score += 20
            if slot == "quiver":
                score += 20
            if slot in {"ring1", "ring2"}:
                score += 10

        if archetype_name == "Poison Pathfinder":
            if slot == "weapon":
                score += 15
            if slot in {"ring1", "ring2", "amulet"}:
                score += 12

        if archetype_name == "Minion Infernalist":
            if slot == "weapon":
                score += 10
            if slot in {"helmet", "amulet"}:
                score += 15

        scored.append({
            "slot": slot,
            "reason": item.reason,
            "target_stats": item.target_stats,
            "python_priority_score": round(score, 2)
        })

    scored.sort(key=lambda row: row["python_priority_score"], reverse=True)

    ranked = []
    for idx, item in enumerate(scored[:3], start=1):
        ranked.append({
            "priority": idx,
            **item
        })

    return {
        "upgrade_plan": ranked,
        "confidence": 0.72
    }