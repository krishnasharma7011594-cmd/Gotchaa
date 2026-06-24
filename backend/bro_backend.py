import os
import time
import base64
import logging
import asyncio
from typing import Optional, Dict, Any
from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# LLM SDKs
from groq import Groq
import google.generativeai as genai

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BRO-Backend")

# Load environment variables
load_dotenv()

# Startup Instructions:
# 1. Create a .env file in this directory with GROQ_API_KEY and GEMINI_API_KEY
# 2. Install dependencies: pip install fastapi uvicorn groq google-generative-ai python-dotenv
# 3. Run server: uvicorn bro_backend:app --reload --host 0.0.0.0 --port 8000
# 4. Interactive API Docs: http://localhost:8000/docs

app = FastAPI(title="BRO - Jarvis AI Backend for Gotchaa")

# CORS Middleware for Flutter handles (localhost:8000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Models ───────────────────────────────────────────────────────────────────

class TextChatRequest(BaseModel):
    user_input: str
    user_id: str
    action_context: Optional[str] = None

class VoiceChatRequest(BaseModel):
    audio_base64: str  # Base64 encoded audio string
    user_id: str

class BroResponse(BaseModel):
    action_type: str
    status: str
    text_response: str
    data: Dict[str, Any] = {}
    execution_time: float
    error: Optional[str] = None

# ── Core Logic ───────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """
You are BRO, the street-smart, Jarvis-like AI action assistant for the Gotchaa super app. 
Help the user with: cab booking, food ordering, shopping, and payments.
Your tone is proactive, reliable, and uses fluent Hinglish/English.
Be concise. If an action is detected, focus on getting it done.
"""

def detect_action(text: str) -> str:
    text = text.lower()
    if any(k in text for k in ["cab", "ride", "uber", "taxi"]):
        return "cab"
    if any(k in text for k in ["food", "order", "eat", "pizza", "burger"]):
        return "food"
    if any(k in text for k in ["shopping", "buy", "shop", "product"]):
        return "shopping"
    if any(k in text for k in ["pay", "payment", "transfer", "send"]):
        return "payment"
    return "info"

async def call_llm(prompt: str) -> str:
    # 1. Try Groq (Mixtral)
    try:
        client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        completion = client.chat.completions.create(
            model="mixtral-8x7b-32768",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=1024,
        )
        return completion.choices[0].message.content
    except Exception as e:
        logger.warning(f"Groq failed, falling back to Gemini: {e}")
        
    # 2. Fallback to Gemini
    try:
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
        model = genai.GenerativeModel('gemini-2.0-flash')
        response = model.generate_content(f"{SYSTEM_PROMPT}\n\nUser: {prompt}")
        return response.text
    except Exception as e:
        logger.error(f"Gemini fallback failed: {e}")
        raise HTTPException(status_code=500, detail="All LLM providers offline")

# ── Endpoints ───────────────────────────────────────────────────────────────

@app.get("/")
async def health_check():
    return {"status": "online", "agent": "BRO", "version": "1.0.0"}

@app.post("/bro/chat", response_model=BroResponse)
async def chat(request: TextChatRequest):
    start_time = time.time()
    try:
        # Detect action type
        action_type = detect_action(request.user_input)
        
        # Get LLM Response
        llm_text = await call_llm(request.user_input)
        
        execution_time = time.time() - start_time
        return BroResponse(
            action_type=action_type,
            status="success",
            text_response=llm_text,
            data={"context": request.action_context},
            execution_time=execution_time
        )
    except Exception as e:
        logger.error(f"Chat error: {e}")
        return BroResponse(
            action_type="unknown",
            status="failed",
            text_response="Mast check kar raha tha par phat gaya.",
            execution_time=time.time() - start_time,
            error=str(e)
        )

@app.post("/bro/voice-chat", response_model=BroResponse)
async def voice_chat(request: VoiceChatRequest):
    start_time = time.time()
    try:
        # NOTE: In a real production app, you would use Whisper here to transcribe the audio.
        # Since this is a template, we assume the transcription logic happens or use a mock.
        # Transcription would use the request.audio_base64
        
        # Mocking STT for now (Placeholder)
        transcribed_text = "Book a cab to the airport" # This would come from Whisper
        
        action_type = detect_action(transcribed_text)
        llm_text = await call_llm(transcribed_text)
        
        execution_time = time.time() - start_time
        return BroResponse(
            action_type=action_type,
            status="success",
            text_response=llm_text,
            data={"transcription": transcribed_text},
            execution_time=execution_time
        )
    except Exception as e:
        logger.error(f"Voice chat error: {e}")
        return BroResponse(
            action_type="unknown",
            status="failed",
            text_response="Voice command fail ho gaya, boss.",
            execution_time=time.time() - start_time,
            error=str(e)
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
