create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table public.source_uploads (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  storage_bucket text not null default 'print-union-sources',
  storage_path text not null,
  file_name text,
  mime_type text,
  byte_size bigint,
  width integer,
  height integer,
  status text not null default 'uploaded'
    check (status in ('uploaded', 'normalizing', 'ready', 'failed')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

create table public.extraction_runs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  source_upload_id uuid references public.source_uploads(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'queued'
    check (status in ('queued', 'running', 'succeeded', 'failed', 'cancelled')),
  engine text not null default 'local',
  input jsonb not null default '{}'::jsonb,
  geometry_json jsonb not null default '{}'::jsonb,
  style_fingerprint jsonb not null default '{}'::jsonb,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.templates (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  source_upload_id uuid references public.source_uploads(id) on delete set null,
  extraction_run_id uuid references public.extraction_runs(id) on delete set null,
  style_family text,
  thumbnail_bucket text,
  thumbnail_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.template_versions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.templates(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  version_number integer not null,
  template_json jsonb not null default jsonb_build_object(
    'canvas', jsonb_build_object(),
    'style', jsonb_build_object(),
    'elements', jsonb_build_array()
  ),
  style_fingerprint jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  unique (template_id, version_number)
);

create table public.template_assets (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  template_id uuid references public.templates(id) on delete cascade,
  template_version_id uuid references public.template_versions(id) on delete cascade,
  source_upload_id uuid references public.source_uploads(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'asset',
  storage_bucket text not null default 'print-union-assets',
  storage_path text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

create table public.exports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  template_id uuid not null references public.templates(id) on delete cascade,
  template_version_id uuid references public.template_versions(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  format text not null check (format in ('png', 'pdf', 'json', 'svg')),
  status text not null default 'queued'
    check (status in ('queued', 'running', 'succeeded', 'failed')),
  storage_bucket text not null default 'print-union-exports',
  storage_path text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shared_links (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.templates(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique default encode(gen_random_bytes(16), 'hex'),
  permission text not null default 'view' check (permission in ('view', 'remix')),
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index projects_owner_id_idx on public.projects(owner_id);
create index source_uploads_project_id_idx on public.source_uploads(project_id);
create index source_uploads_owner_id_idx on public.source_uploads(owner_id);
create index extraction_runs_project_id_idx on public.extraction_runs(project_id);
create index extraction_runs_owner_id_idx on public.extraction_runs(owner_id);
create index templates_project_id_idx on public.templates(project_id);
create index templates_owner_id_idx on public.templates(owner_id);
create index template_versions_template_id_idx on public.template_versions(template_id);
create index template_versions_owner_id_idx on public.template_versions(owner_id);
create index template_assets_template_id_idx on public.template_assets(template_id);
create index template_assets_owner_id_idx on public.template_assets(owner_id);
create index exports_template_id_idx on public.exports(template_id);
create index exports_owner_id_idx on public.exports(owner_id);
create index shared_links_template_id_idx on public.shared_links(template_id);
create index shared_links_token_idx on public.shared_links(token);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger projects_set_updated_at
before update on public.projects
for each row execute function public.set_updated_at();

create trigger source_uploads_set_updated_at
before update on public.source_uploads
for each row execute function public.set_updated_at();

create trigger extraction_runs_set_updated_at
before update on public.extraction_runs
for each row execute function public.set_updated_at();

create trigger templates_set_updated_at
before update on public.templates
for each row execute function public.set_updated_at();

create trigger template_assets_set_updated_at
before update on public.template_assets
for each row execute function public.set_updated_at();

create trigger exports_set_updated_at
before update on public.exports
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.source_uploads enable row level security;
alter table public.extraction_runs enable row level security;
alter table public.templates enable row level security;
alter table public.template_versions enable row level security;
alter table public.template_assets enable row level security;
alter table public.exports enable row level security;
alter table public.shared_links enable row level security;

create policy "profiles are readable by owner"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy "profiles are insertable by owner"
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "profiles are updatable by owner"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "projects are readable by owner"
on public.projects for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "projects are insertable by owner"
on public.projects for insert
to authenticated
with check ((select auth.uid()) = owner_id);

create policy "projects are updatable by owner"
on public.projects for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "projects are deletable by owner"
on public.projects for delete
to authenticated
using ((select auth.uid()) = owner_id);

create policy "source uploads are readable by project owner"
on public.source_uploads for select
to authenticated
using (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.projects
    where projects.id = source_uploads.project_id
      and projects.owner_id = (select auth.uid())
  )
);

create policy "source uploads are insertable by project owner"
on public.source_uploads for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.projects
    where projects.id = source_uploads.project_id
      and projects.owner_id = (select auth.uid())
  )
);

create policy "source uploads are updatable by project owner"
on public.source_uploads for update
to authenticated
using ((select auth.uid()) = owner_id)
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.projects
    where projects.id = source_uploads.project_id
      and projects.owner_id = (select auth.uid())
  )
);

create policy "source uploads are deletable by project owner"
on public.source_uploads for delete
to authenticated
using ((select auth.uid()) = owner_id);

create policy "extraction runs are readable by project owner"
on public.extraction_runs for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "extraction runs are insertable by project owner"
on public.extraction_runs for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.projects
    where projects.id = extraction_runs.project_id
      and projects.owner_id = (select auth.uid())
  )
);

create policy "extraction runs are updatable by project owner"
on public.extraction_runs for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "templates are readable by owner"
on public.templates for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "templates are insertable by project owner"
on public.templates for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.projects
    where projects.id = templates.project_id
      and projects.owner_id = (select auth.uid())
  )
);

