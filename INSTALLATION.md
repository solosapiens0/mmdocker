# 🚀 Kurulum Kılavuzu

## Sunucuya Kurulum (Ubuntu Server)

### Ön Gereksinimler
```bash
# Docker ve Docker Compose kurulu olmalı
docker --version
docker compose version
```

Eğer kurulu değilse:
```bash
# Docker kurulumu
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Yeniden giriş yap
exit
# SSH ile tekrar bağlan

# Kurulumu test et
docker --version
docker compose version
```

---

## 📦 Kurulum Adımları

### 1️⃣ Template'i Sunucuya Kopyala

**Yerel makinenden:**
```bash
# Zip dosyasını sunucuya gönder
scp docker-compose-template-v2.zip user@server:/tmp/

# VEYA direkt klasörü kopyala
scp -r mediamarkt-proje-compose-template user@server:/tmp/
```

**Sunucuda:**
```bash
# Hedef klasörü oluştur
sudo mkdir -p /opt/proje1
sudo chown $USER:$USER /opt/proje1

# Zip'i aç (eğer zip gönderdiysen)
cd /tmp
unzip docker-compose-template-v2.zip -d /opt/proje1

# VEYA kopyalanan klasörü taşı
mv /tmp/mediamarkt-proje-compose-template/* /opt/proje1/
```

---

### 2️⃣ Environment Dosyasını Hazırla

```bash
cd /opt/proje1

# .env oluştur
cp .env.example .env

# Düzenle
nano .env
```

**Mutlaka değiştir:**
```bash
# Proje adı (benzersiz olmalı!)
PROJECT_NAME=proje1

# Şifreler (GÜVENLİ ŞIFRELER KULLAN!)
POSTGRES_PASSWORD=cok_guclu_postgres_sifre_123abc
REDIS_PASSWORD=cok_guclu_redis_sifre_456def
RABBITMQ_PASSWORD=cok_guclu_rabbitmq_sifre_789ghi
ELASTICSEARCH_PASSWORD=cok_guclu_elastic_sifre_012jkl

# Port'lar (varsayılan değerler, değiştirebilirsin)
POSTGRES_PORT=5432
REDIS_PORT=6379
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672
ELASTICSEARCH_PORT=9200
```

**Güçlü şifre oluştur:**
```bash
# 32 karakterlik random şifre
openssl rand -base64 32

# Veya
pwgen -s 32 1
```

---

### 3️⃣ Elasticsearch için Sistem Ayarı (Önemli!)

```bash
# vm.max_map_count ayarla (Elasticsearch için gerekli)
sudo sysctl -w vm.max_map_count=262144

# Kalıcı yap
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

---

### 4️⃣ Servisleri Başlat

```bash
cd /opt/proje1

# Tüm servisleri başlat
docker compose --profile all up -d

# VEYA sadece ihtiyacın olanları
docker compose --profile postgres --profile redis up -d
```

---

### 5️⃣ Kurulumu Test Et

```bash
# Servis durumunu kontrol et
docker compose ps

# Logları kontrol et
docker compose logs -f

# Her servisin sağlığını kontrol et
docker compose ps

# PostgreSQL test
docker compose exec postgres psql -U app_user -d app_db -c "SELECT version();"

# Redis test
docker compose exec redis redis-cli -a your_redis_password ping

# RabbitMQ Management UI test (tarayıcıda)
# http://server-ip:15672
# Kullanıcı: admin
# Şifre: .env dosyasındaki RABBITMQ_PASSWORD

