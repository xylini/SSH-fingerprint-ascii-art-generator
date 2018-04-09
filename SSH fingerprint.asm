;Modyfikacja skok konia odwrotny do ruchu wskazówek zegara, jak nie moze to w kierunku ruchu zegara
;Jakub Pajor WiET 2017
;Presentation hash function of public key as ASCII art
; sample input: 0 d5293e9a8d90265d6b6bfb8abba5da23

data segment
	argv db 200 dup ('$')
	argb db 10 dup ('$') 	;przechowuje ilosc znakow wraz z poczatkowa spacja
	args db 10 dup ('$')	;przechowuje w kolejnych bitach dlugosci argumentow
	args_il db 3 dup ('$')	;przechowuje ilosc argumentow
	szachownica db 153 dup (0),'$'  ;szachownica
	znaki_na_polu db ' ','.','o','+','=','*','B','O','X','@','%','&','#','/',100 dup ('^')
	ascii_to_hex db 16 dup (?),'$'
	ramka db '+--[ RSA 1024]----+',10,13,'|','$'
	ramka_dol db '|',10,13,'+-----------------+','$'
	probanapisu db 153 dup (14),'$'
	ostatnia_pozycja db 0
	
	zle_arg_1 db 'Podano zla ilosc argumentow, prawidlowa ilosc to 2','$'
	zle_arg_2 db 'Pierwszy argument powinien byc "0" badz "1"','$'
	zle_arg_3 db 'Zla dlugosc drugiego argumentu','$'
	zle_arg_4 db 'Zly format drugiego argumentu','$'
	ok db 'Argumenty ok','$'
data ends

code segment

parse proc
	
	pushf
	
	mov bx,80h
	mov ch,[bx] 				;wrzucam ilosc bitów (PYTANIE: CZY JEST ICH RAZEM ZE SPACJA CZY MNIEJ XD)
	
	mov bx,82h   				;do bx'a wrzucam adres do pierwszego znaku z lini komend
	
	mov ax,seg data				;zapisuje do argb ilosc bitow w psp
	mov es,ax
	mov di,offset argb
	

	mov byte ptr es:[di],ch
	
	mov di,offset argv 			;es:di - argv[0]

	mov cl,1					;w cl mam licznik bialego znaku, na początek ustawiam 1, to zagwarantuje, że pominie te spacje przed argumentami
	
	wypisuj:
		mov dl,[bx]				;pobieram znak z lini
		
		cmp ch,0  			;sprawdzam czy to już nie koniec argumentow
		je koniec				;jeżeli tak to koniec roboty
		dec ch					;zmniejszam ilosc arg do wczytywania
		
		
		cmp dl,' '				;sprawdzam czy znak jest spacją
		je zjedz_biale
		
		cmp dl,'	' 			;sprawdzam czy znak jest tabem
		je zjedz_biale
		
		xor cl,cl				;skoro wypisywanie tutaj doszło, to znak nie jest spacją/tabem, więc zeruję licznik spacji
		mov byte ptr es:[di],dl ;wpisuję znak do tablicy
		
		inc di					;przesuwam adres na kolejny element w argv
		inc bx					;przesuwam adres na kolejny znak w argumentach
		
		jmp wypisuj				 ;powtarzam aż znajdzie koniec lini
		
	zjedz_biale:
		cmp cl,0 				;jeżeli spacja jest pierwszą jaka się pojawiła
		je newline				;to daję nową linię
		inc bx					;w przeciwnym wypadku przesuwam adres na kolejny znak w argumentach
		jmp wypisuj				;oraz zaczynam wypisuwanie od nowa
		
	newline:					;wrzuca do tablicy znak nowej linii i powrót do początku Dh i Ah
		mov byte ptr es:[di],'!';po każdym argumencje daje znak '!'
		inc di		
		
		inc cl					;zwiększam licznik spacji, gdyż pierwsza się już pojawiła
		inc bx					;kolejny adres w psp
		
		jmp wypisuj 			;wracam do wypisywania
	
	koniec:
	dec di
		mov byte ptr es:[di],'!'
		popf
		ret
			
