import os

from fastapi import FastAPI

app = FastAPI()

SERVER_NAME = os.getenv("SERVER_NAME", "unknown")


@app.get("/")
def root():
    return {
        "server": SERVER_NAME,
        "message": f"Hello from {SERVER_NAME} -ver2 root-- deployed by the DevOps platform v4",
    }


@app.get("/hello")
def hello():
    return {
        "server": SERVER_NAME,
        "message": f"Hello from {SERVER_NAME} -ver2 hello-- deployed by the DevOps platform v4",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "server": SERVER_NAME,
    }
