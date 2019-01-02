
	DOSSEG
	.8086
	.8087
	.MODEL small

	.stack	100h

	.CODE
DEBUT:
;       initialisation des segments...
	mov ax,@code
	mov ds,ax
	mov es,ax
	assume ds:@code, es:@code

;	Initialisation du pointeur sur l'espace ram video.
	call	set_video

;	Affichage de la chaine de d‚part
        mov	dx,offset chaine0
	mov	ah,9
	int	21h

;       initialisation pointeurs :
	mov ax,offset string1
	and ax,0fff0h
	add ax,16
	mov ptr1,ax
	mov ax,offset string2
	and ax,0fff0h
	add ax,16
	mov ptr2,ax

;	D‚termination du type de la CPU...
	call	determine_cpu
	mov	ax,cpu_type
	dec	ax
	add	ax,ax
	mov	bx,ax
	mov	dx,cpu_tab[bx]
	mov	ah,9
	int	21h
	mov	dx,offset cpu_string
	mov	ah,9
	int	21h

;       affichage vitesse cpu en mhz :
	call mips

;       affichage vitesse en mips_maxi :
	call mips2

;	affichage vitesse en mips_moyens :
	call mips0

;       affichage vitesse en mips_mini :
	call mips3

termine:
;       le taux de tfr quand-meme :
	call tfr_rate

;	On met maintenant l'indication du mapping m‚moire...
	call memory_scan

;       on quitte !
	MOV AX,4C00H
	INT 21H


determine_cpu	proc	near
;	D‚termination exacte du type de l'unit‚ centrale...
;	1-8088		5-80188		 9-80386
;	2-8086		6-80186		10-80486
;	3-Nec V20	7-80286
;	4-Nec V30	8-80386sx
	xor	ax,ax
	push	ax
	popf
	pushf
	pop	ax
	and	ax,0F000h
	cmp	ax,0F000h
	je	pas_386_286

;	Nous avons … faire soit … un 286, soit un 386/486
	mov	ax,7000h
	push	ax
	popf
	pushf
	pop	ax
	and	ax,7000h
	jne	cest_386_486		;Un 32 bits est d‚tect‚...

;	Il s'agit d'un modeste et vulgaire 80286
	mov	cpu_type,7
	ret
cest_386_486:
;	Par d‚faut un 80386
	mov	cpu_type,9		;… ‚claircir et modifier...
	ret

pas_386_286:
;	Il s'agit d'un 16 bits des vieilles g‚n‚rations...
	mov	dl,5
	mov	al,0FFh
	mov	cl,21h
	shr	al,cl
	jne	cest_186_188		;un des iAPX 188/186

;	Reste plus que les iAPX 88/86 et Nec serie V
	mov	dl,1
	push	cs
	pop	es
	sti
	mov	si,0
	mov	cx,0FFFFh
	rep	lods byte ptr es:[si]
	or	cx,cx
	jne	cest_86_88		;ah ! plus que 8/16 bits … voir.

;	C'est un V20 ou V30
	mov	dl,3
cest_186_188:
cest_86_88:
	push	cs
	pop	es
	std
	mov	al,0FBh
	mov	cx,3
	mov	di,offset cs:fill_it
	cli
	rep	stosb
fill_it:
	cld
	nop
	nop
	nop
	inc	dx
	nop
	xor	dh,dh
	mov	cpu_type,dx		;Le type est trouv‚ !!
	ret
determine_cpu	endp



get_interrupt	proc	near
;	get_interrupt_proc
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
	push	es
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

;	Rappel, pour le fun et la pr‚cision ...
	Int	08h
	Int	08h

	pop	ax
	pop	es

;	On calcule le temps en ms, je crois ?!
	mov	cx,500
	mul	cx
	mov	cx,91
	div	cx

	ret
put_interrupt	endp

new_int8	proc	far
;	Routine d'interruption, simple...

;	Incr‚ment du compteur d'appel, pour un temps "juste"
	inc	word ptr cs:[int8_count]

;	Appel de l'ancienne routine d'interruption...
;	jmp	dword ptr cs:[int8_off]
	push	ax
	mov	al,20h
	out	20h,al
	pop	ax
	iret
new_int8	endp

dtime	proc	near
;	Calcule la dur‚e d'‚xecution de la routine incrimin‚e...
	call	get_interrupt
	push	ds
	push	es
	call	ax
	pop	es
	pop	ds
	call	put_interrupt
	mov	dx,0
	ret
