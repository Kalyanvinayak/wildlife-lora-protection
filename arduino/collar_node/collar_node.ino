// arduino/collar_node/collar_node.ino

#include <SPI.h>
#include <RadioLib.h> // For LoRa communication (e.g., SX1278)
#include <TinyGPS++.h> // For GPS module
#include <DHT.h>       // For DHT11 temperature/humidity sensor

// --- LoRa Module Configuration ---
// SX1278 LoRa module pins (adjust for your specific board/module)
// For ESP32 or similar, these might be different.
// Typical wiring for SX1278 on Arduino UNO/Nano:
// NSS (CS) -> D10
// DIO0 -> D2 (Interrupt pin)
// RST -> D9
// SCK -> D13
// MISO -> D12
// MOSI -> D11
#define LORA_CS   10 // LoRa chip select pin
#define LORA_RST  9  // LoRa reset pin
#define LORA_DIO0 2  // LoRa DIO0 pin (interrupt pin)

// Create a new instance of the SX1278 class
// Use SX1276 for modules with SX1276 chip
SX1278 radio = new Module(LORA_CS, LORA_DIO0, LORA_RST);

// LoRa settings
const float LORA_FREQUENCY = 433.0; // LoRa frequency (e.g., 433, 868, 915 MHz)
const float LORA_BANDWIDTH = 125.0; // LoRa bandwidth (kHz)
const uint8_t LORA_SPREADING_FACTOR = 9; // Spreading factor (7 to 12)
const uint8_t LORA_CODING_RATE = 7; // Coding rate (5 to 8)
const uint8_t LORA_SYNC_WORD = 0x12; // Sync word (0x12 for public, 0x34 for private)
const int8_t LORA_POWER = 14; // Transmit power (dBm)
const uint16_t LORA_PREAMBLE_LENGTH = 8; // Preamble length

// --- GPS Module Configuration ---
// Connect GPS RX to Arduino D3 (SoftwareSerial TX)
// Connect GPS TX to Arduino D4 (SoftwareSerial RX)
// Using SoftwareSerial for GPS on pins other than hardware serial (0, 1)
#include <SoftwareSerial.h>
SoftwareSerial gpsSerial(4, 3); // RX, TX (Connect GPS TX to D4, GPS RX to D3)
TinyGPSPlus gps;

// --- DHT11 Sensor Configuration ---
#define DHTPIN 7     // DHT11 sensor data pin
#define DHTTYPE DHT11 // DHT 11
DHT dht(DHTPIN, DHTTYPE);

// --- Other Sensors (Placeholders) ---
// For gas sensor (e.g., MQ-2, MQ-7), connect analog output to A0
#define GAS_SENSOR_PIN A0
// For soil humidity sensor (analog), connect to A1
#define SOIL_HUMIDITY_PIN A1

// --- Node Specifics ---
const String NODE_ID = "COLLAR_001";
const String NODE_TYPE = "collar";
const unsigned long TRANSMISSION_INTERVAL_MS = 30000; // Transmit every 30 seconds
unsigned long lastTransmissionTime = 0;

// --- Battery Monitoring ---
// Assuming a voltage divider on A2 to measure battery voltage
#define BATTERY_VOLTAGE_PIN A2
const float ANALOG_REFERENCE_VOLTAGE = 5.0; // Arduino's VCC
const float VOLTAGE_DIVIDER_RATIO = 2.0; // (R1+R2)/R2, if R1=R2, ratio is 2.0

void setup() {
  Serial.begin(9600);
  while (!Serial); // Wait for serial port to connect.
  Serial.println(F("Initializing Collar Node..."));

  // Initialize LoRa module
  Serial.print(F("[LoRa] Initializing ... "));
  int state = radio.begin(LORA_FREQUENCY, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                          LORA_CODING_RATE, LORA_SYNC_WORD, LORA_POWER, LORA_PREAMBLE_LENGTH);
  if (state == RADIOLIB_ERR_NONE) {
    Serial.println(F("success!"));
  } else {
    Serial.print(F("failed, code "));
    Serial.println(state);
    while (true); // Halt if LoRa fails
  }

  // Initialize GPS module
  gpsSerial.begin(9600); // GPS module baud rate
  Serial.println(F("[GPS] Initializing ..."));

  // Initialize DHT11 sensor
  dht.begin();
  Serial.println(F("[DHT11] Initializing ..."));

  // Set up battery voltage pin
  pinMode(BATTERY_VOLTAGE_PIN, INPUT);

  Serial.println(F("Collar Node Ready."));
}

void loop() {
  // Process GPS data
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  // Check if it's time to transmit
  if (millis() - lastTransmissionTime >= TRANSMISSION_INTERVAL_MS) {
    transmitSensorData();
    lastTransmissionTime = millis();
  }
}

void transmitSensorData() {
  Serial.println(F("\n--- Transmitting Sensor Data ---"));

  // --- Read Sensor Data ---
  float latitude = gps.location.isValid() ? gps.location.lat() : 0.0;
  float longitude = gps.location.isValid() ? gps.location.lng() : 0.0;
  float temperature = dht.readTemperature(); // Reads temperature in Celsius
  float humidity = dht.readHumidity();

  // Read placeholder sensor data
  int gasSensorValue = analogRead(GAS_SENSOR_PIN);
  float gas_level = map(gasSensorValue, 0, 1023, 0, 100); // Map 0-1023 to 0-100%

  int soilHumiditySensorValue = analogRead(SOIL_HUMIDITY_PIN);
  float soil_humidity = map(soilHumiditySensorValue, 0, 1023, 0, 100); // Map 0-1023 to 0-100%

  // Read battery voltage
  int batteryRaw = analogRead(BATTERY_VOLTAGE_PIN);
  float battery_voltage = (batteryRaw * ANALOG_REFERENCE_VOLTAGE / 1024.0) * VOLTAGE_DIVIDER_RATIO;

  // Validate sensor readings
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println(F("Failed to read from DHT sensor!"));
    temperature = -999.0; // Indicate error
    humidity = -999.0;   // Indicate error
  }

  // --- Prepare Data Payload ---
  // Format: "NODE_ID,NODE_TYPE,LAT,LON,TEMP,HUMIDITY,GAS,BATTERY"
  // Using a simple comma-separated string for demonstration.
  // For production, consider a more robust serialization (e.g., CBOR, Protocol Buffers)
  // to save bytes and ensure data integrity.
  String payload = NODE_ID + "," + NODE_TYPE + "," +
                   String(latitude, 6) + "," + String(longitude, 6) + "," +
                   String(temperature, 2) + "," + String(humidity, 2) + "," +
                   String(gas_level, 2) + "," + String(battery_voltage, 2);

  Serial.print(F("Payload: "));
  Serial.println(payload);

  // --- Send LoRa Packet ---
  Serial.print(F("[LoRa] Sending packet ... "));
  int state = radio.transmit(payload);

  if (state == RADIOLIB_ERR_NONE) {
    Serial.println(F("success!"));
  } else if (state == RADIOLIB_ERR_TX_TIMEOUT) {
    Serial.println(F("timeout!"));
  } else {
    Serial.print(F("failed, code "));
    Serial.println(state);
  }
}