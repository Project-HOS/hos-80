/* ------------------------------------------------------------------------- */
/*  HOS メイルボックス管理 ヘッダファイル                                    */
/*                                               Copyright (C) 1998 by Ryuz  */
/* ------------------------------------------------------------------------- */


-- アセンブリ部
				cseg

-trap.asz
; ------- ソフトウェア割り込み
				public	trap_
trap_:			
				di
				ld	l,a
				ld	a,i
				ld	h,a
				ld	a,(hl)
				inc	hl
				ld	h,(hl)
				ld	l,a
				ld	iy,ret_adr
				push	iy
				jp	(hl)
ret_adr:		
				ret

				end
