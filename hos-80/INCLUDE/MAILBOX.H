/* ------------------------------------------------------------------------- */
/*  HOS メイルボックス管理 ヘッダファイル                                    */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__MAILBOX_H_
#define __HOS__MAILBOX_H_


/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

typedef VP T_MSG;	/* ヘッダは利用しない */

/* MCB(MailBoxコントロールブロック) 動的部分 RAMに置く */
typedef struct t_mcb {
	T_QUE que;		/* メッセージ待ちキュー */
	VP    *head;	/* バッファ中の先頭メッセージ位置 */
	VP    *tail;	/* バッファ中の末尾メッセージ位置 */
} T_MCB;

/* MCB静的部分 ROMに置く */
typedef struct t_mcbs {
	VP   exinf;		/* 拡張情報 */
	VP   *bufhead;	/* メッセージバッファ先頭 */
	VP   *buftail;	/* メッセージバッファ末尾 */
} T_MCBS;

/* メイルボックス状態参照 */
typedef struct t_rmbx {
	VP      exinf;		/* 拡張情報 */
	BOOL_ID wtsk;		/* 待ちタスクの有無 */
	VP      pk_msg;		/* 次に受信されるパケットアドレス */
} T_RMBX;



/* ------------------------------------ */
/*          グローバル変数              */
/* ------------------------------------ */

/* タスク独立部用定義 */
extern T_MCB  mcbtbl[];		/* MCBテーブル RAM部 */
extern T_MCBS mcbstbl[];	/* MCBテーブル ROM部（静的に生成) */
extern UB     mcbcnt;		/* MCBテーブルの数 */



/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

void __ini_mbx(void);		/* メイルボックス初期化 */
ER   snd_msg(ID mbxid, VP pk_msg);	/* メイルボックスへ送信 */
ER   rcv_msg(VP *pk_msg, ID mbxid);	/* メイルボックスから受信 */
ER   prcv_msg(VP *pk_msg, ID mbxid);
								/* メイルボックスから受信(ポーリング) */
ER   ref_mbx(T_RMBX *pk_rmbx, ID mbxid);	/* メイルボックス状態参照 */

#define isnd_msg  snd_msg
#define iprcv_msg prcv_msg
#define iref_mbx  ref_mbx


#endif /* __HOS__MAILBOX_H_ */
