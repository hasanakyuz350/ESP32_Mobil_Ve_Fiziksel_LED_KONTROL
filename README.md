🚀 ESP32 LED Kontrol Sistemi - Firebase ile IoT Projesi

ESP32 mikrodenetleyici, Firebase Realtime Database ve Flutter mobil uygulaması kullanarak uzaktan LED kontrolü sağlayan komple bir IoT çözümü.

---

📋 Proje Hakkında

Bu proje, gerçek zamanlı LED kontrol sistemi sunmaktadır:

- **Mobil uygulamadan LED kontrolü (AÇIK/KAPALI)
- **Gerçek zamanlı LED durum takibi
- **Detaylı kullanım geçmişi kayıtları
- **İnteraktif grafiklerle kullanım istatistikleri
- **Fiziksel buton ile mobil uygulama arasında anlık senkronizasyon

Teknoloji Altyapısı

- **Donanım: ESP32-C6 mikrodenetleyici
- **Firmware: Arduino (C++)
- **Backend: Firebase (Realtime Database + Firestore)
- **Mobil Uygulama: Flutter/Dart
- **Kimlik Doğrulama: Firebase Anonymous Auth

---

🔧 Özellikler

ESP32 Firmware Özellikleri

✅ Otomatik yeniden bağlanma ile WiFi bağlantısı

✅ Debouncing algoritmalı fiziksel buton kontrolü

✅ Firebase ile gerçek zamanlı senkronizasyon

✅ Yeniden deneme mantığı ile komut kuyruğu sistemi

✅ Telemetri raporlama

✅ Zaman damgalı olay kayıtları

Flutter Mobil Uygulama Özellikleri

✅ Gerçek zamanlı LED durum izleme

✅ Uzaktan LED kontrolü

✅ Kullanım geçmişi (Firestore logları)

✅ İnteraktif pasta grafiği istatistikleri

✅ Çoklu platform desteği (iOS/Android)

✅ Material Design 3 arayüzü

---

📱 Uygulama Ekranları

Uygulama üç ana ekrandan oluşmaktadır:

- **Kontrol Sayfası: Görsel geri bildirim ile LED açma/kapama
- **Loglar Sayfası: Kronolojik kullanım geçmişini görüntüleme
- **İstatistik Sayfası: AÇIK/KAPALI kullanım oranlarını görselleştirme

---

🚦 Veri Akışı

- **Kontrol Akışı
- **Buton Basma → ESP32 → Firebase RTDB → Flutter App (Anlık güncelleme)
- **Uygulama Kontrolü → Firebase RTDB → ESP32 → LED Durum Değişimi
- **Loglama Akışı
- **İşlem → Firebase RTDB (events) → Firestore (logs) → Uygulama Gösterimi

---

🛠️ Kurulum Talimatları

Gereksinimler

- **ESP32-C6 geliştirme kartı
- **ESP32 desteğine sahip Arduino IDE
- **Flutter SDK (3.0+)
- **Realtime Database ve Firestore aktif Firebase projesi

ESP32 Yapılandırması

Gerekli Arduino kütüphanelerini yükleyin:

- **Firebase ESP Client
- **WiFi


Firebase_RealTime_Database.ino dosyasındaki bilgileri güncelleyin:

- **cpp#define WIFI_SSID "wifi-adınız"
- **#define WIFI_PASSWORD "wifi-şifreniz"
- **#define API_KEY "firebase-api-anahtarınız"
- **#define DATABASE_URL "veritabanı-url-adresiniz"

Donanım bağlantıları:

- **LED → GPIO 2
- **Buton → GPIO 4 (pull-up direnci ile)


Firmware'i ESP32'ye yükleyin

Flutter Uygulama Kurulumu

- **Repoyu klonlayın
- **Bağımlılıkları yükleyin:

--->bashflutter pub get

- **Firebase'i yapılandırın:

--->bashflutterfire configure

- **Uygulamayı çalıştırın:

--->bashflutter run

---

📊 Veritabanı Yapısı

- **Realtime Database

  "devices": {
  
    "esp32c6-001": {
  
      "cmd": {
  
        "isOn": boolean,
  
        "by": "mobile|device",
  
        "ts": timestamp
  
      },
  
      "telemetry": {
  
        "isOn": boolean,
  
        "source": "esp",
  
        "ts": timestamp
  
      },
  
      "events": {
  
        "eventId": {
  
          "isOn": boolean,
  
          "by": "mobile|device",
  
          "serverTs": timestamp,
  
          "consumed": boolean
  
        }
  
      }
  
    }
  
  }
  
- **Firestore
devices/

  └──
  {deviceId}/
  
      └──
  logs/
          └──
  {logId}/
              ├──
  action: "on|off"
              ├──
  source: "MOBİL|BUTON"
              ├──
  deviceId: string
              ├──
   page: string
              ├──
   platform: string
              └──
  at: timestamp

---

🔐 Güvenlik Özellikleri

- **Uygulama kullanıcıları için anonim kimlik doğrulama
- **Güvenli Firebase yapılandırması
- **Prodüksiyon kodunda sabit kimlik bilgisi bulunmuyor
- **Ağ istekleri için rate limiting ve backoff stratejisi

---

📈 Performans Optimizasyonları

ESP32 Tarafı:

- **Başarısız istekler için üstel geri çekilme (exponential backoff)
- **Geri besleme döngülerini önlemek için olay bastırma
- **Verimli debouncing algoritması


Flutter Uygulama:

- **Stream tabanlı gerçek zamanlı güncellemeler
- **Loglar için lazy loading
- **Optimize edilmiş grafik render işlemi



🎯 Kullanım Senaryoları

- **Akıllı ev otomasyonu
- **IoT prototipleme
- **Uzaktan kontrol sistemleri
- **Gerçek zamanlı izleme uygulamaları
- **Eğitim ve öğretim projeleri
