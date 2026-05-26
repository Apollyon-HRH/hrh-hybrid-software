#!/usr/bin/env python3
"""
Executa testes de benchmark do Apêndice C12 no BeamNG.tech.
Utiliza a biblioteca beamngpy para controlar a simulação.
"""

import beamngpy
from beamngpy import BeamNGpy, Scenario, Vehicle, setup_logging
from beamngpy.sensors import Electrics
import math
import time
import json
import sys
from pathlib import Path

setup_logging()

class HRHTests:
    def __init__(self, beamng_home: str = None, user_home: str = None):
        self.bng = None
        self.scenario = None
        self.vehicle = None
        self.beamng_home = beamng_home
        self.user_home = user_home
        self.results = {}

    def setup(self):
        """Inicializa a ligação com o BeamNG.tech."""
        self.bng = BeamNGpy('localhost', 64256, home=self.beamng_home, user=self.user_home)
        self.bng.open(launch=True)
        print("BeamNG.tech iniciado.")

    def load_scenario(self, vehicle_model: str, map_name: str = 'gridmap_small'):
        """Carrega um cenário com o veículo especificado."""
        self.scenario = Scenario(map_name, 'hrh_test_scenario')
        self.vehicle = Vehicle('ego_vehicle', model=vehicle_model, licence='HRH_TEST')
        self.scenario.add_vehicle(self.vehicle, pos=(-10, 0, 0), rot_quat=(0, 0, 0, 1))
        self.scenario.make(self.bng)
        self.bng.load_scenario(self.scenario)
        self.bng.wait_for_vehicle_spawn()
        print(f"Cenário carregado com o veículo: {vehicle_model}")

    def test_lateral_g(self):
        """Apêndice C12.1: Aceleração Lateral Sustentada (>6G)."""
        print("Iniciando teste de aceleração lateral...")
        self.vehicle.ai.set_mode('span')
        self.vehicle.ai.set_aggression(1.0)
        time.sleep(2)
        lateral_accels = []
        start_time = time.time()
        while time.time() - start_time < 5:
            sensors = self.vehicle.sensors.poll()
            if 'electrics' in sensors and 'lateralAccel' in sensors['electrics']:
                lat_g = sensors['electrics']['lateralAccel'] / 9.81
                lateral_accels.append(lat_g)
            time.sleep(0.05)
        avg_lateral_g = sum(lateral_accels) / len(lateral_accels) if lateral_accels else 0
        passed = avg_lateral_g > 6.0
        self.results['lateral_g'] = {'value': avg_lateral_g, 'passed': passed}
        print(f"  Aceleração lateral média: {avg_lateral_g:.2f} G - {'APROVADO' if passed else 'REPROVADO'}")
        return passed

    def test_top_speed(self):
        """Apêndice C12.2: Velocidade Máxima (>370 km/h)."""
        print("Iniciando teste de velocidade máxima...")
        self.vehicle.ai.set_mode('straight')
        self.vehicle.control(throttle=1.0, steering=0.0, brake=0.0)
        time.sleep(10)
        max_speed = 0
        start_time = time.time()
        while time.time() - start_time < 15:
            sensors = self.vehicle.sensors.poll()
            if 'electrics' in sensors and 'speed' in sensors['electrics']:
                speed_kph = sensors['electrics']['speed'] * 3.6
                max_speed = max(max_speed, speed_kph)
            time.sleep(0.1)
        passed = max_speed > 370.0
        self.results['top_speed'] = {'value': max_speed, 'passed': passed}
        print(f"  Velocidade máxima: {max_speed:.1f} km/h - {'APROVADO' if passed else 'REPROVADO'}")
        return passed

    def test_braking(self):
        """Apêndice C12.3: Distância de Travagem (<100 m de 300 a 0 km/h)."""
        print("Iniciando teste de travagem...")
        self.vehicle.ai.set_mode('straight')
        self.vehicle.control(throttle=1.0, steering=0.0, brake=0.0)
        time.sleep(10)
        sensors = self.vehicle.sensors.poll()
        start_pos = sensors['electrics']['pos'] if 'electrics' in sensors and 'pos' in sensors['electrics'] else 0
        speed_was_300 = False
        brake_distance = 0
        start_time = time.time()
        while time.time() - start_time < 20:
            sensors = self.vehicle.sensors.poll()
            if 'electrics' in sensors:
                speed_ms = sensors['electrics'].get('speed', 0)
                speed_kph = speed_ms * 3.6
                if not speed_was_300 and speed_kph >= 299:
                    speed_was_300 = True
                    start_brake_pos = sensors['electrics'].get('pos', 0)
                    self.vehicle.control(throttle=0.0, brake=1.0, steering=0.0)
                if speed_was_300 and brake_distance == 0 and speed_ms < 1:
                    end_brake_pos = sensors['electrics'].get('pos', 0)
                    brake_distance = abs(end_brake_pos - start_brake_pos) if start_brake_pos else 0
                    break
            time.sleep(0.05)
        passed = brake_distance < 100.0
        self.results['braking'] = {'value': brake_distance, 'passed': passed}
        print(f"  Distância de travagem: {brake_distance:.1f} m - {'APROVADO' if passed else 'REPROVADO'}")
        return passed

    def test_mud_traction(self):
        """Apêndice C12.4: Tração em Lama (>0.8 G)."""
        print("Iniciando teste de tração em lama...")
        self.bng.load_scenario(Scenario('scrape_forest', 'mud_traction_test'))
        self.bng.wait_for_vehicle_spawn()
        self.vehicle.control(throttle=1.0, brake=0.0, steering=0.0, parkingbrake=0.0)
        time.sleep(2)
        accelerations = []
        start_time = time.time()
        while time.time() - start_time < 3:
            sensors = self.vehicle.sensors.poll()
            if 'electrics' in sensors and 'longitudinalAccel' in sensors['electrics']:
                acc_g = sensors['electrics']['longitudinalAccel'] / 9.81
                accelerations.append(acc_g)
            time.sleep(0.05)
        avg_acc_g = sum(accelerations) / len(accelerations) if accelerations else 0
        passed = avg_acc_g > 0.8
        self.results['mud_traction'] = {'value': avg_acc_g, 'passed': passed}
        print(f"  Aceleração média em lama: {avg_acc_g:.2f} G - {'APROVADO' if passed else 'REPROVADO'}")
        return passed

    def save_report(self, filename: str = 'test_report.json'):
        """Guarda os resultados dos testes num ficheiro JSON."""
        with open(filename, 'w') as f:
            json.dump(self.results, f, indent=4)
        print(f"Relatório guardado em: {filename}")

    def run_all_tests(self, vehicle_model: str):
        """Executa a bateria completa de testes."""
        self.setup()
        try:
            self.load_scenario(vehicle_model)
            self.test_lateral_g()
            self.test_top_speed()
            self.test_braking()
            self.test_mud_traction()
            self.save_report()
        finally:
            self.bng.close()

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Uso: run_hrh_tests.py <vehicle_model>")
        sys.exit(1)
    tester = HRHTests()
    tester.run_all_tests(sys.argv[1])