dtime	endp


nops    proc    near
;	Nops_proc
;       Fais faire 3Millions de NOP !!!!
	mov cx,3000*4
nop2:
	rept 995
	nop
	endm

	dec cx
	je fin_loop
	jmp nop2
fin_loop:
	ret
nops    endp


outcar  proc    near
;       affichage (al)
	push ax
	push dx
	mov dl,al
	mov ah,02
	int 21h
	pop dx
	pop ax
	ret
outcar  endp


mips    proc    near
;	mips_proc
;       Calcule la vitesse en Mhz du microprocesseur...
	mov ah,09h
	mov dx,offset chaine1
	int 21h

	mov ax,offset nops
	call dtime

;       Calcul en Mhz de la diff‚rence :
	mov cx,ax
	mov ax,9000
	cmp cpu_type,1
	jnz mipce
	mov ax,12000
mipce:
	mov bx,40
	mul bx
	div cx

	push	ax
	mov	bx,10
	mul	bx
	mov	cs:[freq],ax
	pop	ax

;       on peut l'afficher :
	call aff4ch

	mov ah,09h
	mov dx,offset chaine2
	int 21h

;       fini !!!
	ret
mips    endp

clcs    proc    near
;	clcs_proc
;       fais 6millions de clcs !!!
	mov cx,6000
clcs0:
	rept 1000
	clc
	endm
	dec cx
	jz clcs1
	jmp clcs0
clcs1:
	ret
clcs    endp

xors	proc	near
;	xor_proc
;	fais 6 millions de XOR !!!
	mov	cx,6000
xors0:
	rept	1000
	xor	ax,ax
	endm
	dec	cx
	jz	xors1
	jmp	xors0
xors1:
	ret
xors	endp

loads	proc	near
;	loads_proc
;	fais 6 millions de move data
	mov	cx,6000
loads0:
	rept	1000
	mov	al,123
	endm
	dec	cx
	jz	loads1
	jmp	loads0
loads1:
	ret
loads	endp

moyen	proc	near
;	moyen_proc
;	fais	6 millions d'instructions, soit 750.000 boucles
	mov	cx,750
moyen0:
	rept	1000
	mov	ax,word ptr [si]
	cmp	ax,word ptr [di]
	mov	word ptr [si],ax
	inc	ax
	dec	ax
	shl	ax,1
	shr	ax,1
	mul	cx
	endm
	dec	cx
	jz	moyen1
	jmp	moyen0
	nop
	nop
	nop
	nop
moyen1:
	ret
	nop
	nop
	nop
moyen	endp

divs    proc    near
;	divs_proc
;       fais 1000000 idiv cx :
	mov bx,1000
	mov cx,1
	mov ax,12345
	mov dx,0
divs0:
	rept    1000
	div cx
	endm

	dec bx
	jz divs1
	jmp divs0
	nop
	nop
	nop
	nop

divs1:
	ret
	nop
	nop
	nop
	nop
divs    endp

tfrs    proc    near
;	tfrs_proc
;       fais 1000000 transfert :
	mov bx,10000
tfr0:
	rept 100
	mov cx,31023
	mov ax,12345
	mov dx,25647
	endm
	dec bx
	jz tfr1
	jmp tfr0
	nop
	nop
	nop
	nop
tfr1:
	ret
	nop
	nop
	nop
	nop
tfrs    endp

mips2   proc    near
;	mips2_proc
;       affichage nombre maxi de mips :
	mov dx,offset chaine3
	mov ah,09h
	int 21h

;	Calcul du plus court Mips !!!! h‚h‚h‚...
	mov	ax,offset xors
	call	dtime
	push	ax
	mov	ax,offset loads
	call	dtime
	push	ax
	mov	ax,offset clcs
	call	dtime
;	Prise du plus petit des r‚sultats...
	pop	bx
	cmp	ax,bx
	ja	mips2y
	mov	bx,ax
mips2y:
	pop	bx
	cmp	ax,bx
	ja	mips2z
	mov	bx,ax
mips2z:

;       calcul en real mips :
	mov cx,ax
	mov ax,30000
	mov bx,2
	mul bx
	div cx
;       mips*100 dans ax...
	call aff4ch

	mov dx,offset chaine4
	mov ah,09h
	int 21h
	ret
mips2   endp

