import os
from flask import Flask, jsonify, request
from flask_restful import Api, Resource
import joblib

app = Flask(__name__)
api = Api(app)

if not os.path.isfile('model.joblib'):
    print("Arquivo model.joblib não encontrado")
    exit()

model = joblib.load('model.joblib')

class MakePrediction(Resource):
    @staticmethod
    def post():
        payload = request.get_json()
        features = payload['fields']
        dados = payload['values'][0]

        MATRICULA = dados[0] #['MATRICULA']
        REPROVACOES_DE = dados[1] #['REPROVACOES_DE']
        REPROVACOES_EM = dados[2] #['REPROVACOES_EM']
        REPROVACOES_MF = dados[3] #['REPROVACOES_MF']
        REPROVACOES_GO = dados[4] #['REPROVACOES_GO']
        NOTA_DE = dados[5] #['NOTA_DE']
        NOTA_EM = dados[6] #['NOTA_EM']
        NOTA_MF = dados[7] #['NOTA_MF']
        NOTA_GO = dados[8] #['NOTA_GO']
        INGLES = dados[9] #['INGLES']
        H_AULA_PRES = dados[10] #['H_AULA_PRES']
        TAREFAS_ONLINE = dados[11] #['TAREFAS_ONLINE']
        FALTAS = dados[12] #['FALTAS']

        prediction = model.predict([[MATRICULA, REPROVACOES_DE, REPROVACOES_EM, REPROVACOES_MF, REPROVACOES_GO, NOTA_DE, NOTA_EM, NOTA_MF, NOTA_GO, INGLES, H_AULA_PRES, TAREFAS_ONLINE, FALTAS]])[0]

        return jsonify({
            'FEATURES': features,
            'VALORES': dados,
            '_PERFIL_CALCULADO': prediction
        })
    
    @staticmethod
    def get():
        return "API do Modelo esta online. Para fazer uma previsao, deve-se enviar um POST."

# curl -v -X POST "http://localhost:5000/predict" -H "accept: */*" -H "Content-Type: application/json" -d @./dados.json
api.add_resource(MakePrediction, '/predict')

@app.route('/')
def home():
    return "API ONLINE. Acessasr o endpoint: /predict"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
