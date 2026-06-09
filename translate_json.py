import json
import os
import concurrent.futures
from deep_translator import GoogleTranslator
import time

TARGETS = ["hi", "es", "fr", "ar", "pt", "id", "ru", "de", "zh-CN", "ja", "ko"]
L10N_DIR = r"c:\Gotchaa\assets\l10n"

def translate_file(target_lang):
    file_lang = "zh" if target_lang == "zh-CN" else target_lang
    en_path = os.path.join(L10N_DIR, "en.json")
    out_path = os.path.join(L10N_DIR, f"{file_lang}.json")
    
    with open(en_path, "r", encoding="utf-8") as f:
        en_data = json.load(f)
        
    translator = GoogleTranslator(source='en', target=target_lang)
    translated_data = {}
    
    keys = list(en_data.keys())
    values = list(en_data.values())
    
    try:
        translated_vals = translator.translate_batch(values)
        for i, k in enumerate(keys):
            translated_data[k] = translated_vals[i].strip() if translated_vals[i] else values[i]
                
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(translated_data, f, ensure_ascii=False, indent=2)
        print(f"Finished {target_lang}")
        
    except Exception as e:
        print(f"Error executing batch translate for {target_lang}: {e}")
        # manual loop fallback
        for k, v in en_data.items():
            try:
                translated_data[k] = translator.translate(v)
            except:
                translated_data[k] = v
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(translated_data, f, ensure_ascii=False, indent=2)

with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    executor.map(translate_file, TARGETS)
