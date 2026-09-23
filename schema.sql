-- ============================================================
-- CA Odonto — Schema de agendamento (Supabase / Postgres)
-- ============================================================

create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";

create table dentists (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  name text not null,
  specialty text,
  photo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table services (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  name text not null,
  duration_minutes int not null default 30,
  active boolean not null default true,
  sort_order int not null default 0
);

create table working_hours (
  id uuid primary key default gen_random_uuid(),
  dentist_id uuid not null references dentists(id) on delete cascade,
  weekday int not null check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  check (end_time > start_time)
);

create table appointments (
  id uuid primary key default gen_random_uuid(),
  dentist_id uuid not null references dentists(id) on delete restrict,
  service_id uuid not null references services(id) on delete restrict,
  patient_name text not null,
  patient_phone text not null,
  date date not null,
  start_time time not null,
  end_time time not null,
  room text not null default 'Sala 1',
  status text not null default 'agendado' check (status in ('agendado','confirmado','concluido','cancelado')),
  notes text,
  created_at timestamptz not null default now(),
  check (end_time > start_time),
  -- faixa de tempo (usada só para o exclusion constraint abaixo)
  slot_range tsrange generated always as (
    tsrange((date + start_time), (date + end_time), '[)')
  ) stored
);

create index idx_appointments_dentist_date on appointments (dentist_id, date);

-- ------------------------------------------------------------
-- Trava de concorrência: impede duas consultas sobrepostas na
-- mesma sala (uma sala física não comporta dois pacientes), mesmo
-- em caso de dois pacientes confirmando ao mesmo tempo o mesmo
-- horário (condição de corrida). Salas diferentes podem ter
-- consultas no mesmo horário. Ignora agendamentos cancelados.
-- ------------------------------------------------------------
alter table appointments
  add constraint appointments_no_overlap
  exclude using gist (
    room with =,
    slot_range with &&
  )
  where (status <> 'cancelado');

-- ============================================================
-- Row Level Security
-- ============================================================

alter table dentists enable row level security;
alter table services enable row level security;
alter table working_hours enable row level security;
alter table appointments enable row level security;

create policy "public pode ler dentistas ativos"
  on dentists for select using (active = true);

create policy "dentista ve o proprio perfil"
  on dentists for select using (auth_user_id = auth.uid());

create policy "public pode ler servicos ativos"
  on services for select using (active = true);

create policy "public pode ler horarios de trabalho"
  on working_hours for select using (true);

-- IMPORTANTE: não existe policy pública de SELECT em `appointments`.
-- appointments.patient_name / patient_phone são dados pessoais de
-- pacientes e não podem ser lidos pelo anon key. A disponibilidade
-- de horários no site público é calculada via a função
-- get_busy_slots() abaixo (SECURITY DEFINER, devolve só
-- dentist_id/start_time/end_time, nunca dados do paciente).

-- Paciente cria a consulta como 'agendado' (pendente); só a dentista,
-- via update, pode passar para 'confirmado'.
create policy "public pode criar agendamento"
  on appointments for insert with check (status = 'agendado');

create policy "dentista ve os proprios agendamentos"
  on appointments for select
  using (dentist_id in (select id from dentists where auth_user_id = auth.uid()));

create policy "dentista atualiza os proprios agendamentos"
  on appointments for update
  using (dentist_id in (select id from dentists where auth_user_id = auth.uid()));

-- Só permite excluir consultas já concluídas, e só as da própria dentista.
create policy "dentista exclui os proprios agendamentos concluidos"
  on appointments for delete
  using (
    status = 'concluido'
    and dentist_id in (select id from dentists where auth_user_id = auth.uid())
  );

-- ============================================================
-- Função pública de disponibilidade
-- Devolve apenas os horários ocupados (sem dados do paciente)
-- para o site público calcular os horários livres.
-- ============================================================
create or replace function public.get_busy_slots(p_date date)
returns table (dentist_id uuid, room text, start_time time, end_time time)
language sql
security definer
set search_path = public
stable
as $$
  select a.dentist_id, a.room, a.start_time, a.end_time
  from appointments a
  where a.date = p_date
    and a.status <> 'cancelado';
$$;

grant execute on function public.get_busy_slots(date) to anon, authenticated;

-- ============================================================
-- Serviços (procedimentos) oferecidos pela clínica
-- ============================================================
insert into services (category, name, duration_minutes, sort_order) values
  -- Clínico Geral
  ('Clínico Geral', 'Consulta de Avaliação', 30, 1),
  ('Clínico Geral', 'Limpeza (Profilaxia)', 45, 2),
  ('Clínico Geral', 'Restauração Simples', 40, 3),
  ('Clínico Geral', 'Restauração Composta', 60, 4),
  ('Clínico Geral', 'Aplicação de Flúor', 20, 5),
  ('Clínico Geral', 'Raspagem Subgengival', 60, 6),
  ('Clínico Geral', 'Tratamento de Canal', 90, 7),
  ('Clínico Geral', 'Retratamento de Canal', 90, 8),
  -- Ortodontia
  ('Ortodontia', 'Consulta Ortodôntica', 45, 9),
  ('Ortodontia', 'Aparelho Fixo Metálico', 90, 10),
  ('Ortodontia', 'Aparelho Estético', 90, 11),
  ('Ortodontia', 'Alinhadores Invisíveis', 60, 12),
  ('Ortodontia', 'Manutenção Ortodôntica', 30, 13),
  ('Ortodontia', 'Contenção', 45, 14),
  -- Odontopediatria
  ('Odontopediatria', 'Consulta Infantil', 30, 15),
  ('Odontopediatria', 'Limpeza Infantil', 30, 16),
  ('Odontopediatria', 'Selante', 20, 17),
  ('Odontopediatria', 'Restauração Infantil', 40, 18),
  -- Cirurgia
  ('Cirurgia', 'Consulta Implante', 45, 19),
  ('Cirurgia', 'Implante Unitário', 90, 20),
  ('Cirurgia', 'Prótese sobre Implante', 60, 21),
  ('Cirurgia', 'Enxerto Ósseo', 90, 22),
  ('Cirurgia', 'Extração Simples', 30, 23),
  ('Cirurgia', 'Extração de Siso', 60, 24),
  ('Cirurgia', 'Extração Múltipla', 90, 25),
  -- Estética
  ('Estética', 'Clareamento de Consultório', 60, 26),
  ('Estética', 'Clareamento Caseiro', 30, 27),
  ('Estética', 'Clareamento Combinado', 60, 28),
  ('Estética', 'Faceta de Porcelana', 60, 29),
  ('Estética', 'Lente de Contato Dental', 60, 30),
  ('Estética', 'Faceta de Resina', 60, 31),
  ('Estética', 'Toxina Botulínica', 30, 32),
  ('Estética', 'Preenchimento Labial', 45, 33),
  ('Estética', 'Bichectomia', 60, 34),
  ('Estética', 'Preenchimento Malar', 45, 35);

-- ============================================================
-- Passo manual: criar a dentista no Supabase Auth e vincular
-- ============================================================
-- 1) Vá em Authentication > Users > Add user e crie o login da
--    Dra. Catarina Rodrigues (e-mail + senha).
-- 2) Copie o UUID gerado para esse usuário e rode:
--
-- insert into dentists (auth_user_id, name, specialty) values
--   ('COLE-O-UUID-AQUI', 'Dra. Catarina Rodrigues', 'Cirurgiã-Dentista');
--
-- insert into working_hours (dentist_id, weekday, start_time, end_time)
-- select id, wd, '09:00', '17:00' from dentists, generate_series(1,5) as wd
-- where name = 'Dra. Catarina Rodrigues';
--
-- insert into working_hours (dentist_id, weekday, start_time, end_time)
-- select id, 6, '09:00', '12:00' from dentists
-- where name = 'Dra. Catarina Rodrigues';

