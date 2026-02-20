# SonarQube + GitLab + VS Code Integration Guide for Python Development

> **Prerequisites:** You already have Docker-based SonarQube and GitLab containers running.  
> This guide walks through connecting everything end-to-end, including OWASP PyGoat security testing.

---

## Table of Contents

1. [Verify Existing Docker Containers](#1-verify-existing-docker-containers)
2. [Generate a SonarQube Authentication Token](#2-generate-a-sonarqube-authentication-token)
3. [Add the Token as a GitLab CI/CD Variable](#3-add-the-token-as-a-gitlab-cicd-variable)
4. [Example Python Project Structure](#4-example-python-project-structure)
5. [sonar-project.properties Configuration](#5-sonar-projectproperties-configuration)
6. [.gitlab-ci.yml Configuration](#6-gitlab-ciyml-configuration)
7. [Install and Configure SonarScanner CLI](#7-install-and-configure-sonarscanner-cli)
8. [Configure GitLab CLI (glab)](#8-configure-gitlab-cli-glab)
9. [Set Up GitLab Projects in VS Code](#9-set-up-gitlab-projects-in-vs-code)
10. [Set Up SonarQube for VS Code (SonarLint)](#10-set-up-sonarqube-for-vs-code-sonarlint)
11. [Connect SonarLint to Your Local SonarQube Server](#11-connect-sonarlint-to-your-local-sonarqube-server)
12. [Test the Full Setup](#12-test-the-full-setup)
13. [Python Unit Test Example for Coverage Reporting](#13-python-unit-test-example-for-coverage-reporting)
14. [OWASP PyGoat Security Testing in GitLab and VS Code](#14-owasp-pygoat-security-testing-in-gitlab-and-vs-code)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Verify Existing Docker Containers

Before starting, confirm your SonarQube and GitLab containers are running.

```bash
# List all running containers
docker ps

# You should see something like:
# CONTAINER ID   IMAGE                  PORTS                    NAMES
# xxxxxxxxxxxx   sonarqube:lts          0.0.0.0:9000->9000/tcp   sonarqube
# xxxxxxxxxxxx   gitlab/gitlab-ce:...   0.0.0.0:80->80/tcp       gitlab
```

### 1.1 Access SonarQube

Open your browser and navigate to:

```
http://localhost:9000
```

Default credentials (first-time login):
- **Username:** `admin`
- **Password:** `admin`

> You will be prompted to change the password on first login.

### 1.2 Access GitLab

Open your browser and navigate to:

```
http://localhost:80
```

Default credentials (first-time login):
- **Username:** `root`
- **Password:** Retrieve it from the container:

```bash
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

### 1.3 Container Networking (Important)

Since SonarQube and GitLab are both in Docker, the GitLab CI runner needs to reach SonarQube by container name or host IP, **not** `localhost`.

```bash
# Find the Docker bridge network IP of your host machine
ip route | grep docker
# Typical result: 172.17.0.1

# Or find the SonarQube container IP directly
docker inspect sonarqube | grep '"IPAddress"'
```

> Use the host IP (e.g., `http://172.17.0.1:9000`) in your CI configuration wherever SonarQube URL is needed, **not** `http://localhost:9000`.

---

## 2. Generate a SonarQube Authentication Token

### 2.1 Using the SonarQube UI

1. Log in to SonarQube at `http://localhost:9000`.
2. Click your **avatar** (top right) → **My Account**.
3. Select the **Security** tab.
4. Under **Generate Tokens**, enter a token name (e.g., `gitlab-ci-token`).
5. Choose token type: **Global Analysis Token** (or **Project Analysis Token** for a specific project).
6. Click **Generate**.
7. **Copy and save the token immediately** — it won't be shown again.

```
Example token: squ_abcdef1234567890abcdef1234567890abcdef12
```

### 2.2 Using the SonarQube API (Optional)

```bash
curl -u admin:YOUR_PASSWORD -X POST \
  "http://localhost:9000/api/user_tokens/generate" \
  -d "name=gitlab-ci-token"
```

---

## 3. Add the Token as a GitLab CI/CD Variable

### 3.1 Using the GitLab Web UI

1. Log in to GitLab and navigate to your project.
2. Go to **Settings** → **CI/CD** → **Variables** (expand).
3. Click **Add variable**.
4. Fill in:
   - **Key:** `SONAR_TOKEN`
   - **Value:** *(paste the token from Step 2)*
   - **Type:** Variable
   - **Environment scope:** All
   - ✅ Check **Mask variable** (hides it from logs)
   - ✅ Optionally check **Protect variable** (only available to protected branches)
5. Click **Add variable**.

6. Add a second variable for the SonarQube URL:
   - **Key:** `SONAR_HOST_URL`
   - **Value:** `http://172.17.0.1:9000` *(use your Docker host IP, not localhost)*
   - **Type:** Variable

### 3.2 Using the GitLab API (Optional)

```bash
# Replace PROJECT_ID, TOKEN, and values as appropriate
curl --request POST \
  --header "PRIVATE-TOKEN: YOUR_GITLAB_ROOT_TOKEN" \
  --form "key=SONAR_TOKEN" \
  --form "value=squ_abcdef1234567890" \
  --form "masked=true" \
  "http://localhost/api/v4/projects/PROJECT_ID/variables"
```

---

## 4. Example Python Project Structure

Create this project structure in your GitLab repository:

```
my-python-project/
├── app.py
├── calculator.py
├── tests/
│   ├── __init__.py
│   └── test_calculator.py
├── sonar-project.properties
├── .gitlab-ci.yml
├── requirements.txt
└── README.md
```

### 4.1 `app.py`

```python
"""
Main application entry point.
A simple example app demonstrating SonarQube integration.
"""

from calculator import Calculator


def greet(name: str) -> str:
    """Return a greeting string."""
    if not name or not isinstance(name, str):
        raise ValueError("Name must be a non-empty string")
    return f"Hello, {name}!"


def main():
    calc = Calculator()

    # Basic operations
    print(greet("World"))
    print(f"10 + 5 = {calc.add(10, 5)}")
    print(f"10 - 5 = {calc.subtract(10, 5)}")
    print(f"10 * 5 = {calc.multiply(10, 5)}")

    try:
        print(f"10 / 5 = {calc.divide(10, 5)}")
        print(f"10 / 0 = {calc.divide(10, 0)}")  # Will raise exception
    except ValueError as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
```

### 4.2 `calculator.py`

```python
"""
Calculator module with basic arithmetic operations.
"""


class Calculator:
    """A simple calculator class."""

    def add(self, a: float, b: float) -> float:
        """Add two numbers."""
        return a + b

    def subtract(self, a: float, b: float) -> float:
        """Subtract b from a."""
        return a - b

    def multiply(self, a: float, b: float) -> float:
        """Multiply two numbers."""
        return a * b

    def divide(self, a: float, b: float) -> float:
        """Divide a by b. Raises ValueError if b is zero."""
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b

    def power(self, base: float, exponent: float) -> float:
        """Raise base to the power of exponent."""
        return base ** exponent
```

### 4.3 `requirements.txt`

```
pytest==7.4.3
pytest-cov==4.1.0
coverage==7.3.2
```

---

## 5. `sonar-project.properties` Configuration

Create this file in the **root of your project repository**:

```properties
# =============================================================
# SonarQube Project Configuration
# =============================================================

# Unique project key (no spaces, use hyphens or underscores)
sonar.projectKey=my-python-project

# Display name shown in the SonarQube dashboard
sonar.projectName=My Python Project

# Project version (can also be set dynamically in CI)
sonar.projectVersion=1.0

# =============================================================
# Source & Language Settings
# =============================================================

# Comma-separated paths to source directories
sonar.sources=.

# Exclude directories you don't want analysed
sonar.exclusions=**/__pycache__/**,**/migrations/**,**/.git/**,**/venv/**,**/.venv/**,**/node_modules/**,**/tests/**

# Include test directories for coverage mapping
sonar.tests=tests

# Test file pattern
sonar.test.inclusions=**/tests/**/*.py,**/*_test.py,**/test_*.py

# Python version
sonar.python.version=3

# =============================================================
# Coverage Reporting
# =============================================================

# Path to the coverage XML report (generated by pytest-cov)
sonar.python.coverage.reportPaths=coverage.xml

# =============================================================
# Encoding
# =============================================================
sonar.sourceEncoding=UTF-8
```

---

## 6. `.gitlab-ci.yml` Configuration

Create this file in the **root of your project repository**:

```yaml
# =============================================================
# GitLab CI/CD Pipeline with SonarQube Analysis
# =============================================================

image: python:3.11-slim

stages:
  - test
  - quality
  - security

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip
    - venv/

# -----------------------------------------------------------
# Stage 1: Run Tests & Generate Coverage Report
# -----------------------------------------------------------
unit-tests:
  stage: test
  script:
    - python -m venv venv
    - source venv/bin/activate
    - pip install -r requirements.txt
    - pytest tests/ --cov=. --cov-report=xml:coverage.xml --cov-report=term-missing -v
  artifacts:
    when: always
    paths:
      - coverage.xml
      - .coverage
    reports:
      junit: junit.xml  # Optional: if you add --junitxml=junit.xml to pytest
    expire_in: 1 day
  coverage: '/TOTAL.*\s+(\d+%)$/'

# -----------------------------------------------------------
# Stage 2: SonarQube Analysis
# -----------------------------------------------------------
sonarqube-analysis:
  stage: quality
  image: sonarsource/sonar-scanner-cli:latest
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
    GIT_DEPTH: "0"  # Full clone for blame analysis
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  script:
    - sonar-scanner
        -Dsonar.projectKey=my-python-project
        -Dsonar.sources=.
        -Dsonar.host.url=${SONAR_HOST_URL}
        -Dsonar.token=${SONAR_TOKEN}
        -Dsonar.python.coverage.reportPaths=coverage.xml
        -Dsonar.exclusions=**/__pycache__/**,**/venv/**,**/.venv/**
        -Dsonar.qualitygate.wait=true
  needs:
    - unit-tests
  dependencies:
    - unit-tests
  allow_failure: false
  only:
    - main
    - merge_requests

# -----------------------------------------------------------
# Stage 3: OWASP Dependency Check (Optional Security Scan)
# -----------------------------------------------------------
dependency-check:
  stage: security
  image: python:3.11-slim
  script:
    - pip install safety
    - safety check --full-report --output text || true
  allow_failure: true
  only:
    - main
    - merge_requests
```

> **Note on `sonar.qualitygate.wait=true`:** This makes the CI pipeline wait for SonarQube to evaluate the Quality Gate and fail the pipeline if the gate fails. Requires SonarQube to be reachable from the runner.

---

## 7. Install and Configure SonarScanner CLI

The SonarScanner CLI lets you run analysis locally (outside of CI).

### 7.1 Install SonarScanner CLI

**Option A — Using Docker (Recommended, no install needed):**

```bash
# Run SonarScanner from your project directory
docker run \
  --rm \
  -e SONAR_HOST_URL="http://host.docker.internal:9000" \
  -e SONAR_TOKEN="squ_your_token_here" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli
```

> On Linux, replace `host.docker.internal` with your Docker host IP (e.g., `172.17.0.1`).

**Option B — Manual Install on Linux/macOS:**

```bash
# Download SonarScanner (check https://docs.sonarqube.org for latest version)
SCANNER_VERSION=5.0.1.3006
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}-linux.zip

unzip sonar-scanner-cli-${SCANNER_VERSION}-linux.zip
sudo mv sonar-scanner-${SCANNER_VERSION}-linux /opt/sonar-scanner

# Add to PATH
echo 'export PATH="/opt/sonar-scanner/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
sonar-scanner --version
```

**Option B — Install on Windows (PowerShell):**

```powershell
# Download from https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/
# Extract to C:\sonar-scanner

# Add to System PATH via Settings > Environment Variables
# Or temporarily in PowerShell:
$env:PATH += ";C:\sonar-scanner\bin"

# Verify
sonar-scanner --version
```

### 7.2 Configure SonarScanner CLI

Edit the global configuration file (optional — settings in `sonar-project.properties` take precedence):

```bash
# Linux/macOS
nano /opt/sonar-scanner/conf/sonar-scanner.properties
```

```properties
# Default SonarQube server URL
sonar.host.url=http://localhost:9000

# Default token (alternatively, pass via -Dsonar.token=... on the CLI)
# sonar.token=squ_your_token_here
```

### 7.3 Run Analysis Locally

From your project root directory:

```bash
sonar-scanner \
  -Dsonar.projectKey=my-python-project \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=squ_your_token_here \
  -Dsonar.python.coverage.reportPaths=coverage.xml
```

Or simply run `sonar-scanner` if `sonar-project.properties` is present and the token is set in the config file.

---

## 8. Configure GitLab CLI (glab)

`glab` is the official GitLab CLI tool for managing issues, MRs, pipelines, and more from the terminal.

### 8.1 Install glab

**Linux (apt):**

```bash
curl -fsSL https://cli.gitlab.com/packages/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/gitlab-cli.gpg
echo "deb [signed-by=/usr/share/keyrings/gitlab-cli.gpg] https://cli.gitlab.com/packages/debian stable main" | sudo tee /etc/apt/sources.list.d/gitlab-cli.list
sudo apt update
sudo apt install glab
```

**macOS (Homebrew):**

```bash
brew install glab
```

**Windows (Winget):**

```powershell
winget install --id GLab.GLab
```

**Or download a binary:** https://gitlab.com/gitlab-org/cli/-/releases

### 8.2 Authenticate glab to Your Local GitLab Instance

```bash
glab auth login --hostname localhost
```

You will be prompted:
1. **GitLab hostname:** `localhost` (or your Docker host IP)
2. **Protocol:** `http`
3. **Authentication method:** Token
4. **Token:** *(paste your GitLab personal access token)*

**Create a GitLab Personal Access Token:**

1. Log in to `http://localhost`.
2. Click your **avatar** → **Edit profile** → **Access Tokens**.
3. Click **Add new token**.
4. Name: `glab-cli`, Scopes: `api`, `read_user`, `write_repository`.
5. Click **Create personal access token** and copy it.

```bash
# Verify authentication
glab auth status
```

### 8.3 Useful glab Commands

```bash
# Clone a project
glab repo clone my-group/my-python-project

# List open merge requests
glab mr list

# Create a merge request
glab mr create --title "Add feature X" --description "Details here" --target-branch main

# View a merge request
glab mr view 1

# View CI/CD pipeline status
glab pipeline list
glab pipeline status

# View pipeline job logs
glab pipeline jobs list
glab job log JOB_ID

# Manage CI/CD variables
glab variable list
glab variable set SONAR_TOKEN "squ_your_token"

# Trigger a pipeline manually
glab pipeline run --branch main
```

---

## 9. Set Up GitLab Projects in VS Code

### 9.1 Install Required Extensions

Open VS Code and install these extensions:

1. **GitLab Workflow** (by GitLab) — ID: `gitlab.gitlab-workflow`
2. **Git Graph** (optional, for visual git history) — ID: `mhutchie.git-graph`
3. **GitLens** (optional, for advanced git features) — ID: `eamodio.gitlens`

```bash
# Install via terminal
code --install-extension gitlab.gitlab-workflow
code --install-extension mhutchie.git-graph
code --install-extension eamodio.gitlens
```

### 9.2 Configure the GitLab Workflow Extension

1. Open VS Code **Settings** (`Ctrl+,` / `Cmd+,`).
2. Search for `gitlab`.
3. Set the following:

**Via `settings.json`** (`Ctrl+Shift+P` → "Open User Settings (JSON)"):

```json
{
  "gitlab.instanceUrl": "http://localhost",
  "gitlab.pipelineGitRemoteName": "origin",
  "gitlab.showStatusBarLinks": true,
  "gitlab.showIssueLinkOnStatusBar": true,
  "gitlab.showMrStatusOnStatusBar": true
}
```

4. **Authenticate:** Press `Ctrl+Shift+P` → search `GitLab: Authenticate` → follow the prompts to add your token (`http://localhost` + your PAT).

### 9.3 Clone Your GitLab Project in VS Code

```bash
# Clone via HTTPS (using your GitLab PAT for auth)
git clone http://root:YOUR_PAT@localhost/root/my-python-project.git

# Or via the VS Code command palette:
# Ctrl+Shift+P → "Git: Clone" → enter the repo URL
```

### 9.4 VS Code GitLab Features Available

Once configured, you can:

- View **pipelines** in the status bar and sidebar
- View and create **merge requests** from VS Code
- Review **issues** inline
- See **CI/CD job logs** directly in VS Code
- Use `Ctrl+Shift+P` → `GitLab:` to access all commands

---

## 10. Set Up SonarQube for VS Code (SonarLint)

### 10.1 Install SonarLint Extension

SonarLint provides real-time code analysis in VS Code — it shows the same issues SonarQube finds, right in your editor as you type.

```bash
code --install-extension SonarSource.sonarlint-vscode
```

Or in VS Code: **Extensions** (`Ctrl+Shift+X`) → search `SonarLint` → Install the one by **SonarSource**.

### 10.2 Basic SonarLint Configuration

SonarLint works **standalone** (built-in rules, no server needed) by default. No configuration is needed for basic use — it will start analyzing Python files immediately.

**Configure Python-specific settings in `settings.json`:**

```json
{
  "sonarlint.ls.javaHome": "",
  "sonarlint.pathToNodeExecutable": "",
  "sonarlint.output.showAnalyzerLogs": false,
  "sonarlint.rules": {
    "python:S1481": { "level": "on" },
    "python:S3776": { "level": "on" },
    "python:S106":  { "level": "on" }
  }
}
```

---

## 11. Connect SonarLint to Your Local SonarQube Server

**Connected Mode** syncs your project's SonarQube rules, quality profiles, and issue status directly to your IDE. This is the most powerful way to use SonarLint.

### 11.1 Add a SonarQube Connection in VS Code

1. Open VS Code Command Palette (`Ctrl+Shift+P`).
2. Type and select: **SonarLint: Connect to SonarQube**.
3. In the SonarLint sidebar that appears, click **+ New Connection** → **SonarQube**.
4. Fill in:
   - **Connection name:** `local-sonarqube`
   - **SonarQube URL:** `http://localhost:9000`
   - **Token:** *(paste your SonarQube token from Step 2)*
5. Click **Save Connection**.

### 11.2 Bind Your Project to SonarQube

After creating the connection, bind your local workspace to the SonarQube project:

1. Open Command Palette → **SonarLint: Open Project Binding Settings**.
2. Click **+ Bind this folder**.
3. Select connection: `local-sonarqube`.
4. Select project: `my-python-project`.
5. Click **Save**.

Alternatively, add this to your workspace's `.vscode/settings.json`:

```json
{
  "sonarlint.connectedMode.project": {
    "connectionId": "local-sonarqube",
    "projectKey": "my-python-project"
  }
}
```

And in your **User settings** (`settings.json`):

```json
{
  "sonarlint.connectedMode.connections.sonarqube": [
    {
      "connectionId": "local-sonarqube",
      "serverUrl": "http://localhost:9000",
      "token": "squ_your_token_here"
    }
  ]
}
```

> **Security Note:** Avoid committing tokens to version control. Use VS Code secret storage — SonarLint handles this when you connect through the UI.

### 11.3 Verify the Connection

1. Open any Python file in your project (e.g., `app.py`).
2. Look for SonarLint highlights in the editor (squiggly underlines for issues).
3. Open the **Problems** panel (`Ctrl+Shift+M`) — SonarLint issues appear here.
4. Check the SonarLint **Output** panel for connection status:
   - `View` → `Output` → select `SonarLint` from the dropdown.

### 11.4 SonarLint Commands Reference

| Command | Description |
|---|---|
| `SonarLint: Connect to SonarQube` | Create server connection |
| `SonarLint: Open Project Binding Settings` | Bind workspace to project |
| `SonarLint: Show SonarLint Output` | View logs |
| `SonarLint: Update Bindings` | Re-sync rules from server |
| `SonarLint: Deactivate Rule` | Suppress a specific rule |
| `SonarLint: Open Rule Description` | View rule details |

---

## 12. Test the Full Setup

### 12.1 Initial Setup: Create the SonarQube Project

1. Go to `http://localhost:9000`.
2. Click **Projects** → **Add project** → **Manually**.
3. **Project key:** `my-python-project`
4. **Display name:** `My Python Project`
5. Click **Set Up**.
6. Choose **With GitLab CI** (for GitLab integration) or **Locally** for manual setup.

### 12.2 Push Code to GitLab

```bash
# Initialize git in your project directory (if not already done)
cd my-python-project
git init
git remote add origin http://localhost/root/my-python-project.git

# Stage and commit all files
git add .
git commit -m "Initial commit: Python project with SonarQube config"

# Push to main branch
git push -u origin main
```

### 12.3 Create a Feature Branch and Merge Request

```bash
# Create a new branch
git checkout -b feature/add-calculator

# Make a change (e.g., add a new method or intentional issue for testing)
cat >> calculator.py << 'EOF'

    def modulo(self, a: float, b: float) -> float:
        """Return remainder of a divided by b."""
        if b == 0:
            raise ValueError("Cannot modulo by zero")
        return a % b
EOF

# Commit and push
git add calculator.py
git commit -m "feat: add modulo operation to Calculator"
git push origin feature/add-calculator

# Create merge request via glab
glab mr create \
  --title "feat: add modulo operation" \
  --description "Adds modulo method to Calculator class with zero-division guard." \
  --target-branch main \
  --source-branch feature/add-calculator
```

### 12.4 Monitor the CI/CD Pipeline

**In VS Code** (GitLab Workflow extension):
- Look at the status bar at the bottom for pipeline status.
- Open the GitLab sidebar → **Pipelines** to see jobs.

**In the GitLab UI:**
- Navigate to your project → **CI/CD** → **Pipelines**.
- Click the running pipeline to see job logs.

**In terminal with glab:**

```bash
glab pipeline list
glab pipeline status
```

### 12.5 View Results in SonarQube

1. Go to `http://localhost:9000`.
2. Click on **Projects** → `My Python Project`.
3. You will see:
   - **Bugs**, **Vulnerabilities**, **Code Smells** count
   - **Coverage** percentage
   - **Duplications** percentage
   - **Quality Gate** status (Passed / Failed)

4. Click any category to drill down into specific issues with file and line references.

### 12.6 View Results on the Merge Request

In GitLab:
1. Navigate to **Merge Requests** → your MR.
2. SonarQube posts a comment with the quality gate status and issue summary (requires SonarQube GitLab integration configured — see optional setup below).

**Optional: Configure SonarQube GitLab Integration for MR decoration:**

In SonarQube → **Administration** → **Configuration** → **GitLab**:
- **GitLab URL:** `http://localhost`
- **Personal Access Token:** *(GitLab root token with `api` scope)*

---

## 13. Python Unit Test Example for Coverage Reporting

### 13.1 `tests/__init__.py`

```python
# Empty file — marks directory as a Python package
```

### 13.2 `tests/test_calculator.py`

```python
"""
Unit tests for the Calculator class.
Designed to demonstrate SonarQube coverage reporting.
"""

import pytest
from calculator import Calculator


class TestCalculatorAdd:
    """Tests for the add method."""

    def setup_method(self):
        self.calc = Calculator()

    def test_add_positive_numbers(self):
        assert self.calc.add(3, 5) == 8

    def test_add_negative_numbers(self):
        assert self.calc.add(-3, -5) == -8

    def test_add_mixed_numbers(self):
        assert self.calc.add(-3, 5) == 2

    def test_add_zero(self):
        assert self.calc.add(0, 0) == 0

    def test_add_floats(self):
        assert self.calc.add(1.5, 2.5) == pytest.approx(4.0)


class TestCalculatorSubtract:
    """Tests for the subtract method."""

    def setup_method(self):
        self.calc = Calculator()

    def test_subtract_positive(self):
        assert self.calc.subtract(10, 5) == 5

    def test_subtract_negative_result(self):
        assert self.calc.subtract(5, 10) == -5

    def test_subtract_zero(self):
        assert self.calc.subtract(5, 0) == 5


class TestCalculatorMultiply:
    """Tests for the multiply method."""

    def setup_method(self):
        self.calc = Calculator()

    def test_multiply_positive(self):
        assert self.calc.multiply(4, 5) == 20

    def test_multiply_by_zero(self):
        assert self.calc.multiply(100, 0) == 0

    def test_multiply_negative(self):
        assert self.calc.multiply(-4, 5) == -20

    def test_multiply_floats(self):
        assert self.calc.multiply(2.5, 4) == pytest.approx(10.0)


class TestCalculatorDivide:
    """Tests for the divide method."""

    def setup_method(self):
        self.calc = Calculator()

    def test_divide_positive(self):
        assert self.calc.divide(10, 2) == 5.0

    def test_divide_floats(self):
        assert self.calc.divide(7, 2) == pytest.approx(3.5)

    def test_divide_by_zero_raises(self):
        with pytest.raises(ValueError, match="Cannot divide by zero"):
            self.calc.divide(10, 0)

    def test_divide_negative(self):
        assert self.calc.divide(-10, 2) == -5.0


class TestCalculatorPower:
    """Tests for the power method."""

    def setup_method(self):
        self.calc = Calculator()

    def test_power_positive(self):
        assert self.calc.power(2, 10) == 1024

    def test_power_zero_exponent(self):
        assert self.calc.power(5, 0) == 1

    def test_power_negative_base(self):
        assert self.calc.power(-2, 3) == -8


class TestAppGreet:
    """Tests for the greet function in app.py."""

    def test_greet_valid_name(self):
        from app import greet
        assert greet("Alice") == "Hello, Alice!"

    def test_greet_empty_string_raises(self):
        from app import greet
        with pytest.raises(ValueError):
            greet("")

    def test_greet_none_raises(self):
        from app import greet
        with pytest.raises(ValueError):
            greet(None)

    def test_greet_non_string_raises(self):
        from app import greet
        with pytest.raises(ValueError):
            greet(123)
```

### 13.3 Run Tests Locally with Coverage

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests with coverage XML report
pytest tests/ \
  --cov=. \
  --cov-report=xml:coverage.xml \
  --cov-report=html:htmlcov \
  --cov-report=term-missing \
  -v

# View HTML coverage report in browser
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

---

## 14. OWASP PyGoat Security Testing in GitLab and VS Code

[OWASP PyGoat](https://devguide.owasp.org/en/07-training-education/01-vulnerable-apps/03-pygoat/) is an intentionally vulnerable Python/Django web application for learning about security vulnerabilities.

### 14.1 What Is PyGoat?

PyGoat is a deliberately insecure Django application that demonstrates OWASP Top 10 vulnerabilities including:

- SQL Injection
- Cross-Site Scripting (XSS)
- Broken Authentication
- Sensitive Data Exposure
- XML External Entities (XXE)
- Insecure Direct Object References (IDOR)
- Security Misconfiguration
- Cross-Site Request Forgery (CSRF)

### 14.2 Import PyGoat into Your GitLab Instance

```bash
# Option A: Clone PyGoat and push to your local GitLab
git clone https://github.com/adeyosemanputra/pygoat.git
cd pygoat

# Remove the original remote and add your local GitLab
git remote remove origin
git remote add origin http://root:YOUR_PAT@localhost/root/pygoat.git

# Create the project first in GitLab (UI or API)
curl --request POST \
  --header "PRIVATE-TOKEN: YOUR_PAT" \
  --header "Content-Type: application/json" \
  --data '{"name": "pygoat", "description": "OWASP PyGoat - Intentionally Vulnerable App", "visibility": "private"}' \
  "http://localhost/api/v4/projects/"

# Push the code
git push -u origin main
```

### 14.3 Run PyGoat with Docker

```bash
# Run PyGoat as a Docker container
docker run --rm -p 8000:8000 \
  --name pygoat \
  adeyosemanputra/pygoat:latest

# Access PyGoat in your browser
open http://localhost:8000
```

**Or build it yourself:**

```bash
cd pygoat
docker build -t pygoat-local .
docker run --rm -p 8000:8000 --name pygoat pygoat-local
```

### 14.4 Set Up PyGoat in VS Code

```bash
# Open PyGoat in VS Code
cd pygoat
code .

# Create a Python virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\activate    # Windows

# Install dependencies
pip install -r requirements.txt

# Run PyGoat locally (for development)
python manage.py migrate
python manage.py runserver 8000
```

**Recommended VS Code Extensions for Security Analysis:**

```bash
code --install-extension ms-python.python
code --install-extension SonarSource.sonarlint-vscode
code --install-extension hbenl.vscode-test-explorer
```

### 14.5 SonarQube Project for PyGoat

Create a SonarQube project for PyGoat:

1. Go to `http://localhost:9000` → **Projects** → **Add project** → **Manually**.
2. **Project key:** `pygoat`
3. **Display name:** `OWASP PyGoat`

Create `sonar-project.properties` in the PyGoat root:

```properties
# SonarQube configuration for PyGoat
sonar.projectKey=pygoat
sonar.projectName=OWASP PyGoat
sonar.projectVersion=1.0

# Sources
sonar.sources=.
sonar.exclusions=**/migrations/**,**/__pycache__/**,**/static/**,**/templates/**,**/venv/**,**/.venv/**,**/node_modules/**

# Python settings
sonar.python.version=3

# Coverage (if tests are added)
# sonar.python.coverage.reportPaths=coverage.xml

sonar.sourceEncoding=UTF-8
```

### 14.6 `.gitlab-ci.yml` for PyGoat with Security Scanning

Create `.gitlab-ci.yml` in the PyGoat root:

```yaml
# =============================================================
# PyGoat CI/CD Pipeline with Security Scanning
# =============================================================

image: python:3.11-slim

stages:
  - install
  - sast
  - sonarqube
  - dast

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  paths:
    - .cache/pip

# -----------------------------------------------------------
# Stage 1: Install Dependencies
# -----------------------------------------------------------
install-deps:
  stage: install
  script:
    - pip install -r requirements.txt
    - pip install bandit safety semgrep
  artifacts:
    paths:
      - .cache/pip

# -----------------------------------------------------------
# Stage 2: Static Application Security Testing (SAST)
# -----------------------------------------------------------

# Bandit: Python security linter
bandit-scan:
  stage: sast
  script:
    - pip install bandit
    - bandit -r . -f json -o bandit-report.json --exclude ./.venv,./venv || true
    - bandit -r . -f txt --exclude ./.venv,./venv || true
  artifacts:
    when: always
    paths:
      - bandit-report.json
    expire_in: 1 week
  allow_failure: true

# Safety: Check for known vulnerable dependencies
safety-check:
  stage: sast
  script:
    - pip install safety
    - safety check --full-report || true
  allow_failure: true

# Semgrep: Advanced static analysis for security
semgrep-scan:
  stage: sast
  image: returntocorp/semgrep:latest
  script:
    - semgrep --config=auto --json --output=semgrep-report.json . || true
    - semgrep --config=p/owasp-top-ten --json --output=semgrep-owasp.json . || true
  artifacts:
    when: always
    paths:
      - semgrep-report.json
      - semgrep-owasp.json
    expire_in: 1 week
  allow_failure: true

# -----------------------------------------------------------
# Stage 3: SonarQube Analysis (includes security rules)
# -----------------------------------------------------------
sonarqube-security-analysis:
  stage: sonarqube
  image: sonarsource/sonar-scanner-cli:latest
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
    GIT_DEPTH: "0"
  cache:
    key: "${CI_JOB_NAME}"
    paths:
      - .sonar/cache
  script:
    - sonar-scanner
        -Dsonar.projectKey=pygoat
        -Dsonar.sources=.
        -Dsonar.host.url=${SONAR_HOST_URL}
        -Dsonar.token=${SONAR_TOKEN}
        -Dsonar.exclusions=**/migrations/**,**/venv/**,**/__pycache__/**,**/static/**
  allow_failure: true
  only:
    - main
    - merge_requests

# -----------------------------------------------------------
# Stage 4: DAST - Dynamic Application Security Testing
# (Requires the app to be running — use with Docker services)
# -----------------------------------------------------------
owasp-zap-scan:
  stage: dast
  image: ghcr.io/zaproxy/zaproxy:stable
  services:
    - name: adeyosemanputra/pygoat:latest
      alias: pygoat-app
  variables:
    TARGET_URL: "http://pygoat-app:8000"
  script:
    - mkdir -p /zap/reports
    - zap-baseline.py
        -t ${TARGET_URL}
        -r zap-report.html
        -J zap-report.json
        -I || true
  artifacts:
    when: always
    paths:
      - zap-report.html
      - zap-report.json
    expire_in: 1 week
  allow_failure: true
  only:
    - main
```

### 14.7 Run Security Scans Locally with VS Code

**Install security tools:**

```bash
pip install bandit safety semgrep
```

**Run Bandit scan from VS Code terminal:**

```bash
# Full scan with detailed output
bandit -r . -ll -i --exclude ./.venv,./venv

# HTML report
bandit -r . -f html -o bandit-report.html --exclude ./.venv,./venv
open bandit-report.html  # macOS
```

**Run Safety check:**

```bash
safety check --full-report
```

**Run Semgrep with OWASP Top 10 rules:**

```bash
# Install semgrep
pip install semgrep

# Run against PyGoat with OWASP rules
semgrep --config=p/owasp-top-ten .
semgrep --config=p/python .
semgrep --config=p/django .
```

### 14.8 SonarLint Configuration for PyGoat Security Rules

Add to your VS Code `settings.json` to enable security-focused rules:

```json
{
  "sonarlint.connectedMode.project": {
    "connectionId": "local-sonarqube",
    "projectKey": "pygoat"
  },
  "sonarlint.rules": {
    "python:S2076": { "level": "on" },
    "python:S2077": { "level": "on" },
    "python:S5131": { "level": "on" },
    "python:S5144": { "level": "on" },
    "python:S4830": { "level": "on" },
    "python:S2255": { "level": "on" },
    "python:S6437": { "level": "on" }
  }
}
```

### 14.9 Understanding PyGoat Vulnerabilities in SonarQube

After running the analysis, navigate to `http://localhost:9000/project/issues?id=pygoat` to see:

| Category | Example Finding | SonarQube Rule |
|---|---|---|
| SQL Injection | Raw SQL queries with user input | `python:S2077` |
| XSS | Unescaped template variables | `python:S5131` |
| Hardcoded credentials | Passwords in source code | `python:S6437` |
| Path traversal | Unvalidated file paths | `python:S5144` |
| Insecure cookies | Missing `HttpOnly`/`Secure` flags | `python:S2255` |
| Weak SSL/TLS | `verify=False` in requests | `python:S4830` |

### 14.10 Learning Exercises with PyGoat

Use the combination of PyGoat + SonarQube + SonarLint to practice:

1. **Find vulnerabilities** in SonarQube dashboard
2. **Navigate to the vulnerable code** in VS Code (SonarLint highlights it)
3. **Exploit the vulnerability** via the PyGoat web interface at `http://localhost:8000`
4. **Fix the code** in VS Code and observe SonarLint clearing the warning
5. **Push the fix** and verify the CI pipeline passes SonarQube quality gate

---

## 15. Troubleshooting

### SonarQube Not Reachable from GitLab CI Runner

```bash
# The GitLab CI runner cannot reach localhost — use Docker network IP
# Find the correct IP:
docker network inspect bridge | grep Gateway
# Use this IP in SONAR_HOST_URL variable (e.g., http://172.17.0.1:9000)
```

### SonarScanner Fails with Authentication Error

```bash
# Verify your token is correct
curl -u TOKEN: http://localhost:9000/api/authentication/validate

# Ensure the SONAR_TOKEN CI variable is not empty
glab variable list | grep SONAR_TOKEN
```

### SonarLint Not Showing Issues

1. Check the SonarLint Output panel: `View` → `Output` → `SonarLint`
2. Ensure you have a Python file open that belongs to the bound project
3. Try: Command Palette → `SonarLint: Update Bindings`
4. Verify SonarQube is running: `curl http://localhost:9000/api/system/status`

### GitLab Workflow Extension Not Connecting

```bash
# Test GitLab API access
curl -H "PRIVATE-TOKEN: YOUR_PAT" http://localhost/api/v4/user

# Re-authenticate
# Ctrl+Shift+P → GitLab: Remove Account → GitLab: Authenticate
```

### Coverage Not Appearing in SonarQube

```bash
# Ensure coverage.xml is generated before sonar-scanner runs
pytest tests/ --cov=. --cov-report=xml:coverage.xml

# Verify the file exists and has content
cat coverage.xml | head -5

# Check the path in sonar-project.properties matches
# sonar.python.coverage.reportPaths=coverage.xml
```

### Docker Containers Not Starting

```bash
# Check logs for SonarQube
docker logs sonarqube --tail 50

# Common fix: increase vm.max_map_count for Elasticsearch (SonarQube requirement)
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072

# Make permanent (Linux)
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
```

### Quality Gate Always Failing

1. Go to `http://localhost:9000` → **Quality Gates**
2. Check the conditions on the gate assigned to your project
3. For new projects with no historical data, set the gate to use **"New Code"** conditions
4. Navigate to **Project Settings** → **Quality Gate** to assign a less strict gate for initial setup

---

## Quick Reference Cheatsheet

```bash
# ============================
# Docker
# ============================
docker ps                                          # List running containers
docker logs sonarqube --tail 20                    # SonarQube logs
docker logs gitlab --tail 20                       # GitLab logs

# ============================
# SonarScanner (local)
# ============================
sonar-scanner -Dsonar.token=TOKEN                  # Run analysis
docker run --rm -v $(pwd):/usr/src \               # Run via Docker
  -e SONAR_HOST_URL=http://172.17.0.1:9000 \
  -e SONAR_TOKEN=TOKEN \
  sonarsource/sonar-scanner-cli

# ============================
# GitLab CLI (glab)
# ============================
glab auth login --hostname localhost               # Authenticate
glab mr create --title "..." --target-branch main # Create MR
glab pipeline list                                 # List pipelines
glab pipeline status                               # Current pipeline status
glab variable set KEY VALUE                        # Set CI variable

# ============================
# Tests & Coverage
# ============================
pytest tests/ --cov=. --cov-report=xml            # Run with coverage
bandit -r . -ll                                    # Security scan
safety check                                       # Dependency audit
semgrep --config=p/owasp-top-ten .                # OWASP scan

# ============================
# Git Workflow
# ============================
git checkout -b feature/my-feature                 # New branch
git add . && git commit -m "feat: ..."             # Stage & commit
git push origin feature/my-feature                 # Push branch
```

---

*Guide Version: 1.0 | Compatible with SonarQube LTS, GitLab CE, VS Code 1.85+*
