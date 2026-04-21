# Portfolio5 – Redis Pub/Sub 分散チャット (FastAPI + React)

FastAPI(WebSocket) で受けた投稿を **Redis Pub/Sub** に `PUBLISH` し、全サーバーが `SUBSCRIBE` してクライアントへ配信するサンプルです。

- 単一サーバーでも動作
- **バックエンドを2プロセス起動 (8000/8001)** しても相互にメッセージが届く（水平分散の最小実証）

## 構成
- Backend: FastAPI + WebSocket
- Frontend: Vite + React
- Redis: Docker Compose

## 前提
- Docker Desktop
- Python（backend の `.venv` を使用）
- Node.js

## 起動手順（Redis）
プロジェクトルートで実行します。

```powershell
cd c:\Portfolios\Portfolio5
docker compose up -d
# 確認
# docker compose exec redis redis-cli ping  # => PONG
```

停止：

```powershell
docker compose down
```

## 起動手順（Backend を2プロセス）
ターミナルを2つ開いて実行します。

### Backend A (port 8000)
```powershell
cd c:\Portfolios\Portfolio5\backend
.\.venv\Scripts\Activate.ps1
$env:REDIS_URL = "redis://localhost:6379/0"
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### Backend B (port 8001)
```powershell
cd c:\Portfolios\Portfolio5\backend
.\.venv\Scripts\Activate.ps1
$env:REDIS_URL = "redis://localhost:6379/0"
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001
```

ヘルスチェック：
- `http://127.0.0.1:8000/health`
- `http://127.0.0.1:8001/health`

## 起動手順（Frontend を2つ）
フロントは接続先を Vite 環境変数で切り替えます。

> `.env*` は `.gitignore` 済みです（自分の環境に合わせて作ってOK）。

### Frontend A (5173 → Backend A)
`frontend/.env.development` を作成：

```env
VITE_API_BASE_URL=http://127.0.0.1:8000
VITE_WS_URL=ws://127.0.0.1:8000/ws/chat
```

起動：
```powershell
cd c:\Portfolios\Portfolio5\frontend
npx vite --host localhost --port 5173 --strictPort
```

### Frontend B (5174 → Backend B)
`frontend/.env.development.local` を作成：

```env
VITE_API_BASE_URL=http://127.0.0.1:8001
VITE_WS_URL=ws://127.0.0.1:8001/ws/chat
```

起動：
```powershell
cd c:\Portfolios\Portfolio5\frontend
npx vite --host localhost --port 5174 --strictPort
```

## 動作確認（分散の実証）
- ブラウザで `http://localhost:5173` と `http://localhost:5174` を開く
- どちらかで送信 → **両方に表示**される
- 逆方向も確認

## 仕組み（要点）
- `backend/app/ws/chat.py`
  - クライアント投稿（`type: send_message`）を受け取る
  - メッセージを Redis に `PUBLISH`（`chat:global`）
- `backend/app/main.py`
  - 起動時に Redis を `SUBSCRIBE` する常駐タスクを開始
  - 受信した payload を `manager.broadcast` で各サーバーの接続クライアントへ配信

## トラブルシュート
- `API: ERROR` の場合
  - backend が起動しているか（`/health` をブラウザで確認）
  - CORS 許可にフロントのポート（5173/5174）が入っているか
- `WS: closed` の場合
  - `VITE_WS_URL` が正しいか（8000/8001）
  - backend の WebSocket が起動しているか



## 実務っぽさ（重複排除・順序の土台）
- backend が message_id(UUID) と created_at(UTC ISO8601) を付与して配信
- frontend は message_id をキーに重複メッセージを表示しない（分散時の二重配信対策）

