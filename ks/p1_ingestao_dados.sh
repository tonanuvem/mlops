# Preparacao:

# https://github.com/kubeflow/examples/tree/master/object_detection
git clone https://github.com/kubeflow/examples.git
cd examples/object_detection

# Ksonnet (Kubernetes config easy)
# wget https://github.com/ksonnet/ksonnet/releases/download/v0.13.1/ks_0.13.1_linux_amd64.tar.gz
export KS_VER=ks_0.13.1_linux_amd64
export DIR_KS_VER=v0.13.1
wget -O /tmp/$KS_VER.tar.gz https://github.com/ksonnet/ksonnet/releases/download/$DIR_KS_VER/$KS_VER.tar.gz
mkdir -p ${HOME}/bin
tar -xvf /tmp/$KS_VER.tar.gz -C ${HOME}/bin
export PATH=$PATH:${HOME}/bin/$KS_VER

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
#APP_NAME=fiap-kubeflow
#ks init ${APP_NAME}
#cd ${APP_NAME}
# Autogenerate a basic manifest
#ks generate deployed-service guestbook-ui \
#  --image gcr.io/heptio-images/ks-guestbook-demo:0.1 \
#  --type ClusterIP

cd ks-app
ENV=default
ks env add ${ENV} --context=`kubectl config current-context`
ks env set ${ENV} --namespace kubeflow

# First, lets configure and apply the pets-pvc to create a PVC where the training data will be stored
ks param set pets-pvc accessMode "ReadWriteMany"
ks param set pets-pvc storage "20Gi"
ks apply ${ENV} -c pets-pvc
kubectl get storageclass
kubectl get pvc pets-pvc -n kubeflow

# Configure and apply the get-data-job component this component will download the dataset,
# annotations, the model we will use for the fine tune checkpoint, and
# the pipeline configuration file
PVC="pets-pvc"
MOUNT_PATH="/pets_data"
DATASET_URL="http://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz"
ANNOTATIONS_URL="http://www.robots.ox.ac.uk/~vgg/data/pets/data/annotations.tar.gz"
MODEL_URL="http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet101_coco_2018_01_28.tar.gz"
PIPELINE_CONFIG_URL="https://raw.githubusercontent.com/kubeflow/examples/master/object_detection/conf/faster_rcnn_resnet101_pets.config"
ks param set get-data-job mounthPath ${MOUNT_PATH}
ks param set get-data-job pvc ${PVC}
ks param set get-data-job urlData ${DATASET_URL}
ks param set get-data-job urlAnnotations ${ANNOTATIONS_URL}
ks param set get-data-job urlModel ${MODEL_URL}
ks param set get-data-job urlPipelineConfig ${PIPELINE_CONFIG_URL}

# The downloaded files will be dumped into the MOUNT_PATH
ks apply ${ENV} -c get-data-job

# Now we will configure and apply the decompress-data-job component:

ANNOTATIONS_PATH="${MOUNT_PATH}/annotations.tar.gz"
DATASET_PATH="${MOUNT_PATH}/images.tar.gz"
PRE_TRAINED_MODEL_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_coco_2018_01_28.tar.gz"

ks param set decompress-data-job mountPath ${MOUNT_PATH}
ks param set decompress-data-job pvc ${PVC}
ks param set decompress-data-job pathToAnnotations ${ANNOTATIONS_PATH}
ks param set decompress-data-job pathToDataset ${DATASET_PATH}
ks param set decompress-data-job pathToModel ${PRE_TRAINED_MODEL_PATH}

ks apply ${ENV} -c decompress-data-job

# Finally, and since TensorFlow Object Detection API uses the TFRecord format we need to create the TF pet records. 
# For that, we wil configure and apply the create-pet-record-job component:

OBJ_DETECTION_IMAGE="lcastell/pets_object_detection"
DATA_DIR_PATH="${MOUNT_PATH}"
OUTPUT_DIR_PATH="${MOUNT_PATH}"

ks param set create-pet-record-job image ${OBJ_DETECTION_IMAGE}
ks param set create-pet-record-job dataDirPath ${DATA_DIR_PATH}
ks param set create-pet-record-job outputDirPath ${OUTPUT_DIR_PATH}
ks param set create-pet-record-job mountPath ${MOUNT_PATH}
ks param set create-pet-record-job pvc ${PVC}

ks apply ${ENV} -c create-pet-record-job
