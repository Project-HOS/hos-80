/* ------------------------------------------------------------------------- */
/*  HOS タスク管理                                                           */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

-- C 言語部
#include <ITRON.h>


-_ini_tsk.c
/* グローバル変数 */
T_TCB  *curtcb;			/* 現在のタスクのTCB */
BOOL   dlydsp;			/* 遅延されているディスパッチがあるか */


/* タスク部の初期化 */
void __ini_tsk(void)
{
	int i;
	
	curtcb = NADR;
	dlydsp = FALSE;
	
	/* レディーキューの初期化 */
	for ( i = 0; i < rdqcnt; i++ )
		rdyque[i].tskcnt = 0;
	
	/* TCBテーブルの初期化 */
	for ( i = 0; i < tcbcnt; i++ ) {
		if ( tcbstbl[i].itskpri != 0 )
			tcbtbl[i].tskstat = TTS_DMT;
		else 
			tcbtbl[i].tskstat = 0;	/* NON-EXISTENT */
		tcbtbl[i].que = NADR;
	}
}


-sta_tsk.c
/* タスク開始 */
ER sta_tsk(ID tskid, INT stacd)
{
	T_TCB  *tcb;
	T_TCBS *tcbs;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb  = &tcbtbl[tskid - 1];
	tcbs = &tcbstbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* タスク状態チェック */
	if ( tcb->tskstat != TTS_DMT ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* TCBを初期化 */
	tcb->sp      = tcbs->isp;
	tcb->tskpri  = tcbs->itskpri;
	tcb->tskstat = TTS_RDY;
	tcb->wupcnt  = 0;
	tcb->suscnt  = 0;
	
	/* スタックの初期設定 */
	*(--tcb->sp) = (UH)__tskst_entry;	/* リターンアドレス */
	*(--tcb->sp) = (UH)tcbs->task;		/* タスク開始アドレス */
	*(--tcb->sp) = (UH)stacd;			/* 初期化コード */
	
	/* READYキューに追加 */
	__adt_que(&rdyque[tcb->tskpri - 1], tcb);
	
	/* ディスパッチ */
	__tsk_dsp();
	
	__res_imsk();
	
	return E_OK;
}

-- アセンブラ部
				cseg
-_tss_ent.asz
; -----------------------------------------------
;           タスクスタート部分
;     最初のディスパッチ後ここに来る
; -----------------------------------------------
				extrn	ext_tsk_
				public	__tskst_entry_
__tskst_entry_:	
				ld		iy,tse_ret
				push	iy
				ei						; 割り込み許可
				jp		(ix)			; 初期アドレスコール
tse_ret:		jp		ext_tsk_		; タスク終了



-- Ｃ言語部
#include <ITRON.h>


-ext_tsk.c
/* タスク終了 */
void ext_tsk(void)
{
#if __ERR_CHECK_LEVEL >= 4
	/* エラーチェック */
	if ( sysstat != TSS_TSK ) {
		/* 致命的エラーだがリターン出来ない */
		sysstat = TSS_TSK;
	}
#endif
	
	__set_imsk();
	
	if ( curtcb != NADR ) {
		/* キューから外しDOMANT状態に移行 */
		if ( curtcb->que != NADR )
			__del_que(curtcb);
		curtcb->tskstat = TTS_DMT;
		curtcb = NADR;
	}
	
	/* ディスパッチ */
	__tsk_dsp();
}


-ter_tsk.c
/* 他タスク強制終了 */
ER  ter_tsk(ID tskid)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* タスク状態チェック */
	if ( (!(sysstat & TSS_INDP) && tcb == curtcb)
				|| tcb->tskstat == TTS_DMT || tcb->tskstat == TTS_GST ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* タスク終了 */
	if ( tcb->que != NADR )
		__del_que(tcb);
	tcb->tskstat = TTS_DMT;
	if ( curtcb == tcb ) {
		if ( sysstat & TSS_DDSP )
			curtcb->tskstat = TTS_GST;
		else
			curtcb = NADR;
	}
	
	/* ディスパッチ */
	__tsk_dsp();
	
	__res_imsk();
	
	return E_OK;
}


-dis_dsp.c
/* ディスパッチ禁止 */
ER  dis_dsp(void)
{
#if __ERR_CHECK_LEVEL >= 3
	/* エラーチェック */
	if ( sysstat & (TSS_INDP | TSS_DINT) )
		return E_CTX;
#endif
	__set_imsk();
	
	sysstat = TSS_DDSP;
	
	__res_imsk();
	
	return E_OK;
}


-ena_dsp.c
/* ディスパッチ許可 */
ER  ena_dsp(void)
{
#if __ERR_CHECK_LEVEL >= 3
	/* エラーチェック */
	if ( sysstat & (TSS_INDP | TSS_DINT) )
		return E_CTX;
#endif
	
	__set_imsk();
	
	if ( curtcb->tskstat == TTS_GST )
		ext_tsk();	/* 遅延終了 */
	
	/* 遅延ディスパッチ */
	sysstat = TSS_TSK;
	if ( dlydsp )
		__tsk_dsp();
	
	__res_imsk();
	
	return E_OK;
}


-chg_pri.c
/* タスク優先度変更 */
ER  chg_pri(ID tskid, PRI tskpri)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* パラメーターチェック */
	if ( tskid > tcbcnt )
		return E_NOEXS;
	if ( tskid == TSK_SELF && (sysstat & TSS_INDP) )
		return E_ID;
	if ( tskpri > rdqcnt )
		return E_PAR;
#endif
	
	/* ID -> TCB */
	if ( tskid == TSK_SELF )
		tcb = curtcb;
	else
		tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* 状態チェック */
	if ( tcb->tskstat == TTS_DMT ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* 優先度の変更 */
	if ( tskpri == TPRI_INI )
		tcb->tskpri = tcbstbl[tskid - 1].itskpri;
	else
		tcb->tskpri = tskpri;
	if ( tcb->tskstat == TTS_RDY ) {
		/* レディーキューの繋ぎ替え */
		__del_que(tcb);
		__adt_que(&rdyque[tskpri - 1], tcb);
	}
	
	/* ディスパッチ */
	__tsk_dsp();
	
	__res_imsk();
	
	return E_OK;
}


-rot_rdq.c
/* レディーキューの回転 */
ER  rot_rdq(PRI tskpri)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* パラメーターチェック */
	if ( tskpri > rdqcnt )
		return E_PAR;
#endif
	
	__set_imsk();
	
	if ( tskpri == TPRI_RUN ) {
		if ( curtcb == NADR ) {
			__res_imsk();
			return E_OK;	/* タスクが無い場合は何もしない */
		}
		tskpri = curtcb->tskpri;
	}
	
	/* キューにタスクはあるか */
	if ( rdyque[tskpri - 1].tskcnt == 0 ) {
		__res_imsk();
		return E_OK;
	}
	
	/* レディーキュー回転 */
	__rot_que(&rdyque[tskpri - 1]);
	
	/* 必要であればディスパッチを行なう */
	tcb = rdyque[tskpri - 1].head;
	if ( curtcb->tskpri == tskpri && tcb != curtcb ) {
		if ( sysstat == TSS_TSK ) {
			/* ディスパッチ */
			curtcb->tskstat = TTS_RDY;
			tcb->tskstat    = TTS_RUN;
			__swc_dsp(tcb);
		}
		else {
			/* 遅延ディスパッチの準備 */
			dlydsp = TRUE;
		}
	}
	
	__res_imsk();
	
	return E_OK;
}


