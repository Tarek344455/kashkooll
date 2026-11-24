"""Parse every Supabase migration with libpg_query (via pglast).

Real PostgreSQL grammar validation without needing a running server:
    python supabase/validate_sql.py
Exits 0 only when every .sql file parses cleanly.
"""

from pathlib import Path
import sys

from pglast import parse_sql
from pglast.parser import ParseError

ROOT = Path(__file__).resolve().parent
FILES = sorted(ROOT.glob("migrations/*.sql")) + [ROOT / "seed.sql"]

failures = 0
for path in FILES:
    sql = path.read_text(encoding="utf-8")
    try:
        statements = parse_sql(sql)
        print(f"OK   {path.relative_to(ROOT).as_posix():<52} {len(statements)} statements")
    except ParseError as error:
        failures += 1
        print(f"FAIL {path.relative_to(ROOT).as_posix()}: {error}")

if failures:
    print(f"\n{failures} SQL file(s) failed to parse.")
    sys.exit(1)

print(f"\nAll {len(FILES)} SQL files parsed with the PostgreSQL grammar.")
