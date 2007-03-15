#include <stdrom.h>
#include <ITRON.h>
#include "sample.h"
#include "defid.h"


/* 秋月電子製 AKI-80 の場合のサンプル */

#define CTC0	0x10
#define CTC1	0x11
#define CTC2	0x12
#define CTC3	0x13


/* スタートアップ（非タスク部）*/
void start_up(void)
{
	/* タイマ設定 */
	vset_tmi(5);		/* 割り込み間隔設定 */
	
	di();
	outp(CTC0,0x90);	/* 割り込みベクタ設定 */
	outp(CTC1,0xa7);	/* 割り込み可,タイマモード,1/256 */ 
	outp(CTC1,192);		/* 5[ms] / ( 1 / 9.8304e6[Hz] * 256) = 192 */
	ei();
	
	/* Ch.1を利用 コンフィギュレータに DEF_INT(0x92, __timer_handler) */
	/* という定義が必要 */

	/* タスクを起動 */
	sta_tsk(TID_TEST1, 1);
	sta_tsk(TID_TEST2, 2);
}


/* タスク１ */
void TestTask1(INT stcd)
{
	/* タスク終了 */
	ext_tsk();
}


/* タスク２ */
void TestTask2(INT stcd)
{
	/* タスク終了 */
	ext_tsk();
}
