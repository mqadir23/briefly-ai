# main.py
import os
import json
import time
import hmac
import hashlib
import sqlite3
from typing import List, Optional, Dict
from datetime import datetime, timedelta
from collections import Counter
from math import log

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from dotenv import load_dotenv
from openai import OpenAI
from ddgs import DDGS

load_dotenv()

# ==============================================================================
# CONFIG & MODELS
# ==============================================================================

app = FastAPI(title="Briefly AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Use a 32-byte secret for security
JWT_SECRET = os.getenv("JWT_SECRET", "briefly-ai-super-secret-key-32-chars-long!")
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7 # 1 week

class UserRegister(BaseModel):
    email: EmailStr
    full_name: str
    google_id: str

class SummarizeRequest(BaseModel):
    content: str
    input_type: str = "text" # text, url, ocr, voice
    eli5: bool = False

class InsightRequest(BaseModel):
    region: str = "Global"
    time_filter: str = "Today"
    interests: List[str] = []

# ==============================================================================
# DB & AUTH
# ==============================================================================

def get_db():
    conn = sqlite3.connect("briefly.db")
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    db = get_db()
    db.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            full_name TEXT,
            google_id TEXT UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    db.commit()

init_db()

def create_token(data: dict):
    # Simple HMAC-based "token" for demonstration (not full JWT but similar logic)
    payload = json.dumps(data)
    signature = hmac.new(JWT_SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return f"{payload}.{signature}"

def verify_token(token: str):
    try:
        payload_str, signature = token.rsplit(".", 1)
        expected_sig = hmac.new(JWT_SECRET.encode(), payload_str.encode(), hashlib.sha256).hexdigest()
        
        if hmac.compare_digest(signature, expected_sig):
            return json.loads(payload_str)
    except:
        pass
    return None

async def get_current_user(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    token = authorization.split(" ", 1)[1]
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    return payload["email"]

# ==============================================================================
# AI SERVICES (GROQ/OPENAI)
# ==============================================================================

client = OpenAI(
    base_url="https://api.groq.com/openai/v1",
    api_key=os.getenv("GROQ_API_KEY")
)

def call_llm(prompt: str, model: str = "llama-3.3-70b-versatile") -> str:
    try:
        response = client.chat.completions.create(
            messages=[{"role": "user", "content": prompt}],
            model=model,
            temperature=0.2,
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"LLM Error: {e}")
        return ""

# ==============================================================================
# DATA MINING & REAL-TIME SEARCH
# ==============================================================================

def fetch_realtime_news(query: str, max_results: int = 10, timelimit: Optional[str] = None) -> List[dict]:
    try:
        time.sleep(1.0) # Rate limit protection
        ddgs = DDGS()
        results = ddgs.news(query, max_results=max_results, timelimit=timelimit)
        if not results:
            return _get_mock_news(query)
        return [{"title": r.get("title", ""), "body": r.get("body", ""), "href": r.get("url", "")} for r in results]
    except Exception as e:
        print(f"Search error: {e}")
        return _get_mock_news(query)

def _get_mock_news(query: str) -> List[dict]:
    return [
        {"title": f"Latest updates on {query}", "body": "Stable growth observed in the region with new initiatives launching this week.", "href": "#"},
        {"title": f"Market trends in {query}", "body": "Analysts report increased interest in local startups and technology hubs.", "href": "#"}
    ]

def compute_tfidf(documents: List[str]):
    tokenized_docs = [doc.lower().split() for doc in documents]
    tf = []
    for doc in tokenized_docs:
        doc_len = max(len(doc), 1)
        counts = Counter(doc)
        tf.append({word: count/doc_len for word, count in counts.items()})
    
    all_words = set(word for doc in tokenized_docs for word in doc)
    df = Counter()
    for word in all_words:
        for doc in tokenized_docs:
            if word in doc:
                df[word] += 1
    
    n = len(documents)
    idf = {word: log(n / (count)) for word, count in df.items()}
    
    tfidf = []
    for doc_tf in tf:
        tfidf.append({word: val * idf.get(word, 0) for word, val in doc_tf.items()})
    
    return tfidf, list(all_words)

def kmeans_cluster(tfidf_docs: List[dict], vocab: List[str], k: int = 3):
    if not tfidf_docs: return [], []
    # Simplified K-Means logic
    centroids = [tfidf_docs[i] for i in range(min(k, len(tfidf_docs)))]
    
    for _ in range(5): # 5 iterations
        clusters = [[] for _ in range(k)]
        for idx, doc in enumerate(tfidf_docs):
            # Find closest centroid
            best_sim = -1
            best_c = 0
            for ci, centroid in enumerate(centroids):
                sim = sum(doc.get(w, 0) * centroid.get(w, 0) for w in doc)
                if sim > best_sim:
                    best_sim = sim
                    best_c = ci
            clusters[best_c].append(idx)
        
        # Update centroids
        for ci in range(k):
            if not clusters[ci]: continue
            new_c = {}
            for idx in clusters[ci]:
                for w, val in tfidf_docs[idx].items():
                    new_c[w] = new_c.get(w, 0) + val / len(clusters[ci])
            centroids[ci] = new_c
            
    return clusters, centroids

def get_top_keywords(centroid: dict, top_n: int = 5):
    sorted_words = sorted(centroid.items(), key=lambda x: x[1], reverse=True)
    return [w for w, v in sorted_words[:top_n]]

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

@app.post("/auth/google")
async def google_auth(user: UserRegister):
    db = get_db()
    
    # Check if user exists by google_id
    existing = db.execute("SELECT * FROM users WHERE google_id = ?", (user.google_id,)).fetchone()
    
    if not existing:
        # Check if user exists by email (link account)
        existing_by_email = db.execute("SELECT * FROM users WHERE email = ?", (user.email,)).fetchone()
        if existing_by_email:
            db.execute("UPDATE users SET google_id = ?, full_name = ? WHERE email = ?",
                       (user.google_id, user.full_name, user.email))
            db.commit()
        else:
            # Create new user
            db.execute("INSERT INTO users (email, full_name, google_id) VALUES (?, ?, ?)",
                       (user.email, user.full_name, user.google_id))
            db.commit()
    
    token = create_token({"email": user.email, "name": user.full_name})
    return {"token": token, "user": {"email": user.email, "full_name": user.full_name}}

@app.post("/summarize")
async def summarize(req: SummarizeRequest, current_user: str = Depends(get_current_user)):
    try:
        content_to_summarize = req.content
        source_url = req.content if req.input_type == "url" else None
        
        if req.input_type in ["text", "voice"] and len(req.content.split()) < 20:
            live_news = fetch_realtime_news(req.content, max_results=3)
            if live_news:
                context_str = "\n".join([f"- {n['title']}: {n['body']}" for n in live_news])
                content_to_summarize = f"User Question: {req.content}\n\nLatest Live News Context:\n{context_str}"

        style = "simple, child-friendly" if req.eli5 else "professional, concise"
        prompt = f"""Summarize the following content in a {style} way.
Return the result ONLY as a valid JSON object:
{{
    "headline": "...",
    "bullets": ["...", "...", "...", "...", "..."],
    "sentiment": "positive",
    "sentiment_score": 0.75
}}
Content: {content_to_summarize}"""

        raw = call_llm(prompt)
        data = parse_json_response(raw)
        data["source_url"] = source_url
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
    time_map = {"Today": "d", "Last 7 Days": "w", "Last 30 Days": "m", "Last 3 Months": "m"}
    t_limit = time_map.get(time_filter, "d")

    live_news = fetch_realtime_news(f"{region} {interest_list}", max_results=10, timelimit=t_limit)
    context_str = "\n".join([f"- {n['title']}: {n['body']}" for n in live_news]) if live_news else "No news found."
    
    prompt = f"""Generate news insights for Region: {region}, Interests: {interest_list}, Time: {time_filter}.
News: {context_str}
Return ONLY JSON:
{{
    "positive_percent": 45.0,
    "negative_percent": 25.0,
    "neutral_percent": 30.0,
    "total_articles": 10,
    "trend_points": [{{"date": "May 1", "value": 12}}],
    "top_entities": [{{"name": "...", "type": "company", "mentions": 5, "sentiment": "positive"}}],
    "hot_topics": ["Topic 1", "Topic 2"],
    "sentiment_volatility": 0.15,
    "entity_pulse": [{{"name": "Entity", "pulse": [10, 15, 8, 20]}}]
}}"""

    try:
        raw = call_llm(prompt)
        return parse_json_response(raw)
    except Exception as e:
        return {"positive_percent": 0, "negative_percent": 0, "neutral_percent": 0, "total_articles": 0,
                "trend_points": [], "top_entities": [], "hot_topics": [], "sentiment_volatility": 0, "entity_pulse": []}

@app.get("/mining/clusters")
async def get_mining_clusters(topic: str = "world news", current_user: str = Depends(get_current_user)):
    news = fetch_realtime_news(topic, max_results=20)
    if not news: return {"clusters": []}
    docs = [f"{n['title']} {n['body']}" for n in news]
    tfidf_docs, vocab = compute_tfidf(docs)
    k = min(3, len(docs))
    clusters_indices, centroids = kmeans_cluster(tfidf_docs, vocab, k=k)
    
    result_clusters = []
    for i, cluster in enumerate(clusters_indices):
        if not cluster: continue
        top_words = get_top_keywords(centroids[i], top_n=5)
        articles = [news[idx]['title'] for idx in cluster[:3]]
        result_clusters.append({"id": i + 1, "theme_keywords": top_words, "article_count": len(cluster), "top_articles": articles})
    return {"clusters": result_clusters, "total_analyzed": len(docs)}

@app.get("/mining/advanced")
async def get_advanced_mining(region: str = "Global", current_user: str = Depends(get_current_user)):
    news = fetch_realtime_news(f"{region} news", max_results=20)
    if not news: return {"error": "No news found"}
    docs = [f"{n['title']} {n['body']}" for n in news]
    
    prompt = f"""Perform advanced data mining and relationship extraction on the following news articles:
{" ".join(docs[:8])}

Extract a knowledge graph representing key relationships.
Return the result ONLY as a valid JSON object with the following structure:
{{
    "keyword_network": [
        {{"source": "Entity A", "target": "Entity B", "weight": 7}},
        {{"source": "Entity C", "target": "Entity D", "weight": 5}}
    ],
    "sentiment_distribution": {{
        "very_positive": 2,
        "positive": 8,
        "neutral": 12,
        "negative": 6,
        "very_negative": 2
    }},
    "emerging_trends": [
        {{"topic": "Trend Name", "strength": 0.85}}
    ]
}}

Requirements:
1. "keyword_network" must contain at least 4 real-world connections found in the text.
2. "weight" should be an integer from 1-10 based on connection strength.
3. Use specific names of companies, people, technologies, or events as sources/targets.
4. Do NOT use generic placeholder names like "word1" or "Entity A".
"""
    try:
        raw = call_llm(prompt)
        data = parse_json_response(raw)
        return data
    except Exception as e:
        print(f"Mining error: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
