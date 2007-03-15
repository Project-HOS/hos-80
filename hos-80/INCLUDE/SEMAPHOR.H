/* ------------------------------------------------------------------------- */
/*  HOS セマフォ管理 ヘッダファイル                                          */
/*                                                Copyright (C) 1998 by Ryuz */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__SEMAPHOR_H_
#define __HOS__SEMAPHOR_H_


/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

/* SCB動的部分 RAMに置く*/
typedef struct t_scb {
	T_QUE que;		/* セマフォ待ち行列 */
	UB    semcnt;	/* セマフォのカウンタ */
} T_SCB;

/* TCB静的部分 ROMに置く */
typedef struct t_scbs {
	VP    exinf;	/* 拡張情報 */
	UB    isemcnt;	/* セマフォの初期値 */
	UB    maxsem;	/* セマフォの最大値 */
} T_SCBS;

/* セマフォ状態参照用 */
typedef struct t_rsem {
	VP      exinf;	/* 拡張情報 */
	BOOL_ID wtsk;	/* 待ちタスクの有無 */
	INT     semcnt;	/* 現在のセマフォカウント値 */
} T_RSEM;



/* ------------------------------------ */
/*          グローバル変数              */
/* ------------------------------------ */

extern T_SCB  scbtbl[];			/* SCB配列RAM部 */
extern T_SCBS scbstbl[];		/* SCB配列ROM部 */
extern UB     scbcnt;			/* SCB配列の数 */


/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

void __ini_sem(void);		/* セマフォの初期化 */
ER   sig_sem(ID semid);		/* セマフォ返却 */
ER   wai_sem(ID semid);		/* セマフォを待つ */
ER   preq_sem(ID semid);	/* セマフォを待つ(ポーリング) */
ER   ref_sem(T_RSEM *pk_rsem, ID semid);	/* セマフォ状態参照 */

/* タスク独立部用定義 */
#define isig_sem  sig_sem
#define ipreq_sem preq_sem
#define iref_sem  ref_sem


#endif /* __ROS__SEMAPHOR_H_ */
