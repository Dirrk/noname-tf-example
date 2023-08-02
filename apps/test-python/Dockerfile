FROM python:3.8-slim-buster

WORKDIR /code

COPY requirements.txt requirements.txt

RUN pip3 install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ./app /code/app/

CMD ["uvicorn", "app.main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "80"]
