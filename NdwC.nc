 #include <Timer.h>
 #include "Ndw.h"

//#include "printf.h"
//#include "pr.h"


 
 module NdwC {

  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as CSTimer;
  uses interface Timer<TMilli> as PITTimer;
  uses interface Timer<TMilli> as BEACONTimer;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;

  uses interface AMSend as BeaconSend;
  uses interface Receive as BeaconReceive;

  //uses interface Read<uint16_t> as lightread;
  uses interface Random;

 }

 implementation {

  bool send_busy;

  //unsigned char *name = "t3/632/t";
  unsigned char beaconname[NAME_LEN];
  unsigned char name_req_list[15][NAME_LEN];



  message_t packet; //pkt to send
  message_t beaconpacket;
  ndw_data_t ndw_send;
  ndw_data_t* ndw_send_ptr;

  uint8_t pit_active;
  uint8_t cs_active;
  uint8_t fib_active;
  uint8_t local_beacon_class;
  uint16_t send_count;  //for simulation
  uint16_t receive_count;  //for simulation
  uint16_t energy_count = 0;  //for simulation
  uint16_t sink_send;
  uint16_t sink_recv;
  uint16_t data;
  uint16_t seq;

  ndw_repo_t ndw_repo;  //local repository  (now one item)
  ndw_cs_item_t ndw_cs[NDW_CS_NUM]; //CS table
  ndw_pit_item_t ndw_pit[NDW_PIT_NUM]; //PIT table
  ndw_fib_item_t ndw_fib[NDW_FIB_NUM];  //FIB table
  ndw_beacon_t ndw_beacon;  //route beacon
  ndw_beacon_t* ndw_beacon_ptr;

  //****************function declaration****************//
  bool ndw_query_fib_beacon(ndw_data_t* ndw_recv);
  uint8_t beacon_class_calculate(ndw_data_t* ndw_recv);
  void repo_fib_init(am_addr_t local_node_id);
  bool ndw_query_repo(message_t* msg_recv, ndw_data_t* ndw_recv);
  bool ndw_query_cs(message_t* msg_recv, ndw_data_t* ndw_recv);
  bool ndw_query_pit_req(ndw_data_t* ndw_recv);
  bool ndw_query_fib(message_t* msg_recv, ndw_data_t* ndw_recv);
  bool ndw_query_pit_rsp(message_t* msg_recv, ndw_data_t* ndw_recv);

  event void Boot.booted()
  {
    #ifdef DEBUG_PRINT
    printf("BOOT booted.\n");
    printfflush();
    #endif
    dbg("BOOT", "%s BOOT booted.\n",sim_time_string());
    repo_fib_init(TOS_NODE_ID);
    call AMControl.start();
  }
 
  event void AMControl.startDone(error_t err)
  {
   if (err == SUCCESS)
    {
      call Timer0.startPeriodic(TIMER_PERIOD_REPO);
      call CSTimer.startPeriodic(TIMER_PERIOD_CS);
      call PITTimer.startPeriodic(TIMER_PERIOD_PIT);
      call BEACONTimer.startPeriodic(TIMER_PERIOD_BEACON);

      ndw_beacon_ptr = (ndw_beacon_t*)call BeaconSend.getPayload(&beaconpacket, sizeof(ndw_beacon_t));
      memcpy(ndw_beacon_ptr, &ndw_beacon, sizeof(ndw_beacon_t));
      ndw_beacon_ptr->beacon_type = BEACON_ONBOARD;

      if (call BeaconSend.send(AM_BROADCAST_ADDR, &beaconpacket, sizeof(ndw_beacon_t)) == SUCCESS)
      {
        send_busy = TRUE; //mark the send queue
        send_count ++;
        energy_count ++;
        dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
        #ifdef DEBUG_PRINT
        printf("BEACON beacon onboard sent. %d\n", send_count);
        printfflush();
        #endif
        dbg("BEACON", "%s BEACON beacon onboard sent. %d\n",sim_time_string(), send_count);
      }

      #ifdef DEBUG_PRINT
      printf("TIMER started.\n");
      printfflush();
      #endif
      dbg("TIMER", "%s TIMER started.\n",sim_time_string());
    }
    else
    {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err)
  {


  }

  //event void lightread.readDone(error_t result, uint16_t data) 
  //{
    //call Leds.led0Toggle(); //readDone, toggle the red led

   // sprintf(ndw_repo.buf, "%d lx", data);
  //}

  event void Timer0.fired() //update the REPO infomation
  {
    //call lightread.read();  //light info
    //ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));

    uint8_t i; 
    uint16_t dest_id;
    data++;
    seq++;
    sprintf(ndw_repo.buf, "%d lx", data);

    if(strcmp(beaconname, "/") == 0)
    {
      ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));
      
      memset(&ndw_send, 0, sizeof(ndw_data_t));

      strcpy(ndw_send.name, "t3/6/32/h");
      //data = call Random.rand16();
      //strcpy(ndw_send.name, name_req_list[data%15]);  //lun xun
      


      ndw_send.datatype = NDW_REQ;
      ndw_send.sequence = seq;

      memcpy(ndw_send_ptr, &ndw_send, sizeof(ndw_data_t));
      memset(&ndw_send, 0, sizeof(ndw_data_t));

      for (i = 0; i < NDW_FIB_NUM; ++i)
      {
        if(strstr(ndw_send_ptr->name, ndw_fib[i].name) == ndw_send_ptr->name) //got the FIB item
        {
          dest_id = ndw_fib[i].go_id;
   
          //ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));


          if (call AMSend.send(dest_id, &packet, sizeof(ndw_data_t)) == SUCCESS)
          {
            send_busy = TRUE; //mark the send queue
            send_count ++;
            energy_count ++;
            sink_send ++;
            dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
            #ifdef DEBUG_PRINT
            printf("FIB send item %d.\n", i);
            printfflush();
            #endif
            dbg("FIB", "%s FIB send item %d.\n",sim_time_string(), i);
            dbg("SINK", "%s SINK sink_send count %d sequence %d\n",sim_time_string(), sink_send, ndw_send_ptr->sequence);
          }
        }
      }
    }

  }

  event void CSTimer.fired() //update the CS infomation; clear the stale content cache
  {
    uint8_t i, j;
    
    for ( i = 0; i < cs_active; ++i)
    {
      if(ndw_cs[i].stale_count >0)
        ndw_cs[i].stale_count --;
      else
      {
        call Leds.led2Toggle(); //cs stale   oringe led 
        for(j = i; j+1 < cs_active; ++j)
        {
          memcpy(&ndw_cs[j], &ndw_cs[j+1], sizeof(ndw_cs_item_t));
        }
        memset(&ndw_cs[j], 0, sizeof(ndw_cs_item_t));
        cs_active--;

        #ifdef DEBUG_PRINT
        printf("CS clear stale item %d.\n", i);
        printfflush();
        #endif
        dbg("CS", "%s CS clear stale item %d.\n",sim_time_string(), i);
      }
    }
  }


  event void PITTimer.fired() //update the PIT infomation
  {
    uint8_t i, j;
    for ( i = 0; i < pit_active; ++i)
    {
      if(ndw_pit[i].stale_count > 0)
      {
        ndw_pit[i].stale_count --;
        #ifdef DEBUG_PRINT
        //printf("PIT stale_count) %d\n", ndw_pit[i].stale_count);
        //printfflush();
        #endif
      }
      else
      {
        for(j = i; j+1 < pit_active; ++j)
        {
          memcpy(&ndw_pit[j], &ndw_pit[j+1], sizeof(ndw_pit_item_t));
        }
        memset(&ndw_pit[j], 0, sizeof(ndw_pit_item_t));
        pit_active--;

        #ifdef DEBUG_PRINT
        printf("PIT clear stale item %d.\n", i);
        printfflush();
        #endif
        dbg("PIT", "%s PIT clear stale item %d.\n",sim_time_string(), i);
      }
    }
  }

  event void BEACONTimer.fired() //update the FIB infomation
  {
    uint8_t i, j;

    ndw_beacon_ptr = (ndw_beacon_t*)call BeaconSend.getPayload(&beaconpacket, sizeof(ndw_beacon_t));
    memcpy(ndw_beacon_ptr, &ndw_beacon, sizeof(ndw_beacon_t));

    
    for ( i = 0; i < fib_active; ++i)
    {
      if(ndw_fib[i].stale_count > 0)
      {
        ndw_fib[i].stale_count --;
        #ifdef DEBUG_PRINT
        //printf("FIB stale_count) %d\n", ndw_fib[i].stale_count);
        //printfflush();
        #endif
      }
      else
      {
        for(j = i; j+1 < fib_active; ++j)
        {
          memcpy(&ndw_fib[j], &ndw_fib[j+1], sizeof(ndw_fib_item_t));
        }
        memset(&ndw_fib[j], 0, sizeof(ndw_fib_item_t));
        fib_active--;

        #ifdef DEBUG_PRINT
        printf("FIB clear stale item %d.\n", i);
        printfflush();
        #endif
        dbg("FIB", "%s FIB clear stale item %d.\n",sim_time_string(), i);
      }
    }

    if(strcmp(beaconname, "/") == 0)
      return;

    if (call BeaconSend.send(AM_BROADCAST_ADDR, &beaconpacket, sizeof(ndw_beacon_t)) == SUCCESS)
    {
      send_busy = TRUE; //mark the send queue
      send_count ++;
      energy_count ++;
      dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
      #ifdef DEBUG_PRINT
      printf("BEACON beacon normal sent. %d\n", send_count);
      printfflush();
      #endif
      dbg("BEACON", "%s BEACON beacon normal sent. %d\n",sim_time_string(), send_count);
    }
  }

  event void BeaconSend.sendDone(message_t* msg, error_t error)
  {
    if(&beaconpacket == msg)
      send_busy = TRUE;
  }

  event message_t* BeaconReceive.receive(message_t* msg, void* payload, uint8_t len)
  {
    call Leds.led2Toggle(); //receive a Packet   toggle the yellow led

    //printf("Beacon received.\n");

    if(len == sizeof(ndw_beacon_t))
    {
      ndw_beacon_t* ndw_recv = (ndw_beacon_t*)payload;  //get the recv buf pointer

      if(beacon_class_calculate(ndw_recv) > BEACON_CLASS)
        return msg;

      if(ndw_recv->beacon_type == BEACON_ONBOARD)
      {
        ndw_beacon_ptr = (ndw_beacon_t*)call BeaconSend.getPayload(&beaconpacket, sizeof(ndw_beacon_t));
        memcpy(ndw_beacon_ptr, &ndw_beacon, sizeof(ndw_beacon_t));

        if (call BeaconSend.send(AM_BROADCAST_ADDR, &beaconpacket, sizeof(ndw_beacon_t)) == SUCCESS)
        {
          send_busy = TRUE; //mark the send queue
          send_count ++;
          receive_count ++;
          energy_count = energy_count -2;
          dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
          #ifdef DEBUG_PRINT
          printf("BEACON beacon onboard received. %d\n", send_count);
          printf("BEACON beacon re-onboard sent. %d\n", receive_count);
          printfflush();
          #endif
          dbg("BEACON", "%s BEACON beacon onboard received. %d\n",sim_time_string(), send_count);
          dbg("BEACON", "%s BEACON beacon re-onboard sent. %d\n",sim_time_string(), receive_count);
        }
      }
      
      if(strstr(ndw_recv->name, beaconname) == ndw_recv->name  || strcmp(beaconname, "/") == 0)
      {
        receive_count ++;
        energy_count ++;
        dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
        #ifdef DEBUG_PRINT
        printf("BEACON beacon normal received. %d\n", receive_count);
        #endif
        dbg("BEACON", "%s BEACON beacon normal received. %d\n",sim_time_string(), receive_count);

        // mark in the FIB
        if(ndw_query_fib_beacon(ndw_recv))
          return msg;
        else if(fib_active < NDW_FIB_NUM)
        {
          strcpy(ndw_fib[fib_active].name, ndw_recv->name);
          ndw_fib[fib_active].go_id = ndw_recv->beacon_id;
          ndw_fib[fib_active].stale_count = FIB_STALE_COUNT;
          //ndw_pit[fib_active].stale_count = PIT_STALE_COUNT;
          fib_active ++;

          #ifdef DEBUG_PRINT
          printf("FIB mark item %d.\n", fib_active-1);
          printfflush();
          #endif
          dbg("FIB", "%s FIB mark item %d.\n",sim_time_string(), fib_active-1);
        }

      }
    }
    return msg;
  }

  event void AMSend.sendDone(message_t* msg, error_t error)
  {
    if(&packet == msg)
      send_busy = FALSE;
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
  {
    call Leds.led1Toggle(); //receive a Packet   toggle the green led

    if(len == sizeof(ndw_data_t))
    {

      ndw_data_t* ndw_recv = (ndw_data_t*)payload;  //get the recv buf pointer

      #ifdef DEBUG_PRINT
      //printf("-len: %d\n", len);
      //printf("-ndw_recv name: %s len:%d\n", ndw_recv->name, strlen(ndw_recv->name));
      
      //printfflush();
      #endif

      if(ndw_recv->datatype == NDW_REQ)
      {
        receive_count ++;
        energy_count ++;
        dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
        #ifdef DEBUG_PRINT
        printf("DATA receive an interest message. %d \n", receive_count);
        printfflush();
        #endif
        dbg("DATA", "%s DATA receive an interest message. %d \n",sim_time_string(), receive_count);

        if(ndw_query_repo(msg, ndw_recv))  //if got the content in REPO, Response the data and return TRUE.
          return msg;
        else if(ndw_query_cs(msg, ndw_recv)) //if got the content in CS, Response the data and return TRUE.
          return msg;
        else if(ndw_query_pit_req(ndw_recv)) //if got matched item in PIT, DISCARD the REQ.
          return msg;
        else if(ndw_query_fib(msg, ndw_recv))  //if got matched item in FIB, FORWARD the REQ & mark in the PIT.
          return msg;
      }

      if(ndw_recv->datatype == NDW_RSP)
      {
        receive_count ++;
        energy_count ++;
        dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
        #ifdef DEBUG_PRINT
        printf("DATA receive a content message. %d\n", receive_count);
        printfflush();
        #endif
        dbg("DATA", "%s DATA receive a content message. %d %d\n",sim_time_string(), receive_count, energy_count);

        if(strcmp(beaconname, "/") == 0)
        {
          sink_recv ++;
          dbg("SINK", "%s SINK sink_recv count %d sequence %d\n",sim_time_string(), sink_recv, ndw_recv->sequence);
        }

        if(ndw_query_pit_rsp(msg, ndw_recv)) //if recoard in PIT, FORWARD the RSP & cache RSP & clear PIT& return TRUE
          return msg;
      }

    }
    return msg;
  }




  //*****************help function***************//
  void repo_fib_init(am_addr_t local_node_id)
  {
    pit_active = 0;
    cs_active = 0;
    fib_active = 0;
    send_count = 0;
    receive_count = 0;
    energy_count = 0,
    sink_send = 0;
    sink_recv = 0;

    memset(ndw_fib, 0xff, sizeof(ndw_fib_item_t)*NDW_FIB_NUM);

    switch(local_node_id) //inital the static FIB table by nodeid
    {
      case 0:
      {
        //printf("node 1\n");

        strcpy(ndw_repo.name, "/");
        strcpy(beaconname, "/");
        local_beacon_class = 0;


        //strcpy(ndw_fib[0].name, "t3/632");
        //ndw_fib[0].go_id = 3;

        //strcpy(ndw_fib[1].name, "t3/911");
        //ndw_fib[1].go_id = 4;

        //strcpy(ndw_fib[2].name, "s10");
        //ndw_fib[2].go_id = 2;
        break;
      }

      case 1:
      {
        //printf("node 2\n");

        strcpy(ndw_repo.name, "t3");
        strcpy(beaconname, "t3");
        local_beacon_class = 1;
        
        //strcpy(ndw_fib[0].name, "s10/356");
        //ndw_fib[0].go_id = 5;

        //strcpy(ndw_fib[1].name, "s10/479");
        //ndw_fib[1].go_id = 6;
        break;
      }

      case 2:
      {
        //printf("node 3\n");

        strcpy(ndw_repo.name, "d10");
        strcpy(beaconname, "d10");
        local_beacon_class = 1;

        break;
      }

      case 3:
      {
        //printf("node 4\n");

        strcpy(ndw_repo.name, "t3/6");
        strcpy(beaconname, "t3/6");
        local_beacon_class = 2;
        break;
      }

      case 4:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/9");
        strcpy(beaconname, "t3/9");
        local_beacon_class = 2;
        break;
      }

      case 5:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/3");
        strcpy(beaconname, "d10/3");
        local_beacon_class = 2;
        break;
      }

      case 6:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/5");
        strcpy(beaconname, "d10/5");
        local_beacon_class = 2;
        break;
      }

      case 7:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/32");
        strcpy(beaconname, "t3/6/32");
        local_beacon_class = 3;
        break;
      }

      case 8:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/33");
        strcpy(beaconname, "t3/6/33");
        local_beacon_class = 3;
        break;
      }

      case 9:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/9/11");
        strcpy(beaconname, "t3/9/11");
        local_beacon_class = 3;
        break;
      }

      case 10:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/3/56");
        strcpy(beaconname, "d10/3/56");
        local_beacon_class = 3;
        break;
      }

      case 11:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/5/42");
        strcpy(beaconname, "d10/5/42");
        local_beacon_class = 3;
        break;
      }

      case 12:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/32/h");
        strcpy(beaconname, "t3/6/32/h");
        local_beacon_class = 4;
        break;
      }

      case 13:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/32/t");
        strcpy(beaconname, "t3/6/32/t");
        local_beacon_class = 4;
        break;
      }

      case 14:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/32/l");
        strcpy(beaconname, "t3/6/32/l");
        local_beacon_class = 4;
        break;
      }

      case 15:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/33/h");
        strcpy(beaconname, "t3/6/33/h");
        local_beacon_class = 4;
        break;
      }

      case 16:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/33/t");
        strcpy(beaconname, "t3/6/33/t");
        local_beacon_class = 4;
        break;
      }

      case 17:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/6/33/l");
        strcpy(beaconname, "t3/6/33/l");
        local_beacon_class = 4;
        break;
      }

      case 18:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/9/11/h");
        strcpy(beaconname, "t3/9/11/h");
        local_beacon_class = 4;
        break;
      }

      case 19:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/9/11/t");
        strcpy(beaconname, "t3/9/11/t");
        local_beacon_class = 4;
        break;
      }

      case 20:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "t3/9/11/l");
        strcpy(beaconname, "t3/9/11/l");
        local_beacon_class = 4;
        break;
      }

      case 21:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/3/56/h");
        strcpy(beaconname, "d10/3/56/h");
        local_beacon_class = 4;
        break;
      }

      case 22:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/3/56/t");
        strcpy(beaconname, "d10/3/56/t");
        local_beacon_class = 4;
        break;
      }

      case 23:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/3/56/l");
        strcpy(beaconname, "d10/3/56/l");
        local_beacon_class = 4;
        break;
      }

      case 24:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/5/42/h");
        strcpy(beaconname, "d10/5/42/h");
        local_beacon_class = 4;
        break;
      }

      case 25:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/5/42/t");
        strcpy(beaconname, "d10/5/42/t");
        local_beacon_class = 4;
        break;
      }

      case 26:
      {
        //printf("node 5\n");

        strcpy(ndw_repo.name, "d10/5/42/l");
        strcpy(beaconname, "d10/5/42/l");
        local_beacon_class = 4;
        break;
      }

    }
    if(strcmp(beaconname, "/") == 0)
    {
      strcpy(name_req_list[0], "t3/6/32/h");
      strcpy(name_req_list[1], "t3/6/32/t");
      strcpy(name_req_list[2], "t3/6/32/l");

      strcpy(name_req_list[3], "t3/6/33/h");
      strcpy(name_req_list[4], "t3/6/33/t");
      strcpy(name_req_list[5], "t3/6/33/l");

      strcpy(name_req_list[6], "t3/9/11/h");
      strcpy(name_req_list[7], "t3/9/11/t");
      strcpy(name_req_list[8], "t3/9/11/l");

      strcpy(name_req_list[9], "d10/3/56/h");
      strcpy(name_req_list[10], "d10/3/56/t");
      strcpy(name_req_list[11], "d10/3/56/l");

      strcpy(name_req_list[12], "d10/5/42/h");
      strcpy(name_req_list[13], "d10/5/42/t");
      strcpy(name_req_list[14], "d10/5/42/l");
    }
    


    strcpy(ndw_beacon.name, beaconname);
    #ifdef DEBUG_PRINT
    printf("NODE beacon name: %s nodeid: %d.\n", ndw_beacon.name, local_node_id);
    printfflush();
    #endif
    dbg("NODE", "%s NODE beacon name: %s nodeid: %d.\n",sim_time_string(), ndw_beacon.name, local_node_id);
    ndw_beacon.beacon_id = local_node_id;
    ndw_beacon.beacon_type = BEACON_NORMAL;
  }

  uint8_t beacon_class_calculate(ndw_data_t* ndw_recv)
  {
    uint8_t i, recv_class, res;
    recv_class = 1;
    for(i = 0; i < NAME_LEN; i++)
    {
      if(*(ndw_recv->name + i) == '/')
        recv_class++;
    }

    res = recv_class - local_beacon_class;

    #ifdef DEBUG_PRINT
    //printf("recv_class %d res %d.\n", recv_class, res);
    //printfflush();
    #endif

    return res;
  }

  bool ndw_query_fib_beacon(ndw_data_t* ndw_recv)
  {
    uint8_t i;
    for (i = 0; i < fib_active; ++i)
    {
      if(strcmp(ndw_recv->name, ndw_fib[i].name) == 0)
      {
        ndw_fib[i].stale_count = FIB_STALE_COUNT;  //refresh
        return TRUE;
      }
    }
    return FALSE;
  }

  bool ndw_query_repo(message_t* msg_recv, ndw_data_t* ndw_recv)
  {
    am_addr_t dest_id = call AMPacket.source(msg_recv);

    #ifdef DEBUG_PRINT
    //printf("repo name len: %d\n", strlen(ndw_repo.name));
    #endif

    if(strcmp(ndw_recv->name, ndw_repo.name) == 0)
    {

      ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));
      strcpy(ndw_send.name, ndw_recv->name);
      ndw_send.datatype = NDW_RSP;
      ndw_send.sequence = ndw_recv->sequence;
      strcpy(ndw_send.buf, ndw_repo.buf);

      memcpy(ndw_send_ptr, &ndw_send, sizeof(ndw_data_t));
      memset(&ndw_send, 0, sizeof(ndw_data_t));

      if (call AMSend.send(dest_id, &packet, sizeof(ndw_data_t)) == SUCCESS)
      {
        send_count ++;
        energy_count ++;
        dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
        send_busy = TRUE; //mark the send queue
        #ifdef DEBUG_PRINT
        printf("REPO content sent. %d\n", send_count);
        printfflush();
        #endif
        dbg("REPO", "%s REPO content sent. %d\n",sim_time_string(), send_count);
      }
      return TRUE;
    }
    else
      return FALSE;
  }

  bool ndw_query_cs(message_t* msg_recv, ndw_data_t* ndw_recv)
  {
    uint8_t i;
    am_addr_t dest_id = call AMPacket.source(msg_recv);

    for (i = 0; i < cs_active; ++i)
    {
      if(strcmp(ndw_recv->name, ndw_cs[i].name) == 0)
      {
        ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));
        strcpy(ndw_send.name, ndw_recv->name);
        ndw_send.datatype = NDW_RSP;
        ndw_send.sequence = ndw_recv->sequence;
        strcpy(ndw_send.buf, ndw_cs[i].buf);

        memcpy(ndw_send_ptr, &ndw_send, sizeof(ndw_data_t));
        memset(&ndw_send, 0, sizeof(ndw_data_t));

        if (call AMSend.send(dest_id, &packet, sizeof(ndw_data_t)) == SUCCESS)
        {
          send_busy = TRUE; //mark the send queue
          send_count ++;
          energy_count ++;
          dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
          #ifdef DEBUG_PRINT
          printf("CS send cache item %d. %d\n", i, send_count);
          printfflush();
          #endif
          dbg("CS", "%s CS send cache item %d. %d\n",sim_time_string(), i, send_count);
        }
        return TRUE;
      }
    }
    return FALSE;
  }

  bool ndw_query_pit_req(ndw_data_t* ndw_recv)
  {
    uint8_t i;
    for (i = 0; i < pit_active; ++i)
    {
      if(strcmp(ndw_recv->name, ndw_pit[i].name) == 0)
      {
        return TRUE;
      }
    }
    return FALSE;
  }

  bool ndw_query_fib(message_t* msg_recv, ndw_data_t* ndw_recv)
  {
    uint8_t i;
    am_addr_t dest_id;
    am_addr_t come_id = call AMPacket.source(msg_recv);

    for (i = 0; i < NDW_FIB_NUM; ++i)
    {
      if(strstr(ndw_recv->name, ndw_fib[i].name) == ndw_recv->name) //got the FIB item
      {
        dest_id = ndw_fib[i].go_id;

 
        ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));

        memcpy(ndw_send_ptr, ndw_recv, sizeof(ndw_data_t));
        memset(&ndw_send, 0, sizeof(ndw_data_t));

        if (call AMSend.send(dest_id, &packet, sizeof(ndw_data_t)) == SUCCESS)
        {
          send_busy = TRUE; //mark the send queue
          send_count ++;
          energy_count ++;
          dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
          #ifdef DEBUG_PRINT
          printf("FIB forward item %d. %d\n", i, send_count);
          printfflush();
          #endif
          dbg("FIB", "%s FIB forward item %d. %d\n",sim_time_string(), i, send_count);
        }
        // mark in the PIT
        if(pit_active < NDW_PIT_NUM)
        {
          strcpy(ndw_pit[pit_active].name, ndw_recv->name);
          ndw_pit[pit_active].come_id = come_id;
          ndw_pit[pit_active].stale_count = PIT_STALE_COUNT;
          pit_active ++;
          #ifdef DEBUG_PRINT
          printf("PIT mark item %d.\n", pit_active-1);
          printfflush();
          #endif
          dbg("PIT", "%s PIT mark item %d.\n",sim_time_string(), pit_active-1);
        }
        return TRUE;
      }
    }
    return FALSE;
  }

  bool ndw_query_pit_rsp(message_t* msg_recv, ndw_data_t* ndw_recv)
  {
    uint8_t i, j;
    for (i = 0; i < pit_active; ++i)
    {
      if(strcmp(ndw_recv->name, ndw_pit[i].name) == 0)
      {

        ndw_send_ptr = (ndw_data_t*)call Packet.getPayload(&packet, sizeof(ndw_data_t));

        memcpy(ndw_send_ptr, ndw_recv, sizeof(ndw_data_t));

        if (call AMSend.send(ndw_pit[i].come_id, &packet, sizeof(ndw_data_t)) == SUCCESS)
        {
          send_busy = TRUE; //mark the send queue
          send_count ++;
          energy_count ++;
          dbg("ENERGY", "%s ENERGY is %d\n", sim_time_string(), energy_count);
          #ifdef DEBUG_PRINT
          printf("DATA forward a content %d. %d\n", i, send_count);
          printf("PIT clear satisfied item %d.\n", i);
          printfflush();
          #endif
          dbg("DATA", "%s DATA forward a content %d. %d\n",sim_time_string(), i, send_count);
          dbg("PIT", "%s PIT clear satisfied item %d.\n",sim_time_string(), i);
        }

        //clear PIT
        //memset(&ndw_pit[i], 0, sizeof(ndw_pit_item_t));
        for(j = i; j+1 < pit_active; ++j)
        {
          memcpy(&ndw_pit[j], &ndw_pit[j+1], sizeof(ndw_pit_item_t));
        }
        memset(&ndw_pit[j], 0, sizeof(ndw_pit_item_t));
        pit_active--;

        //cache it
        if(cs_active < NDW_CS_NUM)
        {
          strcpy(ndw_cs[cs_active].name, ndw_recv->name);
          strcpy(ndw_cs[cs_active].buf, ndw_recv->buf);
          ndw_cs[cs_active].stale_count = CS_STALE_COUNT;
          cs_active ++;
          #ifdef DEBUG_PRINT
          printf("CS cache content item %d.\n", cs_active-1);
          printfflush();
          #endif
          dbg("CS", "%s CS cache content item %d.\n",sim_time_string(), cs_active-1);
        }
        return TRUE;
      }
    }
    return FALSE;
  }

}