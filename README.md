# 🐳 Docker - Hello World

Projeto simples para estudar Docker do zero: uma aplicação web em
Python (FastAPI) que mostra "Hello, Docker!" no navegador, rodando
dentro de um container.

Projeto parte do curso [Introdução ao Docker da DataCamp](https://app.datacamp.com/learn/courses/introduction-to-docker).

O foco aqui **não é a aplicação em si** - é entender a mecânica do
Docker. Depois de dominar esse esqueleto simples, você já sabe
empacotar praticamente qualquer projeto Python (uma API, um site,
um bot).

## Qual problema o Docker resolve

Sem Docker, pra rodar essa aplicação em outra máquina você precisaria:

1. Instalar o Python na versão certa
2. Instalar o FastAPI e o uvicorn nas versões certas
3. Rodar o comando certo pra subir o servidor
4. Torcer pra não dar conflito com outra coisa instalada na máquina
   (o clássico "na minha máquina funciona")

O Docker resolve isso empacotando **tudo isso dentro de uma imagem**:
o sistema, o Python, as bibliotecas, o código e o comando de start.
Quem for rodar só precisa ter o Docker instalado - não precisa nem
saber que é Python por dentro. `docker run` e pronto, roda igual em
qualquer lugar (seu PC, servidor da empresa, nuvem).

## Estrutura do projeto

```
docker-hello-world/
├── app.py             -> o código da aplicação (Python + FastAPI)
├── requirements.txt   -> lista de dependências Python
├── Dockerfile          -> a "receita" de como construir a imagem
├── .dockerignore       -> https://app.datacamp.com/learn/courses/introduction-to-docker
└── README.md           -> este arquivo
```

## Pré-requisitos

Instale o [Docker Desktop](https://www.docker.com/products/docker-desktop/)
e confirme que está funcionando:

```bash
docker --version
```

## Passo a passo

### 1. Construir a imagem

```bash
docker build -t docker-hello-world .
```

| Parte | O que significa |
|---|---|
| `docker build` | manda o Docker **construir uma imagem** a partir de um Dockerfile |
| `-t docker-hello-world` | `-t` é de "tag" (nome). Dá o nome `docker-hello-world` à imagem, pra não precisar usar um ID gigante depois |
| `.` | o "contexto de build": diz ao Docker "procure o Dockerfile e os arquivos aqui na pasta atual" |

Depois desse comando, a imagem é só uma **"foto congelada"**: tem o
Python, o FastAPI, o uvicorn e o `app.py` guardados dentro dela, mas
nada está rodando ainda.

### 2. Rodar o container

```bash
docker run -d -p 8080:5000 --name meu-hello docker-hello-world
```

| Parte | O que significa |
|---|---|
| `docker run` | cria e inicia um **container** a partir de uma imagem |
| `-d` | modo "detached": roda em segundo plano, sem travar o terminal |
| `-p 8080:5000` | mapeia portas: `porta_do_seu_pc:porta_do_container` |
| `--name meu-hello` | dá um nome fácil ao container, em vez de um ID aleatório |
| `docker-hello-world` | o nome da imagem construída no passo 1 |

**O que acontece de fato quando você roda isso:**

1. O Docker pega a imagem (a "foto") e cria um **container** a partir
   dela - um processo isolado, com seu próprio sistema de arquivos e
   rede, separado do seu computador.
2. Assim que o container nasce, ele executa automaticamente o `CMD`
   definido no Dockerfile:
   ```
   uvicorn app:app --host 0.0.0.0 --port 5000
   ```
   Isso sobe um servidor web dentro do container, escutando na porta
   `5000`, esperando alguém acessar `/`.
3. O `-p 8080:5000` cria uma ponte entre a porta 5000 (dentro do
   container) e a porta 8080 (do seu PC). Sem isso, o servidor
   ficaria isolado lá dentro e você não conseguiria acessar pelo
   navegador.
4. O `-d` mantém o container rodando em segundo plano, até você
   mandar parar.

Agora abra o navegador em: **http://localhost:8080**

Bônus do FastAPI: abra também **http://localhost:8080/docs** - uma
documentação interativa da API, gerada automaticamente.

> Dá pra rodar vários containers da mesma imagem ao mesmo tempo -
> cada um é uma cópia independente. Basta usar portas e nomes
> diferentes:
> ```bash
> docker run -d -p 8080:5000 --name hello1 docker-hello-world
> docker run -d -p 8081:5000 --name hello2 docker-hello-world
> ```

### 3. Ver os containers rodando

```bash
docker ps
```
Lista os containers **ativos** no momento (ID, imagem, portas, status).

Para ver TODOS, incluindo os parados:
```bash
docker ps -a
```

### 4. Ver os logs do container

```bash
docker logs meu-hello
```
Mostra a saída (prints, erros etc.) que o programa gerou dentro do
container. Útil pra debugar.

Para acompanhar em tempo real:
```bash
docker logs -f meu-hello
```

### 5. Entrar dentro do container (opcional, pra explorar)

```bash
docker exec -it meu-hello bash
```

| Parte | Significado |
|---|---|
| `exec` | executa um comando **dentro** de um container já rodando |
| `-it` | `-i` (interativo) + `-t` (terminal) - dá um terminal de verdade lá dentro |
| `meu-hello` | o container alvo |
| `bash` | o comando a rodar (abre um shell) |

Digite `exit` para sair.

### 6. Parar o container

```bash
docker stop meu-hello
```

### 7. Remover o container

```bash
docker rm meu-hello
```
Precisa estar parado antes, ou use `docker rm -f meu-hello` pra forçar.

### 8. Ver e remover imagens

```bash
docker images
docker rmi docker-hello-world
```

## Por que o `requirements.txt` é copiado antes do resto do código

Repare no Dockerfile:

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

Cada instrução do Dockerfile vira uma **camada (layer)**, e o Docker
guarda cada camada em cache. Quando você roda `docker build` de
novo, ele compara com o build anterior:

- Se a instrução e os arquivos que ela usa **não mudaram** → reaproveita
  a camada do cache (build quase instantâneo).
- Se algo **mudou** → refaz aquela camada **e todas as seguintes**.

Se o `COPY . .` viesse antes da instalação das dependências, toda vez
que você mudasse uma linha do `app.py` - mesmo sem tocar em nenhuma
dependência - o Docker reinstalaria o FastAPI e o uvicorn do zero de
novo. Copiando o `requirements.txt` primeiro, a instalação das
dependências fica em cache e só roda de novo quando ele realmente
muda.

**Regra prática:** no Dockerfile, coloque primeiro o que muda
**menos**, e por último o que muda **mais**.

## Como subir esse projeto pro GitHub

1. Crie um repositório novo e VAZIO no GitHub (sem README, sem
   .gitignore - pra não dar conflito).
2. No terminal, dentro da pasta `docker-hello-world`:

```bash
git init
git add .
git commit -m "Primeiro projeto Docker - Hello World"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/docker-hello-world.git
git push -u origin main
```

Troque `SEU_USUARIO` pelo seu usuário do GitHub.

## Próximos passos de estudo

1. Troque a porta e veja o efeito.
2. Mude o texto do `app.py` e refaça o `docker build` - repare que
   ele reaproveita o cache até chegar no `COPY . .`.
3. Tente rodar dois containers dessa mesma imagem em portas
   diferentes ao mesmo tempo.
4. Depois disso, avance para o tutorial oficial
   (`docker/getting-started`) - ele ensina volumes, bind mounts,
   redes e Docker Compose, os próximos passos naturais.