option casemap:none

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
							; ':;<' are not in encoding table
							byte	0FFh, 0FFh, 0FFh
							; '=' is the padding char
							byte	 00h 
							; '>?@' are not in encoding table
							byte	0FFh, 0FFh, 0FFh
							; 'index of ''A'-'Z' in encoding table
							byte	 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h
							; '[\]^_`' are not in encoding table
							byte	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 
							; index of 'a'-'z' in encoding table
							byte	 1Ah, 1Bh, 1Ch, 1Dh, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h

.code

public reverse_lookup
public base64_decode

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;   rcx: char to be converted
	;
	; register usage:
	;   rbx: base pointer to conversion table
	;   
	; returns: 
	;	index of given char in base 64 encoding table
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	reverse_lookup PROC

		push	rbx					; save	rbx in case we get here, as rbx is nonvolatile

		mov		al, cl
		sub		al, '+'				; '+' is the lowest value char in the base 64 encoded table, so it is value 0 in decoding table
		jb		unknown_character	; if carry is set, al was less then '+'

		cmp		al, 4Fh				; we have a max of 50 chars in the lookup_table
		ja		unknown_character

		; load base adress of conversion table to rbx register, xlat requires pointer to conversion table being stored in rbx
		lea		rbx, decoding_table

		xlat

		pop		rbx
		ret
	
unknown_character:

		pop		rbx
		mov		rax, 0FFh
		ret

	reverse_lookup ENDP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;   rcx: pointer to input structure - there should be 4 bytes available
	;   rdx: input_len: Anzahl der zu konvertierenden Zeichen 
	;        muss ein vielfaches der Zahl 4 sein
	;   r8:  pointer to output structure
	;   r9:  size of elements in output buffer
	;
	; register usage:
	;   rsi: pointer to input structure
	;   rdi: pointer to output structure
	;   r12: input_ctr
	;   r13: input_len
	;   r14: output_ctr
	;   
	; returns: 
	;	size of return string including trailing zero 
	; 
	; algorithm:
	;	void base64_decode(const char* input, const int input_len, uint8_t* output, const int output_len) {
	;	  int out_ctr = 0;
	;	  int in_ctr = 0;
	;	
 	;	  while (in_ctr < input_len) {
	;		char tuple[4] = { 0 };
	;	
	;		tuple[0] = reverse_lookup(input[in_ctr++]);
	;		tuple[1] = reverse_lookup(input[in_ctr++]);
	;		tuple[2] = reverse_lookup(input[in_ctr++]);
	;		tuple[3] = reverse_lookup(input[in_ctr++]);
	;	
	;		output[out_ctr++] = (uint8_t)(tuple[0] << 2) + (uint8_t)(tuple[1] >> 4);
	;		output[out_ctr++] = (uint8_t)(tuple[1] << 4) + (uint8_t)(tuple[2] >> 2);
	;		output[out_ctr++] = (uint8_t)(tuple[2] << 6) + (uint8_t)(tuple[3]);
	;	}
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	base64_decode PROC

		push	rsi
		push	rdi
		push	r12
		push	r13
		push	r14

		mov		rsi, rcx
		mov		rdi, r8
		mov		r12, 0
		mov		r13, rdx
		mov		r14, 0

input_loop:

		;	bl = tuple[0] = reverse_lookup(input[in_ctr++]);
		mov		cl, byte ptr[rsi+r12]				
		inc		r12
		call	reverse_lookup
		mov		bl, al		

		;	al = dl = tuple[1] = reverse_lookup(input[in_ctr++]);
		mov		cl ,byte ptr[rsi+r12]				
		inc		r12
		call	reverse_lookup
		mov		dl, al

		;	output[out_ctr++] = (uint8_t)(tuple[0] << 2) + (uint8_t)(tuple[1] >> 4);
		shl		bl, 2
		shr		al, 4
		add		al, bl
		mov		byte ptr [r8 + r14], al
		inc		r14

		;	al = bl = tuple[2] = reverse_lookup(input[in_ctr++]);
		mov		cl, byte ptr[rsi+r12]				
		inc		r12
		call	reverse_lookup
		mov		bl, al		

		;	output[out_ctr++] = (uint8_t)(tuple[1] << 4) + (uint8_t)(tuple[2] >> 2);
		shl		dl, 4
		shr		al, 2
		add		al, dl
		mov		byte ptr [r8 +r14], al
		inc		r14

		;	al = tuple[3] = reverse_lookup(input[in_ctr++]);
		mov		cl, byte ptr[rsi+r12]				
		inc		r12
		call	reverse_lookup

		;	output[out_ctr++] = (uint8_t)(tuple[2] << 6) + (uint8_t)(tuple[3]);
		shl		bl, 6
		add		al, bl
		mov		byte ptr [r8 +r14], al
		inc		r14

		cmp		r12, r13		
		jb		input_loop

		mov		byte ptr [r8 +r14], 0
		mov		rax, r14

		pop		r14
		pop		r13
		pop		r12
		pop		rdi
		pop		rsi

		ret

	base64_decode ENDP

END