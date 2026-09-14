# Sistema de Agendamento — CA Odonto

Sistema de agendamento on-line da CA Odonto (Mogi das Cruzes - SP). Três arquivos autocontidos, sem build:

- `index.html` — página pública de agendamento (vira o link do botão "Agendar" no Google Meu Negócio)
- `admin.html` — login + agenda das doutoras, otimizado para celular
- `schema.sql` — schema do banco (Supabase/Postgres)

## 1. Criar o projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e crie um novo projeto (região São Paulo, se disponível).
2. Anote a **senha do banco** que você definir — vai precisar dela só se for acessar via `psql`.
3. Espere o projeto terminar de provisionar (1-2 minutos).

## 2. Rodar o schema

1. No painel do Supabase, vá em **SQL Editor** → **New query**.
2. Cole todo o conteúdo do arquivo `schema.sql` deste projeto.
3. Clique em **Run**. Isso cria as tabelas (`dentists`, `services`, `working_hours`, `appointments`), as políticas de RLS, a função `get_busy_slots` e já insere os ~35 procedimentos da clínica.

> O schema já vem com duas proteções extras além do que foi pedido:
> - **Dados de pacientes protegidos:** não existe policy pública de leitura em `appointments`. A disponibilidade de horários no site público é calculada por uma função (`get_busy_slots`) que devolve só `dentist_id/start_time/end_time` — nunca nome ou telefone de paciente.
> - **Trava contra conflito de horário:** um `exclusion constraint` no banco impede que duas pessoas reservem o mesmo horário com a mesma dentista ao mesmo tempo (condição de corrida), mesmo que os dois cliques cheguem quase simultâneos.

## 3. Pegar a URL e a chave pública (anon key)

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

## 4. Criar o login da Dra. Catarina Rodrigues

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

## 5. Testar local

Como são arquivos HTML puros, basta abrir com um servidor estático simples (não abra com `file://` direto, porque alguns navegadores bloqueiam certas chamadas):

```bash
# na pasta do projeto
npx serve .
# ou
python3 -m http.server 8080
```

Acesse `http://localhost:8080/index.html` (fluxo do paciente) e `http://localhost:8080/admin.html` (login da doutora).

Teste o fluxo completo: escolher categoria → procedimento → data → horário → preencher dados → confirmar. Depois confira no `admin.html` se a consulta aparece na agenda do dia certo, e teste os botões "Concluir" e "Cancelar".

## 6. Publicar no Vercel

1. Suba os arquivos para um repositório no GitHub (`gh repo create`, se ainda não tiver um).
2. No [Vercel](https://vercel.com), clique em **Add New → Project** e importe o repositório.
3. Em **Framework Preset**, selecione **Other**.
4. Deixe o **Build Command** e o **Output Directory** em branco (não precisa de build).
5. Clique em **Deploy**.
6. Depois do deploy, você terá uma URL pública, por exemplo `https://ca-odonto.vercel.app`. A página de agendamento fica em `https://ca-odonto.vercel.app/index.html` (ou só `/`, se você configurar o Vercel para servir `index.html` como padrão — já é o comportamento default) e a agenda das doutoras em `https://ca-odonto.vercel.app/admin.html`.

> Dica: registre o link do `admin.html` em algum lugar só seu (ex. favoritos) — ele não precisa e não deve ser divulgado publicamente.

## 7. Colocar o link no Google Meu Negócio

1. Acesse o [Google Meu Negócio](https://business.google.com) com a conta que administra o perfil da CA Odonto.
2. Vá em **Editar perfil → Botões de ação** (ou **Adicionar botão de perfil**, dependendo da versão da interface).
3. Escolha a opção **Agendar** (ou "Marcar horário / Reservar").
4. Cole a URL pública do `index.html` (ex. `https://ca-odonto.vercel.app`).
5. Salve. O botão "Agendar" no perfil da clínica no Google agora leva direto para o agendamento on-line, sem precisar falar com atendente.

## Estrutura de dados (resumo)

- `dentists` — cadastro das dentistas (nome fica oculto do paciente; usado só internamente e no `admin.html`)
- `services` — os ~35 procedimentos, com categoria e duração
- `working_hours` — horário de trabalho de cada dentista por dia da semana
- `appointments` — as consultas marcadas; `dentist_id` é escolhido automaticamente pelo sistema no momento da confirmação, nunca pelo paciente

## Segurança

- O frontend usa sempre a **anon public key** — nunca a `service_role`.
- RLS garante que cada dentista só vê/edita os próprios agendamentos, mesmo que alguém tente burlar a tela.
- Nenhuma policy pública permite ler nome/telefone de pacientes; a disponibilidade pública passa pela função `get_busy_slots`.
- Um paciente só consegue inserir agendamento com `status = 'confirmado'`.
- Um exclusion constraint no banco impede overbooking (duas pessoas reservando o mesmo horário da mesma dentista ao mesmo tempo).

## 📡 Próximos Passos — Deploy

### 1. Publicar no GitHub
Execute o script de deploy automático (funciona no Git Bash do Windows, sem precisar de WSL):
```bash
chmod +x deploy-github.sh
./deploy-github.sh
```

### 2. Importar no Vercel
Siga o guia visual completo em [`DEPLOY_VERCEL_GUIA_VISUAL.md`](DEPLOY_VERCEL_GUIA_VISUAL.md).

### 3. Linkar no Google Meu Negócio
Depois que o Vercel confirmar a URL final, vá em Google Meu Negócio e cole:
`https://<sua-url-vercel>.vercel.app/index.html`

### ✅ Checklist final
- [ ] Git push feito (código no GitHub)
- [ ] Deploy no Vercel completo
- [ ] URL final testada (agendamento + admin funcionam)
- [ ] Link adicionado no Google Meu Negócio
- [ ] Pacientes conseguem agendar via GMN
