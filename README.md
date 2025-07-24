# VāyuRakshak - Scalable ML-Powered IoT Gas Monitoring System

## 🔍 Overview
**VāyuRakshak** is an end-to-end, real-time **IoT-based gas monitoring and emission prediction system** designed for both **cattle farms** and **industrial factories**. It leverages **ESP32-based sensor nodes**, **LSTM-based machine learning models**, and **cloud infrastructure (Firebase, GCP, FastAPI)** to provide predictive insights and real-time alerts to protect human and animal life.

## 🚀 Features
* **Real-time gas monitoring** using ESP32 with gas sensors
* **LSTM-based ML model** for emission pattern prediction
* **Flutter mobile app** for alerting and visualization
* **FastAPI backend** for data processing
* **Firebase + GCP** for cloud sync, storage, and notifications
* **Low-cost, low-power edge deployment**
* **Scalable to both agricultural and industrial use cases**

## 📦 Tech Stack

| Layer | Technologies Used |
|-------|------------------|
| Hardware | ESP32, MQ gas sensors, DHT11, Solar Power |
| Firmware | Embedded C / Arduino |
| Mobile App | Flutter (Dart) |
| Backend API | FastAPI (Python) |
| ML Model | LSTM (TensorFlow/Keras) |
| Cloud Infra | Firebase (Firestore, Cloud Functions), GCP (Pub/Sub, Storage) |

## 🛠 Architecture
1. **Sensor Nodes** collect gas concentration, temperature, humidity
2. Data is transmitted over **Wi-Fi** to the FastAPI server
3. FastAPI passes data to **LSTM model** for prediction
4. Results + raw data are stored in **Firebase Firestore**
5. **Flutter app** fetches and displays real-time metrics
6. Alerts are sent based on threshold breaches

## 📲 Flutter App
* Displays live sensor data and predictions
* Sends push notifications for abnormal readings
* Visualizes emission history through charts
* Integrated login via Firebase Auth

## 🧠 Machine Learning
* **Model**: LSTM (Long Short-Term Memory)
* **Input**: Time-series gas sensor data
* **Output**: Predicted gas level for next interval
* **Trained on**: Historical sensor data under various conditions
* **Goal**: Enable **proactive** safety alerts before levels spike

## 🔧 Installation & Setup

### ESP32
1. Flash code via Arduino IDE
2. Configure Wi-Fi & sensor pin mappings

### Backend (FastAPI)
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Flutter App
```bash
cd app
flutter pub get
flutter run
```

### Firebase Setup
* Create Firebase project
* Enable Firestore & Authentication
* Add `google-services.json` in `android/app/`

## 📊 Dashboard Screenshots
*(Add screenshots of Flutter app visualizing gas levels and predictions)*

## 🌐 Use Cases
* **Cattle Farms**: Prevent respiratory incidents in livestock
* **Factories**: Monitor emissions and ensure worker safety
* **Warehouses**: Prevent fire hazards or gas accumulation
* **Smart Cities**: Ambient air quality tracking

## ✅ Future Enhancements
* Add CO2/CO detectors and noise level sensors
* GPS-based sensor mapping
* Support for LoRaWAN or GSM in remote areas
* ML model upgrades using federated learning

## 🤝 Contributions
Pull requests are welcome. Please open an issue first to discuss changes.

## 📄 License
MIT License

## 📫 Contact
**Kalyan Vinayak**  
📧 kalyanvinayak1@gmail.com  
🌍 [LinkedIn](https://linkedin.com/in/kalyanvinayak)
