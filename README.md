# Three-Stackerino 🖥️ ➡️ 🧠 ➡️ 🗄️

Three services that **talk to each other**, all running on your computer (WSL):

| Folder      | What it is        | Technology      | Port   | Speaks…                         |
| ----------- | ----------------- | --------------- | ------ | ------------------------------- |
| `frontend/` | **Frontend**      | Node.js/Express | `3000` | HTML (pages for humans) 👀      |
| `backend/`  | **Backend (API)** | Python/Flask    | `5500` | JSON (data for programs) 🤖     |
| `db/`       | **Database**      | PostgreSQL      | `5432` | SQL (stores the data on disk) 💾 |

In **two-stackerino** you got **two** services talking. Now we add the third one: a real **database**. The app is a **message board**: you write a message on the page, it gets stored in the database, and it stays there even if you shut everything down.

> [!NOTE]
> 🇵🇹 Versão em português: https://github.com/professordiogodev/devops.three-stackerino-pt

> [!IMPORTANT]
> This lab runs **locally, on WSL (Ubuntu)**. You don't need VMs, the cloud, or Docker.

---

## 0. How do the three services connect?

Continuing with the restaurant 🍝:

- The **frontend** is the **waiter**: it talks to the customer (you, in the browser).
- The **backend** is the **kitchen**: it does the real work.
- The **database** is the **pantry**: it's where things are stored. Only the kitchen goes in there.

```
 ┌─────────┐  GET /       ┌────────────┐  GET /api/messages   ┌────────────┐   SELECT / INSERT   ┌──────────────┐
 │ Browser │ ───────────► │  FRONTEND  │ ───────────────────► │  BACKEND   │ ──────────────────► │  POSTGRESQL  │
 │  (you)  │ ◄─────────── │  :3000     │ ◄─────────────────── │  :5500     │ ◄────────────────── │  :5432       │
 └─────────┘  HTML page   └────────────┘   JSON data          └────────────┘   table rows        └──────────────┘
```

> [!IMPORTANT]
> 💡 **Key idea:** each service only knows about **the next one** in the chain, and finds it through **environment variables**:
> - the frontend finds the backend with `BACKEND_URL`
> - the backend finds the database with `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
>
> The frontend **never** talks directly to the database.

### Environment variables

| Service  | Variable      | Purpose                                     | Default                 |
| -------- | ------------- | ------------------------------------------- | ----------------------- |
| frontend | `PORT`        | Port the frontend listens on                | `3000`                  |
| frontend | `BACKEND_URL` | **Where the frontend finds the backend**    | `http://localhost:5500` |
| backend  | `PORT`        | Port the backend listens on                 | `5500`                  |
| backend  | `NUMBER`      | Number shown on the page                    | `0`                     |
| backend  | `DB_HOST`     | **Where the backend finds the database**    | `localhost`             |
| backend  | `DB_PORT`     | Database port                               | `5432`                  |
| backend  | `DB_NAME`     | Database name                               | `stackerino`            |
| backend  | `DB_USER`     | Database user                               | `stackerino`            |
| backend  | `DB_PASSWORD` | Database password                           | `stackerino`            |

### Endpoints

| Service  | Endpoint              | What it does                                                 |
| -------- | --------------------- | ------------------------------------------------------------ |
| frontend | `GET /`               | Page with the message board and the form                     |
| frontend | `POST /messages`      | Receives the form and sends it to the backend                |
| backend  | `GET /api/messages`   | Lists the latest 20 messages (JSON)                          |
| backend  | `POST /api/messages`  | Stores a message `{"author": "...", "text": "..."}`          |
| backend  | `GET /healthcheck`    | Says whether the backend is alive **and** can reach the DB   |

---

## Before you start (WSL) 🐧

- Open **Ubuntu** (WSL). You'll need **3 terminals**: in Windows Terminal, open new tabs with `Ctrl + Shift + T` (or use VS Code with `code .` and split the terminal).
- Work **inside Linux** (e.g. `~/`), not in `/mnt/c/...`. It's much faster.
- The Windows browser can open `http://localhost:3000` directly: WSL forwards the ports.

> [!TIP]
> Your terminal prompt should show your username (e.g. `joana@PC:~$`). It will show up in your screenshots: that's how I know they're yours.

---

## Step 1 — Fork and clone the repository

1. On GitHub, open https://github.com/professordiogodev/devops.three-stackerino and click **Fork** (top right corner). You'll get a copy in your account.
2. In WSL:

