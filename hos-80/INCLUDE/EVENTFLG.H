/* ------------------------------------------------------------------------- */
/*  HOS イベントフラグヘッダファイル                                         */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__EVENTFLG_H_
#define __HOS__EVENTFLG_H_



/* ------------------------------------ */
/*             定数定義                 */
/* ------------------------------------ */

#define TWF_ANDW  0x00
#define TWF_ORW   0x02
#define TWF_CLR   0x01

/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

/* FCB動的部分 RAMに置く */
typedef struct t_fcb {
	T_QUE que;		/* イベントフラグ待ち行列 */
	UB    flgptn;	/* イベントフラグの状態 */
} T_FCB;

/* FCB静的部分 ROMに置く */
typedef struct t_fcbs {
	VP   exinf;		/* 拡張情報 */
	UB   iflgptn;	/* イベントフラグの初期値 */
} T_FCBS;

/* イベントフラグ状態参照用 */
typedef struct t_rflg {
	VP      exinf;
	BOOL_ID wtsk;
	UB      flgptn;
} T_RFLG;

/* ------------------------------------ */
/*          グローバル変数              */
/* ------------------------------------ */

extern T_FCB  fcbtbl[];		/* FCB配列RAM部 */
extern T_FCBS fcbstbl[];	/* FCB配列ROM部 */
extern UB     fcbcnt;		/* FCB配列の数 */


/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

void __ini_flg(void);		/* イベントフラグ初期化 */
ER   set_flg(ID flgid, UB setptn);	/* イベントフラグセット */
ER   clr_flg(ID flgid, UB clrptn);	/* イベントフラグのクリア */
ER   wai_flg(UB *p_flgptn, ID flgid, UB waiptn, UB wfmode);
									/* イベントフラグ待ち */
ER   pol_flg(UB *p_flgptn, ID flgid, UB waiptn, UB wfmode);
									/* イベントフラグ待ち(ポーリング) */
ER   ref_flg(T_RFLG *pk_rflg, ID flgid);	/* イベントフラグ状態参照 */

/* タスク独立部用定義 */
#define iset_flg  set_flg
#define iclr_flg  clr_flg
#define ipol_flg  pol_flg
#define iref_flg  ref_flg


#endif /* __HOS__EVENTFLG_H_ */
