/* ------------------------------------------------------------------------- */
/*  HOS-80 用 コンフィギュレーター Ver 0.00                                  */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>


/* ------------------------------------ */
/*             定数定義                 */
/* ------------------------------------ */

#define MAX_PATH   		128		/* 最大パス名 */
#define MAX_PARAMETER     5     /* 最大パラメーター数 */
#define MAX_ID          255     /* 最大ＩＤ数 */
#define MAX_INT         128		/* 最大割り込み番号 */
#define MAX_INCLUDE_C    32		/* 最大読み込みファイル数(Ｃ言語用) */

#define TRUE  1
#define FALSE 0



/* ------------------------------------ */
/*             関数宣言                 */
/* ------------------------------------ */

void AnalizeCommand(char *(*pppPara[MAX_PARAMETER]), int nPara, char *pBuf);
void AnalizeDefInt(char *pBuf);
void AnalizeIncludeC(char *pBuf);
void AnalizeMaxTskPri(char *pBuf);
void AnalizeSysStack(char *pBuf);

void FreeParameter(char *ppPara[MAX_PARAMETER]);
void FreeTable(char ***pppTable);

void CutSpace(char *pBuf);
int  ClipParameter(char *ppPar[], int nNum, char *pBuf);
int  StrToInt(int *pNum, char *pBuf);

void Write_Def_ID(void);		/* 定義ファイル出力 */
void Write_C_Cfg(void);			/* Ｃ言語部出力 */
void Write_Asm_Cfg(void);		/* アセンブリ言語部出力 */



/* ------------------------------------ */
/*             変数宣言                 */
/* ------------------------------------ */

char szCfgFile[MAX_PATH]  = "hos.cfg";		/* コンフィグレーションファイル */
char szAsmFile[MAX_PATH]  = "cfg_asm.asz";	/* アセンブリ言語出力ファイル名 */
char szCFile[MAX_PATH]    = "cfg_c.c";		/* Ｃ言語出力ファイル名 */
char szDefCFile[MAX_PATH] = "defid.h";		/* 定数定義ヘッダファイル名 */

int  nLine;			/* 解析中の行番号 */
int  bErr = FALSE;	/* エラー */

char *pMaxTskPri = NULL;		/* 最大優先度(デフォルトで８) */

char **pppTaskTable[MAX_ID];	/* タスク生成データテーブル */
char **pppSemTable[MAX_ID];		/* セマフォ生成データテーブル */
char **pppFlgTable[MAX_ID];		/* イベントフラグ生成データテーブル */
char **pppMbxTable[MAX_ID];		/* メッセージボックス生成データテーブル */
char **pppMpfTable[MAX_ID];		/* 固定長メモリプール生成データテーブル */

char *ppIntTable[MAX_INT];		/* 割り込みベクタのテーブル */

char *ppIncludeCTable[MAX_INCLUDE_C];	/* Ｃ言語のインクルードファイル */
int  nIncCCount;		/* インクルードファイル数 */

unsigned short SystemStack = 0x0000;	/* システムスタックのアドレス */

int  bUseTimer = TRUE;		/* タイマを使うか */


/* ------------------------------------ */
/*             メイン                   */
/* ------------------------------------ */

