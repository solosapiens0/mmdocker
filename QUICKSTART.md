# ⚡ Hızlı Başlangıç Kılavuzu

## 🎯 5 Dakikada Başla

### Adım 1: Template'i Kopyala
```bash
# Proje klasörü oluştur
sudo mkdir -p /opt/proje1
sudo chown $USER:$USER /opt/proje1

# Template'i kopyala
cp -r ~/development/shiftup/mediamarkt-proje-compose-template/* /opt/proje1/
cd /opt/proje1
```

### Adım 2: Environment Ayarla
```bash
# .env dosyasını oluştur
make setup
# VEYA
cp .env.example .env

# Şifreleri düzenle
nano .env
```

**Değiştir:**
```bash
PROJECT_NAME=proje1
POSTGRES_PASSWORD=guclu_sifre_123
REDIS_PASSWORD=guclu_sifre_456
RABBITMQ_PASSWORD=guclu_sifre_789
ELASTICSEARCH_PASSWORD=guclu_sifre_012
```

### Adım 3: Başlat
```bash
# Tüm servisleri başlat
make up
# VEYA
docker compose --profile all up -d

# Durumu kontrol et
make ps
# VEYA
docker compose ps
```

### Adım 4: Test Et
```bash
# Health check
make health

# PostgreSQL test
make psql
# \l  (veritabanlarını listele)
# \q  (çık)

# Redis test
make redis-cli
# ping
# exit

# RabbitMQ Management UI
# Tarayıcıda aç: http://localhost:15672
# Kullanıcı: admin
# Şifre: .env dosyasındaki RABBITMQ_PASSWORD

# Elasticsearch test
curl -u elastic:your_password http://localhost:9200/_cluster/health?pretty
```

## 🔥 Yaygın Senaryolar

### Senaryo 1: Sadece PostgreSQL ve Redis Lazım
```bash
# .env dosyasında şifreleri ayarla
nano .env

# Sadece bunları başlat
docker compose --profile postgres --profile redis up -d

# Kontrol et
docker compose ps
```

### Senaryo 2: İkinci Proje Ekle
```bash
# Template'i kopyala
sudo mkdir -p /opt/proje2
sudo chown $USER:$USER /opt/proje2
cp -r /opt/proje1/* /opt/proje2/
cd /opt/proje2

# .env'i düzenle
nano .env
```

**Değiştir:**
```bash
PROJECT_NAME=proje2        # ÇOK ÖNEMLİ: Benzersiz olmalı!
POSTGRES_PORT=5433         # Proje1 ile çakışmasın
REDIS_PORT=6380
RABBITMQ_PORT=5673
RABBITMQ_MANAGEMENT_PORT=15673
ELASTICSEARCH_PORT=9201
# ... şifreleri de değiştir
```

```bash
# Proje2'yi başlat
docker compose --profile all up -d

# Her iki proje de çalışıyor
docker ps
```

### Senaryo 3: PostgreSQL 15 İstiyorum
```bash
# .env'de değiştir
POSTGRES_VERSION=15-alpine

# Yeniden başlat
docker compose down
docker compose --profile postgres up -d
```

### Senaryo 4: Production'da Elastic Gerekmedi
```bash
# Sadece ihtiyacın olanları başlat
docker compose --profile postgres --profile redis --profile rabbitmq up -d

# Elasticsearch başlamaz
```

## 🎨 Makefile Komutları

```bash
make help              # Tüm komutları göster
make setup             # .env oluştur
make up                # Tüm servisleri başlat
make down              # Durdur
make logs              # Logları izle
make ps                # Durum göster
make health            # Sağlık kontrolü
make backup-postgres   # PostgreSQL backup
make clean             # Tümünü sil (DİKKAT!)
```

## ⚠️ Önemli Notlar

### Port Çakışması
Eğer port zaten kullanılıyorsa:
```bash
# Hangi port kullanımda kontrol et
sudo netstat -tulpn | grep 5432

# .env'de farklı port kullan
POSTGRES_PORT=5433
```

### Elasticsearch Başlamıyor
```bash
# vm.max_map_count ayarla
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Permission Hatası
```bash
# Data klasörü izinlerini düzelt
sudo chown -R $USER:$USER data/
```

### Disk Doldu
```bash
# Eski container'ları temizle
make prune
# VEYA
docker system prune -a --volumes
```

## 📊 Monitoring

### Resource Kullanımı
```bash
# Realtime monitoring
make stats

# Docker stats
docker stats

# Disk kullanımı
docker system df
```

### Loglar
```bash
# Tüm loglar
make logs

# Sadece PostgreSQL
docker compose logs -f postgres

# Son 100 satır
docker compose logs --tail=100

# Hata logları
docker compose logs | grep -i error
```

## 🔒 Güvenlik Checklist

- [ ] `.env` dosyasındaki tüm şifreleri değiştirdim
- [ ] Her proje için farklı şifreler kullandım
- [ ] `PROJECT_NAME` her proje için benzersiz
- [ ] Port'lar çakışmıyor
- [ ] `.env` dosyası `.gitignore`'da
- [ ] Production'da güçlü şifreler (min 16 karakter)
- [ ] Firewall ayarları yapıldı (gerekirse)

## 🚀 Production'a Al

```bash
# 1. Güçlü şifreler oluştur
openssl rand -base64 32  # Her servis için çalıştır

# 2. .env'e ekle
nano .env

# 3. Firewall ayarla (sadece gerekli IP'ler)
sudo ufw allow from 192.168.1.100 to any port 5432

# 4. Backup cron job kur
crontab -e
# Ekle: 0 2 * * * cd /opt/proje1 && make backup-postgres

# 5. Log rotation ayarla
sudo nano /etc/docker/daemon.json
```

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
sudo systemctl restart docker
```

## 📞 Yardım

Sorun mu yaşıyorsun?

1. **Logları kontrol et:** `make logs`
2. **Servis durumu:** `make ps`
3. **Health check:** `make health`
4. **Config doğrula:** `make validate`
5. **README'yi oku:** `less README.md`

## 🎓 Öğrenme Kaynakları

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Redis Docker Hub](https://hub.docker.com/_/redis)
- [RabbitMQ Docker Hub](https://hub.docker.com/_/rabbitmq)
- [Elasticsearch Docker](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html)

---

**İyi çalışmalar! 🚀**
