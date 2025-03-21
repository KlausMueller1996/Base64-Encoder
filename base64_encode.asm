
option casemap:none

.const
	
	conversion_table		byte	'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
                   
.code

public base64_encode

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;	rcx: pointer to input structure - there should be 4 bytes available
	;	rdx: size of input structure
	;	R8:  pointer to result structure (4 bytes required)
	;	R9:  size of result buffer 
	;
	; register usage:
	;   rax: calculate 6 bit value and use it as index in conversion table
	;   rbx: pointer to conversion table
	;   rcx: shift and mask input bytes  
	;   rdx: stores 3 input bytes in LO DWORD part of register
	;   rsi: pointer to input string
	;   r12: input string size
	;   rdi: pointer to output string
	;   r13: output string size
	;   r14: input index
	;   r15: output index
	; 
	; returns: 
	;	none;
	; 
	; algorithm:
	;   load 3 bytes from input. 
	;		byte 4		????????
	;		byte 2		33444444
	;		byte 1		22223333
	;		byte 0		11111122
	;   extract 6 bit blocks into al register using shifts, rotates and and
	;	use al as index into the base 64 table
	;   add output string depending on input length
	;	
	; limitation: 
	;   this algorithm epects the input data to end with a 0x00 byte.
	;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	base64_encode PROC

		push	rbx
		push	rdi
		push	rsi
		push	r12
		push	r13

		; copy arguments to nonvolatile registers
		mov		rsi, rcx
		mov		rdi, r8
		mov		r12, rdx
		mov		r13, r9
		mov		r14, 0
		mov		r15, 0

		; load base adress of conversion table to rbx register, xlat requires pointer to conversion table being stored in rbx
		lea		rbx, conversion_table

convert_triplet_loop:
		
		cmp		r12, r14					; check if we have reached the end of the input
		jbe		cleanup_and_exit			; so we have at least one byte left  and need to produce 2 output bytes 

		mov		edx, dword ptr [rsi + r14]	; read 4 Bytes from source string into low dword part of rdx register

		;	calculate 1st result byte
		mov		al, dl						; al = 11111122
		shr		al, 2						; al = 00111111

		xlat
		mov		[rdi + r15], al
		inc		r15							; increase output counter to point to next char

		;	calculate 2nd result byte
		mov		ax, dx						; ax = 2222333311111122
		rol		ax, 4						; ax = 3333111111222222
		and		ax, 0000000000111111b

		xlat
		mov		[rdi + r15], al
		inc		r15							; increase output counter to point to next char

		inc		r14							; we need the third input byte to calculate the third output byte 
		cmp		r12, r14					; check if there is a third input byte available
		jbe		add_two_escape_chars		; if not than add two padding chars to result and finish


		;	calculate 3rd result byte
		mov		ecx, edx					; ecx = ????????334444442222333311111122
		shr		ecx, 6						; ecx = 000000????????334444442222333311
		mov		al, cl						; al = 22333311
		and		al, 00111100b				; al = 00333300
		shr		ecx, 16						; ecx = 0000000000000000000000????????33
		and		cl, 00000011b				; cl = 00000033
		add		al, cl

		xlat
		mov		[rdi+ r15], al

		inc		r15							; third output byte is calculated
		inc		r14							; we need fourth input byte to calculate the fourth output byte 
		cmp		r12, r14					; check if there is a fourth input byte available
		jbe		add_one_escape_char			; if not, then add a padding char to result and finish

		; calculate 4th result byte

		mov		eax, edx					; eax = 334444442222333311111122
		shr		eax, 16						; eax = 000000000000000033444444
		and		al, 00111111b				; al = 00444444

		xlat
		mov		[rdi+r15], al
		inc		r15							; increase output counter to point to next char
		inc		r14							; increase input counter to point to next char
				
		jmp convert_triplet_loop

add_two_escape_chars:

		mov		byte ptr [rdi+r15], '='
		inc		r15
	
add_one_escape_char:

		mov		byte ptr [rdi+r15], '='

cleanup_and_exit:

		pop	r13
		pop r12
		pop rsi
		pop rdi
		pop rbx

		ret 
	base64_encode ENDP

END