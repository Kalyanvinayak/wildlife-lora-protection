// arduino/villager_alert_device/villager_alert_device.ino

#include <SPI.h>
#include <RadioLib.h> // For LoRa communication (e.g., SX1278)

// --- LoRa Module Configuration ---
// SX1278 LoRa module pins (adjust for your specific board/module)
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
SX1278 radio = new Module(LORA_CS, LORA_DIO0, LORA_RST);

// LoRa settings (must match gateway/collar node settings)
const float LORA_FREQUENCY = 433.0;
const float LORA_BANDWIDTH = 125.0;
const uint8_t LORA_SPREADING_FACTOR = 9;
const uint8_t LORA_CODING_RATE = 7;
const uint8_t LORA_SYNC_WORD = 0x12;

// --- Alert Device Specifics ---
#define SIREN_PIN 5   // Pin connected to a relay or transistor for siren/buzzer
#define LED_PIN   6   // Pin connected to an LED (e.g., a high-brightness warning LED)

const String DEVICE_ID = "villager_device_001"; // Unique ID for this device

// Flag to indicate if a packet was received
volatile bool packetReceived = false;

// This function is called when a packet is received
void setFlag(void) {
  packetReceived = true;
}

void setup() {
  Serial.begin(9600);
  while (!Serial); // Wait for serial port to connect.
  Serial.println(F("Initializing Villager Alert Device..."));

  // Initialize LoRa module
  Serial.print(F("[LoRa] Initializing ... "));
  int state = radio.begin(LORA_FREQUENCY, LORA_BANDWIDTH, LORA_SPREADING_FACTOR,
                          LORA_CODING_RATE, LORA_SYNC_WORD);
  if (state == RADIOLIB_ERR_NONE) {
    Serial.println(F("success!"));
  } else {
    Serial.print(F("failed, code "));
    Serial.println(state);
    while (true); // Halt if LoRa fails
  }

  // Set up interrupt for DIO0 (packet reception)
  radio.setDio0Action(setFlag);

  // Start listening for packets
  Serial.print(F("[LoRa] Starting to listen for packets... "));
  state = radio.startReceive();
  if (state == RADIOLIB_ERR_NONE) {
    Serial.println(F("success!"));
  } else {
    Serial.print(F("failed, code "));
    Serial.println(state);
    while (true);
  }

  // Configure output pins
  pinMode(SIREN_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(SIREN_PIN, LOW); // Ensure siren is off initially
  digitalWrite(LED_PIN, LOW);   // Ensure LED is off initially

  Serial.println(F("Villager Alert Device Ready."));
}

void loop() {
  if (packetReceived) {
    packetReceived = false; // Reset flag

    // Read the incoming packet
    String str;
    int state = radio.readData(&str);

    if (state == RADIOLIB_ERR_NONE) {
      Serial.print(F("[LoRa] Received packet: "));
      Serial.println(str);
      processCommand(str);
    } else if (state == RADIOLIB_ERR_RX_TIMEOUT) {
      // Timeout occurred, but no packet was received
      Serial.println(F("[LoRa] Receive timeout!"));
    } else {
      Serial.print(F("[LoRa] Failed to receive packet, code "));
      Serial.println(state);
    }

    // Restart listening for the next packet
    radio.startReceive();
  }
}

void processCommand(String commandString) {
  // Expected command format: "DEVICE_ID,COMMAND_TYPE,MESSAGE,DURATION"
  // Example: "villager_device_001,activate_siren,Flood Warning,30"
  // Example: "villager_device_001,display_message,Evacuate Immediately,0"

  String parts[4];
  int partIndex = 0;
  int lastCommaIndex = 0;

  for (int i = 0; i < commandString.length(); i++) {
    if (commandString.charAt(i) == ',') {
      parts[partIndex] = commandString.substring(lastCommaIndex, i);
      lastCommaIndex = i + 1;
      partIndex++;
      if (partIndex >= 4) break;
    }
  }
  parts[partIndex] = commandString.substring(lastCommaIndex); // Last part

  if (partIndex < 3) { // Need at least device_id, command_type, message
    Serial.println(F("Invalid command format received."));
    return;
  }

  String receivedDeviceId = parts[0];
  String commandType = parts[1];
  String message = parts[2];
  int duration = parts[3].toInt(); // Duration in seconds

  if (receivedDeviceId != DEVICE_ID) {
    Serial.print(F("Command for wrong device: "));
    Serial.println(receivedDeviceId);
    return;
  }

  Serial.print(F("Processing command: "));
  Serial.println(commandType);

  if (commandType == "activate_siren") {
    Serial.print(F("Activating siren for "));
    Serial.print(duration);
    Serial.println(F(" seconds."));
    digitalWrite(SIREN_PIN, HIGH); // Turn siren ON
    digitalWrite(LED_PIN, HIGH);   // Turn LED ON
    delay(duration * 1000);        // Keep siren/LED on for duration
    digitalWrite(SIREN_PIN, LOW);  // Turn siren OFF
    digitalWrite(LED_PIN, LOW);    // Turn LED OFF
    Serial.println(F("Siren deactivated."));
  } else if (commandType == "deactivate_siren") {
    Serial.println(F("Deactivating siren."));
    digitalWrite(SIREN_PIN, LOW);
    digitalWrite(LED_PIN, LOW);
  } else if (commandType == "display_message") {
    Serial.print(F("Displaying message: "));
    Serial.println(message);
    // In a real scenario, you'd send this to an LCD/OLED display
    // For now, we'll just print to serial and blink the LED
    for (int i = 0; i < 5; i++) { // Blink LED 5 times
      digitalWrite(LED_PIN, HIGH);
      delay(200);
      digitalWrite(LED_PIN, LOW);
      delay(200);
    }
  } else {
    Serial.print(F("Unknown command type: "));
    Serial.println(commandType);
  }
}