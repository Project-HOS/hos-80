/* ------------------------------------------------------------------------- */
/*  HOS システム管理                                                         */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */

-- 共通部
#include <ITRON.h>

-sys_glb.c
UB     sysstat;		/* システムの状態 */


-get_ver.c
/* バージョン参照 */
ER   get_ver(T_VER *pk_ver)
{
	pk_ver->maker   = 0x0000;	/* バージョンなし（実験システム) */
	pk_ver->id      = 0x0100;	/* HOS-80 */
	pk_ver->spver   = 0x5302;	/* μITRON 3.02 */
	pk_ver->prver   = 0x0001;   /* Ver 0.01 */
	pk_ver->prno[0] = 0;
	pk_ver->prno[1] = 0;
	pk_ver->prno[2] = 0;
	pk_ver->prno[3] = 0;
	pk_ver->cpu     = 0x0000;	/* CPU情報なし (Z80系) */
	pk_ver->var     = 0x8000;	/* μITRON レベルS */
	
	return E_OK;
}


-ref_sys.c
/* システム状態参照 */
ER   ref_sys(T_RSYS *pk_rsys)
{
	__set_imsk();
	
	pk_rsys->sysstat = sysstat;
	
	__res_imsk();
	
	return E_OK;
}
