/* ------------------------------------------------------------------------- */
/*  HOS タスク管理 ヘッダファイル                                            */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__TAKS_H_
#define __HOS__TAKS_H_


/* ------------------------------------ */
/*             定数定義                 */
/* ------------------------------------ */

/* タスク属性 */
#define TA_ASM   0x0000		/* アセンブラによるプログラム */
#define TA_HLNG  0x0001		/* 高級言語によるプログラム */
#define TA_COP0  0x8000
#define TA_COP1  0x4000
#define TA_COP2  0x2000
#define TA_COP3  0x1000
#define TA_COP4  0x0800
#define TA_COP5  0x0400
#define TA_COP6  0x0200
#define TA_COP7  0x0100

/* 引数となるパラメーター */
#define TSK_SELF      0		/* 自分自身のタスク */
#define TPRI_INI      0		/* 初期優先度を指定 */
#define TPRI_RUN      0		/* 自分自身の優先度 */

/* タスク状態定義 */
#define TTS_RUN  0x01		/* 実行状態 */
#define TTS_RDY  0x02		/* 実行可能状態 */
#define TTS_WAI  0x04		/* 待ち状態 */
#define TTS_SUS  0x08		/* 強制待ち状態 */
#define TTS_WAS  0x0c		/* 二重待ち状態 */
#define TTS_DMT  0x10		/* 休止状態 */
#define TTS_GST  0x90		/* ゴースト状態 (tar_tsk 遅延中) */

/* 待ち状態 */
#define TTW_SLP  0x0001		/* slp_tsk, tslp_tsk による待ち */
#define TTW_DLY  0x0002		/* dly_tsk による待ち */
#define TTW_NOD  0x0008		/* 接続機能応答待ち */
#define TTW_FLG  0x0010		/* wai_flg, twai_flg による待ち */
#define TTW_SEM  0x0020		/* wai_sem, twai_sem による待ち */
#define TTW_MBX  0x0040		/* rcv_msg, trcv_msg による待ち */
#define TTW_SMBF 0x0080		/* snd_mbf, tsnd_mbf による待ち */
#define TTW_MBF  0x0100		/* rcv_mbf, trcv_mbf による待ち */
#define TTW_CAL  0x0200		/* ランデブ呼出し待ち */
#define TTW_ACP  0x0400		/* ランデブ受付け待ち */
#define TTW_RDV  0x0800		/* ランデブ終了待ち */
#define TTW_MPL  0x1000		/* get_blk, tget_blk による待ち */
#define TTW_MPF  0x2000		/* get_blf, tget_blf による待ち */

/* TCB関連の定数 */
#define MAX_SUSCNT  255		/* SUSPEND 最大ネスト数 */
#define MAX_WUPCNT  255		/* 起床要求 最大キューイング数 */



/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

/* タスク管理用キュー */
typedef struct t_que {
	UB     tskcnt;			/* キューに並んでいるタスクの数 */
	struct t_tcb *head;		/* キューの先頭 */
} T_QUE;

/* TCB(タスクコントロールブロック) 動的部分 RAMに置く */
/* アセンブラで操作するものは先頭に置く */
typedef struct t_tcb {
	VH   *sp;			/* 現在のスタックポインタ */
	UB   tskstat;		/* タスクの状態 */
	PRI  tskpri;		/* 現在の優先度 */
	UINT tskwait;		/* 待ち状態 */
	UB   wupcnt;		/* 起床要求キューイング数 */
	UB   suscnt;		/* SUSPEND要求ネスト数 */
	VP   data;			/* 状態毎に保存の必要なデータがあれば使う */
	struct t_que *que;	/* 属しているキュー  */
	struct t_tcb *next;	/* キューでの次のTCB */
	struct t_tcb *prev;	/* キューでの前のTCB */
} T_TCB;

/* TCB静的部分 ROMに置く */
typedef struct t_tcbs {
	VP   exinf;			/* 拡張情報 */
	FP   task;			/* タスク起動アドレス */
	PRI  itskpri;		/* タスク起動時優先度 */
	VH   *isp;			/* タスク起動時のスタックポインタの値*/
} T_TCBS;

