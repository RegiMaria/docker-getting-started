# 📘 Guia: Docker e o projeto Hello World

Este documento explica **por que aprender Docker**, **o que é este
projeto**, e **cada arquivo** que o compõe - incluindo a ordem em
que eles dependem uns dos outros e o motivo dessa ordem.

---

## 1. Por que aprender Docker

Antes de containers, rodar uma aplicação em outra máquina exigia
replicar manualmente todo um ambiente: a versão certa da linguagem,
as bibliotecas certas, variáveis de ambiente, configurações do
sistema operacional. Isso gera o problema mais clássico do
desenvolvimento de software:

> "Na minha máquina funciona."

O Docker resolve isso empacotando a aplicação **junto com tudo que
ela precisa pra rodar** - sistema, linguagem, bibliotecas, código e
comando de start - em uma unidade só, chamada **imagem**. Essa
imagem roda de forma idêntica em qualquer lugar que tenha Docker
instalado: seu notebook, o servidor da empresa, a nuvem (AWS, GCP,
Azure), o notebook de outro desenvolvedor.

Por isso Docker é considerado uma habilidade básica em DevOps hoje:

- **Portabilidade** - o mesmo pacote roda igual em qualquer ambiente
- **Isolamento** - cada aplicação roda separada das outras, sem
  conflito de versões de bibliotecas entre projetos diferentes
- **Padronização de times** - todo mundo do time sobe o projeto com
  o mesmo comando, sem precisar seguir um manual de instalação
  manual, cheio de passos que variam por sistema operacional
- **Base para orquestração** - ferramentas como Kubernetes,
  usadas em produção em larga escala, funcionam gerenciando
  containers. Entender Docker é o primeiro degrau pra chegar lá
- **Ambientes de CI/CD** - pipelines de teste e deploy automatizado
  quase sempre rodam dentro de containers, justamente pela
  consistência que eles garantem

---

## 2. O que é este projeto

Este é um "Hello World" containerizado: uma aplicação web mínima em
Python (FastAPI) que responde com uma mensagem simples, empacotada
em uma imagem Docker.

**O objetivo não é a aplicação em si** - é aprender, na prática, o
fluxo completo de containerizar algo:

1. Escrever a "receita" de como montar a imagem (`Dockerfile`)
2. Construir a imagem a partir dessa receita (`docker build`)
3. Rodar um container a partir da imagem (`docker run`)
4. Entender por que a ordem das instruções no Dockerfile importa
   (cache de camadas)

Uma vez que esse fluxo básico esteja internalizado, ele se repete
(com variações) em praticamente qualquer projeto real que você for
containerizar depois - só muda a complexidade da aplicação, não a
lógica do Docker.

---

## 3. Os arquivos do projeto, um por um

```
docker-hello-world/
├── Dockerfile
├── app.py
├── requirements.txt
├── .dockerignore
├── .gitignore
└── README.md
```

### 3.1 `Dockerfile`

A "receita" que diz ao Docker como construir a imagem. É lido de
cima pra baixo, e cada instrução vira uma camada (layer):

| Instrução | O que faz |
|---|---|
| `FROM python:3.12-slim` | Define a imagem base: Python 3.12 já instalado, em uma variante enxuta (menos pacotes, imagem menor) |
| `WORKDIR /app` | Define a pasta de trabalho dentro do container. Os comandos seguintes rodam a partir dali |
| `COPY requirements.txt .` | Copia só o arquivo de dependências primeiro (ver seção 4, sobre ordem) |
| `RUN pip install -r requirements.txt` | Executa a instalação das dependências **durante o build** da imagem |
| `COPY . .` | Copia o restante do código do projeto (o `app.py`) para dentro da imagem |
| `EXPOSE 5000` | Documenta que a aplicação pretende usar a porta 5000 (não abre a porta sozinho - quem faz isso de fato é o `docker run -p`) |
| `CMD [...]` | Define o comando executado quando o **container** é iniciado (diferente do `RUN`, que roda só durante o build) |

É o único arquivo, entre todos do projeto, que é **obrigatório** ter
em qualquer Dockerfile - no mínimo o `FROM`.

### 3.2 `app.py`

