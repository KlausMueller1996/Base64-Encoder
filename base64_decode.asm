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

;#########################################################
; 
; arguments:
;	single_byte_register: 1 byte register containing the charcter to be looked up
;
; details:
;	check if char in given regsiter is valid  '=' < char < '=' + 4fh
;	look up char in converson table and return result in single_byte_register
;	jump to return_error in case anything goes wrong
;
; register usage:
;	al
;   
;#########################################################

lookup_char MACRO single_byte_register

		mov		al, single_byte_register
		sub		al, '+'				
		jc		return_error		

		cmp		al, 4Fh				
		ja		return_error
		
		xlat

		cmp		al, 0FFh
		jz		return_error

		mov		single_byte_register, al						

ENDM

;#########################################################
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
;	rcx: temporary storage of tuple[0] and tuple[2]
;	rdx: temporary storage of tuple[0] and tuple[2]
;   rsi: const pointer to input structure
;   rdi: const pointer to output structure
;   r12: input_ctr
;   r10: input_len
;   r11: output_ctr
;   
; returns: 
;	size of return string excluding trailing zero 
;	0 in case of error
; 
;#########################################################

base64_decode PROC
	;
	;	INPUT VALIDATION
	;
		
		xor		rax, rax	; return 0 in case one of the input params is NULL

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

		lea		rbx, decoding_table
		mov		rsi, rcx
		mov		rdi, r8
		mov		r10, rdx
		xor		r11, r11
		xor		r12, r12
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

		lookup_char dl

		;	convert second byte, 

		lookup_char dh

		;	output = (tuple[0] << 2) + (tuple[1] >> 4);

		mov		cl, dl						
		shl		cl, 2
		shr		al, 4
		add		al, cl

		mov		byte ptr [rdi + r11], al

		;	decrease available output bytes
		;	check if we've reached end of output
		;	increase input counter

		dec		r9							
		jz		return_error		
		inc		r11

		;	convert third byte 

		shr		edx, 8						
		cmp		dh, '='
		je		prepare_result

		lookup_char dh

		;	output = (tuple[1] << 4) + (tuple[2] >> 2);

		shl		dl, 4
		shr		al, 2
		add		al, dl
		mov		byte ptr [rdi + r11], al

		;	decrease available output bytes
		;	check if we've reached end of output
		;	increase input counter

		dec		r9
		jz		return_error		
		inc		r11

		;	convert fourth byte, 
		;		edx = [00000000] [00000000] [input+3] [tuple_2] 

		shr		edx, 8						
		cmp		dh, '='
		je		prepare_result

		lookup_char dh

		shl		dl, 6
		add		al, dl
		mov		byte ptr [rdi + r11], al

		;	decrease available output bytes
		;	check if we've reached end of output
		;	increase input counter

		dec		r9
		jz		return_error		
		inc		r11

		;	increase input counter by 4 to read next quadrupel of input bytes (if available)

		add		r12, 4
		cmp		r12, r10		
		jb		input_loop

	prepare_result:
		;	add trailing zero and return output counter

		mov		rax, r11
		jmp		cleanup 

	return_error:

		xor		rax, rax

	;
	;	CLEANUP
	;
	cleanup:

		pop		r12
		pop		rdi
		pop		rsi
		pop		rbx

	return:
		ret

	base64_decode ENDP

END