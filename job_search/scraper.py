import httpx
from jobspy import scrape_jobs


def search_all(titles: list[str], remote_only: bool = True, results_per_title: int = 15) -> list[dict]:
    """Fetch jobs from LinkedIn, Indeed, ZipRecruiter, and RemoteOK."""
    jobs: list[dict] = []

    for title in titles:
        try:
            df = scrape_jobs(
                site_name=["linkedin", "indeed", "zip_recruiter"],
                search_term=title,
                location="Remote" if remote_only else "United States",
                is_remote=remote_only,
                results_wanted=results_per_title,
                country_indeed="USA",
                hours_old=336,  # 2 weeks
            )
            if df is not None and not df.empty:
                jobs.extend(df.to_dict("records"))
        except Exception as e:
            print(f"  [warn] Board search failed for '{title}': {e}")

    if remote_only:
        jobs.extend(_search_remoteok(titles))

    return _deduplicate(jobs)


def _search_remoteok(titles: list[str]) -> list[dict]:
    try:
        r = httpx.get(
            "https://remoteok.com/api",
            headers={"User-Agent": "job-search-tool/1.0"},
            timeout=20,
        )
        r.raise_for_status()
        data = r.json()
    except Exception:
        return []

    terms = [t.lower() for t in titles]
    results = []
    for item in data:
        if not isinstance(item, dict) or "position" not in item:
            continue
        text = f"{item.get('position', '')} {' '.join(item.get('tags', []))}".lower()
        if any(t in text for t in terms):
            results.append({
                "title": item.get("position", ""),
                "company": item.get("company", ""),
                "location": "Remote",
                "job_url": item.get("url", ""),
                "description": item.get("description", ""),
                "date_posted": item.get("date", ""),
                "site": "remoteok",
                "min_amount": item.get("salary_min"),
                "max_amount": item.get("salary_max"),
            })
    return results


def _deduplicate(jobs: list[dict]) -> list[dict]:
    seen: set[tuple] = set()
    unique: list[dict] = []
    for j in jobs:
        key = (str(j.get("title", "")).lower()[:60], str(j.get("company", "")).lower()[:40])
        if key not in seen:
            seen.add(key)
            unique.append(j)
    return unique
