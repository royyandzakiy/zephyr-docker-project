# pytest Integration Guide

## Quick Start

### Setup (one-time)
```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install pytest and plugins
pip install -r requirements-dev.txt
```

### Running Tests

```bash
# Activate venv
source .venv/bin/activate

# Run all Python tests
pytest tests/python/

# Run with verbose output (shows test names & status)
pytest tests/python/ -v

# Run specific test file
pytest tests/python/test_build_validation.py -v

# Run specific test class
pytest tests/python/test_build_validation.py::TestProjectStructure -v

# Run specific test
pytest tests/python/test_build_validation.py::TestProjectStructure::test_source_exists -v

# Generate beautiful HTML report
pytest tests/python/ -v --html=build_tests_pytest/report.html --self-contained-html

# Run only "smoke" tests (quick - instant)
pytest tests/python/ -v -m smoke

# Run only "unit" tests (fast - < 1 second)
pytest tests/python/ -v -m unit

# Run only "integration" tests (< 10 seconds)
pytest tests/python/ -v -m integration

# Run only "e2e" tests (builds, runs binaries)
pytest tests/python/ -v -m e2e

# Skip "slow" tests
pytest tests/python/ -v -m "not slow"

# Run all EXCEPT e2e (quick validation)
pytest tests/python/ -v -m "not e2e"

# Run tests in parallel (4 workers)
pytest tests/python/ -v -n 4

# Run with shorter output
pytest tests/python/ -q

# Stop on first failure
pytest tests/python/ -x

# Show local variables on failure
pytest tests/python/ -v -l
```

## Test Categories Explained

| Marker | Speed | Purpose | Examples |
|--------|-------|---------|----------|
| `@pytest.mark.smoke` | Instant | Quick sanity checks | File exists, configs readable |
| `@pytest.mark.unit` | < 1s | Fast validation | Parse configs, check syntax |
| `@pytest.mark.integration` | < 10s | Subsystems together | Build system, scripts |
| `@pytest.mark.e2e` | > 10s | Full workflows | Compile & run binaries, check output |
| `@pytest.mark.slow` | Any | Slow tests | Mark anything that takes time |

## Running by Speed

```bash
# FAST: Everything except E2E (< 10 seconds total)
pytest tests/python/ -v -m "not e2e"

# MEDIUM: Everything (includes builds)
pytest tests/python/ -v

# E2E ONLY: Full application workflows
pytest tests/python/ -v -m e2e
```

## E2E Tests (New!)

### What They Test
E2E tests **build and run** your actual applications to verify end-to-end workflows:
- ✅ Does the native_sim binary boot?
- ✅ Is startup output correct?
- ✅ Do ztest suite tests pass?
- ✅ Full integration from source → build → execution

### Available E2E Tests

#### 1. **Native Sim Boot Test**
```bash
pytest tests/python/test_e2e.py::TestNativeSimE2E::test_native_sim_boots -v
```

What it does:
- Looks for compiled native_sim binary
- Runs it with 5-second timeout
- Verifies boot messages appear in output
- Skips gracefully if binary doesn't exist

#### 2. **Twister E2E Test**
```bash
pytest tests/python/test_e2e.py::TestZtestE2E::test_twister_execution -v
```

What it does:
- Runs `west twister` on your biz_logic tests
- Verifies all tests pass
- Skips if west not available (non-NCS environment)

### Running E2E Tests

```bash
# Build native_sim first
west build -b native_sim -s . --pristine

# Then run E2E tests
source .venv/bin/activate
pytest tests/python/test_e2e.py -v

# Or just the boot test
pytest tests/python/test_e2e.py::TestNativeSimE2E -v

# With HTML report
pytest tests/python/test_e2e.py -v --html=build_tests_pytest/report_e2e.html --self-contained-html
```

### Example: E2E Test Output

```
tests/python/test_e2e.py::TestNativeSimE2E::test_native_sim_boots PASSED
tests/python/test_e2e.py::TestZtestE2E::test_twister_execution PASSED
```

## File Structure

