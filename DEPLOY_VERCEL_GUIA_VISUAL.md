# 🚀 Guia de Deploy no Vercel — CA Odonto

> Este guia descreve exatamente os campos e botões que você vai encontrar na interface
> do Vercel. Não inclui capturas de tela porque a interface do Vercel muda com frequência
> e uma imagem desatualizada atrapalha mais do que ajuda — mas cada tela abaixo descreve
> com precisão o que você vai ver e onde clicar.

## A. Pré-requisitos

- [ ] Conta no Vercel (https://vercel.com) — pode entrar com login do GitHub, sem precisar criar senha nova
- [ ] Repositório `ca-odonto` já criado no GitHub (rode `./deploy-github.sh` primeiro, se ainda não fez)

## B. Passo a passo

### 1. Acessar o Vercel

Vá em **https://vercel.com** e clique em **Log In** (canto superior direito). Escolha **Continue with GitHub** e autorize o acesso — isso conecta sua conta do Vercel à sua conta do GitHub (`Joa0Zera`), sem exigir nada além da autorização padrão do OAuth.

### 2. Importar o projeto

No painel do Vercel (a tela inicial depois do login, chamada **Dashboard**):

1. Clique no botão **"Add New..."** (fica no canto superior direito).
2. No menu que abre, escolha **"Project"**.
3. Você verá uma lista **"Import Git Repository"** com os repositórios da sua conta GitHub. Procure por **`ca-odonto`** na barra de busca, se não aparecer direto na lista.
4. Clique em **"Import"** ao lado do repositório `ca-odonto`.

> Se o repositório não aparecer na lista, é porque o Vercel ainda não tem permissão pra
> ver esse repo. Clique em **"Adjust GitHub App Permissions"** (link que aparece embaixo
> da lista) e libere o acesso ao repositório `ca-odonto`.

### 3. Configurar o projeto

Você vai cair numa tela chamada **"Configure Project"**, com alguns campos:

| Campo | O que fazer |
|---|---|
| **Project Name** | Pode deixar o padrão (`ca-odonto`) ou mudar, é só o nome interno no Vercel |
| **Framework Preset** | Clique no dropdown e selecione **"Other"** — o Vercel costuma detectar sozinho, mas confirme que não ficou marcado "Next.js" ou outro framework |
| **Root Directory** | Deixe como está (`./`) |
| **Build and Output Settings** | Expanda essa seção e **deixe os campos "Build Command" e "Output Directory" em branco/vazios** — não há processo de build, os arquivos HTML já estão prontos |
| **Environment Variables** | **Não precisa adicionar nenhuma.** As credenciais do Supabase (`anon key`) já estão embutidas diretamente no `index.html` e `admin.html` — isso é seguro porque é uma chave pública protegida por Row Level Security no banco, feita pra ser exposta no navegador |

### 4. Fazer o deploy

Clique no botão azul **"Deploy"** no final da página.

O Vercel vai mostrar uma tela de progresso ("Building" → "Deploying" → "Ready"). Como não há build de verdade (é só publicar os arquivos estáticos), isso leva geralmente menos de 1 minuto.

Quando terminar, você verá uma tela de sucesso com confete e um botão **"Continue to Dashboard"**, além de um preview da página. A URL pública aparece no topo, no formato:

```
https://ca-odonto-xxxxxxx.vercel.app
```

(o `xxxxxxx` é gerado automaticamente pelo Vercel; você pode trocar depois em **Settings → Domains** se quiser um nome mais curto, tipo `ca-odonto.vercel.app`, se estiver disponível).

**Copie essa URL** — você vai precisar dela nos próximos passos.

## C. Testar o deploy

Com a URL em mãos, teste os dois fluxos antes de divulgar:

1. **Fluxo do paciente:** acesse `https://SUA-URL.vercel.app/index.html` e percorra o fluxo completo — escolher categoria, procedimento, data, horário, preencher nome/telefone e confirmar. Confira se o agendamento aparece certinho.
2. **Fluxo da doutora:** acesse `https://SUA-URL.vercel.app/admin.html` e faça login com o e-mail/senha cadastrados para a Dra. Catarina Rodrigues no Supabase Auth. Confirme que a consulta que você acabou de marcar aparece na agenda do dia.

Se alguma etapa falhar, revise o passo 2-4 do `README.md` (URL/anon key do Supabase e vínculo da dentista com `working_hours`) — o deploy em si quase nunca é a causa de problemas nessa etapa.

## D. Linkar no Google Meu Negócio

1. Acesse **https://business.google.com** com a conta que administra o perfil da CA Odonto.
2. Selecione o perfil da clínica.
3. Vá em **"Editar perfil"** e procure a seção de **botões de ação** (pode aparecer como **"Adicionar botão de perfil"** ou já existir um botão **"Agendar"** pra editar).
4. Escolha a opção **"Agendar"** (às vezes aparece como "Marcar horário" ou "Reservar", dependendo da versão da interface).
5. Cole a URL pública:
   ```
   https://SUA-URL.vercel.app/index.html
   ```
6. Salve.

Pronto — o botão "Agendar" no perfil da CA Odonto no Google agora leva direto pro agendamento on-line, sem precisar falar com atendente.

---

Depois de confirmar a URL final, atualize a seção **"📡 Próximos Passos — Deploy"** do `README.md` com o link real — ou peça pro Claude Code fazer isso pra você.