/* メイン関数 */
int main(int argc, char argv[])
{
	FILE *fp;
	char szBuf[256];
	int  i;

	/* ロゴ表示 */
	fprintf(stderr, "HOS-80 用コンフィギュレーター Ver0.00 by Ryuz\n");

	/* コマンドライン解析 */
	/*
	for ( i = 0; i < argc; i++ ) {
	}
	*/

	/* ファイルオープン */
	if ( (fp = fopen(szCfgFile, "r")) == NULL ) {
		fprintf(stderr, "%s が開けません\n");
		exit(1);
	}
	
	/* ファイルの解析 */
	nLine = 1;
	while ( fgets(szBuf, sizeof(szBuf), fp) != NULL ) {
		CutSpace(szBuf);
		if ( strncmp(szBuf, "CRE_TSK", 7) == 0 )
			AnalizeCommand(pppTaskTable, 5, &szBuf[7]);
		else if ( strncmp(szBuf, "CRE_SEM", 7) == 0 )
			AnalizeCommand(pppSemTable, 4, &szBuf[7]);
		else if ( strncmp(szBuf, "CRE_FLG", 7) == 0 )
			AnalizeCommand(pppFlgTable, 3, &szBuf[7]);
		else if ( strncmp(szBuf, "CRE_MBX", 7) == 0 )
			AnalizeCommand(pppMbxTable, 3, &szBuf[7]);
		else if ( strncmp(szBuf, "CRE_MPF", 7) == 0 )
			AnalizeCommand(pppMpfTable, 4, &szBuf[7]);
		else if ( strncmp(szBuf, "DEF_INT", 7) == 0 )
			AnalizeDefInt(&szBuf[7]);
		else if ( strncmp(szBuf, "INCLUDE_C", 9) == 0 )
			AnalizeIncludeC(&szBuf[9]);
		else if ( strncmp(szBuf, "MAX_TSKPRI", 10) == 0 )
			AnalizeMaxTskPri(&szBuf[10]);
		else if ( strncmp(szBuf, "SYSTEM_STACK", 12) == 0 )
			AnalizeSysStack(&szBuf[12]);
		else if ( strncmp(szBuf, "USE_TIMER", 9) == 0 )
			bUseTimer = TRUE;
		else if ( strncmp(szBuf, "NOUSE_TIMER", 11) == 0 )
			bUseTimer = FALSE;
		else if ( szBuf[0] != ';' && szBuf[0] != '\0' && szBuf[0] != '\n' ) {
			fprintf(stdout, "行番号 %d: 構文エラー\n", nLine);
			bErr = TRUE;
		}
		nLine++;
	}
	
	fclose(fp);

	/* ファイル出力 */
	Write_Def_ID();
	Write_C_Cfg();
	Write_Asm_Cfg();

	/* メモリ開放 */
	FreeTable(pppTaskTable);
	FreeTable(pppSemTable);
	FreeTable(pppFlgTable);
	FreeTable(pppMbxTable);
	FreeTable(pppMpfTable);
	if ( pMaxTskPri != NULL )  free(pMaxTskPri);
	for ( i = 0; i < MAX_INT; i++ )
		if ( ppIntTable[i] != NULL )  free(ppIntTable[i]);
	for ( i = 0; i < MAX_INCLUDE_C; i++ )
		if ( ppIncludeCTable[i] != NULL )  free(ppIncludeCTable[i]);
	
	return bErr;
}



/* ------------------------------------ */
/*         ファイル出力                 */
/* ------------------------------------ */

/* 定義ファイル出力 */
void Write_Def_ID(void)
{
	FILE *fp;
	int  i;
	
	fp = fopen(szDefCFile, "w");

	fprintf(fp, "/* ROS-80用 Ｃ言語用ＩＤ定義ファイル */\n\n");
	fprintf(fp, "#ifndef __ROSCFG__DEFID_H_\n");
	fprintf(fp, "#define __ROSCFG__DEFID_H_\n\n\n");

	/* タスクID 出力 */
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppTaskTable[i] != NULL && pppTaskTable[i][0][0] != '\0' ) 
			fprintf(fp, "#define %s\t%d\n", pppTaskTable[i][0], i + 1);
	}
	fprintf(fp, "\n");

	/* セマフォID 出力 */
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppSemTable[i] != NULL && pppSemTable[i][0][0] != '\0' ) 
			fprintf(fp, "#define %s\t%d\n", pppSemTable[i][0], i + 1);
	}
	fprintf(fp, "\n");

	/* イベントフラグID 出力 */
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppFlgTable[i] != NULL && pppFlgTable[i][0][0] != '\0' ) 
			fprintf(fp, "#define %s\t%d\n", pppFlgTable[i][0], i + 1);
	}
	fprintf(fp, "\n");

	/* メールボックスID 出力 */
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppMbxTable[i] != NULL && pppMbxTable[i][0][0] != '\0' ) 
			fprintf(fp, "#define %s\t%d\n", pppMbxTable[i][0], i + 1);
	}
	fprintf(fp, "\n");

	/* 固定長メモリプールID 出力 */
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppMpfTable[i] != NULL && pppMpfTable[i][0][0] != '\0' ) 
			fprintf(fp, "#define %s\t%d\n", pppMpfTable[i][0], i + 1);
	}
	fprintf(fp, "\n");

	fprintf(fp, "\n#endif /* __ROSCFG__DEFID_H_ */\n");
}