parse endp


wypisz_args proc
		pushf
		mov	ax,seg data
		mov	ds,ax
		mov dx,offset ascii_to_hex
		
		mov	ah,9  				; wypisz na ekran to co jest w ds:dx
		int	21h
		mov al,0
		popf
		ret
wypisz_args endp


Ender proc
	mov ah,4ch
	int 21h
	ret
Ender endp


policz_argumenty proc			;przechodzi przez argv, jest licznik cl który zlicza ilość znaków do '!', potem wpisuje do args, zeruje się i leci od nowa aż do znaku '$'
	pushf						;dodatkowo zlicza ich ilosc

	mov ax,seg data				;
	mov es,ax
	mov di,offset argv			;es:di - start argv	
	mov si,offset args			;es:si - start args
		
	xor cl,cl					;licznik dlugosci argumentow
	xor ch,ch					;licznik ilosci argumentow
	
	petla:
	mov dl,byte ptr es:[di]		;pobieram pierwszy znak z tablicy
	cmp dl,'$'
	je koniec_p
	
	cmp dl,'!'					;spra
	jne dodaj_licznik
	
	cmp dl,'!'
	je zapisz_dlugosc
	
	koniec_p:
	xor di,di
	mov di,offset args_il
	mov byte ptr es:[di], ch
	
	popf
	ret
	
	dodaj_licznik:
	inc cl
	inc di
	jmp petla
	
	zapisz_dlugosc:
	mov byte ptr es:[si],cl
	inc si
	inc di
	inc ch
	xor cl,cl
	jmp petla
	
policz_argumenty endp

sprawdz_argumenty proc
	pushf
	
	mov ax,seg data	
	mov es,ax
	
	mov di,offset args_il		
	cmp byte ptr es:[di],2		;sprawdzam ilość podanych argumentów
	jne zla_ilosc
	
	
	mov di,offset args
	cmp byte ptr es:[di],1		;sprawdzam dlugosc pierwszego argumentu
	jne zly_format_1
	
	cmp byte ptr es:[di+1],32d	;sprawdzam dlugosc drugiego argumentu
	jne zla_dlugosc_2
	
	jeden:
	mov di,offset argv
	cmp byte ptr es:[di],'1'	;sprawdzam czy pierwszy argument jest jedynką
	je next
	
	zero:
	cmp byte ptr es:[di],'0'	;sprawdzam czy pierwszy argument jest zerem
	jne zly_format_1
	
	
	next:
	xor cl,cl					;zeruje licznik kolejnych znakow drugiego argumentu
	mov di,offset argv			;biore do pamieci adres argumentow
	
	add di,2					;ustawiam offset na poczatek drugiego argumentu
	

	format_drugiego:
		cmp cl,32 					;licznik przejscia po drugim argumencie
		je okej
		
		cmp byte ptr es:[di],'0'	;sprawdzam by każdy znak był z przedziału 0-9,a-f,A-F
		jb zly_format_2
		
		cmp byte ptr es:[di],'9'
		jbe sprawdz_koniec
		
		cmp byte ptr es:[di],'A'
		jb zly_format_2
		
		cmp byte ptr es:[di],'F'
		jbe sprawdz_koniec
		
		cmp byte ptr es:[di],'a'
		jb zly_format_2
		
		cmp byte ptr es:[di],'f'
		ja zly_format_2
	
		
		sprawdz_koniec:
			inc di
			inc cl
		
		jmp format_drugiego
	
	jmp okej
	
zla_ilosc:
	mov	ax,seg data
	mov	ds,ax
	mov dx,offset zle_arg_1
	jmp message
	
zly_format_1:
	mov	ax,seg data
	mov	ds,ax
	mov dx,offset zle_arg_2
	jmp message
	

zla_dlugosc_2:
	mov	ax,seg data
	mov	ds,ax
	mov dx,offset zle_arg_3
	jmp message
	
zly_format_2:
	mov	ax,seg data
	mov	ds,ax
	mov dx,offset zle_arg_4
	jmp message
	