```
tests/
├── biz_logic/                       # Zephyr ztest (embedded C unit tests)
│   └── ...                          # Keep using: west twister
└── python/                          # pytest (Python/integration/E2E tests)
    ├── test_build_validation.py     # Build & project structure (smoke/unit)
    └── test_e2e.py                  # Full app workflows (e2e)
conftest.py                          # Global pytest config & fixtures
pytest.ini                           # pytest settings
requirements-dev.txt                 # Python dependencies
.venv/                               # Virtual environment
```

## How pytest Fits In

| Test Type | Framework | What It Tests | Runs On |
|-----------|-----------|---------------|---------|
| **Unit (embedded)** | ztest + twister | GPIO, drivers, device logic | native_sim, qemu, hardware |
| **Build validation** | pytest smoke/unit | Project structure, configs | Host machine |
| **Integration** | pytest integration | Build system, workflows | Host machine |
| **E2E** | pytest e2e | Full app from build→run | Host machine + simulators |

## No Interference!

✅ **pytest and ztest run independently**
- `west twister` still builds and runs Zephyr embedded tests normally
- `pytest` tests your build system, project structure, and full workflows
- Both can run in CI/CD without conflicts

## Zephyr Tests (Keep Using These!)

```bash
# Your existing ztest workflow is UNCHANGED:
west twister -vv -n -T tests/biz_logic --outdir build_tests_twister

# This still works exactly the same!
# Now you can ALSO verify it works via E2E pytest:
pytest tests/python/test_e2e.py::TestZtestE2E -v
```

## Benefits of pytest Here

1. **Validate project before building** (smoke tests - instant)
2. **Test build scripts and automation** (unit/integration tests)
3. **Check configuration files** for correctness
4. **Beautiful HTML reports** with colors and charts
5. **Parallel execution** for faster validation
6. **Better failure messages** than plain shell scripts
7. **E2E verification** - actually run compiled binaries
8. **Easy to extend** - add your own tests

## Example: Add Your Own Test

### Simple Validation
```python
# tests/python/test_my_feature.py
import pytest
from pathlib import Path

@pytest.mark.smoke
def test_my_feature(project_root):
    """Quick validation of my feature."""
    my_file = project_root / "src" / "myfile.c"
    assert my_file.exists()
    content = my_file.read_text()
    assert "my_feature" in content
```

### E2E Workflow
```python
import subprocess
import pytest

@pytest.mark.e2e
@pytest.mark.slow
def test_my_e2e_scenario(project_root):
    """Test full workflow."""
    # Build
    subprocess.run(
        "west build -b native_sim -s . --pristine",
        cwd=project_root,
        shell=True,
        check=True
    )
    
    # Run & verify
    binary = project_root / "build/zephyr/zephyr.exe"
    result = subprocess.run(str(binary), capture_output=True, text=True, timeout=5)
    assert result.returncode == 0
    assert "expected output" in result.stdout
```

Then run:
```bash
pytest tests/python/test_my_feature.py -v
pytest tests/python/test_my_feature.py -v -m e2e
```

## Fixtures Available

From `conftest.py`:

```python
def test_example(project_root, run_command):
    # project_root: Path object pointing to repo root
    
    # run_command: Execute shell commands
    result = run_command("ls -la")
    assert result.returncode == 0
    print(result.stdout)
```

## Deactivate venv

```bash
deactivate
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run pytest validation
  run: |
    source .venv/bin/activate
    pytest tests/python/ -v -m "not e2e"  # Fast checks
    
- name: Run E2E tests
  run: |
    source .venv/bin/activate
    west build -b native_sim -s . --pristine
    pytest tests/python/test_e2e.py -v  # Full workflows
```

## Summary

### Quick Commands
```bash
# Setup (once)
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

# Fast checks (instant)
pytest tests/python/ -m "not e2e" -v

# Full tests
pytest tests/python/ -v

# E2E (requires build)
west build -b native_sim -s . --pristine
pytest tests/python/test_e2e.py -v

# Beautiful report
pytest tests/python/ -v --html=build_tests_pytest/report.html --self-contained-html

# Your existing ztest still works
west twister -vv -n -T tests/biz_logic --outdir build_tests_twister
```

### Test Layers
- **Smoke** (instant) → **Unit** (1s) → **Integration** (10s) → **E2E** (60s+)
- Run faster tests first, E2E last
- Use `pytest -m "not e2e"` for quick CI validation
