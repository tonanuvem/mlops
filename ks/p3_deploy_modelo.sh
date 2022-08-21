# https://github.com/kubeflow/examples/blob/master/object_detection/export_tf_graph.md

# Before exporting the graph we first need to identify a checkpoint candidate in the pets-pvc pvc under ${MOUNT_PATH}/train 
# which is where the training job is saving the checkpoints.
# To see what's being saved in ${MOUNT_PATH}/train while the training job is running you can use:
kubectl -n kubeflow exec tf-training-job-chief-0 -- ls ${MOUNT_PATH}/train

# Once you have identified the checkpoint next step is to configure the checkpoint in the export-tf-graph-job component and apply it.

CHECKPOINT="${TRAINING_DIR}/model.ckpt-<number>" #replace with your checkpoint number
INPUT_TYPE="image_tensor"
EXPORT_OUTPUT_DIR="${MOUNT_PATH}/exported_graphs"

ks param set export-tf-graph-job mountPath ${MOUNT_PATH}
ks param set export-tf-graph-job pvc ${PVC}
ks param set export-tf-graph-job image ${OBJ_DETECTION_IMAGE}
ks param set export-tf-graph-job pipelineConfigPath ${PIPELINE_CONFIG_PATH}
ks param set export-tf-graph-job trainedCheckpoint ${CHECKPOINT}
ks param set export-tf-graph-job outputDir ${EXPORT_OUTPUT_DIR}
ks param set export-tf-graph-job inputType ${INPUT_TYPE}

ks apply ${ENV} -c export-tf-graph-job

# Once the job is completed a new directory called exported_graphs under /pets_data in the pets-data-claim PCV
# will be created containing the model and the frozen graph.

# https://github.com/kubeflow/examples/blob/master/object_detection/tf_serving_cpu.md

# Serve the model using TF-Serving (CPU)
# Before serving the model we need to perform a quick hack since the object detection export python api does not generate a "version" folder for the saved model.
# This hack consists on creating a directory and move some files to it. One way of doing this is by accessing to an interactive shell in one of your running containers and moving the data yourself

kubectl -n kubeflow exec -it pets-training-master-r1hv-0-i6k7c sh "mkdir /pets_data/exported_graphs/saved_model/1 && cp /pets_data/exported_graphs/saved_model/* /pets_data/exported_graphs/saved_model/1"
echo "Pressione ENTER para continuar
read ENTER

# Configuring the pets-model component in 'ks-app':

MODEL_COMPONENT=pets-model
MODEL_PATH=/mnt/exported_graphs/saved_model
MODEL_STORAGE_TYPE=nfs
NFS_PVC_NAME=pets-pvc

ks param set ${MODEL_COMPONENT} modelPath ${MODEL_PATH}
ks param set ${MODEL_COMPONENT} modelStorageType ${MODEL_STORAGE_TYPE}
ks param set ${MODEL_COMPONENT} nfsPVC ${NFS_PVC_NAME}

ks apply ${ENV} -c pets-model
After applying the component you should see pets-model pod. Run:

kubectl -n kubeflow get pods | grep pets-model
