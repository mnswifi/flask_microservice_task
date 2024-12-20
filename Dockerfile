#FROM python:3-alpine3.19
FROM python:3.14.0a3
WORKDIR /app
COPY . /app

COPY requirements.txt /app/
RUN pip install -r requirements.txt

EXPOSE 3000
CMD python ./index.py
