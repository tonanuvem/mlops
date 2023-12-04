FROM python:3.8-slim
ADD . /code
WORKDIR /code
RUN pip3 install -r requirements.txt
EXPOSE 5000
CMD ["python", "predict.py"]
