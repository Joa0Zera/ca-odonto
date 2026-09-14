<div align="center">

<img src="assets/logo.png" width="260" alt="CA Odonto">

# 🦷 CA Odonto — Sistema de Agendamento Online

Agendamento odontológico sem atendente, sem ligação, sem fricção.
Do botão **"Agendar"** do Google Meu Negócio direto pra agenda da clínica.

</div>

---

## O que é?

Um sistema de agendamento on-line construído para a **CA Odonto**, clínica odontológica em Mogi das Cruzes - SP. O paciente clica no botão "Agendar" do perfil da clínica no Google, escolhe o procedimento, o dia e o horário, preenche os dados — e pronto: a consulta já está marcada e visível na agenda da doutora, sem ninguém precisar atender telefone no meio do caminho.

Duas telas compõem o sistema: uma pública, para o paciente agendar sozinho, e uma administrativa, para a clínica gerenciar a própria agenda pelo celular.

## Problema que resolve

- A clínica dependia de ligações para marcar cada consulta.
- A agenda manual (papel ou planilha) gerava confusão e overbooking.
- Pacientes tinham dificuldade para saber quais horários estavam realmente livres.
- Tempo de atendente era gasto no telefone em vez de na cadeira.

## Solução

Um site de agendamento **auto-suficiente**, sem intermediário humano, com:

- **Frontend** em HTML/CSS/JS puro — sem framework, sem build, fácil de manter e hospedar.
- **Backend** no Supabase (Postgres + Auth + Row Level Security) — sem servidor próprio para manter no ar.
- **Duas interfaces**: pública (paciente marca sozinho) e administrativa (doutora gerencia a própria agenda).
- **Deploy** na Vercel — publica em minutos, sem pipeline de build.
- **Segurança de dados no nível do banco**: cada doutora só acessa a própria agenda, e dados de pacientes nunca ficam expostos publicamente — isso é garantido por Row Level Security, não só pela interface.

## Features

- ✅ Agendamento on-line em tempo real, sem intermediário
- ✅ Seleção de procedimento em duas etapas (categoria → mais de 30 procedimentos)
- ✅ Calendário com disponibilidade calculada automaticamente por horário de trabalho
- ✅ Atribuição automática da profissional disponível (transparente para o paciente)
- ✅ Login seguro para a clínica (Supabase Auth)
- ✅ Agenda mobile-first para as doutoras, com navegação por dia
- ✅ Atualização de status da consulta (concluída / cancelada)
- ✅ Row Level Security — dados isolados por usuário, aplicado no banco
- ✅ Anti-race condition — impossível duplicar reserva no mesmo horário
- ✅ Zero dependências pesadas — HTML puro + client do Supabase via CDN
- ✅ Deploy simples — Vercel, sem build, em minutos

## Stack Técnico

```
Frontend:       HTML5 + CSS3 + JavaScript (vanilla, sem framework)
Backend:        Supabase (Postgres + Auth + Row Level Security)
Hospedagem:     Vercel (preset "Other", sem build)
Fonte:          Google Fonts (Poppins)
CDN:            jsDelivr (@supabase/supabase-js)
Versionamento:  Git + GitHub
```

## Arquitetura

```
┌───────────────────────────────────────────────────────────┐
│                 Google Meu Negócio (GMN)                   │
│              Botão "Agendar" → link da Vercel               │
└───────────────────────────┬───────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────┐
│                     Vercel (Frontend estático)               │
│   ┌────────────────┐            ┌────────────────┐          │
│   │  index.html    │            │  admin.html    │          │
│   │  (paciente)    │            │  (doutora)     │          │
│   └────────┬───────┘            └────────┬───────┘          │
└────────────┼─────────────────────────────┼──────────────────┘
             │                             │
             └──────────────┬──────────────┘
                             │  @supabase/supabase-js (anon key)
              ┌──────────────▼──────────────┐
              │        Supabase (Backend)     │
              │  ┌──────────────────────────┐ │
              │  │  Postgres                │ │
              │  │  ├─ dentists              │ │
              │  │  ├─ services              │ │
              │  │  ├─ working_hours         │ │
              │  │  └─ appointments          │ │
              │  │  RLS policies +           │ │
              │  │  função get_busy_slots()  │ │
              │  └──────────────────────────┘ │
              │  ┌──────────────────────────┐ │
              │  │  Auth (JWT)               │ │
              │  │  login das doutoras       │ │
              │  └──────────────────────────┘ │
              └──────────────────────────────┘
```

## Como funciona?