```bash
sudo apt update
sudo apt install git -y
cd ~
git clone https://github.com/<YOUR-USERNAME>/devops.three-stackerino
cd devops.three-stackerino
```

---

## Step 2 — Terminal 1: the DATABASE 🗄️

### 2.1 Install and start PostgreSQL

```bash
sudo apt install postgresql -y
sudo service postgresql start
sudo service postgresql status      # should say "online"
```

> [!NOTE]
> On WSL, PostgreSQL **does not start by itself** when you turn on your computer. Every time you come back to this lab, run `sudo service postgresql start` again.

### 2.2 Create the user and the database

PostgreSQL comes with a superuser called `postgres`. We use it **once** to create a user and a database just for our app:

```bash
sudo -u postgres psql -c "CREATE USER stackerino WITH PASSWORD 'stackerino';"
sudo -u postgres psql -c "CREATE DATABASE stackerino OWNER stackerino;"
```

### 2.3 Create the table

```bash
psql -h localhost -U stackerino -d stackerino -f db/init.sql
```

It asks for the password: type `stackerino` (nothing shows up while you type, that's normal).

### 2.4 Look at what's in there

```bash
psql -h localhost -U stackerino -d stackerino
```

Inside `psql` (the prompt changes to `stackerino=>`):

```sql
\dt
SELECT * FROM messages;
```

You should see the `messages` table with **one** message from the Teacher. Exit with `\q`.

> [!TIP]
> ✅ The database is ready. It speaks **SQL**, on port **5432**. Nobody will open it in a browser: only the backend talks to it.

---

## Step 3 — Terminal 2: the BACKEND 🧠

Open a **new** terminal:

```bash
cd ~/devops.three-stackerino/backend

sudo apt install python3-venv -y
python3 -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt

export NUMBER=1
python3 app.py
```

On startup, the backend shows **where** it will look for the database:

```
Backend 1 listening on http://0.0.0.0:5500/api/messages
The backend will use the database at localhost:5432/stackerino (user stackerino)
```

> [!TIP]
> ✅ Test it in the browser:
> - http://localhost:5500/healthcheck → `{"backend": "ok", "database": "ok"}`
> - http://localhost:5500/api/messages → **JSON** with the Teacher's message

> [!WARNING]
> Leave this terminal **running**! `Ctrl + C` stops the backend.

---

## Step 4 — Terminal 3: the FRONTEND 🖥️

Open a **third** terminal. First check your Node version:

```bash
node -v
```

You need version **18 or higher**. If you get an error or an older version, install it with `nvm`:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install --lts
node -v
```

Then:

```bash
cd ~/devops.three-stackerino/frontend
npm install

export BACKEND_URL=http://localhost:5500
node index.js
```

> [!TIP]
> ✅ Open http://localhost:3000. You should see **Frontend ✅ → Backend ✅ → Database ✅**, the Teacher's message, and a form.

### 4.1 Write on the board ✍️

Post **3 messages**, at least one with **your name** in the "author" field. Then go back to **Terminal 1** and confirm they made it into the database:

```bash
psql -h localhost -U stackerino -d stackerino -c "SELECT * FROM messages;"
```

🎉 **Three services integrated!** You wrote in the browser → the frontend sent it to the backend → the backend stored it in PostgreSQL.

Now stop the frontend and the backend (`Ctrl + C`) and start them again. The messages **are still there**: they're stored in the database, not in the apps' memory.

---

## Step 5 — Break it on purpose 🔨 (very important!)

In a chain of 3 services, when something fails you have to figure out **which link** broke.

### 5.1 Turn off the database

```bash
# Terminal 1
sudo service postgresql stop
```

Refresh http://localhost:3000 → **🟠 The backend responds, but the database does not**. Also open http://localhost:5500/healthcheck → `"database": "error"`. Look at Terminal 2: the error shows up in the backend's log.

Turn it back on: `sudo service postgresql start` and refresh the page.

### 5.2 Turn off the backend

In Terminal 2, `Ctrl + C`. Refresh http://localhost:3000 → **😢 The frontend is up, but the backend is not responding**.

Start the backend again (`python3 app.py`) and refresh.

> [!IMPORTANT]
> Notice: the **same** error page shows up for failures at different points in the chain. The frontend only knows how to talk to the backend; it's the backend that tells it "the DB isn't responding". That's how you troubleshoot in real life: **follow the chain, one link at a time.**

### 🩺 Troubleshooting checklist

1. Is the DB running? `sudo service postgresql status`
2. Can I log into the DB with the backend's credentials? `psql -h localhost -U stackerino -d stackerino -c "SELECT 1;"`
3. Is the backend running and can it reach the DB? `curl localhost:5500/healthcheck`
4. Is the frontend running? `curl localhost:3000/healthcheck`
5. Are `BACKEND_URL` and the `DB_*` variables correct? Both services print them on startup.

| Error                                                  | Likely cause                                                                   |
| ------------------------------------------------------ | ------------------------------------------------------------------------------ |
| `Connection refused` on port 5432                      | PostgreSQL is off → `sudo service postgresql start`                            |
| `password authentication failed for user "stackerino"` | Wrong `DB_PASSWORD`, or you didn't run step 2.2                                |
| `relation "messages" does not exist`                   | You didn't run `db/init.sql` (step 2.3)                                        |
| `database "stackerino" does not exist`                 | You didn't run step 2.2                                                        |
| `Address already in use` (port 5500 or 3000)           | Something is already on that port (e.g. another terminal or VS Code's Live Server). Close it, or change `PORT` |
| `fetch is not defined` / `fetch failed` in the frontend | Old Node (< 18) or the backend is off                                         |

---

## Step 6 — Required challenge: message count 🧮

You'll add a feature that goes through **all three services**:

> The frontend page must show **"Total messages: N"**, where N is calculated by the database.

What you need to do:

1. **Database:** the count is done in SQL: `SELECT COUNT(*) FROM messages;` (try it in `psql` first).
2. **Backend (`backend/app.py`):** create a new endpoint `GET /api/stats` that returns `{"total_messages": N}`. Use `list_messages()` as inspiration.
3. **Frontend (`frontend/index.js`):** in the `GET /` route, also call `${backendUrl}/api/stats` and show the total on the page.
4. Restart the backend and the frontend (`Ctrl + C` and start again) and test.
5. Commit and push to **your** fork:

```bash
cd ~/devops.three-stackerino
git add .
git commit -m "Challenge: message count"
git push
```

> [!TIP]
> If `git push` asks for a password, GitHub won't accept your normal password: use a **Personal Access Token** (GitHub → Settings → Developer settings → Personal access tokens) or log in with `gh auth login`.

---

## 📤 Submission (on Teams)

In the Teams assignment, submit:

1. The **link to your fork** on GitHub (e.g. `https://github.com/joana/devops.three-stackerino`), with the challenge commit.
2. **7 screenshots**, with the file names below. In every terminal screenshot, **your username must be visible in the prompt**.

| Screenshot                   | What it must show                                                                                                      |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `print-1-db.png`             | Terminal 1: `sudo service postgresql status` (online) **and** `\dt` with the `messages` table                          |
| `print-2-backend.png`        | Terminal 2 with the backend running **and** the browser at http://localhost:5500/healthcheck with `"database": "ok"`   |
| `print-3-frontend.png`       | All **3 terminals** visible (side by side or as tabs) **and** the page http://localhost:3000 with your 3 messages (one with your name) |
| `print-4-select.png`         | Terminal 1: `SELECT * FROM messages;` with the same messages that appear on the page                                   |
| `print-5-no-db.png`          | Page 🟠 *"The backend responds, but the database does not"* **and** the terminal with `sudo service postgresql stop`   |
| `print-6-no-backend.png`     | Page 😢 *"The frontend is up, but the backend is not responding"* **and** Terminal 2 stopped                           |
| `print-7-challenge.png`      | Page http://localhost:3000 showing **"Total messages: N"**, where N matches `SELECT COUNT(*)`                          |

> [!TIP]
> On Windows, `Win + Shift + S` takes a screenshot of an area of the screen.

> [!CAUTION]
> Screenshots without your username visible, or identical to a classmate's, **will not be accepted**. The link must be to **your** fork, not the teacher's repository.

---

## 🏆 Extra challenges (not graded)

1. **Change the DB port:** what do you need to change in the backend if PostgreSQL is on port `5433`? And in the frontend?
2. **Two backends:** run a second backend with `NUMBER=2 PORT=5501`. Switch the frontend to it using **only** `BACKEND_URL`. Are the messages the same? Why?
3. **Delete messages:** add `DELETE /api/messages/<id>` to the backend and a 🗑️ button to the frontend.
4. **Explain:** in one sentence each, explain to a classmate why the frontend doesn't talk directly to the database.

Have fun! 🚀
