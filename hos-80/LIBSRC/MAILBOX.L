/* ------------------------------------------------------------------------- */
/*  HOS メイルボックス管理                                                   */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */


--Ｃ言語部
#include <ITRON.h>


-_ini_mbx.c
/* メイルボックス初期化 */
void __ini_mbx(void)
{
	int i;
	
	for ( i = 0; i < mcbcnt; i++ ) {
		mcbtbl[i].que.tskcnt = 0;
		mcbtbl[i].head = mcbstbl[i].bufhead;
		mcbtbl[i].tail = mcbstbl[i].bufhead;
	}
}


-snd_msg.c
/* メイルボックスへ送信 */
ER   snd_msg(ID mbxid, VP pk_msg)
{
	T_MCB  *mcb;
	T_MCBS *mcbs;
	T_TCB  *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mbxid <= 0 )
		return E_ID;
	if ( mbxid > mcbcnt )
		return E_NOEXS;
#endif
	
	mcb  = &mcbtbl[mbxid - 1];
	mcbs = &mcbstbl[mbxid - 1];
	
	__set_imsk();
	
	if ( mcb->que.tskcnt == 0 ) {
		/* 待ちタスクが無ければメッセージキューに追加 */
		mcb->tail++;
		if ( mcb->tail >= mcbs->buftail )
			mcb->tail = mcbs->bufhead;
#if __ERR_CHECK_LEVEL >= 1
		/* オーバーフローチェック */
		if ( mcb->head == mcb->tail ) {
			mcb->tail--;
			return E_QOVR;
		}
#endif
		/* バッファにデータを格納 */
		*mcb->tail = pk_msg;
	}
	else {
		/* 待ちタスク起床 */
		tcb = mcb->que.head;
		tcb->data = pk_msg;
		__wup_dsp(tcb, E_OK);
	}
	
	__res_imsk();
	
	return E_OK;
}


-rcv_msg.c
/* メイルボックスから受信 */
ER   rcv_msg(VP *pk_msg, ID mbxid)
{
	T_MCB  *mcb;
	T_MCBS *mcbs;
	ER     ercd;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mbxid <= 0 )
		return E_ID;
	if ( mbxid > mcbcnt )
		return E_NOEXS;
#endif
#if __ERR_CHECK_LEVEL >= 3
	if ( sysstat != TSS_TSK )
		return E_CTX;
#endif
	
	mcb  = &mcbtbl[mbxid - 1];
	mcbs = &mcbstbl[mbxid - 1];
	
	__set_imsk();
	
	/* メッセージがあれば取り出す */
	if ( mcb->head != mcb->tail ) {
		mcb->head++;
		if ( mcb->head >= mcbs->buftail )
			mcb->head = mcbs->bufhead;
		*pk_msg = *mcb->head;
		__res_imsk();
		return E_OK;
	}

	/* 待ち状態に移行 */
	curtcb->tskstat = TTS_WAI;
	curtcb->tskwait = TTW_MBX;
	
	/* 待ち行列に追加 */
	__del_que(curtcb);
	__adt_que(&mcb->que, curtcb);
	
	/* ディスパッチ */
	ercd = __tsk_dsp();
	*pk_msg = curtcb->data;
	
	__res_imsk();
	
	return ercd;
}


-prcv_msg.c
/* メイルボックスから受信(ポーリング) */
ER   prcv_msg(VP *pk_msg, ID mbxid)
{
	T_MCB  *mcb;
	T_MCBS *mcbs;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mbxid <= 0 )
		return E_ID;
	if ( mbxid > mcbcnt )
		return E_NOEXS;
#endif
	
	mcb  = &mcbtbl[mbxid - 1];
	mcbs = &mcbstbl[mbxid - 1];
	
	__set_imsk();
	
	/* メッセージの存在チェック */
	if ( mcb->head == mcb->tail ) {
		__res_imsk();
		return E_TMOUT;
	}
	
	/* メッセージを取り出す */
	mcb->head++;
	if ( mcb->head >= mcbs->buftail )
		mcb->head = mcbs->bufhead;
	*pk_msg   = *mcb->head;
	
	__res_imsk();
	
	return E_OK;
}


-ref_mbx.c
/* メイルボックス状態参照 */
ER   ref_mbx(T_RMBX *pk_rmbx, ID mbxid)
{
	T_MCB  *mcb;
	T_MCBS *mcbs;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mbxid <= 0 )
		return E_ID;
	if ( mbxid > mcbcnt )
		return E_NOEXS;
#endif
	
	mcb  = &mcbtbl[mbxid - 1];
	mcbs = &mcbstbl[mbxid - 1];
	
	__set_imsk();
	
	pk_rmbx->exinf = mcbs->exinf;
	if ( mcb->que.tskcnt > 0 )
		pk_rmbx->wtsk = tcbtbl - mcb->que.head + 1;
	else
		pk_rmbx->wtsk = 0;
	pk_rmbx->pk_msg = *mcb->head;
	
	__res_imsk();
	
	return E_OK;
}
