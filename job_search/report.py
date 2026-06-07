from rich.console import Console
from rich.panel import Panel

console = Console()


def show(jobs: list[dict], skills: list[str], total_raw: int, min_salary: int | None) -> None:
    salary_str = f"≥ ${min_salary:,}" if min_salary else "no filter"
    console.print(Panel.fit(
        f"[bold cyan]Job Search Results[/bold cyan]\n"
        f"[green]{len(jobs)}[/green] matches  (of {total_raw} fetched)  ·  "
        f"Remote / US  ·  Salary {salary_str}\n"
        f"Skills: {', '.join(skills[:8])}",
        border_style="cyan",
    ))

    if not jobs:
        console.print(
            "\n[yellow]No results matched your filters.[/yellow] "
            "Try [bold]--no-salary-filter[/bold] or add more titles in config.py."
        )
        return

    for i, j in enumerate(jobs[:30], 1):
        score = j["_score"]
        color = "green" if score >= 60 else "yellow" if score >= 35 else "dim"

        title = j.get("title") or "N/A"
        company = j.get("company") or "N/A"
        location = j.get("location") or "N/A"
        salary = _fmt_salary(j)
        source = j.get("site") or j.get("source") or ""
        url = j.get("job_url") or j.get("url") or ""
        reasons = j.get("_reasons", [])
        posted = j.get("date_posted") or ""

        console.print(f"\n[bold]{i}. {title}[/bold]  [{color}]({score}/100)[/{color}]")
        console.print(f"   [cyan]{company}[/cyan]  ·  {location}  ·  {salary}")
        if posted:
            console.print(f"   [dim]Posted: {posted}[/dim]")
        if reasons:
            console.print(f"   [dim]{' · '.join(reasons)}[/dim]")
        if url:
            console.print(f"   {url}")
        if source:
            console.print(f"   [dim]via {source}[/dim]")


def _fmt_salary(j: dict) -> str:
    lo, hi = j.get("min_amount"), j.get("max_amount")
    if lo and hi:
        return f"${int(lo):,}–${int(hi):,}"
    if lo:
        return f"${int(lo):,}+"
    if hi:
        return f"up to ${int(hi):,}"
    return "salary not listed"
