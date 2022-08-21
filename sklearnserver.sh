git clone https://github.com/kubeflow/kfserving.git
cd kfserving/python/sklearnserver/
pip3 install -e .
python3 -m sklearnserver --model_dir model.joblib --model_name decision_tree