create policy "templates are updatable by owner"
on public.templates for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "templates are deletable by owner"
on public.templates for delete
to authenticated
using ((select auth.uid()) = owner_id);

create policy "template versions are readable by owner"
on public.template_versions for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "template versions are insertable by template owner"
on public.template_versions for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.templates
    where templates.id = template_versions.template_id
      and templates.owner_id = (select auth.uid())
  )
);

create policy "template assets are readable by owner"
on public.template_assets for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "template assets are insertable by project owner"
on public.template_assets for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.projects
    where projects.id = template_assets.project_id
      and projects.owner_id = (select auth.uid())
  )
);

create policy "template assets are updatable by owner"
on public.template_assets for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "template assets are deletable by owner"
on public.template_assets for delete
to authenticated
using ((select auth.uid()) = owner_id);

create policy "exports are readable by owner"
on public.exports for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "exports are insertable by template owner"
on public.exports for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.templates
    where templates.id = exports.template_id
      and templates.owner_id = (select auth.uid())
  )
);

create policy "exports are updatable by owner"
on public.exports for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "shared links are readable by owner"
on public.shared_links for select
to authenticated
using ((select auth.uid()) = owner_id);

create policy "shared links are insertable by template owner"
on public.shared_links for insert
to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.templates
    where templates.id = shared_links.template_id
      and templates.owner_id = (select auth.uid())
  )
);

create policy "shared links are updatable by owner"
on public.shared_links for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "shared links are deletable by owner"
on public.shared_links for delete
to authenticated
using ((select auth.uid()) = owner_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.profiles,
  public.projects,
  public.source_uploads,
  public.extraction_runs,
  public.templates,
  public.template_versions,
  public.template_assets,
  public.exports,
  public.shared_links
to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'print-union-sources',
    'print-union-sources',
    false,
    52428800,
    array['image/png', 'image/jpeg', 'image/webp', 'application/pdf']
  ),
  (
    'print-union-assets',
    'print-union-assets',
    false,
    52428800,
    array['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
  ),
  (
    'print-union-exports',
    'print-union-exports',
    false,
    52428800,
    array['image/png', 'application/pdf', 'application/json', 'image/svg+xml']
  )
on conflict (id) do nothing;

create policy "users can read own print union storage objects"
on storage.objects for select
to authenticated
using (
  bucket_id in ('print-union-sources', 'print-union-assets', 'print-union-exports')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users can upload own print union storage objects"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('print-union-sources', 'print-union-assets', 'print-union-exports')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users can update own print union storage objects"
on storage.objects for update
to authenticated
using (
  bucket_id in ('print-union-sources', 'print-union-assets', 'print-union-exports')
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id in ('print-union-sources', 'print-union-assets', 'print-union-exports')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "users can delete own print union storage objects"
on storage.objects for delete
to authenticated
using (
  bucket_id in ('print-union-sources', 'print-union-assets', 'print-union-exports')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
