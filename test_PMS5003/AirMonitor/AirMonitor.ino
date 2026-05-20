// This is a test file for initial breadboard wiring including: 
// HUZZAH32,
// PMS5003 (PM2.5, PM10),
// SCD40 (CO2, Temperature, Humidity),
// and DPS310 (Air Pressure).

#include <HardwareSerial.h>
#include <Wire.h>
#include <Adafruit_DPS310.h>
#include <SensirionI2cScd4x.h>
#include <Adafruit_PM25AQI.h>

// PMS5003 on UART1 (GPIO16=RX, GPIO17=TX)
HardwareSerial pmsSerial(1);
Adafruit_PM25AQI aqi = Adafruit_PM25AQI();

// DPS310
Adafruit_DPS310 dps;

// SCD40
SensirionI2cScd4x scd4x;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  Serial.println("Air Quality Monitor - Test");

  // Start I2C
  Wire.begin();

  // Init PMS5003
  pmsSerial.begin(9600, SERIAL_8N1, 16, 17);
  if (!aqi.begin_UART(&pmsSerial)) {
    Serial.println("PMS5003 not found!");
  } else {
    Serial.println("PMS5003 OK");
  }

  // Init DPS310
  if (!dps.begin_I2C()) {
    Serial.println("DPS310 not found!");
  } else {
    Serial.println("DPS310 OK");
    dps.configurePressure(DPS310_64HZ, DPS310_64SAMPLES);
    dps.configureTemperature(DPS310_64HZ, DPS310_64SAMPLES);
  }

  // Init SCD40
  scd4x.begin(Wire, 0x62);
  uint16_t error = scd4x.startPeriodicMeasurement();
  if (error) {
    Serial.println("SCD40 not found!");
  } else {
    Serial.println("SCD40 OK");
  }

  // Warm up period
  Serial.println("Warming up sensors for 30 seconds...");
  delay(30000);
  Serial.println("Starting measurements...");
}

unsigned long lastPrint = 0;
PM25_AQI_Data data;
bool pmsUpdated = false;

void loop() {
  // Continuously try to read PMS5003 in background
  if (aqi.read(&data)) {
    pmsUpdated = true;
  }

  // Print all sensors every 5 seconds
  if (millis() - lastPrint >= 5000) {
    lastPrint = millis();
    Serial.println("-----------------------------");

    // --- PMS5003 ---
    if (pmsUpdated) {
      Serial.print("PM2.5: ");
      Serial.print(data.pm25_standard);
      Serial.println(" ug/m3");
      Serial.print("PM10:  ");
      Serial.print(data.pm100_standard);
      Serial.println(" ug/m3");
      pmsUpdated = false;
    } else {
      Serial.println("PMS5003: No reading");
    }

    // --- SCD40 ---
    uint16_t co2 = 0;
    float temperature = 0.0f;
    float humidity = 0.0f;
    bool isDataReady = false;
    scd4x.getDataReadyStatus(isDataReady);
    if (isDataReady) {
      scd4x.readMeasurement(co2, temperature, humidity);
      Serial.print("CO2:  ");
      Serial.print(co2);
      Serial.println(" ppm");
      Serial.print("Temp: ");
      Serial.print(temperature);
      Serial.println(" C");
      Serial.print("Hum:  ");
      Serial.print(humidity);
      Serial.println(" %");
    } else {
      Serial.println("SCD40: No reading yet");
    }


    // --- DPS310 ---
    Adafruit_Sensor *dps_pressure = dps.getPressureSensor();
    sensors_event_t pressure_event;
    if (dps.pressureAvailable()) {
      dps_pressure->getEvent(&pressure_event);
      Serial.print("Pressure: ");
      Serial.print(pressure_event.pressure);
      Serial.println(" hPa");
    } else {
      Serial.println("DPS310: No reading yet");
    }
  }
}