mips0	proc	near
;	mirps0_proc
;	affichage nombre moyen de mips :
	mov dx,offset chaine7
	mov ah,09
	int 21h

	mov ax,offset moyen
	call dtime
;	calcul en real mips :
	mov cx,ax
	mov ax,30000
	mov bx,2
	mul bx
	div cx
;	Mips * 100 dans ax
	call aff4ch

	mov dx,offset chaine8
	mov ah,09h
	int 21h
	ret
mips0	endp


mips3   proc    near
;	mips3_proc
;       nombre minimal de mips :
	mov ah,09h
	mov dx,offset chaine5
	int 21h

	mov ax,offset divs
	call dtime

	mov cx,ax
	mov ax,10000
	mov dx,0
	div cx
	call aff4ch

	mov ah,09h
	mov dx,offset chaine6
	int 21h

	ret
mips3   endp


mulx1   proc    near
;	mulx1_proc
	mov cx,1
	call mulx
	ret
mulx1   endp

mulx2   proc near
;	mulx2_proc
	mov cx,31023
	call mulx
	ret
mulx2   endp


mulx    proc    near
;	mulx_proc
;       nananere : mul cx *1000000
	mov bx,10000
muly:
	rept 100
	mov ax,12345
	mul cx
	endm
	dec bx
	jz mulz
	jmp muly
	nop
	nop
	nop
	nop

mulz:
	ret
	nop
	nop
	nop
	nop
mulx    endp

tfr_b   proc    near
;	tfr_b_proc
;       transfert de 2 Mo de donn‚es :
	mov ax,deplacement
	cmp ax,-1
	jz tfr_vb			;Cas de la RAM Video

	mov bx,@code
	mov es,bx
	mov ds,bx
	mov cx,2048
tfr1a:
	push cx
	mov cx,1024
	mov si,ptr1
	mov di,si
	rep movsb		; Ancienne maniŠre
	pop cx
	loop tfr1a
	nop
	nop
	nop
	nop
	ret
tfr_b   endp

tfr_vb	proc	near
;	tfr_vb_proc
;	transfert de 2Mo de donn‚es
;	Test video en BYTES
	mov	es,word ptr cs:[video_seg]
	mov	ds,word ptr cs:[video_seg]
	mov	cx,2048
tfr1va:
	push	cx
	mov	cx,1024
	mov	si,0
	mov	di,si
	rep	movsb
	pop	cx
	loop	tfr1va
	nop
	nop
	nop
	nop
	ret
tfr_vb	endp

tfr_vw	proc	near
;	tfr_vw_proc
;	transfert de 4Mo de donn‚es, align‚es....
;	Test video en WORDS
        mov	es,word ptr cs:[video_seg]
	mov	ds,word ptr cs:[video_seg]
	mov	cx,2048
tfr2va:
	push	cx
	mov	cx,1024
	mov	si,0
	mov	di,si
	rep	movsw
	pop	cx
	loop	tfr2va
	nop
	nop
	nop
	nop
	ret
tfr_vw	endp

tfr_w   proc    near
;	tfr_w_proc
;       transfert de 4Mo de donn‚es, Alignement=AX:
	mov ax,deplacement
	cmp ax,-1
	jz tfr_vw			;Cas de la ram video
	mov bx,@code
	mov es,bx
	mov ds,bx
	mov cx,2048
tfr2a:
	push cx
	mov cx,1024
	mov si,ptr1
	add si,ax
	mov di,si
	rep movsw
	pop cx
	loop tfr2a
	nop
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	nop
tfr_w   endp

	.386
tfr_d   proc    near
;	tfr_d_proc
;       transfert de 8Mo de donn‚es, alignement=AX :
	mov bx,@code
	mov es,bx
	mov ds,bx
	mov ax,deplacement
	mov cx,2048
tfr4a:
	push cx
	mov ecx,1024
	mov si,ptr1
	add si,ax
	mov di,si
	rep movsd
	pop cx
	loop tfr4a
	nop
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	nop
tfr_d   endp
	.8086

	even
tfr_code        proc    near
;	tfr_code_proc
;       Utilisation de 4Mo de code :
	mov bx,6667
	push ax
	push cx
tfr_c0:
	rept 1024
	mov ax,1234h
	mov cx,6597h
	endm
	dec bx
	jz tfr_c1
	jmp tfr_c0
	nop
	nop
	nop
	nop