okej:
	;mov	ax,seg data
	;mov	ds,ax
	;mov dx,offset ok
	jmp koniec_m	



message:
	mov	ah,9  				; wypisz na ekran to co jest w ds:dx
	int	21h
	mov al,0
	call Ender

koniec_m:
	popf
	ret
	
sprawdz_argumenty endp


ascii_to_hexx proc
	pushf
	mov ax,seg data
	mov es,ax
	
	mov si,offset ascii_to_hex ;es:si - start tablicy z przerobionymi znakami
	mov di,offset argv			;es:di - start argv z ascii
	add di,2
	
	xor cl,cl
	xor ah,ah
	
przejdz_przez_znaki:

	mov al,byte ptr es:[di]
	cmp al,'!'
	je znaki_koniec
	
	cmp al,'9'				;sprawdzam czy znak jest od '0'-'9'
	jbe liczba
	
	cmp al,'F'
	jbe wielka_litera
	
	cmp al,'f'
	jbe mala_litera
	
	znaki_koniec:
	popf
	ret
	
	liczba:
		sub al,'0'
		add ah,al
		inc cl
		inc di			;przesuwam się po argv
		cmp cl,2		;jeżeli to był drugi znak to napisuję do ascii_to_hex
		je zapisz_znak
		
		push cx
		mov cl,4d
		shl ah,cl		;przesuwam bity w al 4 w lewo ->  00001001 -> 10010000
		pop cx
		jmp przejdz_przez_znaki
		
	wielka_litera:
		sub al,'A'
		add al,10d
		add ah,al
		inc cl
		inc di			;przesuwam się po argv
		cmp cl,2		;jeżeli to był drugi znak to napisuję do ascii_to_hex
		je zapisz_znak
		
		push cx
		mov cl,4d
		shl ah,cl		;przesuwam bity w al 4 w lewo ->  00001001 -> 10010000
		pop cx
		
		jmp przejdz_przez_znaki
	
	mala_litera:
		sub al,'a'
		add al,10d
		add ah,al
		inc cl
		inc di			;przesuwam się po argv
		cmp cl,2		;jeżeli to był drugi znak to napisuję do ascii_to_hex
		je zapisz_znak
		
		push cx
		mov cl,4d
		shl ah,cl		;przesuwam bity w al 4 w lewo ->  00001001 -> 10010000
		pop cx
		
		jmp przejdz_przez_znaki
		
	zapisz_znak:
		mov byte ptr es:[si],ah	;wpisuję zmienionego ascii na liczbe do tablicy ascii_to_hex
		inc si					;przesuwam adres na kolejna komórkę
		xor cl,cl				;zeruje licznik
		xor ah,ah
		jmp przejdz_przez_znaki
		
	
	
ascii_to_hexx endp

