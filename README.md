# Docker Compose Proje Template

Production-ready, modüler Docker Compose sistemi. PostgreSQL, Redis, RabbitMQ ve Elasticsearch servisleri için hazır altyapı.

## 🚀 Hızlı Başlangıç

### 1. Template'i Kopyala

```bash
# Yeni proje oluştur
sudo mkdir -p /opt/proje1
sudo cp -r . /opt/proje1/
cd /opt/proje1

cp -r ../compose-template/* .
cp ../.env.example .env .

```

### 2. Ayarları Düzenle

```bash
nano .env
```

**Mutlaka değiştir:**
- `PROJECT_NAME` → Benzersiz proje adı
- `POSTGRES_PASSWORD` → Güçlü şifre
- `REDIS_PASSWORD` → Güçlü şifre
- `RABBITMQ_PASSWORD` → Güçlü şifre
- `ELASTICSEARCH_PASSWORD` → Güçlü şifre

### 3. Servisleri Başlat

```bash
# Tüm servisleri başlat
docker compose --profile all up -d

# VEYA sadece ihtiyacın olanları başlat
docker compose --profile postgres --profile redis up -d
```

## 📦 Servisler

| Servis | Default Port | Management UI | Profile |
|--------|--------------|---------------|---------|
| PostgreSQL | 5432 | - | `postgres` |
| Redis | 6379 | - | `redis` |
| RabbitMQ | 5672 | http://localhost:15672 | `rabbitmq` |
| Elasticsearch | 9200 | - | `elasticsearch` |

## 🎯 Kullanım Örnekleri

### Servis Yönetimi

```bash
# Tüm servisleri başlat
docker compose --profile all up -d

# Sadece PostgreSQL başlat
docker compose --profile postgres up -d

# PostgreSQL + Redis başlat
docker compose --profile postgres --profile redis up -d

# Servisleri durdur
docker compose -p projeadi down

# Servisleri durdur ve volume'leri sil (DİKKAT: Data kaybolur!)
docker compose -p -projeadi down -v

# Servisleri yeniden başlat
docker compose -p projeadi restart

# Belirli servisi yeniden başlat
docker compose -p projeadi restart postgres
```

### Log İzleme

```bash
# Tüm logları izle
docker compose logs -f

# Sadece PostgreSQL logları
docker compose logs -f postgres

# Son 100 satır
docker compose logs --tail=100

# Timestamp ile
docker compose logs -f --timestamps
```

### Servis Durumu

```bash
# Çalışan servisler
docker compose ps

# Detaylı bilgi
docker compose ps -a

# Resource kullanımı
docker stats
```

### Veritabanı Bağlantıları

**PostgreSQL:**
```bash
# Container içinden
docker compose exec postgres psql -U app_user -d app_db

# Host'tan
psql -h localhost -p 5432 -U app_user -d app_db
```

**Redis:**
```bash
# Container içinden
docker compose exec redis redis-cli
AUTH your_redis_password

# Host'tan
redis-cli -h localhost -p 6379 -a your_redis_password
```

**RabbitMQ:**
```bash
# Management UI
http://localhost:15672
Username: admin
Password: [.env dosyasındaki şifre]
```

**Elasticsearch:**
```bash
# Health check
curl -u elastic:your_password http://localhost:9200/_cluster/health?pretty

# Indices listesi
curl -u elastic:your_password http://localhost:9200/_cat/indices?v
```

## 🔧 Özelleştirme

### Port Değiştirme

`.env` dosyasında:
```bash
POSTGRES_PORT=5433  # Default 5432 yerine
REDIS_PORT=6380     # Default 6379 yerine
```

### Versiyon Değiştirme

```bash
POSTGRES_VERSION=15-alpine      # 16 yerine 15
REDIS_VERSION=6-alpine          # 7 yerine 6
RABBITMQ_VERSION=3.11-management-alpine
ELASTICSEARCH_VERSION=7.17.15   # 8.x yerine 7.x
```

### Resource Limitleri

```bash
# PostgreSQL için daha fazla kaynak
POSTGRES_CPU_LIMIT=2.0
POSTGRES_MEMORY_LIMIT=2G

# Redis için daha az kaynak
REDIS_CPU_LIMIT=0.25
REDIS_MEMORY_LIMIT=256M
```

### Elasticsearch Heap Size

```bash
# Elasticsearch için JVM memory (RAM'in yarısı önerilir, max 32GB)
ELASTICSEARCH_HEAP_SIZE=1g  # 1GB heap
```

## 📁 Dizin Yapısı

```
/opt/proje1/
├── docker-compose.yml          # Ana compose dosyası
├── .env                        # Proje ayarları (GİZLİ!)
├── .env.example                # Şablon ayarlar
├── README.md                   # Bu dosya
├── data/                       # Persistent data (otomatik oluşur)
│   ├── postgres/
│   ├── redis/
│   ├── rabbitmq/
│   └── elasticsearch/
└── config/                     # İleri seviye config (opsiyonel)
    ├── postgres/
    │   └── init.sql
    ├── redis/
    │   └── redis.conf
    ├── rabbitmq/
    │   ├── rabbitmq.conf
    │   └── definitions.json
    └── elasticsearch/
        └── elasticsearch.yml
```

