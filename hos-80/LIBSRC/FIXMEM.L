/* ------------------------------------------------------------------------- */
/*  HOS 固定長メモリプール管理                                               */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

--共通部
#include <ITRON.h>


/* -------------------------------------------------------------- */
/*  固定メモリプールは空きブロックの先頭部分を使って空きブロック  */
/*  のリストを作ることによって管理する。リストに連結されていない  */
/*  部分が使用中である                                            */
/* -------------------------------------------------------------- */


-_ini_mpf.c
/* 固定長メモリプールの初期化 */
void __ini_mpf(void)
{
	UB i;
	UH j;
	UH cnt;
	UH sz;
	UB *blk;
	
	for ( i = 0; i < fmcbcnt; i++ ) {
		fmcbtbl[i].que.tskcnt = 0;
		fmcbtbl[i].freeblk = fmcbstbl[i].mpfhead;
		blk = (UB *)fmcbstbl[i].mpfhead;
		cnt = fmcbstbl[i].mpfcnt - 1;
		sz  = fmcbstbl[i].mpfsz;
		for ( j = 0; j < cnt; j++ ) {
			*(VP *)blk = (VP)(blk + sz);
			blk += sz;
		}
		*(VP *)blk = NADR;
	}
}


-get_blf.c
/* 固定長メモリブロック獲得 */
ER get_blf(VP *p_blf, ID mpfid)
{
	T_FMCB  *fmcb;
	T_FMCBS *fmcbs;
	ER      ercd;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mpfid <= 0 )
		return E_ID;
	if ( mpfid > fmcbcnt || fmcbstbl[mpfid - 1].mpfcnt == 0 )
		return E_NOEXS;
#endif
	
#if __ERR_CHECK_LEVEL >= 3
	if ( sysstat != TSS_TSK )
		return E_CTX;
#endif
	
	fmcb  = &fmcbtbl[mpfid - 1];
	fmcbs = &fmcbstbl[mpfid - 1];
	
	__set_imsk();
	
	/* メモリがあるなら割り当てる */
	if ( fmcb->freeblk != NADR ) {
		*p_blf = fmcb->freeblk;
		fmcb->freeblk = *(VP *)fmcb->freeblk;
		
		__res_imsk();
		
		return E_OK;
	}
	
	/* 待ち状態にする */
	curtcb->tskstat = TTS_WAI;
	curtcb->tskwait = TTW_SEM;
	__del_que(curtcb);
	/* 固定長メモリプールの待ち行列に追加 */
	__adt_que(&fmcb->que, curtcb);
	
	/* ディスパッチ */
	ercd = __tsk_dsp();
	
	/* メモリブロックセット */
	*p_blf = curtcb->data;	/* ercd == E_OK なら data にアドレスが入る */
	
	__res_imsk();
	
	return ercd;
}


-pget_blf.c
/* 固定長メモリブロック獲得（ポーリング） */
ER pget_blf(VP *p_blf, ID mpfid)
{
	T_FMCB  *fmcb;
	T_FMCBS *fmcbs;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mpfid <= 0 )
		return E_ID;
	if ( mpfid > fmcbcnt || fmcbstbl[mpfid - 1].mpfcnt == 0 )
		return E_NOEXS;
#endif
	
	fmcb  = &fmcbtbl[mpfid - 1];
	fmcbs = &fmcbstbl[mpfid - 1];
	
	__set_imsk();
	
	/* 空きメモリが無ければ失敗 */
	if ( fmcb->freeblk == NADR ) {
		__res_imsk();
		return E_TMOUT;
	}
	
	/* メモリがあるなら割り当てる */
	*p_blf = fmcb->freeblk;
	fmcb->freeblk = *(VP *)fmcb->freeblk;
	
	__res_imsk();
	
	return E_OK;
}


-rel_blf.c
/* 固定長メモリブロック返却 */
ER rel_blf(ID mpfid, VP blf)
{
	T_FMCB  *fmcb;
	T_FMCBS *fmcbs;
	T_TCB   *tcb;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mpfid <= 0 )
		return E_ID;
	if ( mpfid > fmcbcnt || fmcbstbl[mpfid - 1].mpfcnt == 0 )
		return E_NOEXS;
#endif
	
	fmcb  = &fmcbtbl[mpfid - 1];
	fmcbs = &fmcbstbl[mpfid - 1];
	
	__set_imsk();
	
	if ( fmcb->que.tskcnt == 0 ) {
		/* 待ちタスクが無ければメモリ開放 */
		*(VP *)blf    = fmcb->freeblk;
		fmcb->freeblk = blf;
	}
	else {
		/* 待ちタスクにメモリを渡して待ち解除 */
		tcb = fmcb->que.head;
		tcb->data = blf;
		__wup_dsp(tcb, E_OK);
	}
	
	__res_imsk();
	
	return E_OK;
}


-ref_mpf.c
/* 固定長メモリプール状態参照 */
ER ref_mpf(T_RMPF *pk_rsem, ID mpfid)
{
	T_FMCB  *fmcb;
	T_FMCBS *fmcbs;
	UH  cnt;
	VP  adr;
	
#if __ERR_CHECK_LEVEL >= 4
	if ( mpfid <= 0 )
		return E_ID;
	if ( mpfid > fmcbcnt || fmcbstbl[mpfid - 1].mpfcnt == 0 )
		return E_NOEXS;
#endif
	
	fmcb  = &fmcbtbl[mpfid - 1];
	fmcbs = &fmcbstbl[mpfid - 1];
	
	__set_imsk();
	
	/* 空きブロックカウント */
	cnt = 0;
	adr = fmcb->freeblk;
	while ( adr != NADR ) {
		adr = *(VP *)adr;
		cnt++;
	}
	
	/* 待ちタスクＩＤの取得 */
	if ( fmcb->que.tskcnt == 0 )
		pk_rsem->wtsk = FALSE;
	else
		pk_rsem->wtsk = fmcb->que.head - tcbtbl + 1;
	
	__res_imsk();
	
	pk_rsem->exinf  = fmcbs->exinf;	/* 拡張情報 */
	pk_rsem->frbcnt = cnt;			/* 空きメモリ数 */
	
	return E_OK;
}