/* コンフィギュレーションファイルＣ言語部出力 */
void Write_C_Cfg(void)
{
	FILE *fp;
	char *pPri;
	int  nMaxID;
	int  i;
	int  bTsk = FALSE;
	int  bSem = FALSE;
	int  bFlg = FALSE;
	int  bMbx = FALSE;
	int  bMpf = FALSE;
	
	fp = fopen(szCFile, "w");
	
	/* コメント出力 */
	fprintf(fp, "/* ROS-80用 コンフィギュレーションファイルＣ言語部 */\n\n");
	
	/* インクルードファイル出力 */
	fprintf(fp, "#include <ITRON.h>\n");
	for ( i = 0; i < nIncCCount; i++ )
		fprintf(fp, "#include %s\n", ppIncludeCTable[i]);
	
	
	/* ------- レディーキュー出力 -------- */
	if ( pMaxTskPri == NULL )
		pPri = "8";
	else
		pPri = pMaxTskPri;
	fprintf(fp, "\n\n/* レディーキュー */\n");
	fprintf(fp, "T_QUE rdyque[%s];\n", pPri);
	fprintf(fp, "UB    rdqcnt = %s;\n", pPri);

	
	/* ------- タスクデータ出力 -------- */

	/* 最大タスクID検索 */
	nMaxID = 0;
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppTaskTable[i] != NULL )
			nMaxID = i + 1;
	}

	if ( nMaxID > 0 ) {
		bTsk = TRUE;

		/* スタック領域出力 */
		fprintf(fp, "\n\n/*スタック領域*/\n");
		for ( i = 0; i < nMaxID; i++ ) {
			if ( pppTaskTable[i] != NULL ) {
				fprintf(fp, "UB Stack%d[%s];\n", i + 1, pppTaskTable[i][4]);
			}
		}
	
		/* タスク定義 */
		fprintf(fp, "\n/*タスク登録*/\n");
		fprintf(fp, "T_TCB  tcbtbl[%d];\n", nMaxID);
		fprintf(fp, "T_TCBS tcbstbl[%d] = {\n", nMaxID);
		for ( i = 0; i < nMaxID; i++ ) {
			if ( pppTaskTable[i] == NULL )
				fprintf(fp, "\t\t{}");
			else
				fprintf(fp, "\t\t"
							"{%s, %s, %s, (VH *)(Stack%d + sizeof(Stack%d))}",
							pppTaskTable[i][1],
							pppTaskTable[i][2],
							pppTaskTable[i][3],
							i + 1, i + 1
						);
			if ( i == nMaxID - 1 )
				fprintf(fp, "\n");
			else
				fprintf(fp, ",\n");
		}
		fprintf(fp, "\t};\n");
	}
	fprintf(fp, "UB  tcbcnt = %d;\t/* タスク数 */\n", nMaxID);

	
	/* ------- セマフォデータ出力 -------- */

	/* 最大セマフォID検索 */
	nMaxID = 0;
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppSemTable[i] != NULL )
			nMaxID = i + 1;
	}

	if ( nMaxID > 0 ) {
		bSem = TRUE;

		/* セマフォ定義 */
		fprintf(fp, "\n\n/* セマフォ登録 */\n");
		fprintf(fp, "T_SCB  scbtbl[%d];\n", nMaxID);
		fprintf(fp, "T_SCBS scbstbl[%d] = {\n", nMaxID);
		for ( i = 0; i < nMaxID; i++ ) {
			if ( pppSemTable[i] == NULL )
				fprintf(fp, "\t\t{}");
			else
				fprintf(fp, "\t\t{%s, %s, %s}",
							pppSemTable[i][1],
							pppSemTable[i][2],
							pppSemTable[i][3]
						);
			if ( i == nMaxID - 1 )
				fprintf(fp, "\n");
			else
				fprintf(fp, ",\n");
		}
		fprintf(fp, "\t};\n");
	}
	fprintf(fp, "UB  scbcnt = %d;\t/* セマフォ数 */\n", nMaxID);


	/* ------- フラグデータ出力 -------- */

	/* 最大イベントフラグID検索 */
	nMaxID = 0;
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppFlgTable[i] != NULL )
			nMaxID = i + 1;
	}

	if ( nMaxID > 0 ) {
		bFlg = TRUE;

		/* イベントフラグ定義 */
		fprintf(fp, "\n\n/* イベントフラグ登録 */\n");
		fprintf(fp, "T_FCB  fcbtbl[%d];\n", nMaxID);
		fprintf(fp, "T_FCBS fcbstbl[%d] = {\n", nMaxID);
		for ( i = 0; i < nMaxID; i++ ) {
			if ( pppFlgTable[i] == NULL )
				fprintf(fp, "\t\t{}");
			else
				fprintf(fp, "\t\t{%s, %s}",
							pppFlgTable[i][1],
							pppFlgTable[i][2]);
			if ( i == nMaxID - 1 )
				fprintf(fp, "\n");
			else
				fprintf(fp, ",\n");
		}
		fprintf(fp, "\t};\n");
	}
	fprintf(fp, "UB  fcbcnt = %d;\t/* イベントフラグ数 */\n", nMaxID);

	/* ------- メイルボックスデータ出力 -------- */

	/* 最大メールボックスID検索 */
	nMaxID = 0;
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppMbxTable[i] != NULL )
			nMaxID = i + 1;
	}
	
	if ( nMaxID > 0 ) {
		bMbx = TRUE;
		fprintf(fp, "\n\n/* メールボックス用バッファ */\n");
		for ( i = 0; i < nMaxID; i++ )
			fprintf(fp, "VP msgbuf%d[%s];\n", i, pppMbxTable[i][2]);
		
		/* メールボックス定義 */
		fprintf(fp, "\n/* メールボックス登録 */\n");
		fprintf(fp, "T_MCB  mcbtbl[%d];\n", nMaxID);
		fprintf(fp, "T_MCBS mcbstbl[%d] = {\n", nMaxID);
		for ( i = 0; i < nMaxID; i++ ) {
			if ( pppMbxTable[i] == NULL )
				fprintf(fp, "\t\t{}");
			else
				fprintf(fp, "\t\t{%s, msgbuf%d, msgbuf%d + %s}",
							pppMbxTable[i][1], i, i, pppMbxTable[i][2]);
			if ( i == nMaxID - 1 )
				fprintf(fp, "\n");
			else
				fprintf(fp, ",\n");
		}
		fprintf(fp, "\t};\n");
	}
	fprintf(fp, "UB  mcbcnt = %d;\t/* メールボックス数 */\n", nMaxID);
	
	
	/* ------- 固定長メモリプールデータ出力 -------- */
	
	/* 最大固定長メモリプールID検索 */
	nMaxID = 0;
	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppMpfTable[i] != NULL )
			nMaxID = i + 1;
	}
	
	if ( nMaxID > 0 ) {
		bMpf = TRUE;
		fprintf(fp, "\n\n/* 固定長メモリプール用メモリ */\n");
		for ( i = 0; i < nMaxID; i++ )
			fprintf(fp, "UB mpfblk%d[(%s) * (%s)];\n", i,
						pppMpfTable[i][2], pppMpfTable[i][3]);
		
		/* 固定長メモリプール定義 */
		fprintf(fp, "\n/* 固定長メモリプール登録 */\n");
		fprintf(fp, "T_FMCB  fmcbtbl[%d];\n", nMaxID);
		fprintf(fp, "T_FMCBS fmcbstbl[%d] = {\n", nMaxID);
		for ( i = 0; i < nMaxID; i++ ) {
			if ( pppMpfTable[i] == NULL )
				fprintf(fp, "\t\t{}");
			else
				fprintf(fp, "\t\t{%s, mpfblk%d, %s, %s}",
							pppMpfTable[i][1], i,
							pppMpfTable[i][2], pppMpfTable[i][3]);
			if ( i == nMaxID - 1 )
				fprintf(fp, "\n");
			else
				fprintf(fp, ",\n");
		}
		fprintf(fp, "\t};\n");
	}
	fprintf(fp, "UB  fmcbcnt = %d;\t/* 固定長メモリプール数 */\n", nMaxID);
	
	
	
	/* 初期化ルーチン出力 */
	fprintf(fp, "\n\n/* 初期化 */\n"
				"void __initialize(void)\n{\n"
			);
	if ( bUseTimer )
		fprintf(fp, "\t__ini_tim();\t/* タイマ初期化 */\n");
	if ( bTsk )
		fprintf(fp, "\t__ini_tsk();\t/* タスク初期化 */\n");
	if ( bSem )
		fprintf(fp, "\t__ini_sem();\t/* セマフォ初期化 */\n");
	if ( bFlg )
		fprintf(fp, "\t__ini_flg();\t/* イベントフラグ初期化 */\n");
	if ( bMbx )
		fprintf(fp, "\t__ini_mbx();\t/* メイルボックス初期化 */\n");
	if ( bMpf )
		fprintf(fp, "\t__ini_mpf();\t/* 固定長メモリプール初期化 */\n");
	fprintf(fp, "}\n");

	fclose(fp);
}


