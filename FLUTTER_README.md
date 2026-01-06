# 📱 Apartman Yönetim Sistemi - Flutter Mobil Uygulama

## 🎯 Proje Özeti

Flutter ile geliştirilmiş kapsamlı bir apartman yönetim mobil uygulaması. Backend API ile entegre çalışır.

## ✨ Özellikler

### 🔐 Kimlik Doğrulama
- ✅ Kullanıcı girişi (JWT token)
- ✅ Şifre sıfırlama
- ✅ Oturum yönetimi
- ✅ Role-based erişim kontrolü

### 👥 Malik Yönetimi
- ✅ Malik listesi görüntüleme
- ✅ Yeni malik ekleme
- ✅ Malik bilgilerini güncelleme
- ✅ Malik silme
- ✅ Malik detay görüntüleme

### 🏢 Daire Yönetimi (Unit)
- ✅ Daire listesi
- ✅ Yeni daire ekleme
- ✅ Daire düzenleme
- ✅ Malik atama
- ✅ Pay oranı yönetimi

### 💳 Aidat Yönetimi
- ✅ Aidat listesi
- ✅ Yeni aidat oluşturma
- ✅ Ödenmemiş aidatlar
- ✅ Aidat durumu takibi

### 💰 Ödeme İşlemleri
- ✅ Ödeme alma
- ✅ Ödeme geçmişi
- ✅ Ödeme iptali
- ✅ Kasa/Banka entegrasyonu

### 🧾 Gider Yönetimi
- ✅ Gider listesi
- ✅ Yeni gider ekleme
- ✅ Gider düzenleme
- ✅ Kategori yönetimi

### 🏦 Kasa/Banka
- ✅ Hesap listesi
- ✅ Transfer işlemleri
- ✅ Bakiye takibi

### 📢 Duyuru Sistemi
- ✅ Duyuru listesi
- ✅ Yeni duyuru ekleme
- ✅ Duyuru sabitleme
- ✅ Duyuru silme

### 📊 Raporlar
- ✅ Dashboard istatistikleri
- ✅ Gelir-gider grafikleri
- ✅ Borç raporları
- ✅ Detaylı raporlar

### 🔚 Yıl Sonu İşlemleri
- ✅ Yıl sonu özeti
- ✅ Yıl kapanışı
- ✅ Arşivleme

## 📁 Proje Yapısı

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart      # Sabitler
│   ├── theme/
│   │   └── app_theme.dart          # Tema yapılandırması
│   └── utils/
│       └── helpers.dart            # Yardımcı fonksiyonlar
├── models/
│   ├── user_model.dart             # Kullanıcı modeli
│   ├── owner_model.dart            # Malik modeli
│   ├── unit_model.dart             # Daire modeli
│   ├── rent_model.dart             # Aidat modeli
│   ├── payment_model.dart          # Ödeme modeli
│   ├── expense_model.dart          # Gider modeli
│   ├── account_model.dart          # Hesap modeli
│   ├── announcement_model.dart     # Duyuru modeli
│   └── ...
├── providers/
│   ├── auth_provider.dart          # Kimlik doğrulama state
│   ├── owner_provider.dart         # Malik state
│   ├── unit_provider.dart          # Daire state
│   ├── announcement_provider.dart  # Duyuru state
│   └── dashboard_provider.dart     # Dashboard state
├── services/
│   └── api_service.dart            # API servisi (Dio)
├── screens/
│   ├── login_screen.dart           # Giriş ekranı
│   ├── dashboard_screen.dart       # Ana sayfa
│   ├── owners_screen.dart          # Malik listesi
│   ├── add_owner_screen.dart       # Malik ekleme
│   ├── owner_detail_screen.dart    # Malik detay
│   ├── units_screen.dart           # Daire listesi
│   ├── add_unit_screen.dart        # Daire ekleme
│   ├── edit_unit_screen.dart       # Daire düzenleme
│   ├── rents_screen.dart           # Aidat listesi
│   ├── payments_screen.dart        # Ödeme listesi
│   ├── expenses_screen.dart        # Gider listesi
│   ├── accounts_screen.dart        # Kasa/Banka
│   ├── announcements_screen.dart   # Duyurular
│   ├── add_announcement_screen.dart # Duyuru ekleme
│   ├── reports_screen.dart         # Raporlar
│   ├── year_end_screen.dart        # Yıl sonu
│   └── ...
├── widgets/
│   └── common_widgets.dart         # Ortak widget'lar
└── main.dart                       # Ana giriş noktası
```

## 🔌 API Entegrasyonu

### Backend URL
```dart
static const String baseUrl = 'http://192.168.1.8:5000/api';
```

### Endpoint Yapısı

| Modül | Endpoint | Metod | Açıklama |
|-------|----------|-------|----------|
| **Auth** | /auth/login | POST | Giriş |
| | /auth/forgot-password | POST | Şifre sıfırlama |
| **Owners** | /owners | GET | Malik listesi |
| | /owners | POST | Malik ekle |
| | /owners/{id} | PUT | Malik güncelle |
| | /owners/{id} | DELETE | Malik sil |
| **Units** | /units | GET | Daire listesi |
| | /units | POST | Daire ekle |
| | /units/{id} | PUT | Daire güncelle |
| | /units/{id} | DELETE | Daire sil |
| **Rents** | /rents | GET | Aidat listesi |
| | /rents | POST | Aidat oluştur |
| **Payments** | /payments | POST | Ödeme al |
| | /payments/{id}/cancel | PUT | Ödeme iptal |
| **Expenses** | /expenses | GET | Gider listesi |
| | /expenses | POST | Gider ekle |
| **Accounts** | /accounts | GET | Hesap listesi |
| | /accounts/transfer | POST | Transfer |
| **Announcements** | /announcements | GET | Duyuru listesi |
| | /announcements | POST | Duyuru ekle |
| | /announcements/{id} | DELETE | Duyuru sil |
| **Reports** | /reports/summary | GET | Özet rapor |
| | /reports/chart | GET | Grafik verisi |
| **Year-End** | /year-end/close | POST | Yıl kapat |
| | /year-end/summary/{year} | GET | Yıl özeti |

## 📦 Kullanılan Paketler

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0
  dio: ^5.9.0                    # HTTP istekleri
  provider: ^6.1.5+1              # State management
  shared_preferences: ^2.5.4      # Yerel depolama
  jwt_decode: ^0.3.1              # JWT decode
  intl: ^0.20.2                   # Tarih/Para formatı
  fl_chart: ^1.1.1                # Grafikler
```

