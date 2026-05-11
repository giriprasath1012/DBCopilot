from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def home():
    return {"message": "DBCopilot AI Service Running"}