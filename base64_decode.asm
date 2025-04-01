option casemap:none

public base64_decode

.const
	
	; decoding_table using  
	;	ascii(+) as starting value 
	;	containg all chars in ascii order up to Z
	;	chars not used in encoding table have a value of 0FFh 
	; table has 50h entries

							; '+' has index 3E in encoding table 
	decoding_table			byte	 3Eh 
							; ',-;' are not in encoding table
							byte	0FFh, 0FFh, 0FFh
							; 'index of /' in encoding table
							byte	 3Fh				
							; index of '0-9' in encoding table
							byte	 34h, 035h, 036h, 037h, 038h, 039h, 3Ah, 3Bh, 3Ch, 3Dh	
							; ':;<=>?@' are not in encoding table. 
							; Padding char '=' is treated as invalid char as we do not need to continue decoding after a '=' in input stream
							byte	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
							; 'index of ''A'-'Z' in encoding table
							byte	 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h
							; '[\]^_`' are not in encoding table
							byte	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 
							; index of 'a'-'z' in encoding table
							byte	 1Ah, 1Bh, 1Ch, 1Dh, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h

.code

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;   rcx: pointer to input structure
	;   rdx: input_len: Anzahl der zu konvertierenden Zeichen 
	;        muss ein vielfaches der Zahl 4 sein
	;   r8:  pointer to output structure
	;   r9:  number of elements in output buffer
	;
	; register usage:
	;	rax: calculations
	;	rbx: const pointer to conversion table
	;	rdx: temporary storage of tuple[0] and tuple[2]
	;   rsi: const pointer to input structure
	;   rdi: const pointer to output structure
	;   r12: input_ctr
	;   r13: input_len
	;   r14: output_ctr
	;   
	; returns: 
	;	size of return string excluding trailing zero 
	; 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

base64_decode PROC
	;
	;	INPUT VALIDATION
	;
		; return 0 in case one of the input params is NULL
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
		push	rsi
		push	rdi
		push	r12
		push	r13
		push	r14

		mov		rsi, rcx
		mov		rdi, r8
		xor		r12, r12
		mov		r13, rdx
		xor		r14, r14
		lea		rbx, decoding_table
	;
	;	PROCESSING
	;
	input_loop:
		
		;	clear values to avoid unintended side effects

		xor		rax, rax;
		xor		rcx, rcx;
		xor		rdx, rdx;

		;	read 4 bytes from input pointer at once
		;	edx = [input+3] [input+2] [input+1] [input]

		mov		edx, dword ptr[rsi+r12]

		;	convert first byte, 
		;		ensure char is between '+' and '+' + 4F
		;		convert char via table lookup
		;		check if result is valid (1st & 2nd char in array may not be a padding char)
		;		store conversion result in edx register, overwriting the input value
		;		ebx = [input+3] [input+2] [input+1] [tuple_0]

		mov		al, dl
		sub		al, '+'				
		jc		return_error		

		cmp		al, 4Fh				
		ja		return_error
		
		xlat

		cmp		al, 0FFh
		jz		return_error

		mov		dl, al						

		;	convert second byte, 
		;		ensure char is between '+' and '+' + 4F
		;		convert char via table lookup
		;		check if result is valid (1st & 2nd char in array may not be a padding char)
		;		store conversion result in edx register, overwriting the input value
		;		edx = [input+3] [input+2] [tuple_1] [tuple_0]

		mov		al, dh

		sub		al, '+'				
		jc		return_error		

		cmp		al, 4Fh				
		ja		return_error
		
		xlat

		cmp		al, 0FFh
		jz		return_error

		mov		dh, al						

		;	output = (tuple[0] << 2) + (tuple[1] >> 4);

		mov		cl, dl						
		shl		cl, 2
		shr		al, 4
		add		al, cl
		mov		byte ptr [rdi + r14], al

		;	decrease available output bytes
		;	check if we've reached end of output
		;	increase input counter

		dec		r9							
		jz		return_error		
		inc		r14

		;	convert third byte, 
		;		ensure char is between '+' and '+' + 4F
		;		convert char via table lookup
		;		check if result is valid or a padding char
		;		store conversion result in edx register, overwriting the input value
		;		edx = [00000000] [input+3] [tuple_2] [tuple_1]

		shr		edx, 8						

		cmp		dh, '='
		je		add_zero_and_prepare_result

		mov		al, dh				
		sub		al, '+'				
		jc		return_error		

		cmp		al, 4Fh				
		ja		return_error
		
		xlat

		cmp		al, 0FFh
		jz		return_error

		mov		dh, al						

		;	output = (tuple[1] << 4) + (tuple[2] >> 2);

		shl		dl, 4
		shr		al, 2
		add		al, dl
		mov		byte ptr [rdi + r14], al

		;	decrease available output bytes
		;	check if we've reached end of output
		;	increase input counter

		dec		r9
		jz		return_error		
		inc		r14

		;	convert fourth byte, 
		;		ensure char is between '+' and '+' + 4F
		;		convert char via table lookup
		;		check if result is valid or a padding char
		;		edx = [00000000] [00000000] [input+3] [tuple_2] 

		shr		edx, 8						

		cmp		dh, '='
		je		add_zero_and_prepare_result

		mov		al, dh 				
		sub		al, '+'				
		jc		return_error		

		cmp		al, 4Fh				
		ja		return_error
		
		xlat

		cmp		al, 0FFh
		jz		return_error

		shl		dl, 6
		add		al, dl
		mov		byte ptr [rdi + r14], al

		;	decrease available output bytes
		;	check if we've reached end of output
		;	increase input counter

		dec		r9
		jz		return_error		
		inc		r14

		;	increase output counter by 4 to read next quadrupel of input bytes

		add		r12, 4
		cmp		r12, r13		
		jb		input_loop

	add_zero_and_prepare_result:
		;	add trailing zero and return output counter

		mov		byte ptr [rdi + r14], 0
		mov		rax, r14
		jmp		cleanup 

	return_error:

		xor		rax, rax

	;
	;	CLEANUP
	;
	cleanup:

		pop		r14
		pop		r13
		pop		r12
		pop		rdi
		pop		rsi
		pop		rbx

	return:
		ret

	base64_decode ENDP

END