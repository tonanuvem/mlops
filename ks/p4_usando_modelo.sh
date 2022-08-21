#Take a look at the logs:

kubectl get pod -n kubeflow

# kubectl -n kubeflow logs pets-model-v1-57674c8f76-4qrqp
# And you should see:

#2018-06-21 19:20:32.325406: I tensorflow_serving/core/loader_harness.cc:86] Successfully loaded servable version {name: pets-model version: 1}
#E0621 19:20:34.134165172       7 ev_epoll1_linux.c:1051]     grpc epoll fd: 3
#2018-06-21 19:20:34.135354: I tensorflow_serving/model_servers/main.cc:288] Running ModelServer at 0.0.0.0:9000 ...

# Running inference using your model
# Now you can use a gRPC client to run inference using your trained model as below!
# First we need to install the dependencies (Ubuntu* 16.04 )

sudo apt-get install protobuf-compiler python-pil python-lxml python-tk
pip install tensorflow
pip install matplotlib
pip install tensorflow-serving-api
pip install numpy
pip install grpcio

# Then download and compile TensorFlow models object detection utils API.

TF_MODELS=`pwd`
git clone https://github.com/tensorflow/models.git
cd models/research
protoc object_detection/protos/*.proto --python_out=.
PYTHONPATH=:${TF_MODELS}/models/research:${TF_MODELS}/models/research/slim:${PYTHONPATH}

# At last, we need run below command in a different terminal session to port-forward to trained model server:

echo "kubectl -n kubeflow port-forward service/pets-model 9000:9000"
echo "Pressione ENTER para continuar"
read ENTER

# Now you can run the object detection client, and after that you should be seeing an image file in $OUT_DIR directory with the bounding boxes for detected objects.

#From examples/object_detection/serving_script directory
OUT_DIR=`pwd`
INPUT_IMG="image1.jpg"
python object_detection_grpc_client.py \
--server=localhost:9000 \
--input_image=${INPUT_IMG} \
--output_directory=${OUT_DIR} \
--label_map=${TF_MODELS}/models/research/object_detection/data/pet_label_map.pbtxt  \
--model_name=pets-model
