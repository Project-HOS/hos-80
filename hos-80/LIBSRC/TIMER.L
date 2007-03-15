/* ------------------------------------------------------------------------- */
/*  HOS  時間管理                                                            */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

-- 共通部
#include <stdrom.h>
#include <ITRON.h>


/* アセンブリ言語部 */
void __add_systim(void);	/* タイマ加算 */
void __add_tim(SYSTIME *pk_tim, DLYTIME *dlytim);	/* 時間加算 */
char __cmp_tim(SYSTIME *pk_tim1, SYSTIME *pk_tim2);	/* 時間比較 */


-_ini_ctc.c
/* グローバル変数 */
SYSTIME  systim;	/* システムクロック */
T_QUE    dlyque;	/* タスク遅延中の待ち行列 */
UH       timint;	/* タイマルーチンが呼ばれる間隔 */


/* タイマ初期化 */
void __ini_tim(void)
{
	/* タイマ用グローバル変数初期化 */
	timint         = 1;		/* デフォルトで1ms */
	dlyque.tskcnt  = 0;
	systim.utime   = 0;
	systim.mtime   = 0;
	systim.ltime   = 0;
}


-_timhndl.c
/* タイマハンドラ */
void __timer_handler(void)
{
	T_TCB *tcb;
	
	/* カウンタの加算 */
	__add_systim();
	
	/* 時間待ちタスクの復帰 */
	while ( dlyque.tskcnt > 0 ) {
		tcb = dlyque.head;
		if ( !__cmp_tim((SYSTIME *)tcb->data, &systim) )
			break;
		di();
		__wup_dsp(tcb, E_OK);
		ei();
	}
	
	ret_int();
}


-set_tim.c
/* システムクロック設定 */
ER   set_tim(SYSTIME *pk_tim)
{
	__set_imsk();
	
	systim = *pk_tim;
	
	__res_imsk();
	
	return E_OK;
}


-get_tim.c
/* システムクロック参照 */
ER   get_tim(SYSTIME *pk_tim)
{
	__set_imsk();

	*pk_tim = systim;

	__res_imsk();

	return E_OK;
}


-dly_tsk.c
/* タスク遅延 */
ER   dly_tsk(DLYTIME dlytim)
{
	SYSTIME st;
	T_TCB *tcb;
	ER    ercd;
	
#if __ERR_CHECK_LEVEL >= 3
	/* タスク独立部やディスパッチ禁止状態では呼べない */
	if ( sysstat != TSS_TSK )
		return E_CTX;
#endif
#if __ERR_CHECK_LEVEL >= 4
	if ( dlytim < 0 )
		return E_PAR;
#endif
	
	__set_imsk();
	
	/* 待ち状態に移行 */
	__del_que(curtcb);
	curtcb->tskstat = TTS_WAI;
	curtcb->tskwait = TTW_DLY;
	
	/* 待ち終了時間計算 */
	st = systim;
	__add_tim(&st, &dlytim);
	curtcb->data = (VP)&st;
	
	/* 時間待ちキューにセット */
	if ( dlyque.tskcnt == 0 ) {
		curtcb->que  = &dlyque;
		curtcb->next = curtcb;
		curtcb->prev = curtcb;
		dlyque.head  = curtcb;
		dlyque.tskcnt++;
	}
	else {
		/* 起床時間順に並べる */
		tcb = dlyque.head;
		for ( ; ; ) {
			tcb = tcb->prev;
			if ( __cmp_tim((SYSTIME *)(tcb->data), &st) ) {
				__ins_que(tcb, curtcb);
				break;
			}
			if ( tcb == dlyque.head ) {
				__adh_que(&dlyque, curtcb);
				break;
			}
		}
	}
	
	
	/* ディスパッチ */
	ercd = __tsk_dsp();
	
	
	__res_imsk();
	
	return ercd;
}




-- アセンブリ言語部
				cseg
				extrn	systim_
				extrn	timint_

-_add_stm.asz
; -----------------------------------------------
;  タイマ加算 (timint_の値を加算する)
;  void __add_systim(void);
; -----------------------------------------------
				public	__add_systim_
__add_systim_:	
				ld		bc,(timint_)		; 割り込み周期 (msec)
				ld		hl,(systim_)
				add		hl,bc
				di
				ld		(systim_),hl
				ret		nc
				ld		hl,(systim_ + 2)
				inc		hl
				ld		(systim_ + 2),hl
				ret		nz
				ld		hl,(systim_ + 4)
				inc		hl
				ld		(systim_ + 4),hl
				ei
				ret


-_add_tim.asz
; -----------------------------------------------------
;  時間加算
;  void __add_tim(SYSTIME *pk_tim, DLYTIME *dlytim);
; -----------------------------------------------------
				public	__add_tim_
__add_tim_:		
				push	ix
				push	hl
				pop		ix
				push	de
				pop		iy
				ld		c,(iy+0)
				ld		b,(iy+1)
				ld		l,(ix+0)
				ld		h,(ix+1)
				add		hl,bc
				ld		(ix+0),l
				ld		(ix+1),h
				ld		c,(iy+2)
				ld		b,(iy+3)
				ld		l,(ix+2)
				ld		h,(ix+3)
				adc		hl,bc
				ld		(ix+2),l
				ld		(ix+3),h
				ld		l,(ix+4)
				ld		h,(ix+5)
				ld		bc,0
				adc		hl,bc
				ld		(ix+4),l
				ld		(ix+5),h
				pop		ix
				ret


-_cmp_tim.asz
; -----------------------------------------------------
;  時間の比較
;  char __cmp_tim(SYSTIME *pk_tim1, SYSTIME *pk_tim2);
;
;  pk_tim1 が pk_time2 以下なら真
; -----------------------------------------------------
				public	__cmp_tim_
__cmp_tim_:		
				ld		bc,5
				add		hl,bc
				ex		de,hl
				add		hl,bc
				ld		b,6
cmp_loop:		ld		a,(de)
				cp		(hl)
				jr		nz,cmp_end
				dec		hl
				dec		de
				djnz	cmp_loop
				jr		cmp_true
cmp_end:		
				jr		c,cmp_true
				xor		a
				ret
cmp_true:		
				ld		a,1
				ret
