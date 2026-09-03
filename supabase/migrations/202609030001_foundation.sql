create extension if not exists pgcrypto;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  password_hash text not null,
  role text not null default 'USER' check (role in ('ADMIN','USER')),
  email_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists workspace_members (
  workspace_id uuid not null references workspaces(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  role text not null check (role in ('OWNER','ADMIN','ANALYST','VIEWER')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists cases (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  title text not null,
  description text not null default '',
  status text not null default 'OPEN' check (status in ('OPEN','PAUSED','CLOSED')),
  created_by uuid not null references users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists entities (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  case_id uuid references cases(id) on delete cascade,
  kind text not null,
  name text not null,
  attributes jsonb not null default '{}'::jsonb,
  created_by uuid not null references users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists evidence (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  case_id uuid references cases(id) on delete cascade,
  entity_id uuid references entities(id) on delete set null,
  source_url text not null,
  title text not null default '',
  content_hash text,
  captured_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid not null references users(id) on delete restrict
);

create table if not exists research_runs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  case_id uuid references cases(id) on delete cascade,
  query text not null,
  status text not null default 'QUEUED' check (status in ('QUEUED','RUNNING','SUCCEEDED','FAILED','CANCELLED')),
  provider text not null,
  result jsonb,
  error text,
  created_by uuid not null references users(id) on delete restrict,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  type text not null,
  status text not null default 'QUEUED' check (status in ('QUEUED','RUNNING','SUCCEEDED','FAILED','CANCELLED')),
  progress integer not null default 0 check (progress between 0 and 100),
  attempts integer not null default 0,
  payload jsonb not null default '{}'::jsonb,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists workspace_invitations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  email text not null,
  role text not null check (role in ('ADMIN','ANALYST','VIEWER')),
  token_hash text not null unique,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists audit_logs (
  id bigint generated always as identity primary key,
  user_id uuid references users(id) on delete set null,
  workspace_id uuid references workspaces(id) on delete set null,
  action text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists workspace_members_user_idx on workspace_members(user_id);
create index if not exists cases_workspace_idx on cases(workspace_id, created_at desc);
create index if not exists entities_workspace_idx on entities(workspace_id, created_at desc);
create index if not exists evidence_workspace_idx on evidence(workspace_id, captured_at desc);
create index if not exists research_runs_workspace_idx on research_runs(workspace_id, created_at desc);
create index if not exists jobs_status_idx on jobs(status, created_at);

alter table users enable row level security;
alter table workspaces enable row level security;
alter table workspace_members enable row level security;
alter table cases enable row level security;
alter table entities enable row level security;
alter table evidence enable row level security;
alter table research_runs enable row level security;
alter table jobs enable row level security;
alter table workspace_invitations enable row level security;
alter table audit_logs enable row level security;
