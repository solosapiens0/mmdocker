# Docker Compose Helper Makefile
# Kullanım: make <command>

.PHONY: help
help: ## Bu yardım mesajını göster
	@echo "Kullanılabilir komutlar:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## İlk kurulum - .env dosyasını oluştur
	@if [ -f .env ]; then \
		echo "⚠️  .env dosyası zaten var!"; \
	else \
		cp .env.example .env; \
		echo "✅ .env dosyası oluşturuldu. Şimdi şifreleri düzenle: nano .env"; \
	fi

.PHONY: up
up: ## Tüm servisleri başlat
	docker compose --profile all up -d

.PHONY: down
down: ## Tüm servisleri durdur
	docker compose down

.PHONY: restart
restart: ## Tüm servisleri yeniden başlat
	docker compose restart

.PHONY: logs
logs: ## Tüm logları göster
	docker compose logs -f

.PHONY: ps
ps: ## Çalışan servisleri listele
	docker compose ps

.PHONY: stats
stats: ## Resource kullanımını göster
	docker stats

# Bireysel servisler
.PHONY: postgres
postgres: ## Sadece PostgreSQL başlat
	docker compose --profile postgres up -d

.PHONY: redis
redis: ## Sadece Redis başlat
	docker compose --profile redis up -d

.PHONY: rabbitmq
rabbitmq: ## Sadece RabbitMQ başlat
	docker compose --profile rabbitmq up -d

.PHONY: elasticsearch
elasticsearch: ## Sadece Elasticsearch başlat
	docker compose --profile elasticsearch up -d

# Database bağlantıları
.PHONY: psql
psql: ## PostgreSQL'e bağlan
	docker compose exec postgres psql -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) -d $$(grep POSTGRES_DB .env | cut -d '=' -f2)

.PHONY: redis-cli
redis-cli: ## Redis CLI'ye bağlan
	docker compose exec redis redis-cli -a $$(grep REDIS_PASSWORD .env | cut -d '=' -f2)

# Bakım işlemleri
.PHONY: backup-postgres
backup-postgres: ## PostgreSQL backup al
	@mkdir -p backups
	docker compose exec -T postgres pg_dump -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) $$(grep POSTGRES_DB .env | cut -d '=' -f2) > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup alındı: backups/backup_$$(date +%Y%m%d_%H%M%S).sql"

.PHONY: restore-postgres
restore-postgres: ## PostgreSQL restore et (FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Kullanım: make restore-postgres FILE=backups/backup_20260206.sql"; \
		exit 1; \
	fi
	docker compose exec -T postgres psql -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) $$(grep POSTGRES_DB .env | cut -d '=' -f2) < $(FILE)
	@echo "✅ Restore tamamlandı"

.PHONY: clean
clean: ## Tüm container ve volume'leri sil (DİKKAT: Data kaybolur!)
	@echo "⚠️  Bu işlem TÜM DATA'yı silecek!"
	@read -p "Devam etmek istiyor musun? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✅ Temizlendi"; \
	else \
		echo "❌ İptal edildi"; \
	fi

.PHONY: prune
prune: ## Docker sistem temizliği (kullanılmayan image/container/volume)
	docker system prune -a --volumes

# Health checks
.PHONY: health
health: ## Tüm servislerin sağlık durumunu kontrol et
	@echo "=== PostgreSQL ==="
	@docker compose exec postgres pg_isready -U $$(grep POSTGRES_USER .env | cut -d '=' -f2) || echo "❌ Offline"
	@echo "\n=== Redis ==="
	@docker compose exec redis redis-cli -a $$(grep REDIS_PASSWORD .env | cut -d '=' -f2) ping || echo "❌ Offline"
	@echo "\n=== RabbitMQ ==="
	@docker compose exec rabbitmq rabbitmq-diagnostics ping || echo "❌ Offline"
	@echo "\n=== Elasticsearch ==="
	@curl -s -u elastic:$$(grep ELASTICSEARCH_PASSWORD .env | cut -d '=' -f2) http://localhost:$$(grep ELASTICSEARCH_PORT .env | cut -d '=' -f2)/_cluster/health | grep -o '"status":"[^"]*"' || echo "❌ Offline"

.PHONY: validate
validate: ## docker-compose.yml syntax kontrolü
	docker compose config > /dev/null && echo "✅ Syntax doğru"

.PHONY: update
update: ## Container image'larını güncelle
	docker compose pull
	docker compose up -d
	@echo "✅ Güncelleme tamamlandı"

# Monitoring
.PHONY: watch
watch: ## Resource kullanımını sürekli izle
	watch -n 2 docker stats --no-stream
