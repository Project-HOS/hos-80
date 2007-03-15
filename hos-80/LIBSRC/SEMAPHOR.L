/* ------------------------------------------------------------------------- */
/*  HOS セマフォ管理                                                         */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

--共通部
#include <ITRON.h>


-_ini_sem.c
/* セマフォの初期化 */
void __ini_sem(void)
{
	int i;
	
	for ( i = 0; i < scbcnt; i++ ) {
		scbtbl[i].semcnt = scbstbl[i].isemcnt;
		scbtbl[i].que.tskcnt = 0;
	}
}


-sig_sem.c
/* セマフォ返却 */
ER   sig_sem(ID semid)
{
	T_SCB  *scb;
	T_SCBS *scbs;
	T_TCB  *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( semid <= 0 )
		return E_ID;
	if ( semid > scbcnt || scbstbl[semid - 1].maxsem == 0 )
		return E_NOEXS;
#endif
	
	scb  = &scbtbl[semid - 1];
	scbs = &scbstbl[semid - 1];
	
	__set_imsk();
	
#if __ERR_CHECK_LEVEL >= 1
	/* オーバーフローチェック */
	if ( scb->semcnt >= scbs->maxsem ) {
		__res_imsk();
		return E_QOVR;
	}
#endif
	
	if ( scb->que.tskcnt == 0 ) {
		scb->semcnt++;
	}
	else {
		/* キュー先頭の待ち解除 */
		tcb = scb->que.head;
		__wup_dsp(tcb, E_OK);
	}
	
	__res_imsk();
	
	return E_OK;
}


-wai_sem.c
/* セマフォを待つ */
ER   wai_sem(ID semid)
{
	T_SCB  *scb;
	ER     ercd;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( semid <= 0 )
		return E_ID;
	if ( semid > scbcnt || scbstbl[semid - 1].maxsem == 0 )
		return E_NOEXS;
#endif
	
#if __ERR_CHECK_LEVEL >= 3
	if ( sysstat != TSS_TSK )
		return E_CTX;
#endif
	
	scb  = &scbtbl[semid - 1];
	
	__set_imsk();
	
	if ( scb->semcnt > 0 ) {
		scb->semcnt--;
		__res_imsk();
		return E_OK;
	}
	
	/* 待ち状態にする */
	curtcb->tskstat = TTS_WAI;
	curtcb->tskwait = TTW_SEM;
	__del_que(curtcb);
	/* セマフォの待ち行列に追加 */
	__adt_que(&scb->que, curtcb);
	
	/* ディスパッチ */
	ercd = __tsk_dsp();
	
	__res_imsk();
	
	return ercd;
}


-preq_sem.c
/* セマフォを待つ(ポーリング) */
ER   preq_sem(ID semid)
{
	T_SCB  *scb;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( semid <= 0 )
		return E_ID;
	if ( semid > scbcnt || scbstbl[semid - 1].maxsem == 0 )
		return E_NOEXS;
#endif
	
	scb  = &scbtbl[semid - 1];
	
	__set_imsk();
	
	if ( scb->semcnt > 0 ) {
		scb->semcnt--;
		__res_imsk();
		return E_OK;
	}
	
	__res_imsk();
	
	return E_TMOUT;
}


-ref_sem.c
/* セマフォ状態参照 */
ER   ref_sem(T_RSEM *pk_rsem, ID semid)
{
	T_SCB  *scb;
	T_SCBS *scbs;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( semid <= 0 )
		return E_ID;
	if ( semid > scbcnt || scbstbl[semid - 1].maxsem == 0 )
		return E_NOEXS;
#endif
	
	scb  = &scbtbl[semid - 1];
	scbs = &scbstbl[semid - 1];
	
	__set_imsk();

	pk_rsem->exinf = scbs->exinf;
	if ( scb->que.tskcnt == 0 )
		pk_rsem->wtsk = 0;
	else
		pk_rsem->wtsk = (BOOL_ID)(scb->que.head - tcbtbl + 1);
	pk_rsem->semcnt = (INT)scb->semcnt;
	
	__res_imsk();
	
	return E_OK;
}
