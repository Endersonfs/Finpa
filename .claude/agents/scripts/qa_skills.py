"""
QA Skills — Finpa
Execution skills for the qa-engineer agent.
Each skill is self-contained, safe, and returns structured results.
"""

import subprocess
import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent  # finpa/


# ─────────────────────────────────────────────
# TYPES
# ─────────────────────────────────────────────

class QAResult:
    def __init__(self, skill: str, passed: bool, data: dict, duration_ms: int):
        self.skill       = skill
        self.passed      = passed
        self.data        = data
        self.duration_ms = duration_ms
        self.timestamp   = datetime.utcnow().isoformat()

    def to_dict(self) -> dict:
        return {
            "skill":       self.skill,
            "passed":      self.passed,
            "data":        self.data,
            "duration_ms": self.duration_ms,
            "timestamp":   self.timestamp,
        }

    def __repr__(self) -> str:
        status = "✅ PASS" if self.passed else "❌ FAIL"
        return f"[{self.skill}] {status} ({self.duration_ms}ms)"


# ─────────────────────────────────────────────
# SKILL 1 — run_flutter_tests()
# ─────────────────────────────────────────────

def run_flutter_tests(
    test_path: str = "test/",
    timeout: int = 120,
    reporter: str = "compact",
) -> QAResult:
    """
    Run Flutter tests and parse results.

    Args:
        test_path: Path to test directory or specific test file.
        timeout:   Max seconds before killing the process.
        reporter:  Flutter test reporter ('compact', 'expanded', 'json').

    Returns:
        QAResult with passed/failed counts and failure details.
    """
    start = time.monotonic()
    full_path = PROJECT_ROOT / test_path

    if not full_path.exists():
        return QAResult(
            skill="run_flutter_tests",
            passed=False,
            data={"error": f"Test path not found: {full_path}"},
            duration_ms=0,
        )

    cmd = [
        "flutter", "test", str(test_path),
        f"--reporter={reporter}",
    ]
    if reporter == "json":
        cmd.append("--machine")

    try:
        result = subprocess.run(
            cmd,
            cwd=str(PROJECT_ROOT),
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return QAResult(
            skill="run_flutter_tests",
            passed=False,
            data={"error": f"Tests timed out after {timeout}s"},
            duration_ms=int((time.monotonic() - start) * 1000),
        )
    except FileNotFoundError:
        return QAResult(
            skill="run_flutter_tests",
            passed=False,
            data={"error": "flutter command not found. Is Flutter in PATH?"},
            duration_ms=0,
        )

    duration_ms = int((time.monotonic() - start) * 1000)
    stdout      = result.stdout or ""
    stderr      = result.stderr or ""

    # Parse output for counts
    passed_count  = stdout.count("+") if "+" in stdout else 0
    failed_count  = stdout.count("-") if "-" in stdout else 0
    all_passed    = result.returncode == 0

    # Extract failing test names
    failures = []
    for line in (stdout + stderr).splitlines():
        if "FAILED" in line or "EXCEPTION" in line or "Error:" in line:
            failures.append(line.strip())

    return QAResult(
        skill="run_flutter_tests",
        passed=all_passed,
        data={
            "return_code":   result.returncode,
            "passed_count":  passed_count,
            "failed_count":  failed_count,
            "failures":      failures[:20],      # cap at 20 lines
            "stdout_tail":   stdout[-2000:],     # last 2000 chars
            "stderr_tail":   stderr[-500:],
            "command":       " ".join(cmd),
        },
        duration_ms=duration_ms,
    )


# ─────────────────────────────────────────────
# SKILL 2 — check_supabase()
# ─────────────────────────────────────────────

def check_supabase(timeout: int = 10) -> QAResult:
    """
    Validate Supabase configuration and connectivity.

    Checks:
    - .env exists and has required keys
    - SUPABASE_URL is reachable (HTTP GET to /rest/v1/)
    - ANON_KEY is present and non-empty

    Returns:
        QAResult with connectivity status and config issues.
    """
    start  = time.monotonic()
    issues = []
    checks = {}

    # 1. Check .env file
    env_path = PROJECT_ROOT / ".env"
    if not env_path.exists():
        return QAResult(
            skill="check_supabase",
            passed=False,
            data={"error": ".env file not found", "path": str(env_path)},
            duration_ms=int((time.monotonic() - start) * 1000),
        )

    # 2. Parse .env
    env_vars: dict[str, str] = {}
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, val = line.partition("=")
            env_vars[key.strip()] = val.strip()

    # 3. Validate required keys
    required = ["SUPABASE_URL", "SUPABASE_ANON_KEY"]
    for key in required:
        val = env_vars.get(key, "")
        present = bool(val)
        checks[key] = "✅ present" if present else "❌ missing or empty"
        if not present:
            issues.append(f"{key} is missing or empty in .env")

    supabase_url = env_vars.get("SUPABASE_URL", "")
    anon_key     = env_vars.get("SUPABASE_ANON_KEY", "")

    # 4. Check URL format
    if supabase_url and not supabase_url.startswith("https://"):
        issues.append("SUPABASE_URL must start with https://")
        checks["url_format"] = "❌ invalid"
    elif supabase_url:
        checks["url_format"] = "✅ valid"

    # 5. Connectivity check
    reachable    = False
    http_status  = None
    if supabase_url and anon_key:
        health_url = f"{supabase_url.rstrip('/')}/rest/v1/"
        req = urllib.request.Request(
            health_url,
            headers={
                "apikey":        anon_key,
                "Authorization": f"Bearer {anon_key}",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                http_status = resp.status
                reachable   = http_status < 500
        except urllib.error.HTTPError as e:
            http_status = e.code
            # 200, 400, 401 all mean Supabase is up
            reachable = e.code < 500
        except (urllib.error.URLError, OSError) as e:
            issues.append(f"Cannot reach Supabase: {e}")

    checks["reachable"]    = "✅ yes" if reachable else "❌ no"
    checks["http_status"]  = http_status

    # 6. Check Supabase guard in code
    guard_ok = False
    router_path = PROJECT_ROOT / "lib" / "router" / "app_router.dart"
    if router_path.exists():
        content  = router_path.read_text(encoding="utf-8")
        guard_ok = "_supabaseReady" in content or "try {" in content
    checks["code_guard"] = "✅ present" if guard_ok else "⚠️ not found"
    if not guard_ok:
        issues.append("No Supabase initialization guard found in app_router.dart")

    passed = len(issues) == 0 and reachable

    return QAResult(
        skill="check_supabase",
        passed=passed,
        data={
            "checks": checks,
            "issues": issues,
            "env_path": str(env_path),
        },
        duration_ms=int((time.monotonic() - start) * 1000),
    )


# ─────────────────────────────────────────────
# SKILL 3 — check_api_health(url)
# ─────────────────────────────────────────────

def check_api_health(
    url: str,
    expected_status: int = 200,
    timeout: int = 10,
    headers: dict | None = None,
) -> QAResult:
    """
    Check if an API endpoint is healthy.

    Args:
        url:             Full URL to check (GET request).
        expected_status: Expected HTTP status code.
        timeout:         Max seconds to wait.
        headers:         Optional request headers.

    Returns:
        QAResult with status, latency, and error details.
    """
    start = time.monotonic()

    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status   = resp.status
            body_raw = resp.read(4096)
            latency  = int((time.monotonic() - start) * 1000)

            # Try parse JSON
            body: Any = None
            try:
                body = json.loads(body_raw)
            except (json.JSONDecodeError, UnicodeDecodeError):
                body = body_raw.decode("utf-8", errors="replace")[:500]

            passed = status == expected_status
            return QAResult(
                skill="check_api_health",
                passed=passed,
                data={
                    "url":             url,
                    "status":          status,
                    "expected_status": expected_status,
                    "latency_ms":      latency,
                    "body_preview":    body,
                },
                duration_ms=latency,
            )

    except urllib.error.HTTPError as e:
        latency = int((time.monotonic() - start) * 1000)
        passed  = e.code == expected_status
        return QAResult(
            skill="check_api_health",
            passed=passed,
            data={
                "url":             url,
                "status":          e.code,
                "expected_status": expected_status,
                "latency_ms":      latency,
                "error":           str(e.reason),
            },
            duration_ms=latency,
        )

    except (urllib.error.URLError, OSError, TimeoutError) as e:
        latency = int((time.monotonic() - start) * 1000)
        return QAResult(
            skill="check_api_health",
            passed=False,
            data={
                "url":    url,
                "error":  str(e),
                "status": None,
            },
            duration_ms=latency,
        )


# ─────────────────────────────────────────────
# SKILL 4 — generate_report(findings)
# ─────────────────────────────────────────────

def generate_report(
    findings: list[dict],
    qa_results: list[QAResult] | None = None,
    output_path: str | None = None,
) -> QAResult:
    """
    Generate a structured QA report from findings and skill results.

    Args:
        findings:    List of bug dicts with keys:
                     title, severity, route, steps, actual,
                     expected, cause, fix
        qa_results:  Optional list of QAResult from other skills.
        output_path: If provided, write report to this file path.

    Returns:
        QAResult with the full report as a string in data['report'].
    """
    start = time.monotonic()

    severity_order = {"Crítico": 0, "Alto": 1, "Medio": 2, "Bajo": 3}
    sorted_findings = sorted(
        findings,
        key=lambda f: severity_order.get(f.get("severity", "Bajo"), 99),
    )

    counts = {s: 0 for s in severity_order}
    for f in sorted_findings:
        sev = f.get("severity", "Bajo")
        if sev in counts:
            counts[sev] += 1

    now    = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines  = []

    # ── Header ──────────────────────────────
    lines += [
        "# QA Report — Finpa",
        f"**Generado:** {now}",
        f"**Total bugs:** {len(findings)}",
        "",
        "## Resumen",
        "",
        f"| Severidad | Cantidad |",
        f"|---|---|",
        f"| 🔴 Crítico | {counts['Crítico']} |",
        f"| 🟠 Alto    | {counts['Alto']} |",
        f"| 🟡 Medio   | {counts['Medio']} |",
        f"| 🟢 Bajo    | {counts['Bajo']} |",
        "",
    ]

    # ── Skill Results ────────────────────────
    if qa_results:
        lines += ["## Resultados de Ejecución", ""]
        for r in qa_results:
            icon = "✅" if r.passed else "❌"
            lines.append(f"### {icon} {r.skill} ({r.duration_ms}ms)")

            if r.skill == "run_flutter_tests" and not r.passed:
                d = r.data
                lines += [
                    f"- Tests pasados: {d.get('passed_count', '?')}",
                    f"- Tests fallidos: {d.get('failed_count', '?')}",
                ]
                for fail in d.get("failures", [])[:5]:
                    lines.append(f"  - `{fail}`")

            elif r.skill == "check_supabase":
                for key, val in r.data.get("checks", {}).items():
                    lines.append(f"- {key}: {val}")
                for issue in r.data.get("issues", []):
                    lines.append(f"  - ⚠️ {issue}")

            elif r.skill == "check_api_health":
                d = r.data
                lines += [
                    f"- URL: `{d.get('url')}`",
                    f"- Status: {d.get('status')} (esperado {d.get('expected_status')})",
                    f"- Latencia: {d.get('latency_ms')}ms",
                ]
                if d.get("error"):
                    lines.append(f"- Error: {d['error']}")

            lines.append("")

    # ── Correlation: Frontend + Backend ─────
    if qa_results:
        frontend_bugs = [f for f in findings if f.get("severity") in ("Crítico", "Alto")]
        backend_fail  = any(
            not r.passed for r in qa_results
            if r.skill in ("check_supabase", "check_api_health")
        )
        test_fail     = any(not r.passed for r in qa_results if r.skill == "run_flutter_tests")

        if backend_fail and frontend_bugs:
            lines += [
                "## ⚠️ Correlación Detectada",
                "",
                "Los bugs críticos/altos en la UI pueden estar causados por",
                "fallos en el backend. Prioriza estabilizar Supabase/API antes",
                "de investigar problemas de presentación.",
                "",
            ]
        if test_fail and frontend_bugs:
            lines += [
                "## ⚠️ Tests Fallidos + Bugs UI",
                "",
                "Hay tests fallidos y bugs UI simultáneamente.",
                "Los tests fallidos pueden estar enmascarando bugs adicionales.",
                "Arregla los tests primero para tener una línea base confiable.",
                "",
            ]

    # ── Bug Details ──────────────────────────
    lines += ["## Bugs Encontrados", ""]

    severity_icons = {"Crítico": "🔴", "Alto": "🟠", "Medio": "🟡", "Bajo": "🟢"}

    for i, bug in enumerate(sorted_findings, 1):
        sev  = bug.get("severity", "Bajo")
        icon = severity_icons.get(sev, "⚪")
        lines += [
            f"### {icon} Bug #{i}: {bug.get('title', 'Sin título')}",
            "",
            f"**Severidad:** {sev}",
            f"**Pantalla/Ruta:** `{bug.get('route', 'N/A')}`",
            "",
            "**Reproducción:**",
        ]
        for j, step in enumerate(bug.get("steps", []), 1):
            lines.append(f"{j}. {step}")
        lines += [
            "",
            f"**Resultado actual:** {bug.get('actual', 'N/A')}",
            f"**Resultado esperado:** {bug.get('expected', 'N/A')}",
            f"**Causa probable:** `{bug.get('cause', 'N/A')}`",
            f"**Fix sugerido:** {bug.get('fix', 'N/A')}",
            "",
            "---",
            "",
        ]

    # ── Footer ───────────────────────────────
    lines += [
        "## Próximos Pasos",
        "",
        "1. Arreglar todos los bugs **Críticos** antes del próximo build",
        "2. Revisar bugs **Altos** en el mismo sprint",
        "3. Bugs **Medios** y **Bajos** en el backlog",
        "",
        "_Generado por qa-engineer agent — Finpa QA System_",
    ]

    report = "\n".join(lines)

    # Write to file if requested
    if output_path:
        try:
            out = Path(output_path)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(report, encoding="utf-8")
        except OSError as e:
            return QAResult(
                skill="generate_report",
                passed=False,
                data={"error": f"Could not write report: {e}"},
                duration_ms=int((time.monotonic() - start) * 1000),
            )

    return QAResult(
        skill="generate_report",
        passed=True,
        data={
            "report":        report,
            "total_bugs":    len(findings),
            "counts":        counts,
            "output_path":   output_path,
        },
        duration_ms=int((time.monotonic() - start) * 1000),
    )


# ─────────────────────────────────────────────
# ORCHESTRATOR — run_full_qa()
# ─────────────────────────────────────────────

def run_full_qa(
    supabase_url: str | None = None,
    extra_urls: list[str] | None = None,
    run_tests: bool = True,
    output_path: str = "qa_report.md",
) -> dict:
    """
    Run all QA skills in sequence and generate a combined report.
    This is the main entry point for a full QA run.

    Args:
        supabase_url: Override URL (reads from .env if None).
        extra_urls:   Additional API endpoints to health-check.
        run_tests:    Whether to run Flutter tests (skip if disk is full).
        output_path:  Where to save the final report.

    Returns:
        Dict with all results and the final report path.
    """
    print("🚀 Starting Finpa QA Run...")
    results: list[QAResult] = []

    # 1. Check Supabase
    print("  → Checking Supabase...")
    supabase_result = check_supabase()
    results.append(supabase_result)
    print(f"     {supabase_result}")

    # 2. Health-check extra URLs
    for url in (extra_urls or []):
        print(f"  → Checking API: {url}")
        api_result = check_api_health(url)
        results.append(api_result)
        print(f"     {api_result}")

    # 3. Run Flutter tests (skip if disk is full)
    if run_tests:
        print("  → Running Flutter tests...")
        test_result = run_flutter_tests()
        results.append(test_result)
        print(f"     {test_result}")

    # 4. Collect findings from failed skills
    auto_findings: list[dict] = []

    for r in results:
        if not r.passed:
            if r.skill == "check_supabase":
                for issue in r.data.get("issues", []):
                    auto_findings.append({
                        "title":    f"Supabase: {issue}",
                        "severity": "Crítico",
                        "route":    "main.dart / app_router.dart",
                        "steps":    ["Iniciar la app sin credenciales Supabase"],
                        "actual":   issue,
                        "expected": "Supabase inicializado correctamente",
                        "cause":    ".env",
                        "fix":      "Completar credenciales en .env",
                    })
            elif r.skill == "run_flutter_tests":
                for fail in r.data.get("failures", [])[:5]:
                    auto_findings.append({
                        "title":    f"Test fallido: {fail[:60]}",
                        "severity": "Alto",
                        "route":    "test/",
                        "steps":    ["Ejecutar flutter test"],
                        "actual":   fail,
                        "expected": "Test pasa",
                        "cause":    "test/",
                        "fix":      "Revisar el test y el código fuente",
                    })

    # 5. Generate report
    print("  → Generating report...")
    report_path = str(PROJECT_ROOT / output_path)
    report_result = generate_report(
        findings=auto_findings,
        qa_results=results,
        output_path=report_path,
    )
    results.append(report_result)

    overall_pass = all(r.passed for r in results if r.skill != "generate_report")
    print(f"\n{'✅ QA PASSED' if overall_pass else '❌ QA FAILED'}")
    print(f"📄 Report: {report_path}")

    return {
        "passed":    overall_pass,
        "results":   [r.to_dict() for r in results],
        "report":    report_result.data.get("report", ""),
        "report_path": report_path,
    }


# ─────────────────────────────────────────────
# CLI Entry Point
# ─────────────────────────────────────────────

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Finpa QA Skills Runner")
    parser.add_argument("--skill", choices=[
        "tests", "supabase", "health", "report", "full"
    ], default="full", help="Skill to run")
    parser.add_argument("--url",      help="URL for check_api_health")
    parser.add_argument("--no-tests", action="store_true", help="Skip flutter tests")
    parser.add_argument("--output",   default="qa_report.md", help="Report output path")
    args = parser.parse_args()

    if args.skill == "tests":
        r = run_flutter_tests()
        print(json.dumps(r.to_dict(), indent=2, ensure_ascii=False))

    elif args.skill == "supabase":
        r = check_supabase()
        print(json.dumps(r.to_dict(), indent=2, ensure_ascii=False))

    elif args.skill == "health":
        if not args.url:
            print("Error: --url is required for health check")
            sys.exit(1)
        r = check_api_health(args.url)
        print(json.dumps(r.to_dict(), indent=2, ensure_ascii=False))

    elif args.skill == "report":
        # Example with dummy findings
        sample = [{
            "title":    "Ejemplo de bug",
            "severity": "Medio",
            "route":    "/dashboard",
            "steps":    ["Abrir dashboard", "Observar"],
            "actual":   "Algo incorrecto",
            "expected": "Algo correcto",
            "cause":    "dashboard_screen.dart:80",
            "fix":      "Corregir el widget",
        }]
        r = generate_report(findings=sample, output_path=args.output)
        print(r.data.get("report", ""))

    else:  # full
        result = run_full_qa(
            run_tests=not args.no_tests,
            output_path=args.output,
        )
        sys.exit(0 if result["passed"] else 1)
