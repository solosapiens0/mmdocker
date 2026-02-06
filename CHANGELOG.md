# Değişiklik Geçmişi

## v2.0.0 - 2026-02-06

### 🎯 Kritik Düzeltmeler

#### 1. Docker Compose Version Warning Düzeltildi ✅
**Sorun:**
```yaml
version: '3.8'  # ← Obsolete warning veriyordu
```

**Çözüm:**
- `version:` satırı kaldırıldı
- Modern Docker Compose v2 standardına uygun hale getirildi
- Artık warning mesajı görünmeyecek

---

#### 2. Config Klasörü Opsiyonel Hale Getirildi ✅
**Sorun:**
- Config dosyaları sunucuda yoksa container'lar başlamıyordu
- Elasticsearch: "Unable to load config file null" hatası
- PostgreSQL: "Permission denied" hatası
- RabbitMQ: Restart loop

**Çözüm:**
- **Tüm config mount'ları comment yapıldı (opsiyonel)**
- Artık config klasörü olmadan da tüm servisler çalışır
- İhtiyaç olursa comment'i kaldırarak aktif edilebilir

**docker-compose.yml değişiklikleri:**
```yaml
# PostgreSQL
volumes:
  - ./data/postgres:/var/lib/postgresql/data
  # Config klasörü opsiyonel - init script'ler için gerekirse yorumu kaldır:
  # - ./config/postgres:/docker-entrypoint-initdb.d:ro

# Redis
volumes:
  - ./data/redis:/data
  # Config klasörü opsiyonel - özel ayarlar için gerekirse yorumu kaldır:
  # - ./config/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro

# RabbitMQ
volumes:
  - ./data/rabbitmq:/var/lib/rabbitmq
  # Config klasörü opsiyonel - özel ayarlar için gerekirse yorumu kaldır:
  # - ./config/rabbitmq/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
  # - ./config/rabbitmq/definitions.json:/etc/rabbitmq/definitions.json:ro

# Elasticsearch
volumes:
  - ./data/elasticsearch:/usr/share/elasticsearch/data
  # Config klasörü opsiyonel - özel ayarlar için gerekirse yorumu kaldır:
  # - ./config/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml:ro
```

---

#### 3. RabbitMQ Deprecated Environment Variable Kaldırıldı ✅
**Sorun:**
```bash
error: RABBITMQ_VM_MEMORY_HIGH_WATERMARK is set but deprecated
```

**Çözüm:**
- `RABBITMQ_VM_MEMORY_HIGH_WATERMARK` environment variable'ı docker-compose.yml'den kaldırıldı
- RabbitMQ 3.12+ bu değişkeni desteklemiyor
- Memory ayarı için `config/rabbitmq/rabbitmq.conf` dosyası kullanılmalı (opsiyonel)

**.env.example değişiklikleri:**
```bash
# KALDIRILAN:
# RABBITMQ_MEMORY_WATERMARK=0.6

# YENİ NOT:
# NOT: RABBITMQ_VM_MEMORY_HIGH_WATERMARK RabbitMQ 3.12+ versiyonunda deprecated
# Memory ayarı için config/rabbitmq/rabbitmq.conf dosyasını kullanın
```

---

## 📦 Şimdi Nasıl Kullanılır?

### Minimal Kurulum (Önerilen - Config'siz)
```bash
# 1. Template'i kopyala
cp -r . /opt/proje1/

# 2. .env oluştur
cd /opt/proje1
cp .env.example .env
nano .env  # Şifreleri düzenle

# 3. Başlat (config klasörü olmadan çalışır!)
docker compose --profile all up -d
```

### Full Featured Kurulum (Config ile)
```bash
# 1. Template'i config klasörüyle birlikte kopyala
cp -r . /opt/proje1/

# 2. .env oluştur
cd /opt/proje1
cp .env.example .env
nano .env

# 3. docker-compose.yml'deki config mount'larının yorumunu kaldır
nano docker-compose.yml
# Her servis için # işaretlerini kaldır

# 4. Başlat
docker compose --profile all up -d
```

---

## ✅ Test Edildi

### Başarılı Test Senaryoları:
- ✅ Config klasörü OLMADAN tüm servisler başlıyor
- ✅ PostgreSQL, Redis, RabbitMQ, Elasticsearch çalışıyor
- ✅ `docker compose down` doğru çalışıyor
- ✅ `docker compose --profile all up -d` warning vermiyor
- ✅ Çoklu proje desteği çalışıyor (proje1, proje2, vb.)

### Sorun Giderilen Hatalar:
- ❌ ~~"version is obsolete" warning~~ → ✅ Düzeltildi
- ❌ ~~Config file mount hataları~~ → ✅ Düzeltildi (opsiyonel yapıldı)
- ❌ ~~RabbitMQ deprecated warning~~ → ✅ Düzeltildi
- ❌ ~~docker compose down çalışmıyor~~ → ✅ Düzeltildi

---

## 🔄 Mevcut Sistemleri Güncelleme

Eğer eski versiyonu kullanıyorsan:

### Seçenek 1: Hızlı Güncelleme (Config'siz)
```bash
# Yeni docker-compose.yml'i kopyala
cp docker-compose.yml /opt/proje1/

# Container'ları yeniden başlat
cd /opt/proje1
docker compose down
docker compose --profile all up -d
```

### Seçenek 2: Config ile Devam Et
```bash
# Yeni docker-compose.yml'i kopyala
cp docker-compose.yml /opt/proje1/

# Config mount'larının yorumunu kaldır
cd /opt/proje1
nano docker-compose.yml
# Her servis için config mount satırlarının # işaretlerini kaldır

# Yeniden başlat
docker compose down
docker compose --profile all up -d
```

---

## 📚 İlave Kaynaklar

- **QUICKSTART.md** → 5 dakikada başlangıç kılavuzu
- **README.md** → Detaylı dokümantasyon
- **Makefile** → Kolaylaştırıcı komutlar (`make help`)

---

## 🎯 Özet

Bu versiyon **production-ready** ve **minimal kurulum** odaklı:
- ✅ Sadece `docker-compose.yml` + `.env` yeterli
- ✅ Config klasörü tamamen opsiyonel
- ✅ Hiçbir warning/error yok
- ✅ Modern Docker Compose v2 uyumlu
- ✅ Çoklu proje desteği tam çalışıyor

**Önerilen kullanım:** Config klasörü olmadan başla, ihtiyaç oldukça ekle.
