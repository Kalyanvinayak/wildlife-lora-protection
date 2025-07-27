# backend/ml_model.py

import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import joblib
import os

MODEL_PATH = "isolation_forest_model.joblib"

def train_or_load_model(data=None):
    """
    Trains an Isolation Forest model for anomaly detection or loads an existing one.
    If no data is provided and no model exists, it creates a dummy model.
    """
    if os.path.exists(MODEL_PATH):
        print("Loading existing ML model...")
        return joblib.load(MODEL_PATH)
    elif data is not None and not data.empty:
        print("Training new ML model...")
        # Features for anomaly detection: latitude, longitude, temperature, humidity
        # In a real scenario, you'd add more features and preprocess data.
        features = data[['latitude', 'longitude', 'temperature', 'humidity']].dropna()
        if features.empty:
            print("Not enough data to train, creating dummy model.")
            model = IsolationForest(random_state=42)
            # Fit with some dummy data if no real data available
            model.fit(np.array([[0,0,25,50]]))
            joblib.dump(model, MODEL_PATH)
            return model

        model = IsolationForest(random_state=42)
        model.fit(features)
        joblib.dump(model, MODEL_PATH)
        return model
    else:
        print("No data provided and no existing model. Creating a dummy model.")
        model = IsolationForest(random_state=42)
        # Fit with some dummy data if no real data available
        model.fit(np.array([[0,0,25,50]]))
        joblib.dump(model, MODEL_PATH)
        return model

def predict_anomaly(model, sensor_data):
    """
    Predicts if a new sensor data point is an anomaly.
    Returns 1 for inliers, -1 for outliers (anomalies).
    """
    # Ensure the input data matches the features used for training
    data_point = pd.DataFrame([sensor_data])
    features = data_point[['latitude', 'longitude', 'temperature', 'humidity']].dropna()
    if features.empty:
        print("Missing required features for anomaly prediction.")
        return 1 # Default to not an anomaly if data is incomplete

    # Predict returns -1 for outliers and 1 for inliers
    prediction = model.predict(features)
    return prediction[0]

# Example usage (for testing purposes)
if __name__ == "__main__":
    # Create some dummy data for training
    dummy_data = pd.DataFrame({
        'latitude': np.random.uniform(10, 11, 100),
        'longitude': np.random.uniform(70, 71, 100),
        'temperature': np.random.uniform(20, 30, 100),
        'humidity': np.random.uniform(40, 60, 100)
    })
    # Add a few outliers
    dummy_data.loc[0] = [100, 100, 5, 10] # Extreme GPS
    dummy_data.loc[1] = [10.5, 70.5, 50, 90] # Extreme temp/humidity

    model = train_or_load_model(dummy_data)

    # Test with a normal data point
    normal_data = {'latitude': 10.5, 'longitude': 70.5, 'temperature': 25, 'humidity': 50}
    print(f"Normal data anomaly prediction: {predict_anomaly(model, normal_data)}")

    # Test with an anomalous data point
    anomalous_data = {'latitude': 100, 'longitude': 100, 'temperature': 5, 'humidity': 10}
    print(f"Anomalous data anomaly prediction: {predict_anomaly(model, anomalous_data)}")