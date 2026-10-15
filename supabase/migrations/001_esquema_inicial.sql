-- Esquema PREPARATÓRIO da futura integração Supabase.
-- Este script NÃO conecta automaticamente o app em modo DEMO ao backend.
-- Revise em ambiente de teste antes de usar qualquer dado real.
-- Exige projeto Supabase com auth.users.

create extension if not exists pgcrypto;

create table if not exists public.academias (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (char_length(nome) between 2 and 150),
  criada_em timestamptz not null default now()
);

create table if not exists public.perfis (
  id uuid primary key references auth.users(id) on delete restrict,
  academia_id uuid not null references public.academias(id),
  nome text not null check (char_length(nome) between 2 and 150),
  papel text not null check (papel in ('admin','professor','aluno')),
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  unique (id, academia_id)
);
create index if not exists idx_perfis_academia_papel on public.perfis(academia_id, papel);

create table if not exists public.avaliacoes (
  aluno_id uuid primary key references public.perfis(id) on delete restrict,
  academia_id uuid not null references public.academias(id),
  status text not null default 'pendente' check (status in ('pendente','agendada','concluida')),
  agendada_para timestamptz,
  concluida_em timestamptz,
  atualizada_por uuid references public.perfis(id),
  atualizada_em timestamptz not null default now()
);

-- Histórico de vínculos. Apenas UM vínculo ativo por aluno.
create table if not exists public.vinculos (
  id uuid primary key default gen_random_uuid(),
  academia_id uuid not null references public.academias(id),
  aluno_id uuid not null references public.perfis(id),
  professor_id uuid not null references public.perfis(id),
  criado_por uuid not null references public.perfis(id),
  iniciado_em timestamptz not null default now(),
  encerrado_por uuid references public.perfis(id),
  encerrado_em timestamptz
);
create unique index if not exists idx_vinculo_ativo_aluno
  on public.vinculos (aluno_id) where encerrado_em is null;
create index if not exists idx_vinculos_professor on public.vinculos(professor_id, academia_id);

create table if not exists public.modelos (
  id uuid primary key default gen_random_uuid(),
  academia_id uuid not null references public.academias(id),
  professor_id uuid not null references public.perfis(id),
  nome text not null,
  criado_em timestamptz not null default now()
);
create table if not exists public.modelos_exercicios (
  id uuid primary key default gen_random_uuid(),
  modelo_id uuid not null references public.modelos(id) on delete cascade,
  ordem integer not null check (ordem >= 0),
  nome text not null,
  series integer not null check (series between 1 and 50),
  repeticoes integer not null check (repeticoes between 1 and 300),
  carga_kg numeric(8,2) not null default 0 check (carga_kg between 0 and 2000),
  descanso_segundos integer not null default 60 check (descanso_segundos between 0 and 10000),
  observacao text not null default '',
  unique (modelo_id, ordem)
);

create table if not exists public.fichas (
  id uuid primary key default gen_random_uuid(),
  academia_id uuid not null references public.academias(id),
  aluno_id uuid not null references public.perfis(id),
  professor_id uuid not null references public.perfis(id),
  modelo_origem_id uuid references public.modelos(id) on delete set null,
  nome text not null,
  atribuida_em timestamptz not null default now()
);
create table if not exists public.fichas_exercicios (
  id uuid primary key default gen_random_uuid(),
  ficha_id uuid not null references public.fichas(id) on delete cascade,
  ordem integer not null check (ordem >= 0),
  nome text not null,
  series integer not null check (series between 1 and 50),
  repeticoes integer not null check (repeticoes between 1 and 300),
  carga_kg numeric(8,2) not null check (carga_kg between 0 and 2000),
  descanso_segundos integer not null check (descanso_segundos between 0 and 10000),
  observacao text not null default '',
  unique(ficha_id, ordem)
);

create table if not exists public.sessoes (
  id uuid primary key default gen_random_uuid(),
  ficha_id uuid not null references public.fichas(id),
  aluno_id uuid not null references public.perfis(id),
  iniciada_em timestamptz not null default now(),
  finalizada_em timestamptz
);
create table if not exists public.registros_series (
  id uuid primary key default gen_random_uuid(),
  sessao_id uuid not null references public.sessoes(id),
  aluno_id uuid not null references public.perfis(id),
  ordem_exercicio integer not null check (ordem_exercicio >= 0),
  numero_serie integer not null check (numero_serie >= 1),
  repeticoes integer not null check (repeticoes between 0 and 300),
  carga_kg numeric(8,2) not null check (carga_kg between 0 and 2000),
  concluida_em timestamptz not null default now(),
  unique(sessao_id, ordem_exercicio, numero_serie)
);

-- Funções de leitura, com search_path fixo para limitar resolução de objetos.
create or replace function public.minha_academia_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select p.academia_id from public.perfis p
  where p.id = auth.uid() and p.ativo = true limit 1;
$$;
create or replace function public.meu_papel() returns text
language sql stable security definer set search_path = '' as $$
  select p.papel from public.perfis p
  where p.id = auth.uid() and p.ativo = true limit 1;
$$;
revoke all on function public.minha_academia_id() from public;
revoke all on function public.meu_papel() from public;
grant execute on function public.minha_academia_id() to authenticated;
grant execute on function public.meu_papel() to authenticated;

alter table public.academias enable row level security;
alter table public.perfis enable row level security;
alter table public.avaliacoes enable row level security;
alter table public.vinculos enable row level security;
alter table public.modelos enable row level security;
alter table public.modelos_exercicios enable row level security;
alter table public.fichas enable row level security;
alter table public.fichas_exercicios enable row level security;
alter table public.sessoes enable row level security;
alter table public.registros_series enable row level security;

