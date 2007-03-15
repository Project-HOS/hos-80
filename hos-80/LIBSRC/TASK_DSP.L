/* ------------------------------------------------------------------------- */
/*  HOS タスクディスパッチ処理                                               */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

-- C 言語部
#include <ITRON.h>


-_wup_dsp.c
/* 待ち状態解除 */
void __wup_dsp(T_TCB *tcb, ER ercd)
{
	/* 待ち状態解除 */
	tcb->tskstat &= ~TTS_WAI;
	tcb->tskwait  = 0;
	*(tcb->sp)    = (UH)ercd;
	if ( tcb->que != NADR )
		__del_que(tcb);
	
	if ( !(tcb->tskstat & TTS_SUS) ) {
		/* レディーキューへ接続 */
		tcb->tskstat = TTS_RDY;
		__adt_que(&rdyque[tcb->tskpri - 1], tcb);
		
		/* ディスパッチ */
		__tsk_dsp();
	}
}



-- アセンブリ言語部
				cseg

				extrn	sysstat_
				extrn	curtcb_
				extrn	dlydsp_
				extrn	rdqcnt_
				extrn	rdyque_

-tsk_dsp.asz
; ER __tsk_dsp(void)
				public	__tsk_dsp_
__tsk_dsp_:		
			; システム状態チェック
				ld		a,(sysstat_)
				or		a
				jr		z,ss_ok
				ld		a,1
				ld		(dlydsp_),a
				ld		hl,0
				ret
ss_ok:			
			; タスク遅延フラグクリア
				ld		(dlydsp_),a		; aは０
				
			; 次のタスクを検索
				ld		hl,rdqcnt_
				ld		b,(hl)
				ld		hl,rdyque_
				ld		de,03h			; rdyque のサイズ
				xor		a
search_task:	
				cp		(hl)
				jr		nz,found_task		; 発見！
				add		hl,de
				djnz	search_task
				jp		no_task			; タスクなし

			; タスクを切り替える
found_task:		
				inc		hl
				ld		a,(hl)
				inc		hl
				ld		h,(hl)
				ld		l,a
				
			; curtcb == NADR チェック
				ld		bc,(curtcb_)
				inc		b
				jr		nz,curtcb_exs
				inc		c
				jr		z,curtcb_noexs

			; タスクを切り替える
curtcb_exs:		
				ld		iy,(curtcb_)
				ld		(iy+2),02h		; curtcb->tskstat = TTS_RDY
				push	hl
				pop		iy
				ld		(iy+2),01h		; tcb->tskstat = TTS_RUN
				call	__swc_dsp_##
				ret
				
			; タスクスタート
curtcb_noexs:	
				push	hl
				pop		iy
				ld		(iy+2),01h		; tskstat = TTS_RUN
				ld		(curtcb_),hl
				jp		__sta_dsp_##

			; 次のタスクが無い場合
no_task:		
				ld		a,0ffh
				ld		iy, curtcb_
				cp		(iy)
				jr		nz,tsk_end
				cp		(iy+1)
				jp		z,__tsk_hlt_##
tsk_end:		
				call	__end_dsp_##
				ret


-_swc_dsp.asz
; -----------------------------------------------
;  タスク切り替え
;  H   __swc_dsp(T_TCB *tcb);
;
;  呼び出し前に割り込みを禁止すること
;  LSIC-80の呼び出しに準拠してix以外は保存しない
;  待ちからの復帰などで返り値が要る場合はスタック
;  上の値を書き換えておく
; -----------------------------------------------
				public	__swc_dsp_
__swc_dsp_:		
				push	ix
				push	hl
				ld		hl,0
				add		hl,sp
				ld		ix,(curtcb_)
				ld		(ix+0),l			; sp 保存
				ld		(ix+1),h
				pop		hl
				ld		(curtcb_),hl		; 新tcb登録
				ld		a,(hl)
				inc		hl
				ld		h,(hl)
				ld		l,a
				ld		sp,hl				; sp 復帰
				pop		hl					; リターンパラメータ
				pop		ix
				ret


-_sta_dsp.asz
; -----------------------------------------------
; タスクの復帰
; void __sta_dsp(T_TCB *tcb);
;
; 何もタスクの動いてない状態からのディスパッチ
; 呼び出し元には戻らない
; -----------------------------------------------
				public	__sta_dsp_
__sta_dsp_:		
				ld		a,(hl)
				inc		hl
				ld		h,(hl)
				ld		l,a
				ld		sp,hl				; sp 復帰
				pop		hl					; リターンパラメータ
				pop		ix
				ret


-_end_dsp.asz
; -----------------------------------------------
; タスクの停止
; H    __end_dsp(void);
;
; 次に動くタスクが無い場合のディスパッチ
; -----------------------------------------------
				public	__end_dsp_
__end_dsp_:		
				push	ix
				push	hl				; リターンパラメーター用
				ld		hl,0
				add		hl,sp
				ld		ix,(curtcb_)
				ld		(ix+0),l		; sp 保存
				ld		(ix+1),h
				jp		__tsk_hlt_##


-_tsk_hlt.asz
; -----------------------------------------------
;        HALT (レディーキューにタスクが無い)
; -----------------------------------------------
				public	__tsk_hlt_
__tsk_hlt_:		
				ld		hl,0ffffh		; NADR
				ld		(curtcb_),hl
				ld		sp,system_sp
				ei
				jr		$	; 本物のHALTはMPUによってCTCが止まる

				dseg
system_stack:	ds		32
system_sp		equ		$

