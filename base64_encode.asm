option casemap:none

public base64_encode

.const
	
	conversion_table		byte	'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
                   
.code


check_output_count MACRO

		inc		r8							; 1 char written to output
		dec		r11							; 1 char less space in output
		jz		return_error

ENDM

;#########################################################
; 
; arguments:
;	rcx: pointer to input structure 
;	rdx: size of input structure
;	r8 : pointer to output structure 
;	r9 : size of output structure 
;
; register usage:
;   rax: calculate 6 bit value and use it as index in conversion table
;   rbx: pointer to conversion table
;   rdx: store temporary values
;   rsi: pointer to input string
;   rdi: pointer to output string
;	r8 : output bytes written
;	r10: available input buffer counter
;	r11: available output buffer counter
; 
; returns: 
;	number of chars written without trailing zero;
;	0h in case of an error
;	
; limitation: 
;   this algorithm epects the input data to end with a 0x00 byte.
;
;#########################################################

base64_encode PROC
	;
	;	INPUT VALIDATION
	;
		xor		rax, rax
		test	rcx, rcx
		je		return	
		test	rdx, rdx
		je		return	
		test	r8, r8
		je		return	
		test	r9, r9
		je		return	
	;
	;	STACK AND REGISTER PREPARATION
	;
		push	rbx
		push	rdi
		push	rsi

		mov		rsi, rcx
		mov		rdi, r8
		mov		r10, rdx
		mov		r11, r9

		lea		rbx, conversion_table
		
		xor		rax, rax
		xor		rdx, rdx
		xor		r8 , r8
		cld
	;
	;	PROCESSING
	;
	convert_triplet_loop:

		;	handle first input character

		lodsb								; al = 11111122

		mov		dl, al						; dl = al = 11111122
		shr		al, 2						; al = 00111111

		xlat
		stosb

		check_output_count

		;	handle second input character

		dec		r10							; more input available?
		jz		two_padding_chars			; add two padding chars in case we have only one input char

		lodsb								; al = 22223333

		shl		ax, 8						; ax = 22223333 00000000
		mov		al, dl						; ax = 22223333 11111122
		and		al, 00000011b				; ax = 22223333 00000022
		rol		ax, 4						; ax = 33330000 00222222

		xlat
		stosb

		check_output_count

		shr		ah, 4						; ah = 00003333

		;	handle 3rd input character

		dec		r10							; more input available?
		jz		one_padding_char			; add one padding char in case we have two input chars

		lodsb								; ax = 00003333 33444444

		ror		ax, 6						; ax = 44444400 00333333

		xlat
		stosb

		check_output_count

		shr		ax, 10						; ax = 0000000000444444

		xlat
		stosb

		check_output_count
		
		dec		r10							; more input available?
		jz		return_nr_chars					

		jmp convert_triplet_loop

	two_padding_chars:

		cmp		r11, 3						; enough output buffer available?
		jl		return_error

		mov		al, dl						; al = 11111122
		shl		al, 4						; al = 11220000
		and		al, 00110000b				; ax = 00220000

		xlat
		stosb

		mov		ax, '=='
		stosw	
		add		r8, 3						; 3 chars written to output
		jmp		return_nr_chars

	
	one_padding_char:

		cmp		r11, 2						; enough output buffer available?
		jl		return_error
											; ax = 00003333 ????????
		shr		ax, 6						; ax = 00000000 003333??
		and		ax, 00111100b				; ax = 00000000 00333300
		xlat
		stosb

		mov		rax, '='
		stosb	
		add		r8, 2						; 2 chars written to output
		jmp		return_nr_chars
	;
	;	CLEANUP
	;
	return_error:
		xor		rax, rax
		jmp		cleanup_and_exit

	return_nr_chars:
		mov		rax, r8						; return nr of chars written

	cleanup_and_exit:

		pop		rsi
		pop		rdi
		pop		rbx

	return:

		ret 
base64_encode ENDP

END