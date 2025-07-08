#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h> // Library so we can communicate with I2C devices: https://docs.arduino.cc/language-reference/en/functions/communication/wire/

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
const char *sensorNames[] = {"heel", "big_toe", "arch", "ball", "sole"};
const int numSensors = 5;
const int gyro_address = 0x68;

// Variables to store gyroscope's raw data
int16_t gyro_x, gyro_y, gyro_z;

char temp_str[7];
char *convert_int16_to_str(int16_t i)
{
  sprintf(tmp_str, "%6d", i) return temp_str;
}

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

// BLE UUIDs
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class MyServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer)
  {
    deviceConnected = true;
  }

  void onDisconnect(BLEServer *pServer)
  {
    deviceConnected = false;
  }
};

void setup()
{
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
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x68);
  Wire.write(0);
  Wire.endTransmission(true);

  Serial.println("BLE JSON Notify and Gyroscope Initialized");
}

void loop()
{

  if (deviceConnected)
  {
    String json = "{";

    for (int i = 0; i < numSensors; i++)
    {
      int value = analogRead(sensorPins[i]);
      json += "\"" + String(sensorNames[i]) + "\":" + String(value);
      if (i < numSensors - 1)
        json += ",";
    }

    json += "}";

    pCharacteristic->setValue(json.c_str());
    pCharacteristic->notify();

    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B); 
    Wire.endTransmission(false); 
    Wire.requestFrom(MPU_ADDR, 7 * 2, true); 

    gyro_x = Wire.read() << 8 | Wire.read(); 
    gyro_y = Wire.read() << 8 | Wire.read(); 
    gyro_z = Wire.read() << 8 | Wire.read();

    Serial.println("Sent: " + json);
    Serial.println("Gyroscope data:");
    Serial.print(" | gX = "); Serial.print(convert_int16_to_str(gyro_x));
    Serial.print(" | gY = "); Serial.print(convert_int16_to_str(gyro_y));
    Serial.print(" | gZ = "); Serial.print(convert_int16_to_str(gyro_z));
  }

  delay(100); // 10 updates per second
}