-- ============================================================
-- Migração: fluxo de confirmação em duas etapas
-- (rode isso se o banco já existe e foi criado com a versão
-- anterior deste schema.sql, antes de publicar o novo index.html
-- /admin.html — senão os agendamentos do site público vão parar
-- de funcionar, porque o insert vai tentar gravar status='agendado'
-- e a policy/constraint antigas só aceitavam 'confirmado')
-- ============================================================
-- alter table appointments drop constraint if exists appointments_status_check;
-- alter table appointments add constraint appointments_status_check
--   check (status in ('agendado','confirmado','concluido','cancelado'));
-- alter table appointments alter column status set default 'agendado';
--
-- drop policy if exists "public pode criar agendamento" on appointments;
-- create policy "public pode criar agendamento"
--   on appointments for insert with check (status = 'agendado');

-- ============================================================
-- Migração: múltiplas salas (rode ANTES de publicar o novo
-- index.html/admin.html, num banco já existente)
-- ============================================================
-- alter table appointments add column if not exists room text not null default 'Sala 1';
--
-- alter table appointments drop constraint if exists appointments_no_overlap;
-- alter table appointments add constraint appointments_no_overlap
--   exclude using gist (room with =, slot_range with &&)
--   where (status <> 'cancelado');
--
-- drop function if exists public.get_busy_slots(date);
-- create function public.get_busy_slots(p_date date)
-- returns table (dentist_id uuid, room text, start_time time, end_time time)
-- language sql security definer set search_path = public stable
-- as $$
--   select a.dentist_id, a.room, a.start_time, a.end_time
--   from appointments a
--   where a.date = p_date and a.status <> 'cancelado';
-- $$;
-- grant execute on function public.get_busy_slots(date) to anon, authenticated;
