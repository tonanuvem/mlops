import os
from flask import Flask, jsonify, request, render_template
from flask_restful import Api, Resource
from flask_cors import CORS, cross_origin
import joblib

app = Flask(__name__)
cors = CORS(app, resources={r"/*": {"origins": "*"}})
api = Api(app)

if not os.path.isfile('model.joblib'):
    print("Arquivo model.joblib não encontrado")
    exit()

model = joblib.load('model.joblib')

class MakePrediction(Resource):
    @staticmethod
    @cross_origin()
    def post():
        payload = request.get_json()
        features = payload['fields']
        dados = payload['values']#[0]
        print('Dados recebidos: ')
        print(str(dados)) 
        
        REPROVACOES_MAT1 = dados[0] #['REPROVACOES_MAT']
        REPROVACOES_MAT2 = dados[1] #['REPROVACOES_MAT']
        REPROVACOES_MAT3 = dados[2] #['REPROVACOES_MAT']
        REPROVACOES_MAT4 = dados[3] #['REPROVACOES_MAT']
        NOTA_MAT1 = dados[4] #['NOTA_MAT']
        NOTA_MAT2 = dados[5] #['NOTA_MAT']
        NOTA_MAT3 = dados[6] #['NOTA_MAT']
        NOTA_MAT4 = dados[7] #['NOTA_MAT']
        INGLES = dados[8] #['INGLES']
        H_AULA_PRES = dados[9] #['H_AULA_PRES']
        TAREFAS_ONLINE = dados[10] #['TAREFAS_ONLINE']
        FALTAS = dados[11] #['FALTAS']

        prediction = model.predict([[REPROVACOES_MAT1, REPROVACOES_MAT2, REPROVACOES_MAT3, REPROVACOES_MAT4, NOTA_MAT1, NOTA_MAT2, NOTA_MAT3, NOTA_MAT4, INGLES, H_AULA_PRES, TAREFAS_ONLINE, FALTAS]])[0]

        response = jsonify({
            'FEATURES': features,
            'VALORES': dados,
            '_PERFIL_CALCULADO': prediction
        })
        # Configura headers CORS
        response.headers['Access-Control-Allow-Origin'] = '*'
        return response
    
    @staticmethod
    @cross_origin()
    def get():
        return "API do Modelo esta online. Para fazer uma previsao, deve-se enviar um POST."

# curl -v -X POST "http://localhost:5000/predict" -H "accept: */*" -H "Content-Type: application/json" -d @./dados.json
api.add_resource(MakePrediction, '/predict')

@app.route('/')
def home():
    return render_template('index.html')
    #return "API ONLINE. Acessar o endpoint: /predict"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
