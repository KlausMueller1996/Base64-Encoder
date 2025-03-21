
option casemap:none

.code

public reverse_lookup
public base64_decode

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;	rcx: character to lookup
	;
	; register usage:
	;	rax: for calculations
	;	rcx: for comparisons
	; 
	; returns: 
	;	index value of char in base 64 conversion table;
	;   -1 in case of an error 
	; 
	; algorithm:
	;   base 64 conversion table is = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	;   calculate index in table of given char by calculations using ascii values instead of
	;   iterating through table
	;
	;	if (value_to_find == '+')
	;		return 62;
	;	else if (value_to_find == '/')
	;		return 63;
	;	else if (value_to_find == '=')
	;		return 0;
	;	else if (value_to_find >= '0' && value_to_find  <= '9')
	;		return value_to_find + 4 ; // - '0' + 52;
	;	else if (value_to_find >= 'A' && value_to_find <= 'Z')
	;		return value_to_find - 'A';
	;	else if (value_to_find >= 'a' && value_to_find <= 'z')
	;		return value_to_find - 'a' + 26;
	;	return -1;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	reverse_lookup PROC

		cmp		cl, '+'
		jne		check_slash
		mov		rax, 3Eh
		ret

check_slash:
		cmp		cl, '/'
		jne		check_equals
		mov		rax, 3Fh
		ret

check_equals:
		cmp		cl, '='
		jne		check_number
		mov		rax, 0
		ret

check_number:
		cmp		cl, '0'
		jb		check_capital_letter
		cmp		cl, '9'
		ja		check_capital_letter
		movzx	rax, cl
		add		rax, 4
		ret

check_capital_letter:
		cmp		cl, 'A'
		jb		check_non_capital_letter
		cmp		cl, 'Z'
		ja		check_non_capital_letter
		movzx	rax, cl
		sub		rax, 'A'
		ret

check_non_capital_letter:
		cmp		cl, 'a'
		jb		unknown_character
		cmp		cl, 'z'
		ja		unknown_character
		movzx	rax, cl
		sub		rax, 47h
		ret
	
unknown_character:
		mov		rax, 0ffh
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
	;	index value of char in base 64 conversion table 
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

		pop		r14
		pop		r13
		pop		r12
		pop		rdi
		pop		rsi

		ret

	base64_decode ENDP



END