ozn_szachownice proc
pushf
	
	mov ax,seg data
	mov es,ax
	
	xor cx,cx
	mov si,offset argv			
	mov ch,byte ptr es:[si]		;do ch wrzucam (0 normalnie, 1 modyfikacja)
	
	mov si,offset szachownica			;ds:di - początek szachownicy
	mov di,offset ascii_to_hex ;ds:si - start tablicy z przerobionymi znakami
	
	
	
	xor bx,bx
	mov bl,76d 					;środek szachownyci
	
	start:
	xor ax, ax
		mov al,byte ptr es:[di]
		cmp al,'$'
		je koniec
		
		sprawdzam_bity:
		cmp cl,4d
		je nowy_hex
		
		call podziel_al
		inc cl
		
		cmp ah,00b
		je lg
		
		cmp ah,01b
		je pg
		
		cmp ah,10b
		je ld
		
		cmp ah,11b
		je pd
	
		lg:
			cmp ch,'1'
			je lg_mod
		
			cmp bl,0d
			je jestem_w_lewym_gornym_rogu
			
			cmp bl,16d
			jbe sufit_slizg_w_lewo
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,0d
			je lewa_sciana_slizg_gora
			pop ax
			
			ruch_lg:
			sub bl, 18d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			sufit_slizg_w_lewo:
				sub bl,1d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
			
			jestem_w_lewym_gornym_rogu:
				jmp sprawdzam_bity
		
			lewa_sciana_slizg_gora:
			pop ax
				sub bl,17d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
		pg:
		cmp ch,'1'
		je pg_mod
		
		cmp bl,16d
		je jestem_w_prawym_gornym_rogu
		
		cmp bl,16d
		jb sufit_slizg_w_prawo
		
		push ax
		xor ax,ax
		mov al,bl
		call podziel_al_dla_szach
		cmp ah,16d
		je prawa_sciana_slizg_gora
		pop ax
		
		ruch_pg:
		sub bl, 16d
		add si,bx
		inc byte ptr es:[si]
		sub si,bx
		jmp sprawdzam_bity
	
			sufit_slizg_w_prawo:
				add bl,1d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
		
			jestem_w_prawym_gornym_rogu:
				jmp sprawdzam_bity
		
			prawa_sciana_slizg_gora:
			pop ax
				sub bl,17d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
		ld:
			cmp ch,'1'
			je ld_mod
			
			cmp bl,136d
			je jestem_w_lewym_dolnym_rogu
			
			cmp bl,136d
			ja podloga_slizg_w_lewo
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,0d
			je lewa_sciana_slizg_dol
			pop ax
			
			ruch_ld:
			add bl, 16d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			podloga_slizg_w_lewo:
				sub bl,1d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
			
			jestem_w_lewym_dolnym_rogu:
				jmp sprawdzam_bity
		
			lewa_sciana_slizg_dol:
			pop ax
				add bl,17d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
		pd:
			cmp ch,'1'
			je pd_mod
			
			cmp bl,152d
			je jestem_w_prawym_dolnym_rogu
			
			cmp bl,136d
			jae podloga_slizg_w_prawo
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,16d
			je prawa_sciana_slizg_dol
			pop ax
		
			ruch_pd:
			add bl, 18d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			podloga_slizg_w_prawo:
				add bl,1d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
			
			jestem_w_prawym_dolnym_rogu:
				jmp sprawdzam_bity
		
			prawa_sciana_slizg_dol:
			pop ax
				add bl,17d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
				
				
				
		lg_mod:
			cmp bl,0d
			je jestem_w_lewym_gornym_rogu_mod
			
			cmp bl,18d
			je ruch_lg
			
			cmp bl,16d
			jbe sufit_slizg_w_lewo		;z lg
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,0d
			je lewa_sciana_slizg_gora
			pop ax
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,1d
			je skok_lewo_prawo_gora
			pop ax
		
			sub bl, 19d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			
			jestem_w_lewym_gornym_rogu_mod:
				jmp sprawdzam_bity
		
			skok_lewo_prawo_gora:
			pop ax
				sub bl,35d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
		pg_mod:
			cmp bl,16d
			je jestem_w_prawym_gornym_rogu_mod
			
			cmp bl,32d
			je ruch_pg
			
			cmp bl,16d
			jb sufit_slizg_w_prawo		;z lg
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,16d
			je prawa_sciana_slizg_gora
			pop ax
			
			cmp bl,32d
			jb skok_sufit_prawo_gora
		
			sub bl, 33d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			
			jestem_w_prawym_gornym_rogu_mod:
				jmp sprawdzam_bity
		
			skok_sufit_prawo_gora:
				sub bl,15d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
				
		ld_mod:
			cmp bl,136d
			je jestem_w_prawym_dolnym_rogu_mod
			
			cmp bl,120d
			je ruch_ld
			
			cmp bl,136d
			ja podloga_slizg_w_lewo		;z ld
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,0d
			je lewa_sciana_slizg_dol
			pop ax
			
			cmp bl,120d
			ja skok_podloga_lewo_dol
		
			add bl, 33d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			
			jestem_w_prawym_dolnym_rogu_mod:
				jmp sprawdzam_bity
		
			skok_podloga_lewo_dol:
				add bl,15d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				
		pd_mod:
			cmp bl,152d
			je jestem_w_p_dolnym_rogu_mod
			
			cmp bl,134d
			je ruch_pd
			
			cmp bl,136d
			jae podloga_slizg_w_prawo		;z pd
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,16d
			je prawa_sciana_slizg_dol
			pop ax
			
			push ax
			xor ax,ax
			mov al,bl
			call podziel_al_dla_szach
			cmp ah,15d
			je skok_prawo_prawo_dol
			pop ax
		
			add bl, 19d
			add si,bx
			inc byte ptr es:[si]
			sub si,bx
			jmp sprawdzam_bity
	
			
			jestem_w_p_dolnym_rogu_mod:
				jmp sprawdzam_bity
		
			skok_prawo_prawo_dol:
			pop ax
				add bl,35d
				add si,bx
				inc byte ptr es:[si]
				sub si,bx
				jmp sprawdzam_bity
				

						