tfr_c1:
	pop cx
	pop ax
	ret
	nop
	nop
	nop
	nop
tfr_code        endp


tfr_rate        proc    near
;	tfr_rate_proc
;       On calcule la vitesse r‚elle de tfr m‚moire :
	mov bx,offset infos
rate00:
	mov cl,[bx]
	cmp cl,0
	je rate99               ;fini !
	inc bx
	mov ch,0

	mov al,[bx]
	inc bx
	cbw
	mov deplacement,ax

	push bx
	push cx

;       calculons le temps mis :
	mov ax,offset tfr_b
	cmp cx,1
	je rate01
	mov ax,offset tfr_w
	cmp cx,2
	je rate01

	mov ax,offset tfr_code
	cmp cx,9
	je rate01

	cmp	cpu_type,7
	jna	rate98

	mov ax,offset tfr_d
	cmp cx,4
	jne rate98

rate00x:
;	On boucle, au suivant !!!
	pop	cx
	pop	bx
	jmp	short rate00

rate01:
	call dtime
;       Temps pass‚ dans AX
	mov cx,ax
	mov dx,0
	mov ax,40000

;       multiplication par 1,2 ou 4 !
	pop bx
	cmp bx,9
	jne rate02b               ;idem : byte coding !!!
	mov bx,10
	mul bx
	jmp short rate02

rate02b:
	cmp bx,1
	je rate02
	add ax,ax
	adc dx,dx
	cmp bx,2
	je rate02
	add ax,ax
	adc dx,dx
rate02:

	div cx
;       resultat dans ax pour le quotient.
	call aff4ch

;       on affiche ca !
	pop bx
rate10:
	mov al,byte ptr [bx]
	inc bx
	cmp al,0
	je rate00
	push bx
	call outcar
	pop bx
	jmp short rate10

rate98:
;       nettoyage de la pile !!!
	pop cx
	pop bx

rate99:
;       fini !!!
	ret
tfr_rate        endp


aff4ch  proc    near
;       affichage ax en 4 chiffres :
	mov dx,0
	mov cx,100
	div cx
	push dx
	cmp ax,9
	jg aff4ch0
	push ax
	mov al,' '
	call outcar
	pop ax
	add al,'0'
	call outcar
	jmp short aff4ch1
aff4ch0:
	call aff2ch
aff4ch1:
	mov al,'.'
	call outcar
	pop ax
	call aff2ch
	ret
aff4ch  endp


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


set_video	proc	near
;	Positionnement variable mode video...
	push	es
	mov	ax,0040h
	mov	es,ax
	test	word ptr es:[0063h],20h
	jz	video_cga
	mov	word ptr cs:[video_seg],0B000h
video_cga:
	pop	es
	ret
set_video	endp


memory_scan	proc	near
;	memory_scan_proc
	push	ds
	push	es
;	Construit un v‚ritable tableau exhaustif de la m‚moire centrale...
	mov	ah,09
	mov	dx,offset ms0s
	int	21h

;	Byte Size Speed...
;	Accessoirement, permet de calculer le nombre d'‚tats d'attentes
;	effectif, suivant le type de CPU et la fr‚quence d'horloge !!!
	xor	bx,bx		;Segment 0000...FFFFh par pas de 0400h (16K)
ms00:

;	Indication de l'adresse … l'‚cran...
	push	bx
	mov	ax,bx
	call	out4hex
	mov	al,':'
	call	outcar
	pop	bx

	push	bx
	assume	es:nothing, ds:nothing, cs:@code
	mov	es,bx
	mov	ds,bx

;	Initialisations diverses :
	mov	word ptr cs:[byte_count],0
	mov	word ptr cs:[word_count],0
	mov	word ptr cs:[dword_count],0

	call	get_interrupt
	mov	dx,0		;Nombre de boucles faites...
;	Boucle de comptage de Ko/ticks...
ms10:
	xor	si,si
	mov	di,si
	mov	cx,4096
	rep	movsb

	add	dx,8
	cmp	word ptr cs:[int8_count],0
	jz	ms10
	mov	word ptr cs:[byte_count],dx
	call	put_interrupt

	call	get_interrupt
	mov	dx,0		;Nombres de boucles faites
;	Boucle de comptage de Ko/Ticks
ms11:
	mov	si,0
	mov	di,si
	mov	cx,2048
	rep	movsw

	add	dx,8
	cmp	word ptr cs:[int8_count],0
	jz	ms11
	mov	word ptr cs:[word_count],dx
	call	put_interrupt

