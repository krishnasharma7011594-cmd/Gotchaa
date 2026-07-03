import os
import time
import logging
import json
from typing import Optional, Dict, Any
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# LLM SDK
import google.generativeai as genai

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("BRO-Backend")

# Load environment variables
load_dotenv()

app = FastAPI(title="BRO - Jarvis AI Backend for Gotchaa")

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Models ───────────────────────────────────────────────────────────────────

class TextChatRequest(BaseModel):
    user_input: Optional[str] = None
    query: Optional[str] = None
    user_id: Optional[str] = "guest"
    action_context: Optional[str] = None

class BroResponse(BaseModel):
    action: str
    status: str
    text: str
    data: Dict[str, Any] = {}
    execution_time: float
    error: Optional[str] = None

# ── Core Logic ───────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """
You are BRO, the street-smart, Jarvis-like AI action assistant for the Gotchaa super app.
Your tone is proactive, reliable, and uses fluent Hinglish/English.
You must respond in a structured JSON format containing the text response, detected action type, and any extracted parameters.

JSON Schema to return:
{
  "action": "cab_booking" | "food_order" | "shopping" | "payment" | "navigation" | "ui_control" | "query" | "none",
  "text": "Verbal response to the user in Hinglish/English",
  "data": {
    // Extracted properties based on action:
    // cab_booking -> {"destination": "...", "suggested_provider": "uber" | "rapido"}
    // food_order -> {"item": "...", "restaurant": "Swiggy" | "EatSure" | "Fassos" | "Zepto"}
    // shopping -> {"item": "...", "store": "Amazon" | "Flipkart" | "Myntra"}
    // payment -> {"amount": "...", "recipient": "..."} // Extract if present, but it will be blocked
    // navigation -> {"target": "profile" | "camera" | "explore" | "mini_apps" | "vybz" | "chat" | "privacy" | "terms" | "settings"}
    // ui_control -> {"theme": "dark" | "light"}
  }
}

