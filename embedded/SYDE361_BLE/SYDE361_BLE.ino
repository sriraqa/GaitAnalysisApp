#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>  // Library so we can communicate with I2C devices: https://docs.arduino.cc/language-reference/en/functions/communication/wire/
#include <math.h>

/*
Output data will look like this:

{
  "heel": 123,
  "big_toe": 456,
  "arch": 789,
  "ball": 234,
  "sole": 567,
  "pitch": 0.23,
  "roll": 87.46
}

*/

// Define sensor pins
const int sensorPins[] = { A1, A7, A2, A6, A3 };
const char *sensorNames[] = { "heel", "big_toe", "arch", "ball", "sole" };
const int numSensors = 5;
const int MPU_address = 0x68;

// Variables to store gyroscope's raw data
int16_t acc_x, acc_y, acc_z;  // acceleration
double pitch, roll;           // pitch and roll, which are the angles relative to x and y axes

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

// BLE UUIDs
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
  }

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
  }
};

void setup() {
  Serial.begin(115200);

  BLEDevice::init("ESP32-SYDE 361");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX,
    BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristic->addDescriptor(new BLE2902());

  pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX,
    BLECharacteristic::PROPERTY_WRITE);

  pService->start();
  pServer->getAdvertising()->start();

  // Set up gyroscope using Wire library
  Wire.begin();
  Wire.beginTransmission(MPU_address);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);

  Serial.println("BLE JSON Notify and MPU6050 Initialized");
}

void loop() {


    Wire.beginTransmission(MPU_address);
    Wire.write(0x3B);
    Wire.endTransmission(false);
    Wire.requestFrom(MPU_address, 6, true);

    int acc_x_off, acc_y_off, acc_z_off;

    // acceleration offset correction
    acc_x_off = -250;
    acc_y_off = 36;
    acc_z_off = 1200;

    // read accel data and apply correction
    acc_x = (Wire.read() << 8 | Wire.read()) + acc_x_off;
    acc_y = (Wire.read() << 8 | Wire.read()) + acc_y_off;
    acc_z = (Wire.read() << 8 | Wire.read()) + acc_z_off;

    // get pitch and roll angles
    getAngle(acc_x, acc_y, acc_z);

    String json = "{";

    for (int i = 0; i < numSensors; i++) {
      int value = analogRead(sensorPins[i]);
      json += "\"" + String(sensorNames[i]) + "\":\"" + String(value);
      if (i < numSensors )
        json += "\",";
    }
    // add pitch and roll values to json
    json += "\"" + String("pitch") + "\":\"" + pitch + "\",";
    json += "\"" + String("roll") + "\":\"" + roll + "\"";

    json += "}";

    Serial.println(json);

    pCharacteristic->setValue(json.c_str());
    pCharacteristic->notify();

  delay(100);  // 10 updates per second
}

void getAngle(int Vx, int Vy, int Vz) {
  double x = Vx;
  double y = Vy;
  double z = Vz;
  pitch = atan(x / sqrt((y * y) + (z * z)));
  roll = atan(y / sqrt((x * x) + (z * z)));
  //convert radians into degrees
  pitch = pitch * (180.0 / 3.14);
  roll = roll * (180.0 / 3.14);
}