# Elasticsearch test
curl -u elastic:your_elastic_password http://localhost:9200/_cluster/health?pretty
```

---

## 🔧 İkinci Proje Ekleme (proje2)

```bash
# Template'i kopyala
sudo mkdir -p /opt/proje2
sudo chown $USER:$USER /opt/proje2
cp -r /opt/proje1/* /opt/proje2/

# proje2 dizinine git
cd /opt/proje2

# .env'i düzenle
nano .env
```

**Mutlaka değiştir:**
```bash
# FARKLI PROJE ADI (çok önemli!)
PROJECT_NAME=proje2

# FARKLI PORTLAR (çakışma olmasın!)
POSTGRES_PORT=5433
REDIS_PORT=6380
RABBITMQ_PORT=5673
RABBITMQ_MANAGEMENT_PORT=15673
ELASTICSEARCH_PORT=9201
ELASTICSEARCH_TRANSPORT_PORT=9301

# FARKLI ŞİFRELER (güvenlik!)
POSTGRES_PASSWORD=proje2_postgres_sifre_xyz
REDIS_PASSWORD=proje2_redis_sifre_xyz
RABBITMQ_PASSWORD=proje2_rabbitmq_sifre_xyz
ELASTICSEARCH_PASSWORD=proje2_elastic_sifre_xyz
```

```bash
# proje2'yi başlat
docker compose --profile all up -d

# Her iki projeyi kontrol et
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## 🎨 Config Klasörü Kullanımı (Opsiyonel)

Eğer özel konfigürasyonlara ihtiyacın varsa:

### PostgreSQL Init Script
```bash
# Config klasörünü kopyala
cd /opt/proje1
mkdir -p config/postgres

# Init script oluştur
nano config/postgres/init.sql
```

```sql
-- Örnek init script
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL
);
```

```bash
# docker-compose.yml'de ilgili satırın yorumunu kaldır
nano docker-compose.yml
```

```yaml
# Şu satırı bul:
# - ./config/postgres:/docker-entrypoint-initdb.d:ro

# Yorumu kaldır:
- ./config/postgres:/docker-entrypoint-initdb.d:ro
```

```bash
# Container'ı yeniden oluştur
docker compose down
docker compose --profile postgres up -d
```

Aynı şekilde Redis, RabbitMQ ve Elasticsearch için de config dosyaları eklenebilir.

---

## 🔒 Güvenlik Ayarları

### Firewall Konfigürasyonu
```bash
# UFW aktif et (henüz yoksa)
sudo ufw enable

# Sadece localhost'tan erişime izin ver
sudo ufw allow from 127.0.0.1 to any port 5432  # PostgreSQL
sudo ufw allow from 127.0.0.1 to any port 6379  # Redis
sudo ufw allow from 127.0.0.1 to any port 9200  # Elasticsearch

# Belirli IP'den erişim (uygulamanın IP'si)
sudo ufw allow from 192.168.1.100 to any port 5432

# RabbitMQ Management UI için (güvenli IP'den)
sudo ufw allow from 192.168.1.0/24 to any port 15672
```

### .env Dosyası Güvenliği
```bash
# .env dosyasının izinlerini sınırla
chmod 600 .env

# Sadece owner okuyabilir/yazabilir
ls -la .env
# -rw------- 1 user user ... .env
```

---

## 📊 Yedekleme Sistemi Kurulumu

### PostgreSQL Otomatik Backup
```bash
cd /opt/proje1
mkdir -p backups

# Backup scripti oluştur
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/proje1/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# PostgreSQL backup
docker compose exec -T postgres pg_dump -U app_user app_db > $BACKUP_DIR/postgres_backup_$DATE.sql

# 7 günden eski backupları sil
find $BACKUP_DIR -name "postgres_backup_*.sql" -mtime +7 -delete

echo "Backup tamamlandı: postgres_backup_$DATE.sql"
EOF

chmod +x backup.sh

# Test et
./backup.sh
```

### Cron Job Ekle
```bash
# Crontab düzenle
crontab -e

# Her gün saat 02:00'de backup al
0 2 * * * cd /opt/proje1 && ./backup.sh >> /opt/proje1/logs/backup.log 2>&1
```

---

## 🐛 Sorun Giderme

### Container'lar başlamıyor
```bash
# Logları kontrol et
docker compose logs -f

# Belirli servisi kontrol et
docker compose logs postgres

# Container detaylarını gör
docker inspect proje1_postgres
```

### Port çakışması
```bash
# Hangi portlar kullanımda kontrol et
sudo netstat -tulpn | grep 5432

# .env'de farklı port kullan
nano .env
# POSTGRES_PORT=5433
```

### Disk doldu
```bash
# Docker disk kullanımı
docker system df

# Temizlik
docker system prune -a --volumes
```

### Permission hataları
```bash
# Data klasörü izinlerini düzelt
sudo chown -R $USER:$USER /opt/proje1/data
```

### Elasticsearch başlamıyor
```bash
# vm.max_map_count kontrolü
sysctl vm.max_map_count

# Ayarlanmamışsa
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

---

## 📞 Destek

Sorun yaşarsan:

1. **Logları kontrol et:** `docker compose logs -f`
2. **Servis durumu:** `docker compose ps`
3. **Config doğrula:** `docker compose config`
4. **README'yi oku:** `cat README.md`
5. **CHANGELOG'u kontrol et:** `cat CHANGELOG.md`

---

## ✅ Kurulum Checklist

- [ ] Docker ve Docker Compose kurulu
- [ ] Template sunucuya kopyalandı
- [ ] .env dosyası oluşturuldu ve şifreler değiştirildi
- [ ] PROJECT_NAME benzersiz olarak ayarlandı
- [ ] Port'lar uygun şekilde ayarlandı
- [ ] vm.max_map_count ayarlandı (Elasticsearch için)
- [ ] Servisler başlatıldı: `docker compose --profile all up -d`
- [ ] Servisler çalışıyor: `docker compose ps`
- [ ] Test edildi (PostgreSQL, Redis, RabbitMQ, Elasticsearch)
- [ ] Firewall ayarları yapıldı
- [ ] .env dosyası izinleri sınırlandı: `chmod 600 .env`
- [ ] Backup sistemi kuruldu (opsiyonel)
- [ ] Cron job eklendi (opsiyonel)

---

**Kurulum tamamlandı! İyi çalışmalar! 🚀**
