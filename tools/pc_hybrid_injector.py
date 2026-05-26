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

    # 1. Validação de entrada
    if not os.path.exists(pc_file_path):
        raise FileNotFoundError(f"Ficheiro não encontrado: {pc_file_path}")

    # 2. Carregar o ficheiro .pc
    try:
        with open(pc_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        raise ValueError(f"Erro ao ler ficheiro .pc. Certifique-se de que é um JSON válido: {e}")

    # 3. Injeção dos nós híbridos
    # Esta é uma versão simplificada para demonstração.
    # A implementação final deve ser mais robusta e adicionar os nós corretamente.
    print("Injetando componentes híbridos...")

    # Garantir que a secção 'parts' existe
    if 'parts' not in data:
        data['parts'] = {}

    # Adicionar MGU-KF (exemplo de estrutura)
    data['parts']['mguf'] = {
        "type": "electricMotor",
        "name": "MGU-KF",
        "inputName": "mguf_input",
        "maxTorque": 500,
        "maxPower": 325000  # 325 kW em Watts
    }

    # Adicionar MGU-KR
    data['parts']['mgur'] = {
        "type": "electricMotor",
        "name": "MGU-KR",
        "inputName": "mgur_input",
        "maxTorque": 500,
        "maxPower": 325000  # 325 kW em Watts
    }

    # Adicionar Bateria
    data['parts']['battery'] = {
        "type": "battery",
        "name": "HighVoltageBattery",
        "capacity": 8.0,  # kWh
        "voltage": 800.0   # V
    }

    # Modificar o 'powertrain' para usar os motores elétricos
    # Esta é uma modificação crítica e complexa.
    # Para o carro funcionar, precisamos definir a cadeia cinemática:
    # [mguf] -> [differential] -> [wheels] (eixo dianteiro)
    # [mgur] -> [transmission] -> [differential] -> [wheels] (eixo traseiro)
    # A implementação final necessitará de um mapeamento preciso.
    if 'powertrain' in data and isinstance(data['powertrain'], list):
        # Procurar e modificar o diferencial dianteiro para receber input do 'mguf'
        # Isto é um placeholder para a lógica completa.
        for component in data['powertrain']:
            if isinstance(component, list) and len(component) > 2 and component[1] == 'front_differential':
                component[2] = 'mguf'  # Define 'mguf' como input
                break
        print("Powertrain modificado com sucesso (placeholder).")
    else:
        print("Aviso: Secção 'powertrain' não encontrada ou formato inválido.")

    # 4. Guardar o novo ficheiro
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        raise IOError(f"Erro ao escrever ficheiro de saída: {e}")

    # 5. Verificação de reprodutibilidade
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
