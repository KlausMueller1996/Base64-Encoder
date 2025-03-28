option casemap:none

.const
	
	conversion_table		byte	'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
                   
.code

public base64_encode

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;	rcx: pointer to input structure 
	;	rdx: pointer to output structure 
	;
	; register usage:
	;   rax: calculate 6 bit value and use it as index in conversion table
	;   rbx: pointer to conversion table
	;   rdx: store temporary values
	;   rsi: pointer to input string
	;   rdi: pointer to output string
	;	r8 : output couner
	; 
	; returns: 
	;	number of chars written without trailing zero;
	;	
	; limitation: 
	;   this algorithm epects the input data to end with a 0x00 byte.
	;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	base64_encode PROC

		push	rbx
		push	rdi
		push	rsi

		mov		rsi, rcx
		mov		rdi, rdx

		; load base adress of conversion table to rbx register, xlat requires pointer to conversion table being stored in rbx
		lea		rbx, conversion_table
		
		xor		rax, rax
		xor		rdx, rdx
		xor		r8, r8
		cld

convert_triplet_loop:

		;	handle first input character
		lodsb								; al = 11111122

		test	al, al
		je		cleanup_and_exit			; the first inut char is 0x00, so we are done

		mov		dl, al						; dl = al = 11111122
		shr		al, 2						; al = 00111111

		xlat
		stosb
		inc		r8							; output_ctr++

		;	handle second input character
		lodsb								; al = 22223333

		test	al, al
		je		two_padding_chars			; the second inut char is 0x00, so we add two padding char

		shl		ax, 8						; ax = 22223333 00000000
		mov		al, dl						; ax = 22223333 11111122
		rol		ax, 4						; ax = 33331111 11222222
		and		al, 00111111b				; ax = 33331111 00222222

		xlat
		stosb
		inc		r8							; output_ctr++

		shr		ah, 4						; ah = 00003333

		;	handle 3rd input character
		lodsb								; ax = 00003333 33444444

		test	al, al
		je		one_padding_char			; the third inut char is 0x00, so we add one padding char

		ror		ax, 6						; ax = 44444400 00333333

		xlat
		stosb

		shr		ax, 10						; ax = 0000000000444444

		xlat
		stosb
		add		r8, 2						; output_ctr += 2;
				
		jmp convert_triplet_loop

two_padding_chars:

		mov		al, dl						; al = 11111122
		shl		al, 4						; al = 11220000
		and		al, 00111111b				; ax = 00220000

		xlat
		stosb

		mov		ax, '=='
		stosw	
		add		r8, 3
		jmp		cleanup_and_exit

	
one_padding_char:
											; ax = 00003333 00000000
		shr		ax, 6						; ax = 00000000 00333300
		xlat
		stosb

		mov		rax, '='
		stosb	
		add		r8, 2

cleanup_and_exit:

		xor		rax, rax
		stosb

		mov		rax, r8
		pop		rsi
		pop		rdi
		pop		rbx

		ret 
	base64_encode ENDP

END