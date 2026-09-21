# =========================================================
# 02- No CMD do dockerfile
# Dockerfile a gente escreveu uvicorn app:app 
# o primeiro app é o nome desse arquivo (app.py, sem a extensão),
# e o segundo app é o nome da variável app = FastAPI() aqui dentro.
# É por isso que o nome do arquivo importa
# =========================================================

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

# Cria a aplicação FastAPI
app = FastAPI()

# Define a rota "/" (a raiz do site)
@app.get("/", response_class=HTMLResponse)
def hello():
    return """
    <h1>🐳 Hello, Docker!</h1>
    <p>Se você está vendo isso, seu container está rodando com sucesso!</p>
    <p>Documentação automática da API: <a href="/docs">/docs</a></p>
    """