## 🚀 Kurulum

### 1. Gereksinimler
- Flutter SDK (3.10.4+)
- Dart SDK
- Android Studio / Xcode
- Backend API çalışır durumda

### 2. Projeyi Klonlayın
```bash
git clone <repository_url>
cd ays_mobile
```

### 3. Paketleri Yükleyin
```bash
flutter pub get
```

### 4. Backend URL'i Güncelleyin
`lib/services/api_service.dart` dosyasında backend URL'inizi güncelleyin:
```dart
static const String baseUrl = 'http://YOUR_IP:5000/api';
```

### 5. Uygulamayı Çalıştırın
```bash
flutter run
```

## 🔧 Geliştirme

### Provider Kullanımı
```dart
// Provider'ı okuma
final provider = context.read<OwnerProvider>();

// Provider'ı dinleme
context.watch<OwnerProvider>()

// Consumer widget
Consumer<OwnerProvider>(
  builder: (context, provider, child) {
    return Widget();
  },
)
```

### API Çağrıları
```dart
// API servisini kullanma
final apiService = ApiService();
final result = await apiService.getOwners();
```

### Navigasyon
```dart
// Ekrana gitme
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NewScreen()),
);

// Geri dönme
Navigator.pop(context, result);
```

## 🎨 Tema ve Stil

Uygulama, `AppTheme` sınıfı üzerinden merkezi tema yönetimi kullanır:

```dart
// Renkler
AppTheme.primaryColor
AppTheme.secondaryColor
AppTheme.errorColor
AppTheme.successColor

// Tema
MaterialApp(
  theme: AppTheme.lightTheme,
)
```

## 🛠️ Yardımcı Fonksiyonlar

```dart
// Tarih formatla
Helpers.formatDate(DateTime.now())

// Para formatla
Helpers.formatCurrency(1000.50)

// Snackbar göster
Helpers.showSnackBar(context, 'Mesaj')

// Onay dialogu
await Helpers.showConfirmDialog(context, 
  title: 'Başlık', 
  message: 'Mesaj'
)

// Validasyon
Helpers.validateEmail(value)
Helpers.validatePassword(value)
Helpers.validateRequired(value, 'Alan adı')
```

## 📱 Ekran Görüntüleri

### Login
- E-posta ve şifre ile giriş
- Beni hatırla özelliği
- Şifre sıfırlama

### Dashboard
- İstatistik kartları
- Hızlı erişim butonları
- Grafik gösterimleri

### Malik Yönetimi
- Liste görünümü
- Detay sayfası
- Ekleme/Düzenleme formları

### Daire Yönetimi
- Blok ve daire listesi
- Malik atama
- Pay oranı yönetimi

### Duyurular
- Liste görünümü
- Genişletilebilir kartlar
- Sabitleme özelliği

## 🔒 Güvenlik

- JWT token tabanlı kimlik doğrulama
- Token otomatik header'a eklenir
- Interceptor ile merkezi hata yönetimi
- Güvenli veri depolama (SharedPreferences)

## 🐛 Hata Ayıklama

### Log Kontrolü
```bash
flutter logs
```

### Build Temizleme
```bash
flutter clean
flutter pub get
```

### API Bağlantı Sorunları
- Backend URL'i kontrol edin
- Network izinlerini kontrol edin
- Firewall ayarlarını kontrol edin

## 📄 Lisans

Bu proje özel bir projedir.

## 👨‍💻 Geliştirici

Apartman Yönetim Sistemleri

## 📞 Destek

Sorularınız için lütfen iletişime geçin.

---

**Son Güncelleme:** 3 Ocak 2026  
**Versiyon:** 1.0.0
