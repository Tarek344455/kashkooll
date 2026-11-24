#!/usr/bin/env python3
"""Simulate buyer panel answers for Kashkool. Reads personas, writes answer JSONs."""

import json
import os
import random

random.seed(42)

PANEL_DIR = r"N:\spaceship-ai\projects\kashkool\founder\panel"

def load_personas():
    with open(os.path.join(PANEL_DIR, "personas.json"), encoding="utf-8") as f:
        return json.load(f)

def load_pitch():
    with open(os.path.join(PANEL_DIR, "panel.json"), encoding="utf-8") as f:
        return json.load(f)["pitch"]

def simulate_answer(persona, pitch):
    """Generate a realistic answer based on persona characteristics."""
    segment = persona["segment"]
    behaviour = persona["behaviour"]
    objection = persona["objection"]
    income = persona["income"]
    age = persona["age"]
    
    # Base buy probability by segment
    segment_buy_prob = {
        "Large center owner (3+ branches)": 0.75,
        "Medium center owner (1-2 branches)": 0.55,
        "Small center owner (single location)": 0.40,
        "Independent teacher/tutor": 0.45,
    }
    
    # Behavior modifiers
    behaviour_modifier = {
        "WhatsApp/Excel operator": -0.25,
        "Tried ERP, burned": -0.20,
        "Growth-hungry modernizer": +0.30,
        "Teacher-first entrepreneur": +0.15,
        "Cost-optimizer": -0.30,
    }
    
    # Objection modifiers (some objections are harder to overcome)
    objection_modifier = {
        "My center runs fine on WhatsApp and Excel, why change?": -0.20,
        "I tried EduMe/SchoolPlus and it failed when internet went down": -0.15,
        "EGP 3,000/month is too expensive for my center size": -0.25,
        "My secretaries are not tech-savvy, training will take weeks": -0.15,
        "What happens if Kashkool shuts down? My data is hostage": -0.10,
        "Instapay/Fawry integration - what if it breaks during settlement?": -0.10,
        "I need to see it work in a center like mine before I commit": -0.05,
        "My teachers will refuse to use another app": -0.10,
        "Cash is king - parents pay cash, teachers want cash, why digital wallet?": -0.15,
        "What's the guarantee? If settlement is wrong, who pays?": -0.10,
    }
    
    base_prob = segment_buy_prob.get(segment, 0.5)
    prob = base_prob + behaviour_modifier.get(behaviour, 0) + objection_modifier.get(objection, 0)
    prob = max(0.05, min(0.95, prob))  # Clamp
    
    buys = random.random() < prob
    
    # Reason code based on persona
    if buys:
        reason_codes = ["need", "convenience", "quality", "values"]
        if behaviour == "Growth-hungry modernizer":
            reason_codes = ["need", "quality", "values"]
        elif behaviour == "Teacher-first entrepreneur":
            reason_codes = ["need", "convenience", "quality"]
        reason_code = random.choice(reason_codes)
    else:
        reason_codes = ["price", "habit", "trust", "timing", "need"]
        if behaviour == "WhatsApp/Excel operator":
            reason_codes = ["habit", "trust", "timing"]
        elif behaviour == "Cost-optimizer":
            reason_codes = ["price", "need"]
        elif behaviour == "Tried ERP, burned":
            reason_codes = ["trust", "quality", "habit"]
        reason_code = random.choice(reason_codes)
    
    # Generate reason text
    reason_templates = {
        ("need", True): [
            "أحتاج نظام يخلصني من التسوية اليدوية واللي بتاخد مني ساعات كل ليلة",
            "مشكلة الكاش والتسريبات بتكلفني فلوس كتير، محتاج حل يضمن الفلوس",
            "الأهالي بيسألوا على حضور أولادهم ومفيش نظام يوريهم، ده بيخليهم يروحوا لغيري",
        ],
        ("convenience", True): [
            "النظام شغال أوفلاين وده مهم جداً عندي، النت بيزعل في السنتر",
            "التسوية بضغطة واحدة في 11 بالليل؟ ده حلم بقى حقيقة",
            "السكرتيرة هتقدر تشتغل من غير تدريب معقد، الواجهة بسيطة",
        ],
        ("quality", True): [
            "الإنقاذ الأكاديمي للطلاب حاجة مفيش حد بيعملها، ده يميزني عن المنافسين",
            "حماية محتوى المدرسين بالـ DRM حاجة ضرورية، بخسر مدرسين بسبب تسريب الشيتات",
            "الرادار الحي للسناتر في مصر كله، هعرف أفتح فروع فين بناء على بيانات حقيقية",
        ],
        ("values", True): [
            "أخيراً نظام مصري يفهم طبيعة شغلنا مش نسخة من بره",
            "الدفع بالإنستاباي وفودافون كاش وفوري، ده اللي الأهالي عايزاه دلوقتي",
        ],
        ("price", False): [
            "2500 جنيه في الشهر غالي أوي على مركز زي بتاعي، هفضل على الإكسل",
            "المصروفات كتير وكمان أدفع اشتراك شهري؟ مش مناسبلي دلوقتي",
        ],
        ("habit", False): [
            "معتاد على الواتساب والإكسل من سنين، تغيير النظام هيخلي الشغل يتوقف فترة",
            "المدرسين والسكرتيرة متعودين على الطريقة القديمة، مش هقدّر أغيرهم بسهولة",
        ],
        ("trust", False): [
            "جربت أنظمة قبل كده ووقعت في مشاكل لما النت قطع، مش هخاطر تاني",
            "لو الشركة قفلت بياناتي تضيع، مفيش ضمانة إن النظام هيفضل شغال",
        ],
        ("timing", False): [
            "دلوقتي في موسم امتحانات، مش هقدر أغير نظام وأدرّب الناس",
            "هستنى أشوف حد تاني من أصحاب السناتر في منطقتي استخدمه الأول",
        ],
        ("need", False): [
            "مركزي صغير ومش محتاج كل الميزات دي، الواتساب بيكفيني",
            "أنا مدرس مش صاحب مركز، الميزات دي زيادة عليا",
        ],
    }
    
    key = (reason_code, buys)
    reasons = reason_templates.get(key, ["قراري مبني على ظروف مركزي الحالية"])
    reason = random.choice(reasons)
    
    # Objection text (personalized)
    objection_text = objection
    
    # What would change mind
    flip_templates = {
        "price": "لو السعر كان أقل أو فيه باقة مخصصة للمراكز الصغيرة",
        "habit": "لو فيه فترة تجريبية حقيقية مع دعم كامل للتدريب ونقل البيانات",
        "trust": "لو فيه ضمانة استرداد فلوس لو النظام مش شغال، أو لو شوفته شغال في مركز زيّ بتاعي",
        "timing": "لو فيه عرض إطلاق بخصم ودعم نقل بيانات مجاني",
        "need": "لو احتجت أتوسع وأفتح فروع تانية",
        "quality": "لو شوفت نتائج حقيقية من سناتر تانية استخدمت النظام",
        "convenience": "لو النظام فعلاً بيشتغل أوفلاين من غير مشاكل",
        "values": "لو النظام طوّر ميزات مخصوص لمصر مش مجرد ترجمة",
    }
    would_change = flip_templates.get(reason_code, "مش متأكد، محتاج أشوف النظام على أرض الواقع")
    
    # Price answers (in EGP)
    # Base prices around the 2500 EGP center price
    if segment == "Large center owner (3+ branches)":
        base = 4000
    elif segment == "Medium center owner (1-2 branches)":
        base = 2500
    elif segment == "Small center owner (single location)":
        base = 1500
    else:  # Independent teacher
        base = 800
    
    # Add noise
    noise = random.uniform(0.7, 1.5)
    price_too_cheap = round(base * 0.3 * noise, -2)
    price_cheap = round(base * 0.6 * noise, -2)
    price_expensive = round(base * 1.3 * noise, -2)
    price_too_expensive = round(base * 2.0 * noise, -2)
    
    # Ensure ordering
    prices = sorted([price_too_cheap, price_cheap, price_expensive, price_too_expensive])
    price_too_cheap, price_cheap, price_expensive, price_too_expensive = prices
    
    purchases_first_month = 1 if buys else 0
    
    return {
        "id": persona["id"],
        "buys": buys,
        "purchases_first_month": purchases_first_month,
        "reason_code": reason_code,
        "reason": reason,
        "objection": objection_text,
        "would_change_my_mind": would_change,
        "price_too_cheap": price_too_cheap,
        "price_cheap": price_cheap,
        "price_expensive": price_expensive,
        "price_too_expensive": price_too_expensive,
    }

def main():
    personas = load_personas()
    pitch = load_pitch()
    
    answers_dir = os.path.join(PANEL_DIR, "answers")
    os.makedirs(answers_dir, exist_ok=True)
    
    for persona in personas:
        answer = simulate_answer(persona, pitch)
        out_path = os.path.join(answers_dir, f"{persona['id']}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(answer, f, indent=1, ensure_ascii=False)
            f.write("\n")
    
    print(f"Simulated {len(personas)} buyer answers in {answers_dir}")

if __name__ == "__main__":
    main()