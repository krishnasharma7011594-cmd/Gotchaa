import json
import os

L10N_DIR = r"c:\Gotchaa\assets\l10n"

# A basic map of the core untranslated words for the keys:
translations = {
    "hi": {
        "explore_title": "खोजें",
        "chat_title": "संदेश",
        "mini_apps_title": "मिनी एप्स",
        "mini_apps_recommended": "आपके लिए अनुशंसित",
        "wallet_title": "बटुआ",
        "vybz_title": "वाइब्ज़",
        "karma_title": "कर्म",
        "profile_followers": "फ़ॉलोअर्स",
        "profile_following": "फ़ॉलोइंग"
    },
    "es": {
        "explore_title": "Explorar",
        "chat_title": "Mensajes",
        "mini_apps_title": "Mini Aplicaciones",
        "mini_apps_recommended": "Recomendado para ti",
        "wallet_title": "Billetera",
        "vybz_title": "Vybz",
        "karma_title": "Karma",
        "profile_followers": "Seguidores",
        "profile_following": "Siguiendo"
    },
    "fr": {
        "explore_title": "Explorer",
        "chat_title": "Messages",
        "mini_apps_title": "Mini Applications",
        "mini_apps_recommended": "Recommandé pour vous",
        "wallet_title": "Portefeuille",
        "vybz_title": "Vybz",
        "karma_title": "Karma",
        "profile_followers": "Abonnés",
        "profile_following": "Abonnements"
    },
    "ar": {
        "explore_title": "اكتشف",
        "chat_title": "الرسائل",
        "mini_apps_title": "التطبيقات المصغرة",
        "mini_apps_recommended": "موصى به لك",
        "wallet_title": "المحفظة",
        "vybz_title": "فايبز",
        "karma_title": "كارما",
        "profile_followers": "المتابعون",
        "profile_following": "يتابع"
    },
    "pt": {
        "explore_title": "Explorar",
        "chat_title": "Mensagens",
        "mini_apps_title": "Mini Apps",
        "mini_apps_recommended": "Recomendado para você",
        "wallet_title": "Carteira",
        "vybz_title": "Vybz",
        "karma_title": "Karma",
        "profile_followers": "Seguidores",
        "profile_following": "Seguindo"
    },
    "id": {
        "explore_title": "Eksplor",
        "chat_title": "Pesan",
        "mini_apps_title": "Aplikasi Mini",
        "mini_apps_recommended": "Rekomendasi untuk Anda",
        "wallet_title": "Dompet",
        "vybz_title": "Vybz",
        "karma_title": "Karma",
        "profile_followers": "Pengikut",
        "profile_following": "Mengikuti"
    },
    "ru": {
        "explore_title": "Обзор",
        "chat_title": "Сообщения",
        "mini_apps_title": "Мини-приложения",
        "mini_apps_recommended": "Рекомендуем вам",
        "wallet_title": "Кошелек",
        "vybz_title": "Vybz",
        "karma_title": "Карма",
        "profile_followers": "Подписчики",
        "profile_following": "Подписки"
    },
    "de": {
        "explore_title": "Entdecken",
        "chat_title": "Nachrichten",
        "mini_apps_title": "Mini-Apps",
        "mini_apps_recommended": "Für dich empfohlen",
        "wallet_title": "Brieftasche",
        "vybz_title": "Vybz",
        "karma_title": "Karma",
        "profile_followers": "Follower",
        "profile_following": "Folgend"
    },
    "zh": {
        "explore_title": "探索",
        "chat_title": "消息",
        "mini_apps_title": "小程序",
        "mini_apps_recommended": "为您推荐",
        "wallet_title": "钱包",
        "vybz_title": "Vybz",
        "karma_title": "Karma",
        "profile_followers": "粉丝",
        "profile_following": "关注"
    },
    "ja": {
        "explore_title": "探索",
        "chat_title": "メッセージ",
        "mini_apps_title": "ミニアプリ",
        "mini_apps_recommended": "おすすめ",
        "wallet_title": "ウォレット",
        "vybz_title": "Vybz",
        "karma_title": "カルマ",
        "profile_followers": "フォロワー",
        "profile_following": "フォロー中"
    },
    "ko": {
        "explore_title": "탐색",
        "chat_title": "메시지",
        "mini_apps_title": "미니 앱",
        "mini_apps_recommended": "추천",
        "wallet_title": "지갑",
        "vybz_title": "Vybz",
        "karma_title": "카르마",
        "profile_followers": "팔로워",
        "profile_following": "팔로잉"
    }
}

for lang_code, new_data in translations.items():
    path = os.path.join(L10N_DIR, f"{lang_code}.json")
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
        
    for k, v in new_data.items():
        data[k] = v
        
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
print("Keys updated successfully!")
