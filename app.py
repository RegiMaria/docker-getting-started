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