FROM python:3.7-slim
ADD . /code
WORKDIR /code
RUN pip3 install --upgrade pip
EXPOSE 5000
CMD ["python", "predict.py"]
