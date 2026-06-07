#!/usr/bin/env python3
"""Search for job openings matched to your resume profile.

Usage:
    python job_search/main.py
    python job_search/main.py --no-salary-filter
    python job_search/main.py --min-salary 140000
    python job_search/main.py --titles "VP Customer Experience" "Director CX"
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from rich.console import Console
import config
from scraper import search_all
from matcher import filter_and_rank
from report import show

console = Console()


def main() -> None:
    ap = argparse.ArgumentParser(description="Search jobs tailored to your resume")
    ap.add_argument(
        "--titles", nargs="+", default=config.PREFERRED_TITLES,
        help="Job titles to search for (overrides config.py)",
    )
    ap.add_argument(
        "--min-salary", type=int, default=config.MIN_SALARY,
        help=f"Minimum salary threshold (default: {config.MIN_SALARY:,})",
    )
    ap.add_argument(
        "--no-salary-filter", action="store_true",
        help="Include jobs regardless of listed salary",
    )
    ap.add_argument(
        "--limit", type=int, default=config.RESULTS_PER_TITLE,
        help="Max results to fetch per title per board",
    )
    args = ap.parse_args()

    titles = args.titles
    min_salary = None if args.no_salary_filter else args.min_salary

    console.print(f"\n[dim]Searching: {', '.join(titles[:3])}{'…' if len(titles) > 3 else ''}[/dim]")
    if min_salary:
        console.print(f"[dim]Filters: remote · US · salary ≥ ${min_salary:,}[/dim]")
    else:
        console.print("[dim]Filters: remote · US · no salary filter[/dim]")

    jobs = search_all(titles, remote_only=config.REMOTE_ONLY, results_per_title=args.limit)
    console.print(f"[dim]Fetched {len(jobs)} raw listings[/dim]\n")

    matched = filter_and_rank(jobs, config.SKILLS, titles, min_salary=min_salary)
    show(matched, config.SKILLS, total_raw=len(jobs), min_salary=min_salary)


if __name__ == "__main__":
    main()