-rel_wai.c
/* 他タスクの待ち状態解除 */
ER  rel_wai(ID tskid)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* タスク状態チェック */
	if ( !(tcb->tskstat & TTS_WAI) ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* 待ち解除 */
	__wup_dsp(tcb, E_RLWAI);
	
	__res_imsk();
	
	return E_OK;
}


-get_tid.c
/* 自タスクのID参照 */
ER   get_tid(ID *p_tskid)
{
#if __ERR_CHECK_LEVEL >= 4
	if ( (sysstat & TSS_INDP) || curtcb == NADR ) {
		*p_tskid = FALSE;
		return E_OK;
	}
#endif
	
	*p_tskid = (curtcb - tcbtbl) + 1;
	
	return E_OK;
}


-ref_tsk.c
/* タスク状態参照 */
ER   ref_tsk(T_RTSK *pk_rtsk, ID tskid)
{
	T_TCB  *tcb;
	T_TCBS *tcbs;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
	if ( tskid == TSK_SELF && ((sysstat & TSS_INDP) || curtcb == NADR) )
		return E_ID;
#endif
	
	if ( tskid == TSK_SELF )
		tskid = (tcbtbl - curtcb) + 1;
	
	tcb  = &tcbtbl[tskid - 1];
	tcbs = &tcbstbl[tskid - 1];
	
	__set_imsk();
	
	pk_rtsk->exinf   = tcbs->exinf;
	pk_rtsk->tskpri  = tcb->tskpri;
	pk_rtsk->tskstat = tcb->tskstat;
	
	__res_imsk();
	
	return E_OK;
}




