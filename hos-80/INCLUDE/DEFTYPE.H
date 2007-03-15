/* ------------------------------------------------------------------------- */
/*  HOS データタイプ定義ヘッダファイル                                       */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

#ifndef __HOS__DEFTYPE_H_
#define __HOS__DEFTYPE_H_


/* ------------------------------------ */
/*             定数定義                 */
/* ------------------------------------ */

/* 無効アドレス値 */
#define NADR     ((void *)(0xffff))

/* BOOL値 */
#define TRUE     1
#define FALSE    0

/* エラーコード */
#define E_OK     0
#define E_SYS    (-5)
#define E_NOMEM  (-10)
#define E_NOSPT  (-17)
#define E_INOSPT (-18)
#define E_RSFN   (-20)
#define E_RSATR  (-24)
#define E_PAR    (-33)
#define E_ID     (-35)
#define E_NOEXS  (-52)
#define E_OBJ    (-63)
#define E_MACV   (-65)
#define E_OACV   (-66)
#define E_CTX    (-69)
#define E_QOVR   (-73)
#define E_DLT    (-81)
#define E_TMOUT  (-85)
#define E_RLWAI  (-86)

#define EN_NOND  (-113)
#define EN_OBJNO (-114)
#define EN_PROTO (-115)
#define EN_RSFN  (-116)
#define EN_COMM  (-117)
#define EN_RLWAI (-118)
#define EN_PAR   (-119)
#define EN_RPAR  (-120)
#define EN_CTXID (-121)
#define EN_EXEC  (-122)
#define EN_NOSPT (-123)



/* ------------------------------------ */
/*              型定義                  */
/* ------------------------------------ */

/* 汎用的データタイプ */
typedef int            B;	/* LSIC-80には signed char が無い */
typedef int            H;
typedef long           W;
typedef unsigned char  UB;
typedef unsigned int   UH;
typedef unsigned long  UW;
typedef unsigned char  VB;
typedef unsigned int   VH;
typedef unsigned long  VW;
typedef void           *VP;
typedef void (*FP)();

/* IRON依存データタイプ */
typedef int            INT;
typedef unsigned int   UINT;
typedef char           BOOL;
typedef int            FN;
typedef char           ID;
typedef char           BOOL_ID;
typedef char           HNO;
typedef char           RNO;
typedef char           NODE;
typedef unsigned char  ATR;
typedef int            ER;
typedef char           PRI;
typedef long           TMO;


#endif /* __HOS__DEFTYPE_H_ */
