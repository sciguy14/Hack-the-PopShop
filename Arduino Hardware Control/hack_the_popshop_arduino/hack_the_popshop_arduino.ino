//Hack the PopShop!
//Serial Commands send from the computer
//allow us to control the lights in the room!

//A project by Jeremy Blum, Jason Wright, and Sam Sinensky

int light_control_pin = 12;

void setup()
{
  pinMode(light_control_pin, OUTPUT);
  digitalWrite(light_control_pin, LOW);
  Serial.begin(9600);
 
}

void loop()
{
  //Have the arduino wait to receive input
  while (Serial.available() == 0);
  
  //Read the Input
  int val = Serial.read() - '0';
  if (val == 1) 
  {
    Serial.println("Light is On"); 
    digitalWrite(light_control_pin, HIGH);
  }
  else if (val == 0)
  {
    Serial.println("Light is Off");
    digitalWrite(light_control_pin, LOW);
  }
  else
  {
    Serial.println("Invalid!");
  }
  while(Serial.available()>0) Serial.read();
}
