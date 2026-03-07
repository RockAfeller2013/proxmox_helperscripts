# VS Code – Connect to GitHub (Windows)

## Prerequisites

### 1. Install Git
Download and install Git:  
https://git-scm.com/download/win  

VS Code uses your machine's Git installation.

### 2. Have a GitHub Account
Create a free account:  
https://github.com

### 3. Configure Git

Open a terminal (VS Code terminal works):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Step 1: Authenticate VS Code with GitHub

The easiest way to link VS Code with GitHub is using the built-in authentication.

### 1. Open Command Palette

```
Ctrl + Shift + P
```

### 2. Sign In
Search and select:

```
GitHub: Sign In
```

### 3. Authorize
1. Your default browser will open
2. Sign in to GitHub
3. Authorize Visual Studio Code

### 4. Confirm Connection
Once redirected back to VS Code:
- You should see a confirmation message
- Your GitHub username will appear in the **Accounts** icon (bottom-left of VS Code)

---

## Step 2: Work With a Repository

You can either:
- Clone an existing GitHub repository
- Publish a local project to GitHub

---

### Option A: Clone a GitHub Repository (Recommended)

#### 1. Open Command Palette

```
Ctrl + Shift + P
```

#### 2. Select

```
Git: Clone
```

#### 3. Choose

```
Clone from GitHub
```

#### 4. Select Repository
Choose the repository you want to work with.

#### 5. Choose Local Folder
Select a local folder where the repository will be downloaded.

#### 6. Open the Project
When prompted, click **Open** to load the repository in VS Code.

---

### Option B: Publish a Local Folder to GitHub

#### 1. Open Your Project Folder

```
File → Open Folder
```

Select your project directory.

#### 2. Initialize Git
Open Source Control:

```
Ctrl + Shift + G
```

Click:

```
Initialize Repository
```

#### 3. Commit Your Changes
Files will appear as:

```
U = Untracked
```

Steps:
1. Click `+` next to **Changes** to stage files
2. Enter a commit message
3. Click `✓` **Commit**

#### 4. Publish to GitHub
Click:

```
Publish Branch
```

or the cloud icon in Source Control.

Follow the prompts:
1. Create a new repository on GitHub
2. Choose **Public** or **Private**
3. Push your commits to GitHub