create policy academias_select on public.academias for select to authenticated
  using (id = public.minha_academia_id());
create policy perfis_select on public.perfis for select to authenticated
  using (id = auth.uid() or (academia_id = public.minha_academia_id()
    and public.meu_papel() in ('admin','professor')));
-- Não há políticas públicas de INSERT/UPDATE/DELETE em perfis: operações
-- privilegiadas só pelo backend autenticado e autorizado.

create policy avaliacoes_select on public.avaliacoes for select to authenticated
  using (academia_id = public.minha_academia_id() and
    (aluno_id = auth.uid() or public.meu_papel() in ('admin','professor')));
create policy avaliacoes_insert_admin on public.avaliacoes for insert to authenticated
  with check (academia_id = public.minha_academia_id() and public.meu_papel() = 'admin'
    and exists (select 1 from public.perfis p where p.id = aluno_id and
      p.academia_id = academia_id and p.papel = 'aluno' and p.ativo));
create policy avaliacoes_update_admin on public.avaliacoes for update to authenticated
  using (academia_id = public.minha_academia_id() and public.meu_papel() = 'admin')
  with check (academia_id = public.minha_academia_id() and public.meu_papel() = 'admin'
    and exists (select 1 from public.perfis p where p.id = aluno_id and
      p.academia_id = academia_id and p.papel = 'aluno' and p.ativo));

create policy vinculos_select on public.vinculos for select to authenticated
  using (academia_id = public.minha_academia_id() and
    (aluno_id = auth.uid() or professor_id = auth.uid() or public.meu_papel() = 'admin'));
-- A alteração de vínculo depende de RPC, não de escrita direta na tabela.

create policy modelos_select on public.modelos for select to authenticated
  using (academia_id = public.minha_academia_id() and
    (professor_id = auth.uid() or public.meu_papel() = 'admin'));
create policy modelos_insert on public.modelos for insert to authenticated
  with check (academia_id = public.minha_academia_id() and
    professor_id = auth.uid() and public.meu_papel() = 'professor');
create policy modelos_update on public.modelos for update to authenticated
  using (academia_id = public.minha_academia_id() and professor_id = auth.uid()
    and public.meu_papel() = 'professor')
  with check (academia_id = public.minha_academia_id() and professor_id = auth.uid());

create policy modelo_exercicios_select on public.modelos_exercicios for select to authenticated
  using (exists (select 1 from public.modelos m where m.id = modelo_id));
create policy modelo_exercicios_insert on public.modelos_exercicios for insert to authenticated
  with check (exists (select 1 from public.modelos m where m.id = modelo_id and
    m.professor_id = auth.uid() and m.academia_id = public.minha_academia_id()));
create policy modelo_exercicios_update on public.modelos_exercicios for update to authenticated
  using (exists (select 1 from public.modelos m where m.id = modelo_id and m.professor_id = auth.uid()))
  with check (exists (select 1 from public.modelos m where m.id = modelo_id and m.professor_id = auth.uid()));
create policy modelo_exercicios_delete on public.modelos_exercicios for delete to authenticated
  using (exists (select 1 from public.modelos m where m.id = modelo_id and m.professor_id = auth.uid()));

create policy fichas_select on public.fichas for select to authenticated
  using (academia_id = public.minha_academia_id() and
    (aluno_id = auth.uid() or professor_id = auth.uid() or public.meu_papel() = 'admin'));
-- Escrita de fichas e exercícios por RPC transacional de atribuição ainda a construir.
create policy fichas_exercicios_select on public.fichas_exercicios for select to authenticated
  using (exists (select 1 from public.fichas f where f.id = ficha_id));

create policy sessoes_select on public.sessoes for select to authenticated
  using (aluno_id = auth.uid() or (public.meu_papel() = 'professor' and
    exists (select 1 from public.fichas f where f.id = ficha_id and f.professor_id = auth.uid())));
create policy sessoes_insert on public.sessoes for insert to authenticated
  with check (aluno_id = auth.uid() and public.meu_papel() = 'aluno'
    and exists (select 1 from public.fichas f where f.id = ficha_id and f.aluno_id = auth.uid()));
create policy sessoes_update on public.sessoes for update to authenticated
  using (aluno_id = auth.uid() and finalizada_em is null)
  with check (aluno_id = auth.uid());
create policy registros_select on public.registros_series for select to authenticated
  using (aluno_id = auth.uid());
create policy registros_insert on public.registros_series for insert to authenticated
  with check (aluno_id = auth.uid() and public.meu_papel() = 'aluno'
    and exists (select 1 from public.sessoes s where s.id = sessao_id
      and s.aluno_id = auth.uid() and s.finalizada_em is null));
create policy registros_update on public.registros_series for update to authenticated
  using (aluno_id = auth.uid() and exists (select 1 from public.sessoes s
    where s.id = sessao_id and s.finalizada_em is null and s.aluno_id = auth.uid()))
  with check (aluno_id = auth.uid() and exists (select 1 from public.sessoes s
    where s.id = sessao_id and s.finalizada_em is null and s.aluno_id = auth.uid()));

-- Princípio de menor privilégio: somente SELECT em dados de identidade.
revoke all on table public.perfis from anon, authenticated;
grant select on table public.perfis to authenticated;

-- ATENÇÃO: a migração ainda é uma base arquitetural. Falta revisar
-- proteção contra manipulação de referências em sessoes/avaliacoes,
-- provisionamento de contas e RPCs transacionais, antes de produção.