O código da aplicação em si. Usa o framework **FastAPI**, que expõe
uma rota `/` retornando uma mensagem HTML de "Hello, Docker!". Não
tem `app.run()` no final (diferente de outros frameworks como
Flask) porque o FastAPI depende de um servidor ASGI externo - o
**uvicorn** - que é quem efetivamente sobe o servidor. É por isso
que o `CMD` do Dockerfile chama `uvicorn app:app`, e não `python
app.py`.

### 3.3 `requirements.txt`

Lista as bibliotecas Python que a aplicação precisa:

```
fastapi==0.115.0
uvicorn[standard]==0.30.6
```

As versões são fixadas com `==` para garantir **builds
reprodutíveis** - sem isso, uma atualização de biblioteca poderia
quebrar o projeto sem que nenhuma linha de código tivesse mudado.

### 3.4 `.dockerignore`

Lista de arquivos e pastas que o Docker deve ignorar ao copiar o
projeto para dentro da imagem (no `COPY . .`):

```
__pycache__/
*.pyc
.git
.gitignore
.env
venv/
.venv/
```

Importante por dois motivos: mantém a imagem menor e mais rápida de
construir, e evita que arquivos sensíveis (como um `.env` com
senhas) acabem indo parar dentro da imagem.

### 3.5 `.gitignore`

Equivalente ao `.dockerignore`, mas para o **git** em vez do
Docker - impede que arquivos como a pasta `venv/` (ambiente virtual
local) sejam versionados e enviados ao GitHub.

### 3.6 `README.md`

Documentação de uso: como instalar pré-requisitos, construir a
imagem, rodar o container, ver logs, parar, remover, e como subir o
projeto para o GitHub.

---

## 4. A ordem de dependência entre os arquivos, e por quê

Os arquivos não têm todos o mesmo "peso" dentro do processo de
build - alguns dependem de outros existirem primeiro, e a **ordem
em que aparecem dentro do Dockerfile** afeta diretamente a
velocidade dos builds seguintes.

### Ordem lógica de criação

1. **`Dockerfile`** - definido primeiro porque é ele quem referencia
   todos os outros arquivos (`COPY requirements.txt .`, `COPY . .`)
   e quem define o nome esperado do arquivo principal da aplicação
   (`app:app`, no `CMD`)
2. **`app.py`** - o código, já que o Dockerfile espera encontrá-lo
3. **`requirements.txt`** - lista as bibliotecas que o `app.py`
   importa (`from fastapi import ...`)
4. **`.dockerignore`** - opcional, mas relevante assim que existir
   algo que não deva ir para a imagem (como a venv)

### Ordem das instruções DENTRO do Dockerfile: por que importa

Este é o ponto técnico mais importante do projeto. Repare nesta
sequência:

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

O Docker armazena em **cache** cada camada (cada instrução) de um
build. Ao rodar `docker build` de novo, ele compara com o build
anterior:

- Se a instrução, e os arquivos que ela usa, **não mudaram** → a
  camada é reaproveitada do cache (build quase instantâneo)
- Se algo **mudou** → aquela camada e **todas as seguintes** são
  refeitas

Se o `COPY . .` (copiar todo o código) viesse **antes** da
instalação das dependências, qualquer alteração no `app.py` -
mesmo sem tocar em nenhuma dependência - invalidaria o cache a
partir dali, obrigando o Docker a reinstalar o FastAPI e o uvicorn
do zero, a cada build. Em projetos com dezenas de bibliotecas
pesadas, isso pode custar minutos por build, desnecessariamente.

Fazendo na ordem correta:

1. Copia só o `requirements.txt` (muda raramente)
2. Instala as dependências (fica em cache; só roda de novo se o
   `requirements.txt` mudar)
3. Copia o resto do código (muda com frequência)

**Regra prática:** no Dockerfile, o que muda **menos** vem primeiro;
o que muda **mais** vem por último.

---

## 5. Resumo visual do fluxo completo

```
Dockerfile (receita)
      │
      ▼
docker build  →  monta a imagem (uma "foto congelada":
                  Python + dependências + código + comando de start)
      │
      ▼
docker run    →  cria um container vivo a partir da imagem
                  → executa automaticamente o CMD
                  → uvicorn sobe o servidor na porta 5000 (dentro do container)
                  → -p 8080:5000 conecta essa porta à porta 8080 do seu PC
      │
      ▼
http://localhost:8080  →  aplicação responde "Hello, Docker!"
```
