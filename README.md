# Entera: Smart Digestive Health & Metabolism Regulator 🧬

**Entera**, sindirim sistemi sağlığını optimize etmek ve yaşam kalitesini artırmak isteyen bireyler için geliştirilmiş, yapay zeka tabanlı bir **"Gastrointestinal Düzenleyici Asistan"**dır.

Özellikle **IBS (Huzursuz Bağırsak Sendromu)**, gıda intoleransı ve sindirim düzensizliği yaşayan kullanıcılar için; beslenme alışkanlıkları ile vücudun verdiği biyolojik tepkiler (semptomlar ve sindirim çıktıları) arasındaki gizli bağlantıları **Gemini 1.5 Pro Vision** teknolojisi ile analiz eder.

Amaç sadece takip etmek değil; kullanıcıya kişiselleştirilmiş içgörüler sunarak sindirim ritmini **düzenlemektir.**

## 🚀 Temel Yetenekler (Core Capabilities)

* **🥗 AI Besin & Tolerans Analizi:** Tabağınızın fotoğrafından içeriği, potansiyel alerjenleri (Glüten, Laktoz, FODMAP) ve besin değerlerini otomatik algılar.
* **⚡ Gastrointestinal Ritim Takibi:** Sindirim sistemi aktivitelerini ve döngülerini, klinik standartlara (Bristol Skalası) uygun, görsel ve hijyenik bir arayüzle kaydeder.
* **🧠 Biyolojik Geri Bildirim (Bio-Feedback):** Vücudunuzun hangi besine nasıl tepki verdiğini (şişkinlik, gaz, konfor seviyesi) analiz ederek size özel "Güvenli Gıdalar" listesi oluşturur.
* **📉 Semptom Yönetimi:** Karın ağrısı veya rahatsızlık hissettiğinizde, yapay zeka geçmiş verilerinizi tarayarak olası tetikleyicileri (örn: "Dün tükettiğiniz çiğ sebzeler") tespit eder.
* **📊 Bütüncül Sağlık Raporu:** Doktorunuzla paylaşabileceğiniz, sindirim trendlerinizi ve metabolik durumunuzu özetleyen profesyonel PDF raporları oluşturur.

## 🛠️ Teknik Altyapı (Tech Stack)

Proje, medikal veri güvenliği ve yüksek performans standartlarına göre tasarlanmıştır:

| Katman | Teknoloji | Kullanım Amacı |
| :--- | :--- | :--- |
| **Mobile** | **Flutter** (Dart) | Cross-platform, Clean Architecture UI/UX |
| **Backend** | **Python (FastAPI)** | Asenkron veri işleme ve API yönetimi |
| **AI Engine** | **Google Gemini 1.5 Pro** | Görüntü işleme (Vision) ve Tıbbi Mantık Yürütme (Reasoning) |
| **Database** | **PostgreSQL** | İlişkisel sağlık verisi saklama |
| **Persistence** | **Drift (SQLite)** | Çevrimdışı (Offline-First) kullanım desteği |

## 🔄 Sistem Akışı (System Workflow)

1.  **Veri Girişi:** Kullanıcı öğününü veya sindirim durumunu (saniyeler içinde) sisteme girer.
2.  **AI İşleme:** Gemini Vision API, besinleri moleküler düzeyde (içerik bazlı) analiz eder.
3.  **Korelasyon:** Algoritma, alınan besin ile 24-48 saat sonraki sindirim konforu arasındaki ilişkiyi kurar.
4.  **İçgörü:** Kullanıcıya "Süt ürünleri sindirim ritminizi %40 oranında yavaşlatıyor olabilir" gibi düzenleyici öneriler sunulur.
cd frontend
flutter pub get
flutter run