koniec:

mov si,offset ostatnia_pozycja
mov byte ptr es:[si],bl

popf
ret

nowy_hex:
	xor cl,cl
	inc di
	jmp start

ozn_szachownice endp

podziel_al proc		;wynik w al, reszta w ah
	push bx
	mov bl,100b
	div bl
	pop bx
	ret
podziel_al endp

podziel_al_dla_szach proc		;wynik w al, reszta w ah
	push bx
	mov bl,17d
	div bl
	pop bx
	ret
podziel_al_dla_szach endp




zrob_szchownice proc
pushf
	mov ax,seg data
	mov es,ax
	
	mov di,offset szachownica			;es:di - początek szachownicy
	mov si,offset znaki_na_polu 		;es:si - start tablicy z odpowiadajacymi znakami
	
	
	
	zamien_liczby_na_znaki:
		xor dx,dx
		mov dl,byte ptr es:[di]				;przechowuje liczby z szachownicy
		cmp dl,'$'
		je koniec_zamiany
		
		;add dl,'0'
		mov ax,dx
		add si,ax
		mov al, byte ptr es:[si]			;zawiera znaki odpowiadajace liczbom w szachownicy
		mov byte ptr es:[di],al
		sub si,dx
		inc di
		
		jmp zamien_liczby_na_znaki
		

		
	
	
koniec_zamiany:
	
	mov byte ptr es:[di-77d],'S'
	mov si,offset ostatnia_pozycja
	mov di, offset szachownica
	xor dx,dx
	xor ax,ax
	mov dl,byte ptr es:[si]
	mov ax,dx
	add di,ax
	mov byte ptr es:[di],'E'
popf
ret
zrob_szchownice endp

wypisz_szachownice proc		;działa
	pushf
		xor cl,cl
		mov ax,seg data
		mov es,ax
		mov di,offset szachownica
		
		mov ds,ax
		mov dx,offset ramka
		
		mov ah,9
		int 21h
		
		
	wypisuj_szachownice:
	
		mov dl,byte ptr es:[di]
		
		cmp dl,'$'
		je koniec_wypisywania
		cmp cl, 17
		je nowa_linia
		
		dalej:
		mov ah,2
		int 21h
		
		
		
		inc di
		inc cl
	jmp wypisuj_szachownice
	
	nowa_linia:
		mov dl,'|'
		mov ah,2
		int 21h
	
		mov dl,10d
		mov ah,2
		int 21h
		
		mov dl,13d
		mov ah,2
		int 21h
		
		mov dl,'|'
		mov ah,2
		int 21h
		
		xor cl,cl
		jmp wypisuj_szachownice
		
	koniec_wypisywania:
		mov ax,seg data
		mov ds,ax
		mov dx,offset ramka_dol
		mov ah,9
		int 21h
	popf
	ret

wypisz_szachownice endp

;---------------------------------------------------------------

start:
	call parse
	call policz_argumenty
	call sprawdz_argumenty
	call ascii_to_hexx
	;call oznacz_szachownice
	call ozn_szachownice
	call zrob_szchownice
	call wypisz_szachownice
	;call wypisz_args
	
	call Ender




code ends

stos1	segment stack
		dw	200 dup(?)
		db 200 dup(?)
top1	dw	?

stos1	ends


end start