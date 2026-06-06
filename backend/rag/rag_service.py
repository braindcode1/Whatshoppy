import os
import json
import logging
import requests
import numpy as np
import faiss
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rag_service")

# Resolve absolute paths based on this file's location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INDEX_PATH = os.path.join(SCRIPT_DIR, "whatshoppy.index")
CHUNKS_PATH = os.path.join(SCRIPT_DIR, "chunks.json")

# Expose FastAPI application
app = FastAPI(title="WhatShoppy RAG Navigation Assistant")

# Global instances loaded on startup
model = None
index = None
chunks = []

@app.on_event("startup")
def startup_event():
    global model, index, chunks
    logger.info("Initializing RAG Navigation Assistant Service...")
    
    # 1. Load sentence-transformers model
    logger.info("Loading sentence-transformers/all-MiniLM-L6-v2 model...")
    model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    
    # 2. Load FAISS index
    if not os.path.exists(INDEX_PATH):
        logger.error(f"FAISS index not found at: {INDEX_PATH}. Please run build_index.py first.")
        return
    
    logger.info(f"Loading FAISS index from: {INDEX_PATH}")
    index = faiss.read_index(INDEX_PATH)
    
    # 3. Load Chunks JSON
    if not os.path.exists(CHUNKS_PATH):
        logger.error(f"Chunks file not found at: {CHUNKS_PATH}. Please run build_index.py first.")
        return
        
    logger.info(f"Loading chunks metadata from: {CHUNKS_PATH}")
    with open(CHUNKS_PATH, 'r', encoding='utf-8') as f:
        chunks = json.load(f)
        
    logger.info("RAG Service initialization complete and ready.")

class AskRequest(BaseModel):
    question: str

class AskResponse(BaseModel):
    success: bool
    question: str
    answer: str
    sources: list[str]

def detect_lang(text: str) -> str:
    text_lower = text.lower()
    french_words = [
        "bonjour", "salut", "comment", "produit", "commande", 
        "client", "paramètre", "parametres", "mot de passe", 
        "où", "ou trouver", "ajouter", "changer", "statut"
    ]
    # Check for Arabic characters
    has_arabic = any("\u0600" <= char <= "\u06ff" for char in text)
    if has_arabic:
        return "ar"
    if any(word in text_lower for word in french_words):
        return "fr"
    return "en"

def call_gemini_api(api_key: str, gemini_model: str, system_prompt: str, user_prompt: str) -> str:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{gemini_model}:generateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    body = {
        "system_instruction": {
            "parts": [{"text": system_prompt}]
        },
        "contents": [
            {
                "role": "user",
                "parts": [{"text": user_prompt}]
            }
        ],
        "generationConfig": {
            "temperature": 0.3,
            "maxOutputTokens": 400
        }
    }
    
    logger.info(f"Calling Gemini API using model: {gemini_model}...")
    response = requests.post(url, headers=headers, json=body, timeout=12)
    response.raise_for_status()
    res_data = response.json()
    
    try:
        text = res_data["candidates"][0]["content"]["parts"][0]["text"]
        return text.strip()
    except (KeyError, IndexError, TypeError) as e:
        logger.error(f"Error parsing Gemini response: {e}")
        raise ValueError("Failed to parse Gemini response structure")

@app.get("/health")
def health_check():
    return {
        "success": True,
        "message": "WhatShoppy RAG service is running"
    }

@app.post("/ask-navigation", response_model=AskResponse)
def ask_navigation(req: AskRequest):
    question = req.question.strip()
    if not question:
        raise HTTPException(status_code=400, detail="Question cannot be empty.")
        
    if model is None or index is None or not chunks:
        # Try loading on demand in case startup skipped or failed
        try:
            startup_event()
        except Exception:
            pass
        if model is None or index is None or not chunks:
            raise HTTPException(
                status_code=500, 
                detail="RAG Service is not fully initialized. Ensure build_index.py has been run."
            )
        
    logger.info(f"Received question: {question}")
    
    # 1. Embed query
    query_vector = model.encode([question]).astype('float32')
    faiss.normalize_L2(query_vector)
    
    # 2. Search FAISS index for top_k = 4 chunks
    k = min(4, len(chunks))
    scores, indices = index.search(query_vector, k=k)
    
    # 3. Apply similarity threshold of 0.35
    threshold = 0.35
    valid_chunks = []
    
    for score, idx in zip(scores[0], indices[0]):
        if idx >= 0 and idx < len(chunks):
            logger.info(f"Retrieved chunk: '{chunks[idx]['title']}' with score: {score:.4f}")
            if score >= threshold:
                valid_chunks.append(chunks[idx])
                
    # Out of scope message
    out_of_scope_answer = (
        "I can only help with navigation and usage of the WhatShoppy application. "
        "You can ask me about Dashboard, Products, Orders, Clients, Settings, Inbox, or AI product analysis."
    )
    
    # If top match is below threshold, return out of scope response immediately
    if not valid_chunks:
        logger.info("Top retrieval score is below similarity threshold. Returning out of scope response.")
        return AskResponse(
            success=True,
            question=question,
            answer=out_of_scope_answer,
            sources=[]
        )
        
    # Get unique source titles
    sources = list(dict.fromkeys([c['title'] for c in valid_chunks]))
    
    # Check for Gemini API key
    api_key = os.environ.get("GEMINI_API_KEY")
    gemini_model = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
    
    if api_key and api_key.strip():
        # Mode A: Gemini assisted generation
        try:
            # Construct context
            context_parts = []
            for chunk in valid_chunks:
                context_parts.append(f"Section: {chunk['title']}\nContent: {chunk['content']}")
            retrieved_context = "\n\n---\n\n".join(context_parts)
            
            system_prompt = (
                "You are the WhatShoppy Navigation Assistant.\n\n"
                "Answer the user only using the provided context.\n"
                "If the context does not contain the answer, say:\n"
                "\"I can only help with navigation and usage of the WhatShoppy application.\"\n\n"
                "Rules:\n"
                "- Answer in English unless the user asks in French or Arabic.\n"
                "- Be short and clear.\n"
                "- Give steps when useful.\n"
                "- Do not mention embeddings, chunks, FAISS, Supabase, API, or technical errors.\n"
                "- Do not answer questions outside the WhatShoppy app navigation."
            )
            
            user_prompt = f"Context:\n{retrieved_context}\n\nUser question:\n{question}"
            
            answer = call_gemini_api(api_key, gemini_model, system_prompt, user_prompt)
            
            logger.info("Successfully generated answer using Mode A (Gemini).")
            return AskResponse(
                success=True,
                question=question,
                answer=answer,
                sources=sources
            )
        except Exception as e:
            logger.error(f"Mode A (Gemini) failed: {e}. Falling back to Mode B...")
            # Fall through to Mode B on failure
            
    # Mode B: Local fallback generation using the most relevant chunk
    logger.info("Executing Mode B: Local fallback generation...")
    most_relevant = valid_chunks[0]
    lang = detect_lang(question)
    
    if lang == "fr":
        fallback_answer = (
            f"Voici les informations de navigation pour la section '{most_relevant['title']}':\n\n"
            f"{most_relevant['content']}"
        )
    else:
        fallback_answer = (
            f"Here is the navigation info for '{most_relevant['title']}':\n\n"
            f"{most_relevant['content']}"
        )
        
    return AskResponse(
        success=True,
        question=question,
        answer=fallback_answer,
        sources=sources
    )
