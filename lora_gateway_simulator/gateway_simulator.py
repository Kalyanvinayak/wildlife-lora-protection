# lora_gateway_simulator/gateway_simulator.py

import requests
import time
import random
from datetime import datetime

# Configuration
FASTAPI_ENDPOINT = "http://127.0.0.1:8000/sensor_data/" # Adjust if your FastAPI runs on a different host/port
SIMULATION_INTERVAL_SECONDS = 5 # How often to send data

def generate_mock_sensor_data(node_id_prefix="node", node_num=1):
    """Generates a dictionary with mock sensor data."""
    node_id = f"{node_id_prefix}_{node_num:03d}"
    node_type = random.choice(["collar", "weather_station", "motion_detector"])

    # Simulate GPS coordinates around a central point (e.g., a national park)
    base_lat = 27.5 # Example: Near a border region
    base_lon = 90.0 # Example: Near a border region
    latitude = round(base_lat + random.uniform(-0.1, 0.1), 6)
    longitude = round(base_lon + random.uniform(-0.1, 0.1), 6)

    temperature = round(random.uniform(15.0, 35.0), 2)
    humidity = round(random.uniform(40.0, 90.0), 2)
    gas_level = round(random.uniform(0.0, 10.0), 2) if node_type == "motion_detector" else None # Gas for motion
    battery_voltage = round(random.uniform(3.5, 4.2), 2) # Typical LiPo range

    return {
        "node_id": node_id,
        "node_type": node_type,
        "latitude": latitude,
        "longitude": longitude,
        "temperature": temperature,
        "humidity": humidity,
        "gas_level": gas_level,
        "battery_voltage": battery_voltage,
        "timestamp": datetime.utcnow().isoformat() + "Z" # UTC timestamp
    }

def send_data_to_backend(data):
    """Sends the sensor data to the FastAPI backend."""
    try:
        response = requests.post(FASTAPI_ENDPOINT, json=data)
        response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Successfully sent data from {data['node_id']}: {response.json()}")
    except requests.exceptions.ConnectionError as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Connection Error: Ensure FastAPI backend is running at {FASTAPI_ENDPOINT}. Error: {e}")
    except requests.exceptions.HTTPError as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] HTTP Error: {e.response.status_code} - {e.response.text}")
    except Exception as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] An unexpected error occurred: {e}")

if __name__ == "__main__":
    print(f"Starting LoRa Gateway Simulator. Sending data every {SIMULATION_INTERVAL_SECONDS} seconds...")
    print(f"Targeting FastAPI endpoint: {FASTAPI_ENDPOINT}")
    node_counter = 0
    try:
        while True:
            node_counter += 1
            # Simulate data from a few different nodes
            num_simulated_nodes = 3
            for i in range(1, num_simulated_nodes + 1):
                sensor_data = generate_mock_sensor_data(node_num=i)
                send_data_to_backend(sensor_data)
            time.sleep(SIMULATION_INTERVAL_SECONDS)
    except KeyboardInterrupt:
        print("\nSimulator stopped by user.")