/* アセンブリ言語部出力 */
void Write_Asm_Cfg(void)
{
	FILE *fp;
	int  i;
	
	fp = fopen(szAsmFile, "w");
	
	/* コメント出力 */
	fprintf(fp, "; コンフィギュレーションファイルアセンブリ言語部\n\n");

	/* システムスタックアドレス定義 */
	fprintf(fp,
				"; -----------------------------------------------\n"
				";        システムスタックアドレス定義\n"
				"; -----------------------------------------------\n"
				"\n"
				"\t\tpublic\tsystem_stack\n"
				"system_stack\tequ\t%04xh\n\n\n", SystemStack
			);

	/* 割り込みベクタ出力 */
	fprintf(fp,
				"; -----------------------------------------------\n"
				";        割り込みハンドラ用セグメント\n"
				";            (256の倍数に配置)\n"
				"; -----------------------------------------------\n"
				"intvec_seg\tcseg\ton 256 local\n"
				"\t\textrn\tint_default\n"
				"\t\tpublic\tint_vector\n"
				"int_vector:\t\n"
			);
	for ( i = 0; i < MAX_INT; i++ ) {
		if ( ppIntTable[i] == NULL )
			fprintf(fp, "\t\tdw\tint_default\n");
		else
			fprintf(fp, "\t\tdw\tint%d\n", i * 2);
	}
	
	/* 割り込みハンドラ出力 */
	fprintf(fp,
				"\n\n"
				"; -----------------------------------------------\n"
				";          割り込みハンドラ\n"
				"; -----------------------------------------------\n"
				"\t\tcseg\n"
				"\t\textrn\tint_trap\n\n"
			);
	for ( i = 0; i < MAX_INT; i++ ) {
		if ( ppIntTable[i] != NULL ) {
			fprintf(fp, "int%d:\t\tpush\tiy\n", i * 2);
			fprintf(fp, "\t\tld\tiy,%s_##\n", ppIntTable[i]);
			fprintf(fp, "\t\tjp\tint_trap\n\n");
		}
	}
	
	fprintf(fp, "\n\t\tend\n");
	
	fclose(fp);
}



