#ifndef NDW_H
#define NDW_H

#define NEW_PRINTF_SEMANTICS
//#define DEBUG_PRINT

#define NAME_LEN			12
#define DATA_BUF_LEN		13

#define NDW_PIT_NUM		6
#define NDW_CS_NUM		6
#define NDW_FIB_NUM		6

//#define PIT_STALE_COUNT		10
//#define CS_STALE_COUNT		10

 enum {
	AM_NDW = 3,
	AM_NDW_BEACON = 6,

	TIMER_PERIOD_REPO = 200,

	CS_STALE_COUNT = 3,
	TIMER_PERIOD_CS = 1000,

	TIMER_PERIOD_PIT = 100,
	PIT_STALE_COUNT = 5,

	FIB_STALE_COUNT = 3,
	TIMER_PERIOD_BEACON = 5000,
	
	NDW_REQ = 1,
	NDW_RSP = 2,
	BEACON_ONBOARD = 1,
	BEACON_NORMAL = 2,
	BEACON_CLASS = 1,
	ENERGY_NUM = 10000,
 };


 typedef struct ndw_repo
{
	unsigned char name[NAME_LEN];
	unsigned char  buf[DATA_BUF_LEN];
}ndw_repo_t;

 typedef struct ndw_beacon
{
	unsigned char name[NAME_LEN];
	uint16_t beacon_id;
	uint8_t beacon_type;
}ndw_beacon_t;

 typedef struct ndw_data
{
	unsigned char name[NAME_LEN];
	uint8_t  datatype;
	unsigned char  buf[DATA_BUF_LEN];
	uint16_t sequence;
}ndw_data_t;

 typedef struct ndw_cs_item
{
	unsigned char name[NAME_LEN];
	unsigned char  buf[DATA_BUF_LEN];
	int8_t  stale_count;
}ndw_cs_item_t;

 typedef struct ndw_pit_item
{
	unsigned char name[NAME_LEN];
	uint16_t come_id;	// last hop
	int8_t stale_count;	// counter to clear pt
}ndw_pit_item_t;

 typedef struct ndw_fib_item
{
	unsigned char name[NAME_LEN];
	uint16_t go_id;	// next hop
	int8_t  stale_count;
}ndw_fib_item_t;



 #endif