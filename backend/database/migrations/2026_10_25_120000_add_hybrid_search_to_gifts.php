<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Recherche hybride des cadeaux (assistante IA).
 *
 * PostgreSQL (pgvector) : plein texte français (tsvector) + vecteurs halfvec/HNSW.
 *
 * MySQL / MariaDB (IONOS) : pas de pgvector. On ajoute les colonnes nécessaires
 * et un index FULLTEXT ; GiftSearch utilise le plein texte + les critères
 * structurés, GiftSearchIndex ne stocke que les étiquettes IA (pas de vecteurs).
 */
return new class extends Migration
{
    public function up(): void
    {
        match (DB::connection()->getDriverName()) {
            'pgsql' => $this->upPostgres(),
            'mysql', 'mariadb' => $this->upMysql(),
            default => $this->upFallback(),
        };
    }

    private function upPostgres(): void
    {
        $dims = (int) config('services.openrouter.embedding_dimensions', 1024);

        DB::statement('CREATE EXTENSION IF NOT EXISTS vector');
        DB::statement('CREATE EXTENSION IF NOT EXISTS unaccent');
        // unaccent() n'est pas IMMUTABLE : enveloppe nécessaire pour une colonne générée
        DB::statement(<<<'SQL'
            CREATE OR REPLACE FUNCTION immutable_unaccent(text) RETURNS text
            LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
            AS $$ SELECT public.unaccent('public.unaccent', $1) $$
        SQL);

        DB::statement('ALTER TABLE gifts ADD COLUMN ai_tags text NULL');
        DB::statement('ALTER TABLE gifts ADD COLUMN search_hash varchar(64) NULL');
        DB::statement(<<<'SQL'
            ALTER TABLE gifts ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
                setweight(to_tsvector('french'::regconfig, immutable_unaccent(coalesce(name, ''))), 'A') ||
                setweight(to_tsvector('french'::regconfig, immutable_unaccent(coalesce(category, '') || ' ' || coalesce(ai_tags, ''))), 'B') ||
                setweight(to_tsvector('french'::regconfig, immutable_unaccent(coalesce(description, ''))), 'C')
            ) STORED
        SQL);
        DB::statement('CREATE INDEX gifts_search_vector_idx ON gifts USING gin (search_vector)');

        DB::statement(<<<SQL
            CREATE TABLE gift_embeddings (
                gift_id bigint PRIMARY KEY REFERENCES gifts(id) ON DELETE CASCADE,
                embedding halfvec($dims) NOT NULL,
                model varchar(120) NOT NULL,
                updated_at timestamp(0) NULL
            )
        SQL);
        DB::statement('CREATE INDEX gift_embeddings_hnsw_idx ON gift_embeddings USING hnsw (embedding halfvec_cosine_ops)');
    }

    private function upMysql(): void
    {
        DB::statement('ALTER TABLE gifts ADD COLUMN ai_tags TEXT NULL');
        DB::statement('ALTER TABLE gifts ADD COLUMN search_hash VARCHAR(64) NULL');
        // Recherche plein texte MySQL/MariaDB (InnoDB).
        DB::statement('ALTER TABLE gifts ADD FULLTEXT INDEX gifts_fulltext_idx (name, description, category, ai_tags)');
    }

    private function upFallback(): void
    {
        DB::statement('ALTER TABLE gifts ADD COLUMN ai_tags TEXT NULL');
        DB::statement('ALTER TABLE gifts ADD COLUMN search_hash VARCHAR(64) NULL');
    }

    public function down(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('DROP TABLE IF EXISTS gift_embeddings');
            DB::statement('DROP INDEX IF EXISTS gifts_search_vector_idx');
            DB::statement('ALTER TABLE gifts DROP COLUMN IF EXISTS search_vector, DROP COLUMN IF EXISTS search_hash, DROP COLUMN IF EXISTS ai_tags');
            DB::statement('DROP FUNCTION IF EXISTS immutable_unaccent(text)');

            return;
        }

        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            DB::statement('ALTER TABLE gifts DROP INDEX gifts_fulltext_idx');
            DB::statement('ALTER TABLE gifts DROP COLUMN ai_tags, DROP COLUMN search_hash');

            return;
        }

        DB::statement('ALTER TABLE gifts DROP COLUMN ai_tags, DROP COLUMN search_hash');
    }
};
