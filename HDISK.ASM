
	DOSSEG
	.8086
	.MODEL small

	.stack	100h

	.CODE
DEBUT:
;	Prise de la base de l'horloge... h‚h‚h‚
	assume cs:@code, ds:nothing, es:nothing
	mov	ax,0040h
	mov	es,ax
	mov	si,006Ch
	mov	ax,word ptr es:[si]
	mov	cs:[x_reg],ax

;       initialisation des segments...
	mov ax,@code
	mov ds,ax
	mov es,ax
	assume	ds:@code, es:@code

;	Affichage de la chaine de d‚part
        mov	dx,offset chaine0
	call	outstr

;	Lecture des paramŠtres du disque dur et affichage de ceux-ci...
	call	read_params

;	Calcul du d‚bit maxi (vitesse de rotation !) du disque dur...
	call	debit

;	Estimation de l'entrelacement actuel du disque...
	call	entrelacement

;	Affichage des temps d'accŠs...
	call	seeker

	mov	ax,fl_cache
	or	ax,ax
	jz	termine
	mov	dx,offset cached
	call	outstr

termine:
;       on quitte !
	MOV AX,4C00H
	INT 21H

outstr	proc	near
;	Sortie juste de la chaŒne point‚e par DX
	mov	ah,9
	int	21h
	ret
outstr	endp

get_interrupt	proc	near
;	Initialise le compteur … "avant interruption"...
	mov	word ptr cs:[int8_count],-1

;	D‚tourne l'interruption 08h,
	push	ax
	push	bx
	push	es
	cli
	mov	ax,0
	mov	es,ax
	mov	si,0020h
	mov	ax,word ptr es:[si]
	mov	bx,word ptr es:[si][2]
	mov     cs:[int8_off],ax
	mov	cs:[int8_seg],bx
	mov	ax,offset new_int8
	mov	bx,cs
	mov	word ptr es:[si],ax
	mov	word ptr es:[si][2],bx
	sti
	pop	es
	pop	bx

;	Attends l'interruption de d‚part...
	mov	ax,-1
get_int_loop:
	cmp	ax,cs:[int8_count]
	jz	get_int_loop

;	Et maintenant on y va !!!!
	pop	ax
	ret
get_interrupt	endp

put_interrupt	proc	near
;	On rends le vecteur d'interruption, aprŠs avoir lu le compteur...
	push	word ptr cs:[int8_count]
	cli
	mov	ax,0
	mov	es,ax
	mov	di,0020h
	mov	ax,cs:[int8_off]
	mov	bx,cs:[int8_seg]
	mov	word ptr es:[di],ax
	mov	word ptr es:[di][2],bx
	sti
	pop	ax

;	On calcule le temps en ms, je crois ?!
	mov	cx,500
	mul	cx
	mov	cx,92
	div	cx
	ret
put_interrupt	endp

new_int8	proc	far
;	Routine d'interruption, simple...

;	Incr‚ment du compteur d'appel, pour un temps "juste"
	inc	word ptr cs:[int8_count]

;	Appel de l'ancienne routine d'interruption...
	pushf
	call	dword ptr cs:[int8_off]

	iret
new_int8	endp

dtime	proc	near
;	Calcule la dur‚e d'‚xecution de la routine incrimin‚e...
	push	ax
	push	dx
	call	get_interrupt
	pop	dx
	pop	ax
	push	ds
	push	es
	call	ax
	pop	es
	pop	ds
	call	put_interrupt
	mov	dx,0
	ret
dtime	endp


outcar  proc    near
;       affichage (al)
	push ax
	mov dl,al
	mov ah,02
	int 21h
	pop ax
	ret
outcar  endp


aff4ch  proc    near
;       affichage ax en 5 chiffres :
	mov	cx,100
	div	cx
	push	dx

	mov	cx,100
	mov	dx,0
	div	cx
	push	dx

	cmp	ax,9
	ja	aff4ch2
	push	ax
	mov	al,' '
	call	outcar
	pop	ax
	cmp	ax,0
	jne	aff4ch1
	mov	al,' '
	call	outcar
	jmp	short aff4ch3
aff4ch1:
	add	al,'0'
	call	outcar
	jmp	short aff4ch3
aff4ch2:
	call	aff2ch
aff4ch3:
	pop	ax
	call	aff2ch

	mov al,'.'
	call outcar
	pop ax
	call aff2ch
	ret
aff4ch  endp