/* ------------------------------------ */
/*           コマンド解析               */
/* ------------------------------------ */

/* コマンド解析 (CRE_TSK, CRE_SEM, CRE_FLG, CRE_MBX) */
void AnalizeCommand(char ***pppTable, int nPara, char *pBuf)
{
	char **ppPar;
	int  nID;
	
	/* メモリ確保 */
	ppPar = (char **)calloc(MAX_PARAMETER, sizeof(char *));
	if ( ppPar == NULL ) {
		fprintf(stderr, "メモリ不足です\n");
		exit(1);
	}
	
	/* パラメーター分解 */
	if ( !ClipParameter(ppPar, nPara, pBuf) ) {
		FreeParameter(ppPar);
		return;
	}

	/* IDチェック */
	if ( StrToInt(&nID, ppPar[0]) ) {
		nID--;
		if ( nID < 0 || nID >= MAX_ID ) {
			fprintf(stdout, "行番号 %d: ID番号が不正です\n", nLine);
			FreeParameter(ppPar);
			bErr = TRUE;
			return;
		}
		if ( pppTable[nID] != NULL ) {
			fprintf(stdout, "行番号 %d: ID番号が重複しています\n", nLine);
			FreeParameter(ppPar);
			bErr = TRUE;
			return;
		}
		ppPar[0][0] = '\0';
	}
	else {
		for ( nID = 0; nID < MAX_ID; nID++ ) {
			if ( pppTable[nID] == NULL )
				break;
		}
		if ( nID >= MAX_ID ) {
			fprintf(stdout, "行番号 %d: 使用可能IDを使い切りました\n", nLine);
			FreeParameter(ppPar);
			bErr = TRUE;
			return;
		}
	}
	
	/* 登録 */
	pppTable[nID] = ppPar;
}


