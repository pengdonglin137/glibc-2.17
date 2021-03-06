/* Copyright (C) 2005-2012 Free Software Foundation, Inc.

   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License as
   published by the Free Software Foundation; either version 2.1 of the
   License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library.  If not, see
   <http://www.gnu.org/licenses/>.  */

#include <sysdep.h>
#include <libc-symbols.h>

#include "dl-link.h"

#define ip0 x16
#define ip1 x17
#define lr  x30

	.text
	.globl _dl_runtime_resolve
	.type _dl_runtime_resolve, #function
	cfi_startproc
	.align 2
_dl_runtime_resolve:
	/* AArch64 we get called with:
	   ip0		&PLTGOT[2]
	   ip1		temp(dl resolver entry point)
	   [sp, #8]	lr
	   [sp, #0]	&PLTGOT[n]
	 */

	cfi_rel_offset (lr, 8)

	/* Save arguments.  */
	stp	x8, x9, [sp, #-80]!
	cfi_adjust_cfa_offset (80)
	cfi_rel_offset (x8, 0)
	cfi_rel_offset (x9, 8)

	stp	x6, x7, [sp,  #16]
	cfi_rel_offset (x6, 16)
	cfi_rel_offset (x7, 24)

	stp	x4, x5, [sp,  #32]
	cfi_rel_offset (x4, 32)
	cfi_rel_offset (x5, 40)

	stp	x2, x3, [sp,  #48]
	cfi_rel_offset (x2, 48)
	cfi_rel_offset (x3, 56)

	stp	x0, x1, [sp,  #64]
	cfi_rel_offset (x0, 64)
	cfi_rel_offset (x1, 72)

	/* Get pointer to linker struct.  */
	ldr	x0, [ip0, #-8]

	/* Prepare to call _dl_fixup().  */
	ldr	x1, [sp, 80]	/* Recover &PLTGOT[n] */

	sub     x1, x1, ip0
	add     x1, x1, x1, lsl #1
	lsl     x1, x1, #3
	sub     x1, x1, #192
	lsr     x1, x1, #3

	/* Call fixup routine.  */
	bl	_dl_fixup

	/* Save the return.  */
	mov	ip0, x0

	/* Get arguments and return address back.  */
	ldp	x0, x1, [sp, #64]
	ldp	x2, x3, [sp, #48]
	ldp	x4, x5, [sp, #32]
	ldp	x6, x7, [sp, #16]
	ldp	x8, x9, [sp], #80
	cfi_adjust_cfa_offset (-80)

	ldp	ip1, lr, [sp], #16
	cfi_adjust_cfa_offset (-16)

	/* Jump to the newly found address.  */
	br	ip0

	cfi_endproc
	.size _dl_runtime_resolve, .-_dl_runtime_resolve
#ifndef PROF
	.globl _dl_runtime_profile
	.type _dl_runtime_profile, #function
	cfi_startproc
	.align 2
_dl_runtime_profile:
	/* AArch64 we get called with:
	   ip0		&PLTGOT[2]
	   ip1		temp(dl resolver entry point)
	   [sp, #8]	lr
	   [sp, #0]	&PLTGOT[n]

	   Stack frame layout:
	   [sp,   #...] lr
	   [sp,   #...] &PLTGOT[n]
	   [sp,    #96] La_aarch64_regs
	   [sp,    #48] La_aarch64_retval
	   [sp,    #40] frame size return from pltenter
	   [sp,    #32] dl_profile_call saved x1
	   [sp,    #24] dl_profile_call saved x0
	   [sp,    #16] t1
	   [sp,     #0] x29, lr   <- x29
	 */

# define OFFSET_T1		16
# define OFFSET_SAVED_CALL_X0	OFFSET_T1 + 8
# define OFFSET_FS		OFFSET_SAVED_CALL_X0 + 16
# define OFFSET_RV		OFFSET_FS + 8
# define OFFSET_RG		OFFSET_RV + DL_SIZEOF_RV

# define SF_SIZE		OFFSET_RG + DL_SIZEOF_RG

# define OFFSET_PLTGOTN		SF_SIZE
# define OFFSET_LR		OFFSET_PLTGOTN + 8

	/* Save arguments.  */
	sub	sp, sp, #SF_SIZE
	cfi_adjust_cfa_offset (SF_SIZE)
	stp	x29, x30, [SP, #0]
	mov	x29, sp
	cfi_def_cfa_register (x29)
	cfi_rel_offset (x29, 0)
	cfi_rel_offset (lr, 8)

	stp	x0, x1, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*0]
	cfi_rel_offset (x0, OFFSET_RG + DL_OFFSET_RG_X0 + 16*0 + 0)
	cfi_rel_offset (x1, OFFSET_RG + DL_OFFSET_RG_X0 + 16*0 + 8)
	stp	x2, x3, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*1]
	cfi_rel_offset (x2, OFFSET_RG + DL_OFFSET_RG_X0 + 16*1 + 0)
	cfi_rel_offset (x3, OFFSET_RG + DL_OFFSET_RG_X0 + 16*1 + 8)
	stp	x4, x5, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*2]
	cfi_rel_offset (x4, OFFSET_RG + DL_OFFSET_RG_X0 + 16*2 + 0)
	cfi_rel_offset (x5, OFFSET_RG + DL_OFFSET_RG_X0 + 16*2 + 8)
	stp	x6, x7, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*3]
	cfi_rel_offset (x6, OFFSET_RG + DL_OFFSET_RG_X0 + 16*3 + 0)
	cfi_rel_offset (x7, OFFSET_RG + DL_OFFSET_RG_X0 + 16*3 + 8)

	stp	d0, d1, [X29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*0]
	cfi_rel_offset (d0, OFFSET_RG + DL_OFFSET_RG_D0 + 16*0)
	cfi_rel_offset (d1, OFFSET_RG + DL_OFFSET_RG_D0 + 16*0 + 8)
	stp	d2, d3, [X29, #OFFSET_RG+ DL_OFFSET_RG_D0 + 16*1]
	cfi_rel_offset (d2, OFFSET_RG + DL_OFFSET_RG_D0 + 16*1 + 0)
	cfi_rel_offset (d3, OFFSET_RG + DL_OFFSET_RG_D0 + 16*1 + 8)
	stp	d4, d5, [X29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*2]
	cfi_rel_offset (d4, OFFSET_RG + DL_OFFSET_RG_D0 + 16*2 + 0)
	cfi_rel_offset (d5, OFFSET_RG + DL_OFFSET_RG_D0 + 16*2 + 8)
	stp	d6, d7, [X29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*3]
	cfi_rel_offset (d6, OFFSET_RG + DL_OFFSET_RG_D0 + 16*3 + 0)
	cfi_rel_offset (d7, OFFSET_RG + DL_OFFSET_RG_D0 + 16*3 + 8)

	add     x0, x29, #SF_SIZE + 16
	ldr	x1, [x29, #OFFSET_LR]
	stp	x0, x1, [x29, #OFFSET_RG + DL_OFFSET_RG_SP]

	/* Get pointer to linker struct.  */
	ldr	x0, [ip0, #-8]

	/* Prepare to call _dl_profile_fixup().  */
	ldr	x1, [x29, OFFSET_PLTGOTN]	/* Recover &PLTGOT[n] */

	sub     x1, x1, ip0
	add     x1, x1, x1, lsl #1
	lsl     x1, x1, #3
	sub     x1, x1, #192
	lsr     x1, x1, #3

	stp	x0, x1, [x29, #OFFSET_SAVED_CALL_X0]

	/* Set up extra args for _dl_profile_fixup */
	ldr	x2, [x29, #OFFSET_LR]		/* load saved LR */
	add	x3, x29, #OFFSET_RG		/* address of La_aarch64_reg */
	add	x4, x29, #OFFSET_FS		/* address of framesize */
	bl	_dl_profile_fixup

	ldr	ip0, [x29, #OFFSET_FS]		/* framesize == 0 */
	cmp	ip0, #0
	bge	1f
	cfi_remember_state

	/* Save the return.  */
	mov	ip0, x0

	/* Get arguments and return address back.  */
	ldp	x0, x1, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*0]
	ldp	x2, x3, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*1]
	ldp	x4, x5, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*2]
	ldp	x6, x7, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*3]
	ldp	d0, d1, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*0]
	ldp	d2, d3, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*1]
	ldp	d4, d5, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*2]
	ldp	d6, d7, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*3]

	cfi_def_cfa_register (sp)
	ldp	x29, x30, [x29, #0]
	cfi_restore(x29)
	cfi_restore(x30)

	add	sp, sp, SF_SIZE + 16
	cfi_adjust_cfa_offset (- SF_SIZE - 16)

	/* Jump to the newly found address.  */
	br	ip0

	cfi_restore_state
1:
	/* The new frame size is in ip0.  */

	sub	x1, x29, ip0
	and	sp, x1, #0xfffffffffffffff0

	str	x0, [x29, #OFFSET_T1]

	mov	x0, sp
	add	x1, x29, #SF_SIZE + 16
	mov	x2, ip0
	bl	memcpy

	ldr	ip0, [x29, #OFFSET_T1]

	/* Call the function.  */
	ldp	x0, x1, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*0]
	ldp	x2, x3, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*1]
	ldp	x4, x5, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*2]
	ldp	x6, x7, [x29, #OFFSET_RG + DL_OFFSET_RG_X0 + 16*3]
	ldp	d0, d1, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*0]
	ldp	d2, d3, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*1]
	ldp	d4, d5, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*2]
	ldp	d6, d7, [x29, #OFFSET_RG + DL_OFFSET_RG_D0 + 16*3]
	blr	ip0
	stp	x0, x1, [x29, #OFFSET_RV + DL_OFFSET_RV_X0]
	stp	d0, d1, [x29, #OFFSET_RV + DL_OFFSET_RV_D0 + 16*0]
	stp	d2, d3, [x29, #OFFSET_RV + DL_OFFSET_RV_D0 + 16*1]

	/* Setup call to pltexit  */
	ldp	x0, x1, [x29, #OFFSET_SAVED_CALL_X0]
	add	x2, x29, #OFFSET_RG
	add	x3, x29, #OFFSET_RV
	bl	_dl_call_pltexit

	ldp	x0, x1, [x29, #OFFSET_RV + DL_OFFSET_RV_X0]
	ldp	d0, d1, [x29, #OFFSET_RV + DL_OFFSET_RV_D0 + 16*0]
	ldp	d2, d3, [x29, #OFFSET_RV + DL_OFFSET_RV_D0 + 16*1]
	/* LR from within La_aarch64_reg */
	ldr	lr, [x29, #OFFSET_RG + DL_OFFSET_RG_LR]
	cfi_restore(lr)
	mov	sp, x29
	cfi_def_cfa_register (sp)
	ldr	x29, [x29, #0]
	cfi_restore(x29)
	add	sp, sp, SF_SIZE + 16
	cfi_adjust_cfa_offset (- SF_SIZE - 16)

	br	lr

	cfi_endproc
	.size _dl_runtime_profile, .-_dl_runtime_profile
#endif
	.previous