aff3ch	proc	near
;	Affichage ax en 3 chiffres :
	mov	cl,100
	div	cl
	push	ax
	add	al,'0'
	call	outcar
	pop	ax
	mov	al,ah
	xor	ah,ah
	jmp	Aff2ch
aff3ch	endp

aff2ch  proc    near
;       affichage ax en 2 chiffres :
	mov cl,10
	div cl
	push ax
	add al,'0'
	call outcar
	pop ax
	mov al,ah
	add al,'0'
	call outcar
	ret
aff2ch  endp

debit	proc	near

	mov	dx,8
	mov	ax,offset throuput
	call	dtime

	mov	dx,8
	mov	ax,offset throuput
	call	dtime

	mov	real_throuput,ax
	cmp	ax,26
	jna	debit_incorrect

	mov	dx,1
	mov	ax,offset throuput
	call	dtime
	mov	max_throuput,ax
	cmp	ax,26
	ja	debit_correct

debit_incorrect:
	mov	word ptr [fl_cache],-1
	ret

debit_correct:
	mov	dx,offset chaine1
	call	outstr

;	Reprends les donn‚es...
	mov	ax,real_throuput

;	Calcule de 85000/temps (en 100Šme de seconde)
	mov	cx,ax
	mov	ax,8500
	mov	bx,200
	mul	bx
	div	cx
	mov	cx,5
	mul	cx		;Pour obtenir DX correct !!!

;	Affichage du r‚sultat ...
	call	aff4ch

	mov	dx,offset chaine2
	call	outstr

;	Maintenant le d‚bit th‚orique maximal...
	mov	ax,max_throuput

;	Le temps...
	mov	cx,ax
	mov	ax,8500
	mov	bx,200
	mul	bx
	div	cx
	mov	cx,5
	mul	cx

	call	aff4ch

;	ChaŒne de terminaison...
	mov	dx,offset chaine3
	call	outstr

	ret
debit	endp


entrelacement	proc	near
;	D‚duit des diff‚rences de vitesse entre les tests pr‚c‚dents,
;	l'entrelacement du disque dur...
	mov	ax,fl_cache
	or	ax,ax
	jnz     entre_fin

	mov	dx,offset chaine4
	call	outstr

	mov	ax,real_throuput
	mov	dx,0
	mov	bx,max_throuput
	div	bx

	add	dx,dx
	cmp	dx,bx
	jna	no_more_inter
	inc	ax			;On a fais l'arrondit !!!

no_more_inter:
	xor	ah,ah
	mov	interleave,ax

	add	al,'0'
	call	outcar

	mov	dx,offset chaine5
	call	outstr

entre_fin:
	ret
entrelacement	endp


throuput	proc	near
;	D‚bit du disque dur, calcul‚ en lisant x fois le cylindre 1, tˆte 0,
;	en lisant DX secteurs, du secteur 1 au DX
	mov	cx,100		;Lecture de 850Ko de donn‚es
throu_loop:
	push	cx
	push	dx

;	Une piste … la fois !!!
	neg	cx
	add	cx,101
	add	cx,cx
	add	cx,cx
	add	cx,cx
	add	cx,cx
	add	cx,cx
	add	cx,cx
	and	cx,0FFC0h
	add	cx,1

	mov	ax,@code
	mov	es,ax			;Segment des donn‚es
	mov	al,dl			;Nombre de secteurs … lire...
	mov	bx,offset string1	;Offset des donn‚es
	mov	ah,2			;Lecture de secteurs
	mov	dl,80h			;Premier disque dur (80h)
	mov	dh,0			;PremiŠre tˆte (0)
	mov	cx,256+1		;Cylindre 1, Secteur 1
	int	13h			;LECTURE ! GO....

	pop	dx
	pop	cx
	loop	throu_loop
	ret
throuput	endp


read_params	proc	near
;	Lecture des informations sur le disque dur courant,
;	et affichage de celles-ci.
	mov	dx,offset param1s
	call	outstr

	mov	ah,8
	mov	dl,80h
	int	13h

;	On stocke les infos dans les variables ad-hoc...
	xor	ax,ax
	mov	al,dl
	mov	nb_disk,ax
	mov	al,dh
	inc	ax
	mov	nb_head,ax		;de 0 … Nb_Head-1 : Tˆtes
	mov	ax,cx
	and	ax,63
	mov	nb_sector,ax		;Nombre de secteurs
	mov	al,ch
	mov	ah,cl			;Exchange ?!
	mov	cl,6
	shr	ah,cl
	mov	nb_cylinder,ax		;de 0 … Nb_Cylinder-1 : cylindres

