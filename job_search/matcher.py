_CX_KEYWORDS = {"customer", "cx", "service", "care", "support", "experience", "client"}
_DIR_KEYWORDS = {"director", "vp", "vice president", "head of", "senior director", "chief"}


def filter_and_rank(
    jobs: list[dict],
    skills: list[str],
    preferred_titles: list[str],
    min_salary: int | None = None,
) -> list[dict]:
    scored = []
    for j in jobs:
        score, reasons = _score(j, skills, preferred_titles)
        if score == 0:
            continue
        if min_salary and not _salary_ok(j, min_salary):
            continue
        j = dict(j)
        j["_score"] = score
        j["_reasons"] = reasons
        scored.append(j)

    scored.sort(key=lambda j: j["_score"], reverse=True)
    return scored


def _score(job: dict, skills: list[str], preferred_titles: list[str]) -> tuple[int, list[str]]:
    title = str(job.get("title", "")).lower()
    desc = str(job.get("description", "")).lower()
    combined = f"{title} {desc}"
    score = 0
    reasons: list[str] = []

    for pt in preferred_titles:
        if pt.lower() in title:
            score += 40
            reasons.append(f"Title: {pt}")
            break
    else:
        cx_hit = any(k in title for k in _CX_KEYWORDS)
        dir_hit = any(k in title for k in _DIR_KEYWORDS)
        if cx_hit:
            score += 10
        if dir_hit:
            score += 15

    matched = [s for s in skills if s.lower() in combined]
    score += min(len(matched) * 3, 30)
    if matched:
        reasons.append(f"Skills: {', '.join(matched[:6])}")

    return min(score, 100), reasons


def _salary_ok(job: dict, min_salary: int) -> bool:
    lo, hi = job.get("min_amount"), job.get("max_amount")
    if lo is None and hi is None:
        return True  # no salary listed → don't exclude
    best = max(x for x in [lo, hi] if x is not None)
    return best >= min_salary