## 🔒 Güvenlik

### Önemli Güvenlik Notları

1. **.env dosyasını asla paylaşma veya commit etme**
2. **Production'da güçlü şifreler kullan** (min 16 karakter)
3. **Her proje için farklı şifreler kullan**
4. **Portları gerekmedikçe dışarıya açma**
5. **Düzenli yedek al**

### Şifre Güvenliği

```bash
# Güçlü şifre oluştur
openssl rand -base64 32

# Veya
pwgen -s 32 1
```

### Firewall Ayarları (Ubuntu)

```bash
# Sadece localhost'tan erişim
sudo ufw allow from 127.0.0.1 to any port 5432
sudo ufw allow from 127.0.0.1 to any port 6379

# Belirli IP'den erişim
sudo ufw allow from 192.168.1.100 to any port 5432
```

## 🔄 Yedekleme

### PostgreSQL Backup

```bash
# Manuel backup
docker compose exec postgres pg_dump -U app_user app_db > backup_$(date +%Y%m%d).sql

# Restore
docker compose exec -T postgres psql -U app_user app_db < backup_20260206.sql

# Otomatik backup scripti
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/proje1/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
docker compose exec -T postgres pg_dump -U app_user app_db > $BACKUP_DIR/backup_$DATE.sql
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete  # 7 günden eski backupları sil
EOF
chmod +x backup.sh

# Crontab'a ekle (her gün saat 02:00)
echo "0 2 * * * cd /opt/proje1 && ./backup.sh" | crontab -
```

### Redis Backup

```bash
# RDB snapshot tetikle
docker compose exec redis redis-cli -a your_password BGSAVE

# AOF dosyasını kopyala
docker compose exec redis redis-cli -a your_password BGREWRITEAOF
cp data/redis/appendonly.aof backups/redis_$(date +%Y%m%d).aof
```

## 🐛 Sorun Giderme

### Container başlamıyor

```bash
# Logları kontrol et
docker compose logs postgres

# Container detaylarını gör
docker compose ps -a

# Port çakışması kontrolü
netstat -tulpn | grep 5432
```

### Permission hataları

```bash
# Data klasörü izinlerini düzelt
sudo chown -R $USER:$USER data/

# Elasticsearch için özel
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Disk doldu

```bash
# Kullanılmayan container'ları temizle
docker system prune -a

# Volume'leri kontrol et
docker system df

# Logları temizle
docker compose logs > /dev/null
truncate -s 0 $(docker inspect --format='{{.LogPath}}' proje1_postgres)
```

### Network sorunları

```bash
# Network'ü yeniden oluştur
docker compose down
docker network prune
docker compose up -d
```

## 📊 Monitoring

### Health Check

```bash
# Tüm servislerin sağlığını kontrol et
docker compose ps

# Manuel health check
docker compose exec postgres pg_isready -U app_user
docker compose exec redis redis-cli -a your_password ping
docker compose exec rabbitmq rabbitmq-diagnostics ping
curl -u elastic:your_password http://localhost:9200/_cluster/health
```

### Resource Monitoring

```bash
# Realtime monitoring
docker stats

# Container kaynak kullanımı
docker compose top
```

## 🚀 Çoklu Proje Yapısı

### Proje 2 Oluşturma

```bash
# Template'i kopyala
sudo cp -r /opt/proje1 /opt/proje2
cd /opt/proje2

# .env'i düzenle
nano .env
```

**Mutlaka değiştir:**
- `PROJECT_NAME=proje2` (benzersiz olmalı!)
- Port'ları değiştir (çakışma olmasın):
  - `POSTGRES_PORT=5433`
  - `REDIS_PORT=6380`
  - `RABBITMQ_PORT=5673`
  - `RABBITMQ_MANAGEMENT_PORT=15673`
  - `ELASTICSEARCH_PORT=9201`
- Şifreleri değiştir

```bash
# Proje2'yi başlat
docker compose --profile all up -d
```

### Proje Yönetimi

```bash
# Proje1
cd /opt/proje1 && docker compose ps

# Proje2
cd /opt/proje2 && docker compose ps

# Tüm projeleri göster
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## 📚 İleri Seviye

### Custom Init Scripts

**PostgreSQL init script** (`config/postgres/init.sql`):
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### RabbitMQ Definitions

**RabbitMQ definitions** (`config/rabbitmq/definitions.json`):
```json
{
  "queues": [
    {
      "name": "tasks",
      "vhost": "/",
      "durable": true,
      "auto_delete": false
    }
  ],
  "exchanges": [
    {
      "name": "events",
      "vhost": "/",
      "type": "topic",
      "durable": true
    }
  ]
}
```

### Redis Custom Config

**Redis config** (`config/redis/redis.conf`):
```conf
# Custom Redis ayarları
maxclients 10000
timeout 300
tcp-keepalive 60
```

## 📞 Destek

Sorun yaşarsan:
1. Önce `docker compose logs -f` ile logları kontrol et
2. `docker compose ps` ile container durumlarına bak
3. `.env` dosyasındaki ayarları gözden geçir
4. README'deki "Sorun Giderme" bölümüne bak

## 📄 Lisans

Bu template serbest kullanım içindir. İstediğin gibi değiştir ve kullan.
