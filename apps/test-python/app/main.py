from fastapi import FastAPI, Response, status

app = FastAPI()

@app.get("/test1", status_code=200)
def read_test1(response: Response):
    return {"Hello": "World 1"}

@app.get("/test2", status_code=201)
def read_test2(response: Response):
    return {"Hello": "World 2"}