### Para o Paciente

1. Clica no botão "Agendar" no perfil do Google Meu Negócio.
2. Chega em `index.html` — nenhum login, nenhuma etapa extra.
3. Escolhe a categoria (Clínico Geral, Ortodontia, Odontopediatria, Cirurgia, Estética) e o procedimento.
4. Escolhe o dia no calendário — dias sem disponibilidade já aparecem desabilitados.
5. Escolhe o horário (aba Manhã ou Tarde).
6. Preenche nome e telefone/WhatsApp.
7. Confirma.
8. O sistema atribui automaticamente a profissional disponível para aquele horário — o paciente não escolhe nem vê qual doutora vai atender.
9. Consulta salva no banco, com trava de concorrência contra dois pacientes reservando o mesmo horário ao mesmo tempo.

### Para a Clínica (Admin)

1. Acessa `admin.html` pelo celular ou computador.
2. Faz login com e-mail e senha (Supabase Auth).
3. Vê a própria agenda do dia — nunca a de outra profissional.
4. Marca consultas como "Concluída" ou "Cancelada".
5. Navega entre dias (‹ anterior / próximo › / "Hoje").

## 🛠️ Deploy — Colocando em produção

Resumo do caminho até o ar: rodar o `schema.sql` no Supabase, colar as credenciais nos dois HTMLs, publicar no GitHub, importar na Vercel e colar o link no Google Meu Negócio. O passo a passo completo está abaixo.

### 1. Criar o projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e crie um novo projeto (região São Paulo, se disponível).
2. Anote a **senha do banco** que você definir — vai precisar dela só se for acessar via `psql`.
3. Espere o projeto terminar de provisionar (1-2 minutos).

### 2. Rodar o schema

1. No painel do Supabase, vá em **SQL Editor** → **New query**.
2. Cole todo o conteúdo do arquivo `schema.sql` deste projeto.
3. Clique em **Run**. Isso cria as tabelas (`dentists`, `services`, `working_hours`, `appointments`), as políticas de RLS, a função `get_busy_slots` e já insere os ~35 procedimentos da clínica.

> O schema já vem com duas proteções extras além do que foi pedido:
> - **Dados de pacientes protegidos:** não existe policy pública de leitura em `appointments`. A disponibilidade de horários no site público é calculada por uma função (`get_busy_slots`) que devolve só `dentist_id/start_time/end_time` — nunca nome ou telefone de paciente.
> - **Trava contra conflito de horário:** um `exclusion constraint` no banco impede que duas pessoas reservem o mesmo horário com a mesma dentista ao mesmo tempo (condição de corrida), mesmo que os dois cliques cheguem quase simultâneos.

### 3. Pegar a URL e a chave pública (anon key)

1. No painel do Supabase, vá em **Project Settings → API**.
2. Copie:
   - **Project URL** (algo como `https://xxxxxxxx.supabase.co`)
   - **anon public key** (a chave pública — **nunca** use a `service_role` no frontend)
3. Cole os dois valores no objeto `CONFIG` no topo do `<script>` de **`index.html`** e de **`admin.html`**:

```js
const CONFIG = {
  ...
  supabaseUrl: "https://xxxxxxxx.supabase.co",
  supabaseAnonKey: "eyJhbGciOi...",
};
```

### 4. Criar o login da Dra. Catarina Rodrigues

1. No painel do Supabase, vá em **Authentication → Users → Add user**.
2. Crie o usuário com o e-mail e senha que a doutora vai usar para entrar no `admin.html`.
3. Copie o **UUID** desse usuário (aparece na lista de usuários).
4. Volte ao **SQL Editor** e rode (substituindo o UUID):

```sql
insert into dentists (auth_user_id, name, specialty) values
  ('COLE-O-UUID-AQUI', 'Dra. Catarina Rodrigues', 'Cirurgiã-Dentista');

insert into working_hours (dentist_id, weekday, start_time, end_time)
select id, wd, '09:00', '17:00' from dentists, generate_series(1,5) as wd
where name = 'Dra. Catarina Rodrigues';

insert into working_hours (dentist_id, weekday, start_time, end_time)
select id, 6, '09:00', '12:00' from dentists
where name = 'Dra. Catarina Rodrigues';
```

Isso vincula o login da doutora à tabela `dentists` e cadastra o horário de trabalho: segunda a sexta 09h-17h, sábado 09h-12h (domingo fechado, sem linha = dia desabilitado no calendário).

