FROM python:3.7-slim
ADD . /code
WORKDIR /code
ENV PIP_DISABLE_ROOT_WARNING=1
RUN pip3 install --upgrade pip
EXPOSE 5000
CMD ["python", "predict.py"]