;	Calcul de la surface globale...
	mov	ax,nb_head
	mov	bx,nb_sector
	mul	bx
	mov	bx,2			;En secteurs de 512 octets >>Ko
	div	bx
	mov	bx,nb_cylinder
	mul	bx
	mov	bx,1024			;De Ko en Mo.
	div	bx
	mov	capacite,ax

;	On r‚affiche ‡a formatt‚...
	mov	ax,nb_head
	add	al,'0'
	call	outcar

	mov	dx,offset param2s
	call	outstr

	mov	ax,nb_cylinder
	mov	dx,0
	mov	cx,100
	div	cx
	push	dx
	call	aff2ch
	pop	ax
	call	aff2ch

	mov	dx,offset param3s
	call	outstr

	mov	ax,nb_sector
	call	aff2ch

	mov	dx,offset param4s
	call	outstr

	mov	ax,capacite
	mov	cl,100
	div	cl
	push	ax
	xor	ah,ah
	or	al,al
	jz	read_param0
	call	aff2ch
read_param0:
	pop	ax
	mov	al,ah
	xor	ah,ah
	call	aff2ch

	mov	dx,offset param5s
	call	outstr

;	Positionne cur_head et cur_sect en vue de l'accŠs moyen...
	mov	ax,x_reg
	and	ax,15
	mov	cur_offset,ax		;D‚placement sur le disque en +

	mov	ax,x_reg
	mov	cl,4
	shr	ax,cl
	xor	dx,dx
	mov	bx,nb_head
	dec	bx
	div	bx
	inc	dx
	mov	cur_head,dx		;Le reste = la tˆte de d‚part

	xor	dx,dx
	mov	bx,nb_sector
	dec	bx
	div	bx
	inc	dx			;de 1 … n-1 !!!
	mov	cur_sect,dx		;Le reste = le secteur de d‚part

;	Fini, on revient.
	ret
read_params	endp


seeker	proc	near
;	Mesure des diff‚rents Seek Rate (Vitesse de changement de piste)
	mov	ax,fl_cache
	or	ax,ax
	jnz	seek_fin

	mov	dx,offset chaine6
	call	outstr

	mov	ax,offset first_last
	call	dtime
	mov	cx,20
	mul	cx		;De n secondes, on passe … 20n...
	call	aff4ch

	mov	dx,offset chaine7
	call	outstr

seek_fin:
	mov	dx,offset chaine7b
	call	outstr

	mov	ax,offset average_seek
	call	dtime
	mov	cx,10
	mul	cx
	call	aff4ch

	mov	dx,offset chaine8
	call	outstr

	ret
seeker	endp


first_last	proc	near
;	AccŠs du premier au dernier... na !
	mov	cx,25
fl_loop:
	push	cx

	mov	ax,@code
	mov	es,ax			;Segment des donn‚es
	mov	al,1			;Nombre de secteurs … lire (1)
	mov	bx,offset string1	;Offset des donn‚es
	mov	ah,2			;Lecture de secteurs
	mov	dl,80h			;Premier disque dur (80h)
	mov	dh,0			;PremiŠre tˆte (0)

	mov	cx,nb_cylinder		;on va ruser !!!
	dec	cx
	shr	ch,1
	shr	ch,1
	shr	ch,1
	shr	ch,1
	shr	ch,1
	shr	ch,1
	xchg	ch,cl

	inc	cx			;Dernier cylindre (x 64), Secteur 1
	int	13h			;LECTURE ! GO....

	mov	ax,@code
	mov	es,ax			;Segment des donn‚es
	mov	al,1			;Nombre de secteurs … lire (1)
	mov	bx,offset string1	;Offset des donn‚es
	mov	ah,2			;Lecture de secteurs
	mov	dl,80h			;Premier disque dur (80h)
	mov	dh,0			;PremiŠre tˆte (0)
	mov	cx,256+1		;Cylindre 1, secteur 1...
	int	13h			;LECTURE ! GO....

	pop	cx
	loop	fl_loop

;	Et hop, on revient !!!
	ret
first_last	endp

average_seek	proc	near
;	Fais 100 accŠs al‚atoires sur le disque dur, pour rire... h‚h‚h‚
	mov	cx,100
as_loop:
	push	cx

	add	cx,cx
