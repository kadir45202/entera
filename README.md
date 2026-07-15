# Entera — Smart Digestive Health & Metabolism Regulator 🧬

> Yapay zeka tabanlı **Gastrointestinal Düzenleyici Asistan**. Beslenme alışkanlıkları ile
> vücudun biyolojik tepkileri (semptomlar ve sindirim çıktıları) arasındaki gizli
> bağlantıları analiz eder — takip etmekle kalmaz, sindirim ritmini **düzenlemeye** yardım eder.

![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-8E75B2?logo=google&logoColor=white)
![Supabase](https://img.shields.io/badge/Auth%20%26%20Data-Supabase-3ECF8E?logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?logo=postgresql&logoColor=white)

Özellikle **IBS (Huzursuz Bağırsak Sendromu)**, gıda intoleransı ve sindirim düzensizliği
yaşayan kullanıcılar için tasarlandı. Kullanıcı öğününün fotoğrafını çeker; yapay zeka
içeriği ve potansiyel alerjenleri çözümler, sonraki günlerdeki sindirim konforuyla ilişkilendirir
ve kişiselleştirilmiş "güvenli gıda" içgörüleri sunar.

---

## 🚀 Öne Çıkan Özellikler

- **🥗 AI Besin & Tolerans Analizi** — Tabağın fotoğrafından içeriği, potansiyel alerjenleri
  (Glüten, Laktoz, FODMAP) ve besin değerlerini otomatik algılar.
- **⚡ Gastrointestinal Ritim Takibi** — Sindirim aktivitelerini klinik standarda (**Bristol Skalası**)
  uygun, görsel ve hijyenik bir arayüzle kaydeder.
- **🧠 Biyolojik Geri Bildirim** — Hangi besine nasıl tepki verdiğini (şişkinlik, gaz, konfor)
  analiz ederek kişiye özel "Güvenli Gıdalar" listesi çıkarır.
- **📉 Semptom Yönetimi** — Rahatsızlık anında geçmiş verileri tarayıp olası tetikleyicileri
  ("dün tüketilen çiğ sebzeler" gibi) tespit eder.
- **💬 AI Sohbet Asistanı** — Beslenme ve sindirim sorularını bağlamsal olarak yanıtlar.
- **📊 Bütüncül İçgörü Raporu** — Sindirim trendlerini ve metabolik durumu özetler; doktorla
  paylaşılabilir çıktı hedefler.

## 📱 Uygulama Akışı (Ekranlar)

`Karşılama → Onboarding (alerjen seçimi) → Kayıt / Giriş → Ana ekran`

| Ekran | İşlev |
| :--- | :--- |
| **Meal Capture / Result** | Öğün fotoğrafı çek → AI besin & alerjen analizi |
| **Stool Log** | Bristol Skalası ile sindirim çıktısı kaydı |
| **Symptom Log** | Şişkinlik / ağrı / konfor semptom kaydı |
| **Insights** | Besin–semptom korelasyonları ve kişisel içgörüler |
| **Chat** | AI beslenme/sindirim asistanı |
| **Settings** | Profil, alerjenler ve tercihler |

## 🛠️ Teknik Altyapı

| Katman | Teknoloji |
| :--- | :--- |
| **Mobil** | Flutter (Dart), **Riverpod** (state), **go_router**, Clean Architecture |
| **Kimlik & Veri** | **Supabase** (Auth + PostgreSQL), **Hive** (offline-first cache) |
| **Backend API** | **Python / FastAPI** (async), SQLAlchemy 2.0 + asyncpg |
| **Veritabanı** | **PostgreSQL** |
| **AI Motoru** | **Google Gemini** (Vision + Reasoning) — `google_generative_ai` / `google-generativeai` |
| **Güvenlik** | JWT (python-jose), bcrypt parola hash (passlib) |

## 📂 Proje Yapısı

```
entera/
├── backend/                 # FastAPI + PostgreSQL + Gemini
│   ├── app/
│   │   ├── api/             # routes: auth · allergens · meals · logs (+ deps)
│   │   ├── core/            # config · database · security
│   │   ├── models/          # SQLAlchemy: user · meal · log · allergen
│   │   ├── schemas/         # Pydantic şemaları
│   │   ├── services/        # gemini_service · meal_service
│   │   └── main.py          # uygulama girişi (app.main:app)
│   ├── tests/
│   ├── requirements.txt
│   └── .env.example
├── frontend/                # Flutter (Clean Architecture)
│   ├── lib/
│   │   ├── core/            # config · router · theme
│   │   ├── data/            # models · providers · repositories · services
│   │   ├── presentation/    # screens (welcome, meal, log, insights, chat...)
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── .env.example
├── sql/                     # bakım / dev veritabanı script'leri
├── images/                  # referans görselleri
├── .kiro/                   # ürün spec'leri (design · requirements · tasks)
└── .gitignore
```

## ⚡ Hızlı Başlangıç

Gereksinimler: **Python 3.11+**, **Flutter 3.x**, çalışan bir **PostgreSQL** (veya Supabase projesi),
bir **Google Gemini API anahtarı**.

### 1) Backend (FastAPI)

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: .\venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env            # DATABASE_URL, SECRET_KEY, GEMINI_API_KEY doldur
uvicorn app.main:app --reload
```

- API: `http://localhost:8000`
- Swagger/OpenAPI dokümanı: `http://localhost:8000/docs`
- Sağlık kontrolü: `http://localhost:8000/health`

> Tablolar açılışta otomatik oluşturulur (`Base.metadata.create_all`) — ayrı bir migration adımı gerekmez.

### 2) Frontend (Flutter)

```bash
cd frontend
cp .env.example .env            # SUPABASE_URL, SUPABASE_ANON_KEY doldur
flutter pub get
flutter run
```

## 🔌 API Genel Bakışı

Tüm uçlar `/api/v1` ön eki altındadır.

| Grup | Açıklama |
| :--- | :--- |
| `POST /api/v1/auth/register`, `/auth/login` | Kayıt ve JWT ile giriş (OAuth2 password flow) |
| `/api/v1/allergens` | Alerjen kataloğu (Glüten, Laktoz, FODMAP …) |
| `/api/v1/meals` | Öğün oluşturma + AI besin/alerjen analizi |
| `/api/v1/logs` | Sindirim (Bristol) ve semptom kayıtları |
| `GET /health` | Servis sağlık kontrolü |

## 🔐 Ortam Değişkenleri & Güvenlik

Gerçek `.env` dosyaları **repoya dahil edilmez** (`.gitignore` ile hariç tutulur); yalnızca
`*.env.example` şablonları paylaşılır. Kendi anahtarlarını yerelde oluştur:

**`backend/.env`**
```
DATABASE_URL=postgresql+asyncpg://<user>:<pass>@localhost:5432/entera
SECRET_KEY=<güçlü-rastgele-anahtar>
GEMINI_API_KEY=<gemini-api-anahtarın>
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

**`frontend/.env`**
```
SUPABASE_URL=https://<proje-id>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
```

> ⚠️ `SECRET_KEY`, servis rol anahtarları ve Gemini anahtarını asla commit'leme. Anahtar sızarsa
> ilgili panelden (Supabase / Google AI Studio) hemen yenile.

## 🔄 Sistem Akışı

1. **Veri Girişi** — Kullanıcı öğününü veya sindirim durumunu saniyeler içinde girer.
2. **AI İşleme** — Gemini Vision, besinleri içerik bazında analiz eder.
3. **Korelasyon** — Alınan besin ile 24–48 saat sonraki sindirim konforu ilişkilendirilir.
4. **İçgörü** — "Süt ürünleri sindirim ritmini yavaşlatıyor olabilir" türü düzenleyici öneriler sunulur.

## ⚕️ Sorumluluk Reddi

Entera bir **sağlıklı yaşam / takip aracıdır**, tıbbi teşhis veya tedavi yerine geçmez.
Sağlık kararların için daima bir hekime danış.

## 📄 Lisans

Özel proje (UNLICENSED). Tüm hakları saklıdır © Kadir Çetin.