> Quer cadastrar outra dentista no futuro? É só repetir o mesmo processo (criar o usuário no Auth, inserir em `dentists`, inserir os `working_hours`) — não precisa mudar nada no código.

### 5. Testar local

Como são arquivos HTML puros, basta abrir com um servidor estático simples (não abra com `file://` direto, porque alguns navegadores bloqueiam certas chamadas):

```bash
# na pasta do projeto
npx serve .
# ou
python3 -m http.server 8080
```

Acesse `http://localhost:8080/index.html` (fluxo do paciente) e `http://localhost:8080/admin.html` (login da doutora).

Teste o fluxo completo: escolher categoria → procedimento → data → horário → preencher dados → confirmar. Depois confira no `admin.html` se a consulta aparece na agenda do dia certo, e teste os botões "Concluir" e "Cancelar".

### 6. Publicar no GitHub e importar na Vercel

Execute o script de deploy automático (funciona no Git Bash do Windows, sem precisar de WSL):
```bash
chmod +x deploy-github.sh
./deploy-github.sh
```

Depois, siga o guia visual completo em [`DEPLOY_VERCEL_GUIA_VISUAL.md`](DEPLOY_VERCEL_GUIA_VISUAL.md) para importar o repositório na Vercel — resumindo: **Add New → Project**, Framework Preset **"Other"**, Build Command e Output Directory **em branco**, **Deploy**.

Você terá uma URL pública, por exemplo `https://ca-odonto.vercel.app`. A página de agendamento fica em `https://ca-odonto.vercel.app/index.html` e a agenda das doutoras em `https://ca-odonto.vercel.app/admin.html`.

> Dica: registre o link do `admin.html` em algum lugar só seu (ex. favoritos) — ele não precisa e não deve ser divulgado publicamente.

### 7. Colocar o link no Google Meu Negócio

1. Acesse o [Google Meu Negócio](https://business.google.com) com a conta que administra o perfil da CA Odonto.
2. Vá em **Editar perfil → Botões de ação** (ou **Adicionar botão de perfil**, dependendo da versão da interface).
3. Escolha a opção **Agendar** (ou "Marcar horário / Reservar").
4. Cole a URL pública do `index.html` (ex. `https://ca-odonto.vercel.app/index.html`).
5. Salve. O botão "Agendar" no perfil da clínica no Google agora leva direto para o agendamento on-line, sem precisar falar com atendente.

### ✅ Checklist de publicação

- [ ] Git push feito (código no GitHub)
- [ ] Deploy no Vercel completo
- [ ] URL final testada (agendamento + admin funcionam)
- [ ] Link adicionado no Google Meu Negócio
- [ ] Pacientes conseguem agendar via GMN

## 🗄️ Estrutura de dados (resumo)

- `dentists` — cadastro das dentistas (nome fica oculto do paciente; usado só internamente e no `admin.html`)
- `services` — os ~35 procedimentos, com categoria e duração
- `working_hours` — horário de trabalho de cada dentista por dia da semana
- `appointments` — as consultas marcadas; `dentist_id` é escolhido automaticamente pelo sistema no momento da confirmação, nunca pelo paciente

## 🔒 Segurança

- **Anon key pública, protegida por RLS**: o frontend usa sempre a `anon public key` — nunca a `service_role`. É segura por design porque cada tabela tem Row Level Security ativado.
- **Agenda isolada por profissional**: RLS garante que cada dentista só vê/edita os próprios agendamentos, mesmo que alguém tente burlar a tela.
- **Dados de pacientes nunca expostos publicamente**: não existe policy pública de leitura em `appointments`; a disponibilidade de horários é calculada por uma função (`get_busy_slots`) que devolve só horário ocupado, nunca nome ou telefone.
- **Sem agendamento fantasma**: um paciente só consegue inserir agendamento com `status = 'confirmado'`.
- **Anti-race condition**: um exclusion constraint no banco impede overbooking — duas pessoas não conseguem reservar o mesmo horário da mesma dentista ao mesmo tempo, mesmo em cliques simultâneos.
- **Sem senha em texto plano**: autenticação das doutoras é 100% delegada ao Supabase Auth.

## 🚀 Próximos passos (ideias de evolução)

- Notificação por e-mail ou SMS confirmando o agendamento
- Relatórios de ocupação e histórico de atendimentos para a clínica
- Suporte a múltiplas dentistas com especialidades diferentes (a tabela `dentists` já foi desenhada pra isso)
- Integração com Google Calendar
- Cancelamento automático de consultas não confirmadas com antecedência
- Lembretes automáticos via WhatsApp