;	Stocke dans CX le num‚ro de cylindre voulu...
	mov	ax,nb_cylinder
	sub	ax,17
	mov	bx,cx
	mov	cx,rnd_tab[bx]
	and	cx,32767
	mul	cx
	shl	ax,1
	rcl	dx,1			;1 bit de plus ???
	add	dx,Cur_Offset

	mov	cl,6
	shl	dh,cl
	xchg	dh,dl
	and	dx,0FF80h
	add	dx,cur_sect		;Num‚ro de secteur courant ajout‚
	mov	cx,dx

	mov	ax,@code
	mov	es,ax			;Segment des donn‚es
	mov	al,1			;Nombre de secteurs … lire (1)
	mov	bx,offset string1	;Offset des donn‚es
	mov	ah,2			;Lecture de secteurs
	mov	dx,cur_head		;Tˆte courante, h‚h‚h‚
	mov	dl,80h			;Premier disque dur (80h)
	int	13h			;LECTURE ! GO....

	pop	cx
	loop	as_loop

	ret
average_seek	endp



	even
string1 db      10000 dup (?)


real_throuput	dw	0
max_throuput	dw	0
interleave	dw	0

int8_off	dw	0
int8_seg	dw	0
int8_count	dw	0

nb_disk		dw	0
nb_head		dw	0
nb_cylinder	dw	0
nb_sector	dw	0
capacite	dw	0		;En Mo !!!
fl_cache	dw	0

;	Pour l'accŠs al‚atoire anti-cache
x_reg		dw	0
cur_head	dw	0
cur_sect	dw	0
cur_offset	dw	0		;D‚placement sur le cylindre

cached	db	13,10,10
	db	"Un cache-disque est install‚ sur cette unit‚.",13,10
	db	"D‚sactivez-le avant de relancer le programme HDISK.",13,10
	db	10
	db	"Ce programme n'a pas ‚t‚ con‡u pour analyser et tester",13,10
	db	"les caches !!! Merci de votre compr‚hension...",13,10,"$"

chaine0		db	"    ****    Hard Disk Drive  Benchmark  v1.1    ****",13,10
		db	"              (c)  1990   Philippe  Vigier",13,10
		db	10,"$"

chaine1		db	"D‚bit du disque dur     : $"
chaine2		db	" Ko/s.",13,10
		db	"D‚bit optimum th‚orique : $"
chaine3		db	" Ko/s (Avec un entrelacement de 1:1).",13,10,"$"

chaine4		db	"Entrelacement actuel du disque dur  1:$"
chaine5 	db	"  .",13,10,10,"$"

chaine6		db	"Temps d'accŠs d‚but <-> fin   : $"
chaine7		db	" ms.",13,10,"$"
chaine7b	db	"Temps d'accŠs moyen du disque : $"
chaine8		db	" ms.",13,10,"$"

;	ChaŒnes pour l'affichage des paramˆtres du disque...

param1s	db	"      Nombre de tˆtes du disque : $"
param2s	db	13,10
	db	"            Nombre de cylindres : $"
param3s	db	13,10
	db	"    Nombre de secteurs/cylindre : $"
param4s	db	13,10
	db	"         Capacit‚ du disque dur : $"
param5s	db	" Mo",13,10,10,"$"

;	Valeurs al‚atoires pour tester le piste … piste...
rnd_tab		DW	 28588, 23086, 1655, 30259, 8507
		DW	 10602, 3340, 9626, 27022, 27865
		DW	 3463, 25554, 4079, 30365, 6529
		DW	 25612, 17097, 25466, 25268, 31003
		DW	 20900, 27856, 17658, 30577, 1835
		DW	 23201, 28750, 14111, 9001, 5520
		DW	 13000, 13784, 29831, 22751, 25251
		DW	 22765, 4943, 1136, 26682, 20305
		DW	 15019, 3780, 26630, 5014, 17125
		DW	 5886, 3233, 3565, 15207, 5855
		DW	 28869, 22057, 9403, 13514, 10572
		DW	 5563, 19084, 13760, 28464, 2486
		DW	 15778, 3941, 27020, 9420, 28137
		DW	 6648, 6040, 20815, 25706, 25182
		DW	 23216, 21296, 7503, 7191, 8269
		DW	 18945, 482, 13126, 11273, 21237
		DW	 653, 32428, 414, 19166, 20699
		DW	 4524, 28390, 12334, 14708, 11847
		DW	 13787, 9462, 7716, 22305, 22168
		DW	 4329, 4051, 377, 31061, 25432
		DW	 2189, 26420, 30830, 30006, 17787


	end DEBUT