/* DEF_INT の解析 */
void AnalizeDefInt(char *pBuf)
{
	char *ppPara[2] = {NULL, NULL};
	int  nIntNum;

	/* コマンド切り出し */
	if ( !ClipParameter(ppPara, 2, pBuf) ) {
		if ( ppPara[0] != NULL )  free(ppPara[0]);
		if ( ppPara[1] != NULL )  free(ppPara[1]);
		return;
	}

	/* 割り込み番号チェック */
	if ( !StrToInt(&nIntNum, ppPara[0])
			|| nIntNum < 0 || nIntNum >= 256 || nIntNum % 1 != 0 ) {
		fprintf(stdout, "行番号 %d: 割り込み番号の指定が不正\n", nLine);
		if ( ppPara[0] != NULL )  free(ppPara[0]);
		if ( ppPara[1] != NULL )  free(ppPara[1]);
		bErr = TRUE;
		return;
	}
	if ( ppIntTable[nIntNum / 2] != NULL ) {
		fprintf(stdout, "行番号 %d: 割り込み番号が重複\n", nLine);
		if ( ppPara[0] != NULL )  free(ppPara[0]);
		if ( ppPara[1] != NULL )  free(ppPara[1]);
		bErr = TRUE;
		return;
	}

	/* 割り込みセット */
	ppIntTable[nIntNum / 2] = ppPara[1];
	free(ppIntTable[0]);
}


/* INCLUDE_C の解析 */
void AnalizeIncludeC(char *pBuf)
{
	char *ppPara[1] = {NULL};

	if ( !ClipParameter(ppPara, 1, pBuf) ) {
		if ( ppPara[0] != NULL )  free(ppPara[0]);
		return;
	}

	if ( nIncCCount >= MAX_INCLUDE_C ) {
		fprintf(stdout, "行番号 %d: インクルードファイルがが多すぎます\n",
					nLine);
		free(ppPara[0]);
		bErr = TRUE;
		return;
	}
	
	ppIncludeCTable[nIncCCount++] = ppPara[0];
}


/* MAX_TSKPRI の解析 */
void AnalizeMaxTskPri(char *pBuf)
{
	char *ppPara[1] = {NULL};
	int  nPri;
	
	if ( !ClipParameter(ppPara, 1, pBuf) ) {
		if ( ppPara[0] != NULL )  free(ppPara[0]);
		return;
	}
	
	pMaxTskPri = ppPara[0];
}


