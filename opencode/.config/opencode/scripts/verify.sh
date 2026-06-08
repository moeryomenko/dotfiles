#!/bin/bash
# Pre-push gate — MUST pass before any commit in the opencode config repo
set -euo pipefail

echo "=== CI Gate ==="
pass=true

# 1. Validate all skill frontmatter
echo "[1/5] Validating skills..."
if python3 scripts/validate-skills; then
    echo "  Skills: OK"
else
    echo "  Skills: FAILED"
    pass=false
fi

# 2. Validate agent config JSON
echo "[2/5] Validating opencode.json..."
if python3 -c "import json; json.load(open('opencode.json')); print('  OK')" 2>/dev/null; then
    echo "  Config: OK"
else
    echo "  Config: FAILED (invalid JSON)"
    pass=false
fi

# 3. Check all referenced prompt files exist
echo "[3/5] Checking prompt files..."
errors=0
python3 -c "
import json, os, sys
d = json.load(open('opencode.json'))
errors = 0
for name, cfg in d.get('agent', {}).items():
    prompt = cfg.get('prompt', '')
    if prompt.startswith('{file:./'):
        # Extract path from {file:./prompts/xxx.md}
        path = prompt[8:-1]  # strip '{file:./' and '}'
        if os.path.isfile(path):
            print(f'  {name}: OK ({path})')
        else:
            print(f'  {name}: MISSING ({path})')
            errors += 1
if errors == 0:
    print('  All prompt files: OK')
sys.exit(1 if errors > 0 else 0)
" 2>/dev/null || pass=false

# 4. Verify all referenced skills exist
# Note: create-specification is a bundled skill at ~/.agents/skills/
echo "[4/5] Checking skills..."
errors=0
python3 -c "
import json, os, sys

# Bundled skills that are not in local skills/ dir
bundled_skills = {'create-specification', 'find-skills', 'create-skill'}

d = json.load(open('opencode.json'))
errors = 0
for name, cfg in d.get('agent', {}).items():
    for skill in cfg.get('skills', []):
        # Check local skills dir
        if os.path.isdir(f'skills/{skill}'):
            print(f'  {name} -> {skill}: OK (local)')
        elif skill in bundled_skills:
            print(f'  {name} -> {skill}: OK (bundled)')
        else:
            print(f'  {name} -> {skill}: MISSING')
            errors += 1
if errors == 0:
    print('  All skill references: OK')
sys.exit(1 if errors > 0 else 0)
" 2>/dev/null || pass=false

# 5. Lint scripts
echo "[5/5] Linting scripts..."
if command -v shellcheck &>/dev/null; then
    find scripts/ -name '*.sh' -exec shellcheck {} \; 2>&1 | head -20
else
    echo "  shellcheck not installed, skipping"
fi

echo ""
echo "=== CI Gate Complete ==="
if [ "$pass" = true ]; then
    echo "Result: PASS"
    exit 0
else
    echo "Result: FAIL"
    exit 1
fi
