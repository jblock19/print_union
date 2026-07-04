create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create index exports_project_id_idx on public.exports(project_id);
create index exports_template_version_id_idx on public.exports(template_version_id);
create index extraction_runs_source_upload_id_idx on public.extraction_runs(source_upload_id);
create index shared_links_owner_id_idx on public.shared_links(owner_id);
create index template_assets_project_id_idx on public.template_assets(project_id);
create index template_assets_source_upload_id_idx on public.template_assets(source_upload_id);
create index template_assets_template_version_id_idx on public.template_assets(template_version_id);
create index template_versions_project_id_idx on public.template_versions(project_id);
create index templates_extraction_run_id_idx on public.templates(extraction_run_id);
create index templates_source_upload_id_idx on public.templates(source_upload_id);