/* SYSTEM_STACK の解析 */
void AnalizeSysStack(char *pBuf)
{
	char *ppPara[1] = {NULL};
	int  nAdr;

	if ( !ClipParameter(ppPara, 1, pBuf) ) {
		if ( ppPara[0] != NULL )  free(ppPara[0]);
		return;
	}
	if ( StrToInt(&nAdr, ppPara[0]) )
		SystemStack = (unsigned short)nAdr;
	else
		fprintf(stdout, "行番号 %d: SYSTEM_STACKのパラーメータが不正です\n",
							nLine);
		
	free(ppPara[0]);
}


/* ------------------------------------ */
/*           メモリ開放                 */
/* ------------------------------------ */

/* パラメータ保存部分の開放 */
void FreeParameter(char **ppPara)
{
	int i;
	
	for ( i = 0; i < MAX_PARAMETER; i++ ) {
		if ( ppPara[i] != NULL ) {
			free(ppPara[i]);
			ppPara[i] = NULL;
		}
	}
	free(ppPara);
}

/* パラメーターテーブルの開放 */
void FreeTable(char ***pppTable)
{
	int i;

	for ( i = 0; i < MAX_ID; i++ ) {
		if ( pppTable[i] != NULL ) {
			FreeParameter(pppTable[i]);
			pppTable[i] = NULL;
		}
	}
}



/* ------------------------------------ */
/*            文字列処理                */
/* ------------------------------------ */

/* 前後の空白の除去 */
void CutSpace(char *pBuf)
{
	char *p;
	
	/* 後ろの空白カット */
	p = &pBuf[strlen(pBuf) - 1];
	while ( p >= pBuf && (*p == ' ' || *p == '\t' || *p == '\n') )
		p--;
	*(p + 1) = '\0';
	
	/* 前半の空白カット */
	p = pBuf;
	while ( *p == ' ' || *p == '\t' )
		p++;
	memmove(pBuf, p, strlen(p) + 1);
}


/* 括弧で囲まれた領域からパラメータを切り出す */
int ClipParameter(char *ppPar[], int nNum, char *pBuf)
{
	char *pBase;
	int  nParNest = 1;
	int  i;

	/* 始まりの '(' チェック */
	CutSpace(pBuf);
	if ( *pBuf++ != '(' ) {
		fprintf(stdout, "行番号 %d: 引数が必要なコマンドです\n", nLine);
		bErr = TRUE;
		return FALSE;
	}
	
	/* 引数分解 */
	for ( i = 0; i < nNum; i++ ) {
		pBase = pBuf;
		while ( *pBuf ) {
			if ( nParNest == 1 && *pBuf == ',' )
				break;
			if ( *pBuf == '(' )
				nParNest++;
			if ( *pBuf == ')' )
				nParNest--;
			if ( nParNest == 0 )
				break;
			pBuf++;
		}
		if ( (i < nNum - 1 && *pBuf == ',')
				|| (i == nNum - 1 && *pBuf == ')') ) {
			*pBuf++ = '\0';
			CutSpace(pBase);
			ppPar[i] = (char *)calloc(strlen(pBase) + 1, sizeof(char));
			if ( ppPar[i] == NULL ) {
				fprintf(stderr, "メモリ不足です\n");
				exit(1);
			}
			strcpy(ppPar[i], pBase);
		}
		else {
			fprintf(stdout, "行番号 %d: パラメーター数が異常\n", nLine);
			bErr = TRUE;
			return FALSE;
		}
	}
	
	return TRUE;
}


/* 文字列を数値を変換する(16進対応 */
int StrToInt(int *pNum, char *pBuf)
{
	/* 空白カット */
	CutSpace(pBuf);
	
	/* 数値かどうかチェック */
	if ( pBuf[0] < '0' || pBuf[0] > '9' )
		return FALSE;
	
	/* １６進かどうかチェック */
	if ( pBuf[0] == '0' && (pBuf[1] == 'x' || pBuf[1] == 'X') )
		return (sscanf(&pBuf[2], "%x", pNum) == 1);
	
	return (sscanf(&pBuf[0], "%d", pNum) == 1);
}

