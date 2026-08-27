import os

from fastapi import FastAPI

app = FastAPI()

SERVER_NAME = os.getenv("SERVER_NAME", "unknown")


@app.get("/")
def root():
    return {
        "server": SERVER_NAME,
        "message": f"Hello from {SERVER_NAME} -ver2 root",
    }


@app.get("/hello")
def hello():
    return {
        "server": SERVER_NAME,
        "message": f"Hello from {SERVER_NAME} -ver2 hello",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "server": SERVER_NAME,
    }
