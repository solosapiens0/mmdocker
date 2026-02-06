-- PostgreSQL İlk Kurulum Script'i
-- Bu dosya container ilk başlatıldığında otomatik çalışır

-- Faydalı extension'ları etkinleştir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID üretimi için
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Full-text search için
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Şifreleme fonksiyonları
CREATE EXTENSION IF NOT EXISTS "hstore";         -- Key-value store

-- Örnek tablo (ihtiyaca göre düzenle veya sil)
CREATE TABLE IF NOT EXISTS example_table (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Örnek index
CREATE INDEX IF NOT EXISTS idx_example_email ON example_table(email);
CREATE INDEX IF NOT EXISTS idx_example_created ON example_table(created_at DESC);

-- Güncelleme trigger'ı için fonksiyon
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger oluştur
DROP TRIGGER IF EXISTS update_example_updated_at ON example_table;
CREATE TRIGGER update_example_updated_at
    BEFORE UPDATE ON example_table
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- İşlem tamamlandı mesajı
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully!';
END $$;
