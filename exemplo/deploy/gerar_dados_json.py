import json
payload = {
    'fields': [
        "MATRICULA", 'REPROVACOES_DE', 'REPROVACOES_EM', "REPROVACOES_MF", "REPROVACOES_GO",
        "NOTA_DE", "NOTA_EM", "NOTA_MF", "NOTA_GO",
        "INGLES", "H_AULA_PRES", "TAREFAS_ONLINE", "FALTAS", 
    ],
    'values': [
        [
            513949,1,1,1,1,4.3,4.0,3.1,4.9,0,3,4,3,
        ]
    ]
}
with open('dados.json', 'w', encoding='utf-8') as f:
    json.dump(payload, f, ensure_ascii=False, indent=4)
print("\n Arquivo dados.json salvo. Payload de dados a ser classificada:")
print(json.dumps(payload, indent=4))
