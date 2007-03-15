/* ------------------------------------------------------------------------- */
/*  HOS タスク管理                                                           */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

-- 共通部
#include <ITRON.h>


/* イベントフラグ待ち状態 */
typedef struct t_wflg_stat {
	UB  waiptn;	/* 待ちビットパターン */
	UB  wfmode;	/* 待ちモード */
} T_WFLG_STAT;


/* フラグのチェック */
BOOL __chk_flg(T_FCB *fcb, T_WFLG_STAT *wflg_stat);


-_ini_flg.c
/* イベントフラグ初期化 */
void __ini_flg(void)
{
	int i;
	
	for ( i = 0; i < fcbcnt; i++ ) {
		fcbtbl[i].flgptn     = fcbstbl[i].iflgptn;
		fcbtbl[i].que.tskcnt = 0;
	}
}


-set_flg.c
/* イベントフラグセット */
ER   set_flg(ID flgid, UB setptn)
{
	T_FCB *fcb;
	T_TCB *tcb;
	UB    old_syssat;
	BOOL  reqdsp;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( flgid <= 0 )
		return E_ID;
	if ( flgid > fcbcnt )
		return E_NOEXS;
#endif
	
	fcb = &fcbtbl[flgid - 1];
	
	__set_imsk();
	
	/* フラグセット */
	fcb->flgptn |= setptn;
	
	/* 待ちのタスクのチェック */
	if ( fcb->que.tskcnt > 0 ) {
		/* 一時的にディスパッチを禁止 */
		old_syssat = sysstat;
		sysstat   |= TSS_DDSP;
		reqdsp = FALSE;
		
		/* フラグの一致するタスクを全て起床 */
		tcb = fcb->que.head;
		do {
			if ( __chk_flg(fcb, (T_WFLG_STAT *)tcb->data) ) {
				__wup_dsp(tcb, E_OK);
				reqdsp = TRUE;
			}
			tcb = tcb->next;
		} while ( tcb != fcb->que.head );
		
		/* 状態復帰 */
		sysstat = old_syssat;
		
		/* 起床したタスクがあるならディスパッチ */
		if ( reqdsp )
			__tsk_dsp();
	}
	
	__res_imsk();
	
	return E_OK;
}


-clr_flg.c
/* イベントフラグのクリア */
ER   clr_flg(ID flgid, UB clrptn)
{
	T_FCB *fcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( flgid <= 0 )
		return E_ID;
	if ( flgid > fcbcnt )
		return E_NOEXS;
#endif
	
	fcb = &fcbtbl[flgid - 1];
	
	__set_imsk();
	
	/* フラグクリア */
	fcb->flgptn &= clrptn;
	
	__res_imsk();
	
	return E_OK;
}


-wai_flg.c
/* イベントフラグ待ち */
ER   wai_flg(UB *p_flgptn, ID flgid, UB waiptn, UB wfmode)
{
	T_WFLG_STAT wflg_stat;
	T_FCB  *fcb;
	INT    ercd;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( flgid <= 0 )
		return E_ID;
	if ( flgid > fcbcnt )
		return E_NOEXS;
	if ( wfmode > 3 || waiptn == 0 )
		return E_PAR;
#endif
	
	fcb = &fcbtbl[flgid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 3
	/* 状態チェック */
	if ( sysstat != 0 ) {
		__res_imsk();
		return E_CTX;
	}
#endif
	
	/* フラグチェック */
	wflg_stat.waiptn = waiptn;
	wflg_stat.wfmode = wfmode;
	if ( __chk_flg(fcb, &wflg_stat) ) {
		__res_imsk();
		return E_OK;
	}
	
	/* 待ち状態に移行 */
	__del_que(curtcb);
	curtcb->tskstat = TTS_WAI;
	curtcb->tskwait = TTW_FLG;
	curtcb->data    = (VP)&wflg_stat;
	__adt_que(&fcb->que, curtcb);
	
	/* ディスパッチ */
	ercd = __tsk_dsp();
	
	if ( p_flgptn != NADR )
		*p_flgptn = fcb->flgptn;
	
	__res_imsk();
	
	return ercd;
}


-pol_flg.c
/* イベントフラグ待ち(ポーリング) */
ER   pol_flg(UB *p_flgptn, ID flgid, UB waiptn, UB wfmode)
{
	T_WFLG_STAT wflg_stat;
	T_FCB  *fcb;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( flgid <= 0 )
		return E_ID;
	if ( flgid > fcbcnt )
		return E_NOEXS;
	if ( wfmode > 3 || waiptn == 0 )
		return E_PAR;
#endif
	
	fcb = &fcbtbl[flgid - 1];
	
	__set_imsk();
	
	/* フラグチェック */
	wflg_stat.waiptn = waiptn;
	wflg_stat.wfmode = wfmode;
	if ( __chk_flg(fcb, &wflg_stat) ) {
		if ( p_flgptn != NADR )
			*p_flgptn = fcb->flgptn;
		__res_imsk();
		return E_OK;
	}
	
	__res_imsk();
	
	return E_TMOUT;
}


-ref_flg.c
/* イベントフラグ状態参照 */
ER   ref_flg(T_RFLG *pk_rflg, ID flgid)
{
	T_FCB  *fcb;
	T_FCBS *fcbs;
	
#if __ERR_CHECK_LEVEL >= 4
	/* IDチェック */
	if ( flgid <= 0 )
		return E_ID;
	if ( flgid > fcbcnt )
		return E_NOEXS;
#endif
	
	fcb  = &fcbtbl[flgid - 1];
	fcbs = &fcbstbl[flgid - 1];
	
	__set_imsk();
	
	pk_rflg->exinf = fcbs->exinf;
	if ( fcb->que.tskcnt == 0 )
		pk_rflg->wtsk = 0;
	else
		pk_rflg->wtsk = (BOOL_ID)(fcb->que.head - tcbtbl + 1);
	pk_rflg->flgptn = fcb->flgptn;
	
	__res_imsk();
	
	return E_OK;
}


-_chk_flg.c
/* フラグのチェック */
BOOL __chk_flg(T_FCB *fcb, T_WFLG_STAT *wflg_stat)
{
	/* フラグチェック */
	if ( wflg_stat->wfmode & TWF_ORW ) {
		if ( !(fcb->flgptn & wflg_stat->waiptn) )
			return FALSE;
	}
	else {
		if ( (fcb->flgptn & wflg_stat->waiptn) != wflg_stat->waiptn )
			return FALSE;
	}
	
	/* TWF_CLRが指定されていればフラグをクリア */
	if ( wflg_stat->wfmode & TWF_CLR )
		fcb->flgptn = 0;
	
	return TRUE;
}

