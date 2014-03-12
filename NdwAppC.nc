 #include <Timer.h>
 #include "Ndw.h"

//#define NEW_PRINTF_SEMANTICS
//#include "printf.h"
 
 configuration NdwAppC {
 }
 implementation {

   components MainC;
   components NdwC as App;
   App.Boot -> MainC;
   
   components ActiveMessageC;
   App.AMControl -> ActiveMessageC;

   components new AMSenderC(AM_NDW);
   components new AMReceiverC(AM_NDW);
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.Receive -> AMReceiverC;

   components new AMSenderC(AM_NDW_BEACON) as BeaconSenderC;
   components new AMReceiverC(AM_NDW_BEACON) as BeaconReceiverC;
   App.BeaconSend -> BeaconSenderC;
   App.BeaconReceive -> BeaconReceiverC;

   //components PrintfC;
   //components SerialStartC;
   components RandomC;
   App.Random -> RandomC;
 
   components LedsC;
   App.Leds -> LedsC;

   components new TimerMilliC() as Timer0;
   components new TimerMilliC() as CSTimer;
   components new TimerMilliC() as PITTimer;
   components new TimerMilliC() as BEACONTimer;
   App.Timer0 -> Timer0;
   App.CSTimer -> CSTimer;
   App.PITTimer -> PITTimer;
   App.BEACONTimer -> BEACONTimer;


   //components new SensirionSht11C() as SHT11C;
   //App.temperatureread -> SHT11C.Temperature;
   //App.humidityread -> SHT11C.Humidity;

   //components new HamamatsuS1087ParC() as LightC;
   //App.lightread -> LightC;

   //components new QueueC(queue_entry_t*, QUEUE_SIZE) as SendQueueP; //
   //Router.SendQueue -> SendQueueP;

 }