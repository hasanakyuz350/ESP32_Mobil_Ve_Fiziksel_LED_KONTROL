#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

#define WIFI_SSID "**********"
#define WIFI_PASSWORD "**********"
#define API_KEY "**********"
#define DATABASE_URL "**********"
#define DEVICE_ID "esp32c6-001"

const int LED_PIN = 2;
const int BUTTON_PIN = 4;

bool ledState = false;

FirebaseData fbdo;
FirebaseData stream;
FirebaseAuth auth;
FirebaseConfig config;

String base = String("/devices/") + DEVICE_ID;
String cmdBase = base + "/cmd";
String telemetry = base + "/telemetry";
String events = base + "/events";

bool pendDesired = false;
bool desiredValue = false;
uint32_t nextTryDesired = 0;
uint32_t backoffDesired = 250;
bool pendTelem = false;
bool telemValue = false;
uint32_t nextTryTelem = 0;
uint32_t backoffTelem = 250;
const uint32_t SUPPRESS_MS = 150;
uint32_t suppressUntilMs = 0;
const uint8_t BUTTON_ACTIVE = LOW;
const uint32_t DEBOUNCE_MS = 40;
uint8_t lastRead = HIGH, stable = HIGH;
uint32_t lastFlipMs = 0;

bool readButtonPressedOnce() {
  uint8_t nowRead = digitalRead(BUTTON_PIN);
  if (nowRead != lastRead) {
    lastRead = nowRead;
    lastFlipMs = millis();
  }
  if (millis() - lastFlipMs > DEBOUNCE_MS && nowRead != stable) {
    stable = nowRead;
    if (stable == BUTTON_ACTIVE) return true;
  }
  return false;
}
inline void applyLed(bool on) {
  ledState = on;
  digitalWrite(LED_PIN, on ? HIGH : LOW);
}
inline void queueDesired(bool v) {
  desiredValue = v;
  pendDesired = true;
}
inline void queueTelemetry(bool v) {
  telemValue = v;
  pendTelem = true;
}
void tryPushDesired() {
  if (!pendDesired || millis() < nextTryDesired) return;
  if (!(WiFi.status() == WL_CONNECTED && Firebase.ready())) {
    nextTryDesired = millis() + backoffDesired;
    return;
  }
  FirebaseJson j;
  j.set("isOn", desiredValue);
  j.set("by", "device");
  j.set("ts/.sv", "timestamp");
  bool okCmd = Firebase.RTDB.setJSON(&fbdo, cmdBase.c_str(), &j);
  FirebaseJson evt;
  evt.set("isOn", desiredValue);
  evt.set("by", "device");
  evt.set("serverTs/.sv", "timestamp");
  bool okEvt = Firebase.RTDB.pushJSON(&fbdo, events.c_str(), &evt);

  if (okCmd && okEvt) {
    pendDesired = false;
    backoffDesired = 250;
  } else {
    backoffDesired = min<uint32_t>(backoffDesired * 2, 5000);
    nextTryDesired = millis() + backoffDesired;
  }
}
void tryPushTelemetry() {
  if (!pendTelem || millis() < nextTryTelem) return;
  if (!(WiFi.status() == WL_CONNECTED && Firebase.ready())) {
    nextTryTelem = millis() + backoffTelem;
    return;
  }
  bool ok1 = Firebase.RTDB.setBool(&fbdo, (telemetry + "/isOn").c_str(), telemValue);
  bool ok2 = Firebase.RTDB.setString(&fbdo, (telemetry + "/source").c_str(), "esp");
  bool ok3 = Firebase.RTDB.setTimestamp(&fbdo, (telemetry + "/ts").c_str());
  if (ok1 && ok2 && ok3) {
    pendTelem = false;
    backoffTelem = 250;
  } else {
    backoffTelem = min<uint32_t>(backoffTelem * 2, 5000);
    nextTryTelem = millis() + backoffTelem;
  }
}
void applyFromCmd() {
  bool want = ledState;
  if (Firebase.RTDB.getBool(&fbdo, (cmdBase + "/isOn").c_str())) {
    if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_boolean) want = fbdo.boolData();
    else if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_integer) want = fbdo.intData() != 0;
  }
  if (want != ledState) {
    applyLed(want);
    queueTelemetry(want);
  }
}
void handleStream() {
  if (!Firebase.RTDB.readStream(&stream)) return;
  if (!stream.streamAvailable()) return;
  if (pendDesired || (millis() < suppressUntilMs)) return;
  bool haveWant = false;
  bool want = ledState;
  if (stream.dataTypeEnum() == firebase_rtdb_data_type_boolean) {
    want = stream.boolData();
    haveWant = true;
  } else {
    if (Firebase.RTDB.getBool(&fbdo, (cmdBase + "/isOn").c_str())) {
      if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_boolean) {
        want = fbdo.boolData();
        haveWant = true;
      } else if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_integer) {
        want = fbdo.intData() != 0;
        haveWant = true;
      }
    }
  }
  if (haveWant && want != ledState) {
    applyLed(want);
    queueTelemetry(want);
  }
}
void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  applyLed(false);
  lastRead = stable = digitalRead(BUTTON_PIN);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(150);
  }
  Serial.println("\nWiFi OK");
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (!Firebase.signUp(&config, &auth, "", "")) {
    Serial.printf("SignUp hata: %s\n", config.signer.signupError.message.c_str());
  }
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  if (!Firebase.RTDB.beginStream(&stream, cmdBase.c_str())) {
    Serial.printf("Stream baslatilamadi: %s\n", stream.errorReason().c_str());
  }
  queueTelemetry(ledState);
}
void loop() {
  if (readButtonPressedOnce()) {
    bool next = !ledState;
    applyLed(next);
    suppressUntilMs = millis() + SUPPRESS_MS;
    queueTelemetry(next);
    queueDesired(next);
  }
  tryPushTelemetry();
  tryPushDesired();
  handleStream();
  delay(0);
}