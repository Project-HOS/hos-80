/* ------------------------------------------------------------------------- */
/*  HOS 時間管理 ヘッダファイル                                              */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__TIMER_H_
#define __HOS__TIMER_H_


/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

typedef long DLYTIME;	/* 待ち時間設定用 */

/* 時間管理構造体(リトルエンディアンス４８bit) */
typedef struct t_systime {
	UH  ltime;
	UH  mtime;
	H   utime;
} SYSTIME, CYCTIME, ALMTIME;



/* ------------------------------------ */
/*          グローバル変数              */
/* ------------------------------------ */

extern SYSTIME systim;		/* システムクロック */
extern T_QUE   dlyque;		/* タスク遅延中の待ち行列 */
extern UH      timint;		/* タイマルーチンが呼ばれる間隔 */


/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

void __ini_tim(void);			/* タイマIC初期化 */
void __timer_handler(void);		/* タイマハンドラ */

ER   set_tim(SYSTIME *pk_tim);	/* システムクロック設定 */
ER   get_tim(SYSTIME *pk_tim);	/* システムクロック参照 */
ER   dly_tsk(DLYTIME dlytim);	/* タスク遅延 */

#define vset_tmi(x)  (timint = (x)) /* タイマ間隔の設定 */

/* タスク独立部用定義 */
#define iset_tim  set_tim
#define iget_tim  get_tim


#endif /* __HOS__TIMER_H_ */
