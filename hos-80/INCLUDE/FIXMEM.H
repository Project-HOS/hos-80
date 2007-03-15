/* ------------------------------------------------------------------------- */
/*  HOS 固定長メモリプール管理 ヘッダファイル                                */
/*                                                Copyright (C) 1998 by Ryuz */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__FIXMEM_H_
#define __HOS__FIXMEM_H_


/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

/* Fixed-size MemoryPool Controle Block 動的部分 RAMに置く*/
typedef struct t_fmcb {
	T_QUE que;		/* セマフォ待ち行列 */
	VP    freeblk;	/* 空きブロックのアドレス */
} T_FMCB;

/* Fixed-size MemoryPool Controle Block 静的部分 ROMに置く */
typedef struct t_fmcbs {
	VP    exinf;	/* 拡張情報 */
	VP    mpfhead;	/* メモリプール先頭アドレス */
	UH    mpfsz;	/* ブロックサイズ */
	UH    mpfcnt;	/* ブロック数 */
} T_FMCBS;

/* 固定長メモリプール状態参照用 */
typedef struct t_rmpf {
	VP      exinf;	/* 拡張情報 */
	BOOL_ID wtsk;	/* 待ちタスクの有無 */
	INT     frbcnt;	/* 空き領域のブロック数 */
} T_RMPF;



/* ------------------------------------ */
/*          グローバル変数              */
/* ------------------------------------ */

extern T_FMCB  fmcbtbl[];		/* FMCB配列RAM部 */
extern T_FMCBS fmcbstbl[];		/* FMCB配列ROM部 */
extern UB      fmcbcnt;			/* FMCB配列の数 */


/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

void __ini_mpf(void);		/* 固定長メモリプールの初期化 */
ER   get_blf(VP *p_blf, ID mpfid);	/* 固定長メモリブロック獲得 */
ER   pget_blf(VP *p_blf, ID mpfid);	/* 固定長メモリブロック獲得(ポーリング) */
ER   rel_blf(ID mpfid, VP blf);		/* 固定長メモリブロック返却 */
ER   ref_mpf(T_RMPF *pk_rsem, ID mpfid);	/* 固定長メモリプール状態参照 */

/* タスク独立部用定義 */
#define ipget_blf pget_blf
#define irel_blf  rel_blf
#define iref_mpf  ref_mpf


#endif /* __HOS__FIXMEM_H_ */
