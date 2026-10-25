<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Recherche hybride des cadeaux (assistante IA) :
 *  - plein texte français, sans accents (colonne générée + index GIN) ;
 *  - similarité de sens par vecteurs pgvector (table à part pour ne pas alourdir
 *    les requêtes du catalogue, demi-précision + index HNSW) ;
 *  - étiquettes ajoutées par l'IA (ai_tags) pour enrichir les fiches pauvres.
 * Nécessite l'image Docker pgvector/pgvector:pg16.
 */
return new class extends Migration
{
    public function up(): void
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

    public function down(): void
    {
        DB::statement('DROP TABLE IF EXISTS gift_embeddings');
        DB::statement('DROP INDEX IF EXISTS gifts_search_vector_idx');
        DB::statement('ALTER TABLE gifts DROP COLUMN IF EXISTS search_vector, DROP COLUMN IF EXISTS search_hash, DROP COLUMN IF EXISTS ai_tags');
        DB::statement('DROP FUNCTION IF EXISTS immutable_unaccent(text)');
    }
};
