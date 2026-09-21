# =========================================================
# 01- DOCKERFILE - Hello World
# Cada linha abaixo é uma "instrução". O Docker lê de cima
# pra baixo e cria uma "camada" (layer) pra cada uma.
# =========================================================

# FROM define a IMAGEM BASE, ou seja, o "sistema" que já vem
# pronto pra você construir em cima. Aqui usamos uma imagem
# oficial do Python, na versão 3.12, variante "slim"
# (uma versão enxuta, sem muitos pacotes extras, deixando a
# imagem final menor e mais rápida de baixar).
FROM python:3.12-slim

# WORKDIR define o "diretório de trabalho" dentro do container.
# É como se você desse um "cd /app". Todos os comandos daqui
# pra baixo (COPY, RUN, CMD) vão rodar dentro dessa pasta.
# Se a pasta não existir, o Docker cria ela automaticamente.
WORKDIR /app

# COPY <origem> <destino>
# Aqui copiamos APENAS o requirements.txt primeiro (e não todo
# o código ainda). Isso é uma técnica de otimização: o Docker
# guarda em cache cada camada. Se esse arquivo não mudar entre
# um build e outro, o Docker reaproveita o cache e PULA a
# instalação das dependências de novo, deixando o build bem
# mais rápido.
COPY requirements.txt .

# RUN executa um comando DURANTE a construção da imagem
# (não quando o container roda depois, mas agora, no "build").
# Aqui instalamos as bibliotecas Python listadas no
# requirements.txt.
# --no-cache-dir evita que o pip guarde arquivos temporários,
# deixando a imagem final menor.
RUN pip install --no-cache-dir -r requirements.txt

# Agora sim copiamos o resto do código da aplicação
# (o "." da esquerda é a pasta do seu projeto no computador,
# o "." da direita é o WORKDIR dentro do container, ou seja /app)
COPY . .

# EXPOSE é só DOCUMENTAÇÃO: avisa "esse container pretende usar
# a porta 5000". Ele NÃO abre a porta de verdade sozinho -
# quem realmente conecta a porta é o comando "docker run -p".
EXPOSE 5000

# CMD define o comando que roda quando o CONTAINER É INICIADO
# (diferente do RUN, que roda durante o BUILD da imagem).
# O FastAPI não tem um servidor embutido como o Flask tinha
# (app.run()) — ele precisa de um servidor ASGI. Usamos o
# "uvicorn" pra isso.
#
# uvicorn app:app        -> "app" (arquivo app.py) : "app" (variável FastAPI() dentro do arquivo)
# --host 0.0.0.0          -> aceita conexões de fora do container (igual explicado no Flask)
# --port 5000              -> porta em que o servidor escuta
#
# Usamos a forma em lista (chamada "exec form"), que é a
# recomendada porque roda o comando diretamente, sem passar
# por um shell no meio do caminho.
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