IMPORTANT LEGAL GATE: We strictly refuse to perform payment transactions (payment) because of security regulations. The "text" response for a payment must state: "Sorry boss, payments or transfers are blocked due to security regulations. You need to handle it yourself."
IMPORTANT APP-CONTAINER GATE: All cab, food, or shopping actions open inside the app's internal browser. Never suggest or launch external redirects out of the app.
"""

def detect_action(text: str) -> str:
    text = text.lower()
    
    # Legal barriers: detect payments first
    if any(k in text for k in ["pay", "payment", "transfer", "send money", "gpay", "upi", "credit card", "debit card", "checkout"]):
        return "payment"
        
    # Navigation intents
    if any(k in text for k in ["go to", "navigate", "show screen", "open screen", "open", "show"]):
        if any(np in text for np in ["profile", "my profile", "account"]):
            return "navigation"
        if any(np in text for np in ["camera", "photo", "shoot", "record"]):
            return "navigation"
        if any(np in text for np in ["reels", "vybz", "video feed", "feed"]):
            return "navigation"
        if any(np in text for np in ["explore", "search"]):
            return "navigation"
        if any(np in text for np in ["mini app", "mini-app", "apps", "store"]):
            return "navigation"
        if any(np in text for np in ["chat", "message", "inbox"]):
            return "navigation"
        if any(np in text for np in ["setting", "options"]):
            return "navigation"
        if any(np in text for np in ["privacy", "policy"]):
            return "navigation"
        if any(np in text for np in ["terms", "conditions"]):
            return "navigation"
            
    # UI Control
    if any(k in text for k in ["dark mode", "light mode", "dark theme", "light theme", "night mode", "day mode"]):
        return "ui_control"
        
    # Standard actions
    if any(k in text for k in ["cab", "ride", "uber", "taxi", "rapido", "book ride"]):
        return "cab_booking"
    if any(k in text for k in ["food", "order", "eat", "pizza", "burger", "swiggy", "eatsure", "zomato"]):
        return "food_order"
    if any(k in text for k in ["shopping", "buy", "shop", "product", "amazon", "flipkart", "myntra"]):
        return "shopping"
        
    # Otherwise query or none
    if "?" in text or any(k in text for k in ["what", "how", "why", "who", "tell me"]):
        return "query"
        
    return "none"

async def call_llm(prompt: str) -> str:
    try:
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
        model = genai.GenerativeModel('gemini-2.0-flash')
        response = model.generate_content(f"{SYSTEM_PROMPT}\n\nUser: {prompt}")
        return response.text
    except Exception as e:
        logger.error(f"Gemini call failed: {e}")
        raise HTTPException(status_code=500, detail=f"Gemini provider offline: {e}")

def clean_and_parse_llm_json(llm_out: str, original_query: str) -> Dict[str, Any]:
    cleaned = llm_out.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()
    
    try:
        data = json.loads(cleaned)
        # Ensure it has necessary keys
        if "action" in data and "text" in data:
            # Legal validation guard
            if data["action"] == "payment":
                data["text"] = "Sorry boss, payments or transfers are blocked due to security regulations. You need to handle it yourself."
                data["data"] = {}
            return data
    except Exception as e:
        logger.warning(f"Could not parse LLM output JSON: {e}. Output: {llm_out}")
        
    # Regex fallback parser
    action = detect_action(original_query)
    text = llm_out
    extracted_data = {}
    
    if action == "payment":
        text = "Sorry boss, payments or transfers are blocked due to security regulations. You need to handle it yourself."
    elif action == "navigation":
        target = "chat"
        lowered = original_query.lower()
        if "profile" in lowered: target = "profile"
        elif "camera" in lowered or "photo" in lowered or "shoot" in lowered: target = "camera"
        elif "explore" in lowered: target = "explore"
        elif "mini" in lowered or "apps" in lowered: target = "mini_apps"
        elif "reels" in lowered or "vybz" in lowered or "video" in lowered: target = "vybz"
        elif "privacy" in lowered: target = "privacy"
        elif "terms" in lowered: target = "terms"
        elif "setting" in lowered: target = "settings"
        extracted_data = {"target": target}
    elif action == "ui_control":
        theme = "dark"
        lowered = original_query.lower()
        if "light" in lowered or "day" in lowered: theme = "light"
        extracted_data = {"theme": theme}
    elif action == "cab_booking":
        extracted_data = {"destination": "Cyber City", "suggested_provider": "uber"}
    elif action == "food_order":
        extracted_data = {"item": "Food Item", "restaurant": "Swiggy"}
    elif action == "shopping":
        extracted_data = {"item": "Shopping Item", "store": "Amazon"}
        
    return {
        "action": action,
        "text": text,
        "data": extracted_data
    }

# ── Endpoints ───────────────────────────────────────────────────────────────

@app.get("/")
async def health_check():
    return {"status": "online", "agent": "BRO", "version": "1.1.0"}

@app.post("/bro/chat", response_model=BroResponse)
async def chat(request: TextChatRequest):
    start_time = time.time()
    
    # Resolve correct user query field
    query_text = request.query or request.user_input
    if not query_text:
        raise HTTPException(status_code=400, detail="Missing text input payload (query or user_input)")
        
    try:
        # Get LLM Response
        llm_text = await call_llm(query_text)
        parsed = clean_and_parse_llm_json(llm_text, query_text)
        
        execution_time = time.time() - start_time
        return BroResponse(
            action=parsed["action"],
            status="success",
            text=parsed["text"],
            data=parsed.get("data", {}),
            execution_time=execution_time
        )
    except Exception as e:
        logger.error(f"Chat error: {e}")
        return BroResponse(
            action="none",
            status="failed",
            text="Sorry, boss. Kuch phat gaya backend par.",
            execution_time=time.time() - start_time,
            error=str(e)
        )

@app.post("/bro/voice-chat", response_model=BroResponse)
async def voice_chat(
    audio: UploadFile = File(...),
    user_id: Optional[str] = Form("guest")
):
    start_time = time.time()
    try:
        # Read the file bytes
        audio_content = await audio.read()
        
        # Determine client mime type (default to audio/mp4 for m4a)
        mime_type = audio.content_type or "audio/mp4"
        if audio.filename and audio.filename.endswith(".m4a"):
            mime_type = "audio/mp4"

        # Transcribe audio using Gemini directly
        transcribed_text = ""
        try:
            genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
            transcribe_model = genai.GenerativeModel('gemini-2.0-flash')
            
            logger.info("Transcribing audio using Gemini...")
            audio_part = {
                "mime_type": mime_type,
                "data": audio_content
            }
            transcribe_response = transcribe_model.generate_content([
                audio_part,
                "Transcribe this speech accurately. Return only the transcribed text without warnings, preambles, or formatting."
            ])
            transcribed_text = transcribe_response.text.strip()
            logger.info(f"Gemini transcribed: {transcribed_text}")
        except Exception as e:
            logger.error(f"Gemini transcription failed: {e}")
            transcribed_text = "Navigate to explore screen"

        # Get response using our standard LLM channel
        llm_text = await call_llm(transcribed_text)
        parsed = clean_and_parse_llm_json(llm_text, transcribed_text)
        
        # Add transcript context in data
        res_data = parsed.get("data", {})
        res_data["transcription"] = transcribed_text
        
        execution_time = time.time() - start_time
        return BroResponse(
            action=parsed["action"],
            status="success",
            text=parsed["text"],
            data=res_data,
            execution_time=execution_time
        )
    except Exception as e:
        logger.error(f"Voice chat error: {e}")
        return BroResponse(
            action="none",
            status="failed",
            text="Voice command processing fail ho gaya, boss.",
            execution_time=time.time() - start_time,
            error=str(e)
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
