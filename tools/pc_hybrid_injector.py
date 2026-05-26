#!/usr/bin/env python3
"""
Ferramenta de conversão .pc – Automation → BeamNG com arquitetura híbrida.
Conforme Parecer Técnico PT-2026-001.
"""
import json
import sys
import hashlib
import os

def inject_hybrid(pc_file_path, output_path):
    """Lê ficheiro .pc, injeta nós híbridos e guarda novo ficheiro."""
    if not os.path.exists(pc_file_path):
        raise FileNotFoundError(f"Ficheiro não encontrado: {pc_file_path}")

    try:
        with open(pc_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        raise ValueError(f"Erro ao ler ficheiro .pc. Certifique-se de que é um JSON válido: {e}")

    print("Injetando componentes híbridos...")

    # Garante que a secção 'parts' existe
    if 'parts' not in data:
        data['parts'] = {}

    # Adiciona MGU-KF, MGU-KR e Bateria (apenas se não existirem)
    if 'mguf' not in data['parts']:
        data['parts']['mguf'] = {
            "type": "electricMotor", "name": "MGU-KF", "inputName": "mguf_input",
            "maxTorque": 500, "maxPower": 325000
        }
    if 'mgur' not in data['parts']:
        data['parts']['mgur'] = {
            "type": "electricMotor", "name": "MGU-KR", "inputName": "mgur_input",
            "maxTorque": 500, "maxPower": 325000
        }
    if 'battery' not in data['parts']:
        data['parts']['battery'] = {
            "type": "battery", "name": "HighVoltageBattery",
            "capacity": 8.0, "voltage": 800.0
        }

    # Modifica o 'powertrain' para usar os motores elétricos
    if 'powertrain' in data and isinstance(data['powertrain'], list):
        # ADVERTÊNCIA: Isso é um exemplo. Você precisará adaptar os nomes 
        # ('front_differential', 'transmission') para os usados no seu veículo.
        for component in data['powertrain']:
            if isinstance(component, list) and len(component) > 2:
                if component[1] == 'front_differential':
                    component[2] = 'mguf'
                    print("Powertrain: MGU-KF conectado ao diferencial dianteiro.")
                # Adicione mais condições aqui conforme necessário
        print("Powertrain modificado com sucesso.")
    else:
        print("Aviso: Secção 'powertrain' não encontrada ou formato inválido.")

    # Salva o novo ficheiro
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        raise IOError(f"Erro ao escrever ficheiro de saída: {e}")

    # Verificação de reprodutibilidade
    input_hash = hashlib.sha256(open(pc_file_path, 'rb').read()).hexdigest()
    output_hash = hashlib.sha256(open(output_path, 'rb').read()).hexdigest()
    print(f"Reprodutibilidade - Hash Input: {input_hash}")
    print(f"Reprodutibilidade - Hash Output: {output_hash}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: pc_hybrid_injector.py <input.pc> <output.pc>")
        sys.exit(1)
    try:
        inject_hybrid(sys.argv[1], sys.argv[2])
        print("Injeção híbrida concluída com sucesso!")
    except Exception as e:
        print(f"ERRO: {e}")
        sys.exit(1)
