#!/usr/bin/env bash
# ============================================================
# CA Odonto — Deploy automático para o GitHub
#
# O que este script faz:
#   1. Inicializa um repositório Git local (se ainda não existir)
#   2. Adiciona e commita todos os arquivos do projeto
#   3. Cria um repositório PÚBLICO no GitHub (via GitHub CLI)
#   4. Faz push do código
#
# Como rodar (Linux, Mac, ou Windows com Git Bash — já é o shell
# usado pelo Claude Code neste projeto, então não precisa de WSL
# nem converter pra .bat):
#
#   chmod +x deploy-github.sh
#   ./deploy-github.sh
# ============================================================

set -e

REPO_NAME="ca-odonto"
COMMIT_MSG="CA Odonto - Sistema de Agendamento Online"

echo "🦷 CA Odonto — Deploy automático para o GitHub"
echo ""

# 1. Verifica se o Git está instalado
if ! command -v git &> /dev/null; then
  echo "❌ Git não encontrado. Instale em https://git-scm.com/downloads e rode este script de novo."
  exit 1
fi

# 2. Inicializa o repositório Git local, se ainda não existir
if [ ! -d ".git" ]; then
  echo "📦 Inicializando repositório Git..."
  git init
  git branch -M main
else
  echo "📦 Repositório Git já existe nesta pasta, pulando 'git init'."
fi

# 3. Adiciona os arquivos do projeto
echo "➕ Adicionando arquivos..."
git add .

# 4. Cria o commit (só se houver algo novo para commitar)
if git diff --cached --quiet 2>/dev/null; then
  echo "ℹ️  Nada novo para commitar."
else
  git commit -m "$COMMIT_MSG"
fi

# 5. Cria o repositório no GitHub e faz push
if command -v gh &> /dev/null; then

  if ! gh auth status &> /dev/null; then
    echo "🔑 Você ainda não está logado no GitHub CLI. Abrindo o login..."
    gh auth login
  fi

  if git remote get-url origin &> /dev/null; then
    echo "🔗 Remote 'origin' já configurado. Fazendo push..."
    git push -u origin main
    REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || git remote get-url origin)
  else
    echo "🐙 Criando repositório público '$REPO_NAME' no GitHub..."
    gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
    REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || echo "")
  fi

  echo ""
  echo "✅ Repositório criado e código enviado para GitHub!"
  if [ -n "$REPO_URL" ]; then
    echo "Acesse: $REPO_URL"
  fi
  echo ""
  echo "Próximo passo: siga o DEPLOY_VERCEL_GUIA_VISUAL.md para publicar no Vercel."

else
  echo ""
  echo "⚠️  GitHub CLI ('gh') não encontrado — não consigo criar o repositório automaticamente."
  echo ""
  echo "Instale o GitHub CLI (https://cli.github.com/) e rode este script de novo, ou crie"
  echo "o repositório manualmente:"
  echo ""
  echo "  1. Acesse https://github.com/new"
  echo "  2. Nome do repositório: $REPO_NAME"
  echo "  3. Deixe como Público, e NÃO marque 'Add a README' (o projeto já tem um)"
  echo "  4. Depois de criar, rode aqui:"
  echo "       git remote add origin https://github.com/SEU-USUARIO/$REPO_NAME.git"
  echo "       git push -u origin main"
fi