/* タスク状態参照用 */
typedef struct t_rtsk {
	VP   exinf;			/* 拡張情報 */
	PRI  tskpri;		/* 現在の優先度 */
	UB   tskstat;		/* タスク状態 */
} T_RTSK;



/* ------------------------------------ */
/*          グローバル変数              */
/* ------------------------------------ */

extern T_TCB  tcbtbl[];		/* TCBテーブル RAM部 */
extern T_TCBS tcbstbl[];	/* TCBテーブル ROM部（静的に生成) */
extern UB     tcbcnt;		/* TCBテーブルの数 */

extern T_QUE  rdyque[];		/* レディーキュー */
extern UB     rdqcnt;		/* レディーキューの数 */

extern T_TCB  *curtcb;			/* 現在のタスクのTCB */
extern BOOL   dlydsp;			/* 遅延されているディスパッチがあるか */



/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

/* キュー管理 */
void __adt_que(T_QUE *que, T_TCB *tcb);		/* タスクをキュー末尾に追加 */
void __adh_que(T_QUE *que, T_TCB *tcb);		/* タスクをキュー先頭に追加 */
void __ins_que(T_TCB *tcbs, T_TCB *tcbd);	/* キューにタスクを挿入 */
void __del_que(T_TCB *tcb);					/* タスクをキューから外す */
void __rot_que(T_QUE *que);					/* キューの回転 */

/* タスク管理 */
void __ini_tsk(void);						/* タスク部の初期化 */
ER   sta_tsk(ID tskid, INT stacd);			/* タスク起動 */
void ext_tsk(void);							/* 自タスク終了 */
ER   ter_tsk(ID tskid);						/* 他タスク強制終了 */
ER   dis_dsp(void);							/* ディスパッチ禁止 */
ER   ena_dsp(void);							/* ディスパッチ許可 */
ER   chg_pri(ID tskid, PRI tskpri);			/* タスク優先度変更 */
ER   rot_rdq(PRI tskpri);					/* タスクのレディーキュー回転 */
ER   rel_wai(ID tskid);						/* 他タスクの待ち状態解除 */
ER   get_tid(ID *p_tskid);					/* 自タスクのID参照 */
ER   ref_tsk(T_RTSK *pk_rtsk, ID tskid);	/* タスク状態参照 */

/* タスク独立部用定義 */
#define ista_tsk  sta_tsk
#define iter_tsk  ter_tsk
#define ichg_pri  chg_pri
#define irot_rdq  rot_rdq
#define irel_wai  rel_wai
#define iget_tid  get_tid
#define iref_tsk  ref_tsk


/* タスク付属同期 */
ER   sus_tsk(ID tskid);
ER   rsm_tsk(ID tskid);
ER   frsm_tsk(ID tskid);
ER   slp_tsk(void);
ER   wup_tsk(ID tskid);
ER   can_wup(ID tskid);

/* タスク独立部用定義 */
#define isus_tsk  sus_tsk
#define irsm_tsk  rsm_tsk
#define ifrsm_tsk frsm_tsk
#define iwup_tsk  wup_tsk
#define ican_wup  can_wup


/* ディスパッチ処理 */
ER   __tsk_dsp(void);					/* タスクディスパッチ */
void __wup_dsp(T_TCB *tcb, ER ercd);	/* 待ち状態解除 */
H    __swc_dsp(T_TCB *tcb);		/* タスクの切り替え */
void __sta_dsp(T_TCB *tcb);		/* タスクの開始（リターンしない) */
H    __end_dsp(void);			/* タスクの終了 */
void __tskst_entry(void);		/* タスク実行開始のエントリーポイント */
void __tsk_hlt(void);			/* 実行タスクなし */


/* システムコール内での割り込み制御 */
void _asm_set_imsk(char *s);
void _asm_res_imsk(char *s);
#define __set_imsk()  _asm_set_imsk("\n\tdi\n")
#define __res_imsk()  _asm_res_imsk("\n\tld\ta,(sysstat_##)\n"	\
									"\tand\t02h\n\tjr\tnz,$$+3\n\tei\n")


#endif /* __HOS__TAKS_H_ */