-sus_tsk.c
/* 他タスクを強制待ち状態へ移行 */
ER   sus_tsk(ID tskid)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	if ( (!(sysstat & TSS_INDP) && tcb == curtcb)
			|| tcb->tskstat == TTS_DMT ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* 既に SUSPENDならネスト */
	if ( tcb->tskstat & TTS_SUS ) {
#if __ERR_CHECK_LEVEL >= 1
		/* ネストのオーバーフローチェック */
		if ( tcb->suscnt >= MAX_SUSCNT )
			return E_QOVR;
#endif
		tcb->suscnt++;
	}
	else {
		/* SUSPENDさせる */
		if ( tcb->tskstat == TTS_RDY || tcb->tskstat == TTS_RUN )
			__del_que(tcb);		/* READYならレディーキューから外す */
		if ( tcb->tskstat & TTS_WAI )
			tcb->tskstat = TTS_WAS;
		else
			tcb->tskstat = TTS_SUS;
		
		/* タスク独立部で実行中のタスクを指定した場合 */
		if ( tcb == curtcb )
			dlydsp = TRUE;	/* 遅延ディスパッチ設定 */
	}
	
	__res_imsk();
	
	return E_OK;
}


-rsm_tsk.c
/* 強制待ち状態のタスクを再開 */
ER   rsm_tsk(ID tskid)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* エラーチェック */
	if ( tcb == curtcb || !(tcb->tskstat & TTS_SUS) ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	if ( tcb->suscnt != 0 ) {
		/* ネストデクリメント */
		tcb->suscnt--;
	}
	else {
		/* SUSPEND 解除 */
		tcb->tskstat &= ~TTS_SUS;
		if ( tcb->tskstat != TTS_WAI ) {
			/* レディーキューに接続 */
			__adt_que(&rdyque[tcb->tskpri - 1], tcb);
			tcb->tskstat = TTS_RDY;
			
			/* ディスパッチ */
			__tsk_dsp();
		}
	}
	
	__res_imsk();
	
	return E_OK;
}


-frsm_tsk.c
/* 強制待ち状態のタスクを強制再開 */
ER frsm_tsk(ID tskid)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* エラーチェック */
	if ( tcb == curtcb || !(tcb->tskstat & TTS_SUS) ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* 強制解除 */
	tcb->suscnt = 0;
	return rsm_tsk(tskid);
}


-slp_tsk.c
/* 自タスクを起床待ち状態へ移行 */
ER   slp_tsk(void)
{
	ER ercd;
	
#if __ERR_CHECK_LEVEL >= 3
	/* エラーチェック */
	if( sysstat != 0 )
		return E_CTX;
#endif
	
	__set_imsk();
	
	/* 起床要求のキューイングがあるか */
	if ( curtcb->wupcnt > 0 ) {
		curtcb->wupcnt--;
		__res_imsk();
		return E_OK;
	}
	
	/* 待ち状態に移行 */
	__del_que(curtcb);
	curtcb->tskstat = TTS_WAI;
	curtcb->tskwait = TTW_SLP;
	
	/* ディスパッチ */
	ercd = __tsk_dsp();
	
	__res_imsk();
	
	return ercd;
}


/* 他タスクの起床 */
ER   wup_tsk(ID tskid)
{
	T_TCB *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* ID チェック */
	if ( tskid <= 0 )
		return E_ID;
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
#endif
	
	tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 2
	/* 状態チェック */
	if ( tcb == curtcb || tcb->tskstat == TTS_DMT ) {
		__res_imsk();
		return E_OBJ;
	}
#endif
	
	/* 待ち状態でなければキューイング */
	if ( !(tcb->tskstat & TTS_WAI) || tcb->tskwait != TTW_SLP ) {
#if __ERR_CHECK_LEVEL >= 1
		if ( tcb->wupcnt == MAX_WUPCNT ) {
			__res_imsk();
			return E_QOVR;
		}
#endif
		tcb->wupcnt++;
	}
	else {
		/* 待ち解除 */
		tcb->tskstat &= ~TTS_WAI;
		tcb->tskwait  = 0;
		*(tcb->sp)    = E_OK;
		if ( tcb->tskstat != TTS_SUS ) {
			/* レディーキューに接続 */
			tcb->tskstat = TTS_RDY;
			__adt_que(&rdyque[tcb->tskpri - 1], tcb);
			
			/* ディスパッチ */
			__tsk_dsp();
		}
	}
	
	__res_imsk();
	
	return E_OK;
}


-can_wup.c
/* タスク起床要求を無効化 */
ER   can_wup(ID tskid)
{
	T_TCB *tcb;
	INT   wupcnt;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( tskid > tcbcnt || tcbtbl[tskid - 1].tskstat == 0 )
		return E_NOEXS;
	if ( tskid == TSK_SELF && (sysstat & TSS_INDP) )
		return E_ID;
#endif
	
	if ( tskid == TSK_SELF )
		tcb = curtcb;
	else
		tcb = &tcbtbl[tskid - 1];
	
	__set_imsk();
	
	wupcnt = tcb->wupcnt;
	tcb->wupcnt = 0;
	
	__res_imsk();
	
	return wupcnt;
}

