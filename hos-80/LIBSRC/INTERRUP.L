/* ------------------------------------------------------------------------- */
/*  HOS 割り込み管理                                                         */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */


-- Ｃ言語部
#include <stdrom.h>
#include <ITRON.h>


-loc_cpu.c
/* 割り込みとディスパッチの禁止 */
ER   loc_cpu(void)
{
#if __ERR_CHECK_LEVEL >= 3
	/* タスク独立部からは呼べない */
	if ( sysstat & TSS_INDP )
		return E_CTX;
#endif
	
	/* 割り込みとディスパッチの禁止 */
	di();
	sysstat = TSS_LOC;
	
	return E_OK;
}


-unl_cpu.c
/* 割り込みとディスパッチの許可 */
ER   unl_cpu(void)
{
#if __ERR_CHECK_LEVEL >= 3
	/* タスク独立部からは呼べない */
	if ( sysstat & TSS_INDP )
		return E_CTX;
#endif

	di();	/* 念のため */
	
	/* 遅延ディスパッチ */
	sysstat = TSS_TSK;
	if ( dlydsp )
		__tsk_dsp();
	ei();
	
	return E_OK;
}



-- アセンブリ言語部(コード)
				cseg

				extrn	sysstat_		; システム状態
				extrn	__tsk_dsp_		; タスクの正規化
				extrn	dlydsp_			; 遅延ディスパッチ用フラグ
				extrn	int_sp_			; 割り込み用sp保存
				extrn	int_cnt_		; 割り込みネスト回数
				extrn	system_stack	; システムスタック(RAMの最後)

-int_def.asz
; -----------------------------------------------
;       デフォルトの割り込みハンドラ 
; -----------------------------------------------
				public	int_default
int_default:
				reti


-int_trap.asz
; -----------------------------------------------
;            割り込みのトラップ
;   iy に呼び出しアドレスが入ってくる
; -----------------------------------------------
				public	int_trap
int_trap:		
		; -------- レジスタ保存
				push	af
				push	bc
				push	de
				push	hl
				push	ix
		; -------- 多重割り込みの判別
				ld		hl,int_cnt_
				bit		7,(hl)
				jp		nz,mul_int
				
		; ======== 最初の割り込み ========
				dec		(hl)
		; -------- システム状態の変更
				ld		hl,sysstat_
				set		2,(hl)
		; -------- スタックポインタの入れ替え
				ld		hl,0
				add		hl,sp
				ld		(int_sp_),hl
				ld		sp,system_stack		; RAM領域の最後
				ei
		; -------- ハンドラ呼び出し
				ld		hl,int_first_ret
				push	hl
				jp		(iy)
				
		; -------- 割り込み復帰
int_first_ret:	
				ld		hl,int_cnt_
				di
				ld		(hl),0
		; -------- スタックポインタ復帰
				ld		hl,(int_sp_)
				ld		sp,hl
		; -------- システム状態変更
int_first_end::	ld		hl,sysstat_
				res		2,(hl)
		; -------- 割り込みの終了
				ld		hl,int_end
				push	hl
				reti					; ハード側に割り込み終了を通知
int_end:		
		; -------- 遅延ディスパッチ
				ld		a,(sysstat_)
				or		a
				jr		nz,int_return
				ld		a,(dlydsp_)
				or		a
				call	nz,__tsk_dsp_		; 遅延ディスパッチ
int_return:		
		; -------- 復帰
				pop		ix
				pop		hl
				pop		de
				pop		bc
				pop		af
				pop		iy
				ei
				ret


		; ======== 多重割り込み ========
mul_int:		
				dec		(hl)
				ei
	; -------- 割り込みハンドラ呼び出し
				ld		hl,int_mul_ret
				push	hl
				jp		(iy)
int_mul_ret:	
				ld		hl,int_cnt_
				di
				inc		(hl)
				pop		ix
				pop		hl
				pop		de
				pop		bc
				pop		af
				pop		iy
				ei
				reti


-- アセンブリ言語部（データ）
				dseg
-int_glb.asz
int_sp_::		ds		2		; 割り込み時の sp 保存用
int_cnt_::		ds		1		; 多重割り込みのカウント(0からデクリメント)
