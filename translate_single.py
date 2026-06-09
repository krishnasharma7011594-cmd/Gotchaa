import json
import os
import time
from deep_translator import GoogleTranslator

TARGETS = ["hi", "es", "fr", "ar", "pt", "id", "ru", "de", "zh-CN", "ja", "ko"]
L10N_DIR = r"c:\Gotchaa\assets\l10n"

en_path = os.path.join(L10N_DIR, "en.json")
with open(en_path, "r", encoding="utf-8") as f:
    en_data = json.load(f)

for target_lang in TARGETS:
    file_lang = "zh" if target_lang == "zh-CN" else target_lang
    out_path = os.path.join(L10N_DIR, f"{file_lang}.json")
    
    print(f"Translating {target_lang}...")
    translator = GoogleTranslator(source='en', target=target_lang)
    translated_data = {}
    
    for k, v in en_data.items():
        try:
            # check if v has html or special syntax
            translated_data[k] = translator.translate(v)
            time.sleep(0.05)
        except Exception as e:
            print(f"Error on {k} for {target_lang}: {e}")
            translated_data[k] = v
            
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(translated_data, f, ensure_ascii=False, indent=2)
    print(f"Finished {target_lang}!")

