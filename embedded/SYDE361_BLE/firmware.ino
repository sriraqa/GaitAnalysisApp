#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

/*
Output data will look like this: 

{
  "heel": 123,
  "big_toe": 456,
  "arch": 789,
  "ball": 234,
  "sole": 567
}

*/

// Define sensor pins
const int sensorPins[] = {A3, A4, A5, A6, A7};
const char* sensorNames[] = {"heel", "big_toe", "arch", "ball", "sole"};
const int numSensors = 5;

BLECharacteristic* pCharacteristic;
bool deviceConnected = false;

// BLE UUIDs
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

void setup() {
  Serial.begin(115200);

  BLEDevice::init("ESP32-SYDE 361");
  BLEServer* pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());

  pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE
  );

  pService->start();
  pServer->getAdvertising()->start();

  Serial.println("BLE JSON Notify Initialized");
}

void loop() {
  if (deviceConnected) {
    String json = "{";

    for (int i = 0; i < numSensors; i++) {
      int value = analogRead(sensorPins[i]);
      json += "\"" + String(sensorNames[i]) + "\":" + String(value);
      if (i < numSensors - 1) json += ",";
    }

    json += "}";

    pCharacteristic->setValue(json.c_str());
    pCharacteristic->notify();

    Serial.println("Sent: " + json);
  }

  delay(100); // 10 updates per second
}