;	Est-ce un 80386 ou sup‚rieur ???
	cmp	word ptr cs:[cpu_type],8
	jb	ms20

	.386
	call	get_interrupt
	mov	dx,0
ms12:
	mov	si,0
	mov	di,si
	mov	cx,1024
	rep	movsd

	add	dx,8
	cmp	word ptr cs:[int8_count],0
	jz	ms12
	mov	word ptr cs:[dword_count],dx
	call	put_interrupt
	.8086

ms20:
;	Affichons la largeur de bus (8,16,32 bits)
	mov	bx,cs:[byte_count]
	mov	ax,bx
	add	ax,ax
	add	ax,bx
	shr	ax,1
	cmp	cs:[word_count],ax
	ja	ms30			;16 ou 32 bits...?!

;	Affichons ' 8'
	mov	dx,offset ms1s
	jmp	short ms39		;On fini l'affichage
ms30:
	mov	bx,cs:[word_count]
	cmp	word ptr cs:[cpu_type],8
	jb	ms31			;16 bits sur !
	mov	ax,bx
	add	ax,ax
	add	ax,bx
	shr	ax,1
	cmp	cs:[Dword_count],ax
	ja	ms32			;32 bits sur !
ms31:
	mov	dx,offset ms2s
	jmp	short ms39
ms32:
	mov	bx,cs:[Dword_count]
	mov	dx,offset ms3s
ms39:
	push	bx
	mov	ax,cs
	mov	ds,ax
	mov	ah,9
	int	21h
	pop	ax

;	AX : Ko/ticks : *91 /50 =Ko/s pour la sortie...
	mov	bx,91
	mul	bx
	mov	bx,50
	div	bx
	call	aff4ch

	mov	dx,offset ms4s
	mov	ah,9
	int	21h

;	Calcul des ‚tats d'attentes, maintenant...
	mov	ax,cs:[byte_count]
	mov	bx,91
	mul	bx
	mov	bx,5
	div	bx		;On obtient donc correctement Kos
	mov	cs:[kos],ax
	mov	bx,ax

	mov	ax,cs:[freq]
	mov	cx,100
	mul	cx
	div	bx
	push	ax

	mov	bx,cs:[cpu_type]
	dec	bx
	add	bx,bx
	mov	ax,cs:c_cpu[bx]
	mov	bx,100
	mul	bx
	pop	bx
        sub	ax,bx
	neg	ax

;	cmp	ax,0070
;	jb	ms40		;Deux d‚cimales sont n‚cessaires...

;	Elimination de la derniŠre d‚cimale...
	add	ax,5		;On arrondis quand-mˆme
	mov	bx,10
	mov	dx,0
	div	bx
	mul	bx
ms40:

	call	aff4ch		;Maintenant les ‚tats d'attentes...

	mov	dx,offset ms5s
	mov	ah,9
	int	21h

;	Passons … la ligne suivante...
	mov	al,13
	call	outcar
	mov	al,10
	call	outcar

;	Fin de boucle, on passe aux 16 Ko suivants...
	pop	bx
	add	bx,1000h	;plus 64ko !!!
	cmp	bx,0
	jz	ms99		;Fini !!!
	jmp	ms00

ms99:
	pop	es
	pop	ds
	ret
memory_scan	endp

hexnum	db	'0123456789ABCDEF'

out4hex	proc	near
;	Sortie de AX sur 4 chiffres hexad‚cimaux...
	push	ax
	push	ax
	mov	al,ah
	call	out2hex
	pop	ax
	call	out2hex
	pop	ax
	ret
out4hex	endp

out2hex	proc	near
	push	ax
	push	ax
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	call	out1hex
	pop	ax
	call	out1hex
	pop	ax
	ret
out2hex	endp

out1hex	proc	near
	push	bx
	push	ax
	and	ax,000Fh
	mov	bx,ax
	mov	al,cs:hexnum[bx]
	call	outcar
	pop	ax
	pop	bx
	ret
out1hex	endp

;	Par bloc de 16Ko, Largeur (Byte, Word, DoubleWord) (1, 2 ou 4)
;	et d‚bit (Ko/ticks)
;	complet et exhaustif de la m‚moire... niark niark niark...



byte_count	dw	0
word_count	dw	0
dword_count	dw	0

