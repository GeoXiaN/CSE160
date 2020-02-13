/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface List<pack> as SentPackets;//Container for ENTIRE PACKETS!!!!
}

// interface{
//    //
// }
implementation{
   pack sendPackage;
   pack pingPack;
   
   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   bool hasSentPacket(pack Package){
      //Needs to look thru the list and say if we have a packet or not.
      uint16_t size = call SentPackets.size();//NOT CONNECTED!!!!
      uint16_t i;
      for ( i=0; i<size; i++){
          pack getMe = call SentPackets.get(i);//NOT CONNECTED!!!! WTF!?
          
          if (getMe.src == Package.src && getMe.seq == Package.seq){
            return 1;
          }
            //else
      }
        return 0;    
   }   
   void savePacket(pack Package){
      call SentPackets.pushfront(Package);//keeps track of ALL the packets sent in the list
   }
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){ //Receive, keep it for now...
   
     
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         if(hasSentPacket(*myMsg))//denoting pointer
         {
            return msg;
         }
         dbg(GENERAL_CHANNEL, "YOLO!!!\n");
         if(TOS_NODE_ID == myMsg->dest){
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
            dbg(GENERAL_CHANNEL, "IMMA_TO: %d\n", myMsg->dest);//Getting destination fom packet.
            dbg(GENERAL_CHANNEL, "IMMA_FROM: %d\n", myMsg->src); //Getting where packet CREATED from.
            dbg(GENERAL_CHANNEL, "IT'S_MINE!\n");
            makePack(&pingPack, TOS_NODE_ID, myMsg->src, 0, 0, 0, "DA_PAYLOAD_IS_SECURED!!!!", PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(pingPack, AM_BROADCAST_ADDR);
            savePacket(pingPack);
         }
         else
         {
            call Sender.send(*myMsg, AM_BROADCAST_ADDR); //We want to send to broadcast address AM_BROADCAST_ADDR floods.
            savePacket(*myMsg);
         }
         return msg;
      }
      
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload) {//Sender, we wanr to ping with it.
      dbg(GENERAL_CHANNEL, "Ping Pong! \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, AM_BROADCAST_ADDR); //We want to send to broadcast address AM_BROADCAST_ADDR floods.
   }
   
    

  
 
   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
