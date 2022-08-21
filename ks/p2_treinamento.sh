# https://github.com/kubeflow/examples/blob/master/object_detection/submit_job.md

# Build the TensorFlow object detection training image, or use the pre-built image lcastell/pets_object_detection in Docker hub.

# First copy the Dockerfile file from ./docker directory into your $HOME path
# from your $HOME directory
docker build --pull -t $USER/pets_object_detection -f ./Dockerfile.training .

# Create training TF-Job deployment and launching it
# from the ks-app directory

PIPELINE_CONFIG_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_pets.config"
TRAINING_DIR="${MOUNT_PATH}/train"

ks param set tf-training-job image ${OBJ_DETECTION_IMAGE}
ks param set tf-training-job mountPath ${MOUNT_PATH}
ks param set tf-training-job pvc ${PVC}
ks param set tf-training-job numPs 1
ks param set tf-training-job numWorkers 1
ks param set tf-training-job pipelineConfigPath ${PIPELINE_CONFIG_PATH}
ks param set tf-training-job trainDir ${TRAINING_DIR}

ks apply ${ENV} -c tf-training-job

# NOTE: The default TFJob api verison in the component is kubeflow.org/v1beta1. 
# You can override the default version by setting the tfjobApiVersion param in the ksonnet app

ks param set tf-training-job tfjobApiVersion ${NEW_VERSION}

# https://github.com/kubeflow/examples/blob/master/object_detection/monitor_job.md

# Monitor your job
# View status
kubectl -n kubeflow describe tfjobs tf-training-job
# View logs of individual pods
kubectl -n kubeflow get pods
echo "kubectl -n kubeflow logs <name_of_chief_pod>"
# NOTE: When the job finishes, the pods will be automatically terminated. To see, run the get pods command with the -a flag:

kubectl -n kubeflow get pods -a

# Now you have a trained model!! find it at /pets_data/train inside pvc `pets-pvc``.
# Delete job
ks delete ${ENV} -c tf-training-job
