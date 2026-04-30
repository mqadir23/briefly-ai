import os
import json
import time
import sqlite3
import bcrypt
import jwt
import httpx
from datetime import datetime, timedelta
from typing import List, Optional, Dict
from fastapi import FastAPI, HTTPException, Query, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel, EmailStr
from openai import OpenAI
from dotenv import load_dotenv

# ==============================================================================
# CONFIGURATION
# ==============================================================================
load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
JWT_SECRET = os.getenv("JWT_SECRET", "briefly-ai-super-secret-key-123") # Change in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 1 week

client = OpenAI(
    api_key=GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1",
)

# Models to try in order — if one fails, the next is attempted
FALLBACK_MODELS = [
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
    "gemma2-9b-it",
    "mixtral-8x7b-32768",
]

print(f"✓ Groq API configured (key: ...{GROQ_API_KEY[-6:] if GROQ_API_KEY else 'MISSING'})")

app = FastAPI(title="Briefly AI Backend")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================================================================
# DATABASE SETUP (SQLite)
# ==============================================================================
DB_PATH = "briefly.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Users table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT,
        full_name TEXT,
        auth_provider TEXT DEFAULT 'email', -- 'email' or 'google'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    # Preferences table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS user_preferences (
        user_id INTEGER PRIMARY KEY,
        interests TEXT, -- JSON string
        region TEXT DEFAULT 'Global',
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )
    """)
    
    conn.commit()
    conn.close()

init_db()

# ==============================================================================
# AUTH UTILS
# ==============================================================================
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        return email
    except jwt.PyJWTError:
        raise credentials_exception

# ==============================================================================
# DATA MODELS
# ==============================================================================

class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class GoogleLogin(BaseModel):
    id_token: str

class SummarizeRequest(BaseModel):
    content: str
    input_type: str  # 'text', 'url', 'voice', 'ocr'
    eli5: bool = False

class TranslateRequest(BaseModel):
    headline: str
    bullets: List[str]
    target_language: str

# ==============================================================================
# SMART MODEL CALLER
# ==============================================================================

def call_llm(prompt: str) -> str:
    last_error = None
    for model_name in FALLBACK_MODELS:
        try:
            response = client.chat.completions.create(
                model=model_name,
                messages=[
                    {"role": "system", "content": "You are a helpful assistant that always responds with valid JSON only. No markdown, no explanation, no code fences, just raw JSON."},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.7,
                max_tokens=2048,
            )
            result = response.choices[0].message.content
            return result
        except Exception as e:
            last_error = e
            continue
    raise last_error

def parse_json_response(text: str) -> dict:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        cleaned = cleaned.split("\n", 1)[1] if "\n" in cleaned else cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()
    return json.loads(cleaned)

# ==============================================================================
# ENDPOINTS
# ==============================================================================

@app.get("/health")
async def health_check():
    return {"status": "ok", "db": os.path.exists(DB_PATH)}

# ── AUTH ENDPOINTS ──────────────────────────────────────────────────────────

@app.post("/auth/register")
async def register(user: UserRegister):
    hashed_pwd = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO users (email, password_hash, full_name) VALUES (?, ?, ?)",
            (user.email, hashed_pwd, user.full_name)
        )
        conn.commit()
        token = create_access_token(data={"sub": user.email})
        return {"access_token": token, "token_type": "bearer", "user": {"email": user.email, "full_name": user.full_name}}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Email already registered")
    finally:
        conn.close()

@app.post("/auth/login")
async def login(user: UserLogin):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT password_hash, full_name FROM users WHERE email = ? AND auth_provider = 'email'", (user.email,))
    row = cursor.fetchone()
    conn.close()
    
    if not row or not bcrypt.checkpw(user.password.encode('utf-8'), row[0].encode('utf-8')):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    token = create_access_token(data={"sub": user.email})
    return {"access_token": token, "token_type": "bearer", "user": {"email": user.email, "full_name": row[1]}}

@app.post("/auth/google")
async def google_auth(req: GoogleLogin):
    # Verify Google ID Token
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={req.id_token}")
        if resp.status_code != 200:
            raise HTTPException(status_code=401, detail="Invalid Google token")
        
        google_data = resp.json()
        email = google_data.get("email")
        full_name = google_data.get("name")
        
        # Check if user exists
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("SELECT full_name FROM users WHERE email = ?", (email,))
        row = cursor.fetchone()
        
        if not row:
            # Create user
            cursor.execute(
                "INSERT INTO users (email, full_name, auth_provider) VALUES (?, ?, ?)",
                (email, full_name, 'google')
            )
            conn.commit()
        
        conn.close()
        token = create_access_token(data={"sub": email})
        return {"access_token": token, "token_type": "bearer", "user": {"email": email, "full_name": full_name}}

# ── AI ENDPOINTS (Protected) ─────────────────────────────────────────────────

@app.post("/summarize")
async def summarize(req: SummarizeRequest, current_user: str = Depends(get_current_user)):
    try:
        style = "simple, child-friendly" if req.eli5 else "professional, concise"
        prompt = f"""Summarize the following content in a {style} way.
Return the result ONLY as a valid JSON object with this exact structure:
{{
    "headline": "A catchy, descriptive headline",
    "bullets": ["Key point 1", "Key point 2", "Key point 3", "Key point 4", "Key point 5"],
    "sentiment": "positive",
    "sentiment_score": 0.75
}}
Content to summarize:
{req.content}"""

        raw = call_llm(prompt)
        data = parse_json_response(raw)
        data["source_url"] = req.content if req.input_type == "url" else None
        data["input_type"] = req.input_type
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/insights")
async def get_insights(
    region: str = "Global",
    time_filter: str = "Today",
    interests: Optional[str] = None,
    current_user: str = Depends(get_current_user)
):
    interest_list = interests if interests else "general news"
    prompt = f"""Generate realistic news insights for: Region: {region}, Time: {time_filter}, Interests: {interest_list}.
Return ONLY valid JSON with positive_percent, negative_percent, neutral_percent, total_articles, trend_points, top_entities, hot_topics."""

    try:
        raw = call_llm(prompt)
        return parse_json_response(raw)
    except Exception as e:
        return {"error": "Failed to generate insights"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
