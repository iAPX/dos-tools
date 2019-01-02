
	.8086
	dosseg
	.Model	small
	.Stack	100h

	.Code
	org	100h
Debut:
;	On se contente de d‚terminer la longueur libre...
	mov	ax,word ptr ds:[0002]
	mov	bx,cs
	sub	ax,bx
	mov	cl,6
	shr	ax,cl

;	Bon, ax=n KO...
	mov	bl,100
	div	bl

	mov	dl,al
	add	dl,'0'
	call	OutCar

	mov	al,ah
	xor	ah,ah
	mov	bl,10
	div	bl

	mov	dl,al
	add	dl,'0'
	call	OutCar

	mov	dl,ah
	add	dl,'0'
	call	OutCar

;	Fin de la chaine
	mov	ax,cs
	mov	ds,ax
	mov	dx,offset String_mem
	mov	ah,9
	int	21h

;	On quitte
	mov	ax,4C00h
	int	21h

String_Mem	db	" Ko de m‚moire libre.",13,10,"$"

OutCar	proc
;	Sortie de DL … l'‚cran
	push	ax
	mov	ah,2
	int	21h
	pop	ax
	ret
OutCar	endp

	end	debut
