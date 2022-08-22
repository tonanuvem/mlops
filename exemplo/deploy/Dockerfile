FROM python:3.7-slim
ADD . /code
WORKDIR /code
RUN /usr/local/bin/python -m pip install --upgrade pip
EXPOSE 5000
CMD ["python", "predict.py"]