kos		dw	0
freq		dw	0

c_cpu		dw	4,4,4,4
		dw	3,3,2,2
		dw	2,2,2,2

mem_map	dw	0,0,0,0,0,0,0,0  ;0000-0FFFh
	dw	0,0,0,0,0,0,0,0  ;1000-1FFFh
	dw	0,0,0,0,0,0,0,0  ;2000-2FFFh
	dw	0,0,0,0,0,0,0,0  ;3000-3FFFh
	dw	0,0,0,0,0,0,0,0  ;4000-4FFFh
	dw	0,0,0,0,0,0,0,0  ;5000-5FFFh
	dw	0,0,0,0,0,0,0,0  ;6000-6FFFh
	dw	0,0,0,0,0,0,0,0  ;7000-7FFFh
	dw	0,0,0,0,0,0,0,0  ;8000-8FFFh
	dw	0,0,0,0,0,0,0,0  ;9000-9FFFh
	dw	0,0,0,0,0,0,0,0  ;A000-AFFFh - Vid‚o EGA & VGA
	dw	0,0,0,0,0,0,0,0  ;B000-BFFFh - Vid‚o Hercules, MDA, CGA
	dw	0,0,0,0,0,0,0,0  ;C000-CFFFh
	dw	0,0,0,0,0,0,0,0  ;D000-DFFFh
	dw	0,0,0,0,0,0,0,0  ;E000-EFFFh
	dw	0,0,0,0,0,0,0,0  ;F000-FFFFh - ROM Bios
;	fini donc !!!		;

ptr1    dw      ?
ptr2    dw      ?

string1 dd      1040 dup (?)
string2 dd      1040 dup (?)

video_seg	dw	0B800h
deplacement     dw      0

cpu_8088	db	"iAPX 88$"
cpu_8086	db	"iAPX 86$"
cpu_v20		db	"Nec V20$"
cpu_v30		db	"Nec V30$"
cpu_188		db	"iAPX 188$"
cpu_186		db	"iAPX 186$"
cpu_286		db	"iAPX 286$"
cpu_386sx	db	"iAPX 386sx$"
cpu_386dx	db	"iAPX 386dx$"
cpu_486		db	"iAPX 486$"

cpu_type	dw	0
cpu_tab		dw	cpu_8088, cpu_8086, cpu_v20, cpu_v30
		dw	cpu_188 , cpu_186 , cpu_286, cpu_386sx
		dw	cpu_386dx , cpu_486
cpu_string	db	" .",13,10,10,"$"

int8_off	dw	0
int8_seg	dw	0
int8_count	dw	0

chaine0	db	"    ****    Processor  Benchmark  v2.3    ****",13,10
	db	"            (c)  1990  Philippe Vigier",13,10
	db	10,10,"Processor is : $"

chaine1 db      "Real CPU speed is : $"
chaine2 db      " Mhz.",13,10,"$"

chaine3 db      "-Maximal speed is : $"
chaine4 db      " Mips.",13,10,"$"

chaine7	db	"-Sustained speed  : $"
chaine8	db	" Mips. (Equivalent Risc-Mips)",13,10,"$"

chaine5 db      "-Minimal speed is : $"
chaine6 db      " Mips. (Equivalent Vax-Mips )",13,10,10,"$"

infos   db      9,0," Mo/s ---- Code transfer rate",13,10,0
	db      1,0," Mo/s ---- Byte transfer rate",13,10,0
	db      2,0," Mo/s Even Word transfer rate",13,10,0
	db      2,1," Mo/s Odd  Word transfer rate",13,10,0
	db	1,-1," Mo/s ---- Byte transfer rate (Video Ram)",13,10,0
	db	2,-1," Mo/s Even Word transfer rate (Video Ram)",13,10,0
	db      4,0," Mo/s  +0  80386 dword tfr rate",13,10,0
	db      4,1,' Mo/s  +1    "     "    "    "',13,10,0
	db      4,2,' Mo/s  +2    "     "    "    "',13,10,0
	db      0,0

ms0s	db	13,10
	db	"Memory Scanning : Bus size, Bandwidth and Wait States..."
	db	13,10,"$"
ms1s	db	"  Byte - $"
ms2s	db	"  Word - $"
ms3s	db	" Dword - $"
ms4s	db	" Mo/s  soit $"
ms5s	db	" Wait States   $"

	end DEBUT
