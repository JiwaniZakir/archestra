-- Add slug column (nullable initially so we can populate existing rows)
ALTER TABLE "agents" ADD COLUMN "slug" text;

-- Populate slugs from names: lowercase, replace non-alnum with hyphens, trim hyphens
UPDATE agents SET slug = CASE
  WHEN trim(both '-' from regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g')) = '' THEN 'agent'
  ELSE trim(both '-' from regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g'))
END;

-- Deduplicate: append random suffix to collisions (keep oldest row as-is)
WITH ranked AS (
  SELECT id, slug, ROW_NUMBER() OVER (PARTITION BY slug ORDER BY created_at) AS rn
  FROM agents
)
UPDATE agents SET slug = agents.slug || '-' || substr(md5(random()::text), 1, 6)
FROM ranked
WHERE agents.id = ranked.id AND ranked.rn > 1;

-- Now enforce NOT NULL and uniqueness
ALTER TABLE "agents" ALTER COLUMN "slug" SET NOT NULL;--> statement-breakpoint
CREATE UNIQUE INDEX "agents_slug_idx" ON "agents" USING btree ("slug");
