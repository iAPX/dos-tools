
	DOSSEG
	.MODEL small
	.CODE

	.stack  0100h

	org     0100h
debut:
	assume cs:@code,ds:nothing,es:nothing
;	DS et ES pointent sur le PSP segment...

	mov cs:[prm_f],4		;4.77Mhz PC par dÇfaut..

;       ComprÇhension des paramätres :
	mov ch,0
	mov cl,byte ptr ds:[0080h]
	mov si,0081h
	mov bx,cx
	mov byte ptr [si+bx],0
lop00:
	lodsb
;	En cas de probleme hein !!!
	cmp al,10
	jz loop01x
	cmp al,13
	jz loop01x
	cmp al,0
	jz loop01x

	cmp al,'?'
	jnz lop09
	mov byte ptr cs:[prm_h],1
lop09:
	cmp al,'/'
	jnz lop01

;       /D /PC /AT
	mov al,ds:[si]
	and al,1fh
	add al,40h
	cmp al,'D'
	jnz lop10
	mov byte ptr cs:[prm_d],1
	jmp short lop01
lop10:
	cmp al,'P'
	jnz lop12
	call pc_analyse
	mov byte ptr cs:[prm_a],0
	jmp short lop01
lop12:
	cmp al,'A'
	jnz lop13
	call at_analyse
	mov byte ptr cs:[prm_a],1
	jmp short lop01
lop13:
	cmp byte ptr ds:[si],'3'
	jnz lop01
	call at386_analyse
	mov byte ptr cs:[prm_a],2

lop01:
	loop lop00

loop01x:
;       Bon c'est ok !!!

	mov ax,cs
	assume ds:@code,es:@code
	mov ds,ax
	mov es,ax

;       si help : l'affiche et quitte
	cmp byte ptr cs:[prm_h],0
	jnz lop08
	jmp entry

lop08:
	mov dx,offset synt
	call affstr

	jmp termine


	align	4
workd   dw      0

	align	4
travail proc    near
;       procÇdure de travail qui
;       -IncrÇmente AX
;       puis sinon perd du temps quoi !!!
	mov si,offset tmp1
	mov [si],ax
	inc word ptr [si]
	mov ax,[si]
	mov word ptr [si],0
	mov bx,tmp1
	and bx,ax
	add tmp2,ax
	mov bx,cs:workd[bx][si]
	add bx,cs:workd[si]
	ret
	nop
	nop
	nop
	nop
travail endp


affstr  proc    near
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov ah,09
	int 21h

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
affstr  endp

affcar  proc near
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es

	mov dl,al
	mov ah,02
	int 21h
	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
affcar  endp

affdec  proc    near
;       affichage de ax en 5 chiffres dÇcimaux...
	mov dx,0
	mov cx,10000
	div cx
	add al,'0'
	call affcar
	mov ax,dx
	mov dx,0
	mov cx,1000
	div cx
	add al,'0'
	call affcar
	mov ax,dx
	mov dx,0
	mov cx,100
	div cx
	add al,'0'
	call affcar
	mov ax,dx
	mov dx,0
	mov cx,10
	div cx
	add al,'0'
	call affcar
	mov ax,dx
	add al,'0'
	call affcar
	ret
affdec  endp

set_vector      proc    near
;       Fous le vecteur (cs:ax) en vecteur[1ch]
	push es
	mov bx,0000
	mov es,bx

	mov bx,es:[001Ch*4]
	mov ito,bx
	mov bx,es:[001Ch*4+2]
	mov its,bx

	mov bx,cs
	cli
	mov es:[001Ch*4],ax
	mov es:[001Ch*4+2],bx
	sti
;       all right now....
	pop es
	ret
set_vector      endp

reset_vector    proc    near
	push es
	mov bx,0000
	mov es,bx
	mov bx,its
	mov ax,ito

	cli
	mov es:[001Ch*4],ax
	mov es:[001Ch*4+2],bx
	sti

	pop es
	ret
reset_vector endp


	align	4
routine_a proc far
	inc word ptr cs:[fl_on]
	jmp dword ptr cs:[old_int13]
routine_a endp

	align	4
routine_b       proc    far
	cmp cs:[flin],1
	je on_se_tire
	mov cs:[flin],1
	sti
	push ds
	push ax
	push bx
	push cx
	push si
	mov ax,cs
	mov ds,ax
	mov cx,nb_bcl
bclx:
	call travail
	cmp word ptr [fl_on],1
	dec cx
	jnz bclx
	nop

	pop si
	pop cx
	pop bx
	pop ax

	cli
	pushf
	call dword ptr ds:[old_int13]
	mov cs:[flin],0

	pop ds
on_se_tire:
	iret
	nop
	nop
routine_b       endp

	align	4
flin    dw      0

entry:
;       initialisation des segments...
	mov dx,offset chaine3
	call affstr

;       installation vecteur 08h :
	mov ax,offset routine_a
	call set_vector

	mov si,offset fl_on
	mov ax,0
bcl0:
	cmp word ptr [si],ax
	jne bcl0

bcl1:
	call travail
	dec cx
	cmp word ptr [fl_on],1
	jne bcl1
	nop
	mov nb_actu,ax

;       en effet, travail incremente AX Ö chaque boucle
;       et compare fl_on et 1.

;       desinstallation du vecteur 08h :
	call reset_vector


	cmp [prm_d],0
	jz lop20


;       Bon calcul delta vitesse :
	mov dx,offset chaine1
	call affstr
	mov ax,nb_actu
	call affdec
	mov dx,offset chaine2
	call affstr

	jmp short termine


lop20:
;	Recherchons la vitesse Ö considÇrer...
	mov al,[prm_a]
	lea si,tab_PC
	cmp al,0
	jz regarde
	lea si,tab_AT
	cmp al,1
	jz regarde
	lea si,tab_386
	cmp al,2
	jz regarde
	jmp too_slow


regarde:
;	Recherche nombre de boucle correspondant Ö prm_f dans la table[si]
	mov ah,0
	mov al,[prm_f]
see0:
	cmp ax,[si]
	jz see1			;TrouvÇ !
	lea si,4[si]
	cmp word ptr [si],0
	jnz see0
	jmp not_known		;Vitesse inconnue ?!

see1:
	mov ax,[nb_actu]
	sub ax,2[si]
	jge pose
	jmp short too_slow

not_known:
	mov dx,offset chainek
	call affstr
	jmp short termine
too_slow:
	mov dx,offset chaine4
	call affstr
termine:
	mov ax,4c00h
	int 21h



pose:
	mov nb_bcl,ax

	mov ax,offset routine_b
	call set_vector


;       retour en laissant la mÇmoire Ö la routine :
	mov ax,3100h
	mov dx,0100h            ;4kO
	int 21h



;	Maintenant les routines de dÇcodage complet...
pc_analyse proc near
	mov cs:[prm_f],04
	mov al,ds:1[si]
	and al,001fh
	add al,0040h
	cmp al,'C'
	jnz pc_skip

;	C'est tout bon...donnÇes optionnelles ?!
	push si
	lea si,2[si]
	call get_freq
	pop si
pc_skip:
	ret
pc_analyse endp


at_analyse proc near
	mov cs:[prm_f],06
	mov al,ds:1[si]
	and al,001fh
	add al,0040h
	cmp al,'T'
	jnz at_skip
;	C'est bon on prends la frÇquence...
	push si
	lea si,2[si]
	call get_freq
	pop si
at_skip:
	ret
at_analyse endp



at386_analyse proc near
	mov cs:[prm_f],16
	mov ax,ds:1[si]
	cmp ax,'68'
	jnz at386_skip

	push si
	lea si,3[si]

;	Est-ce un SX ???
	mov ax,ds:[si]
	cmp ax,'XS'
	jz at386sx
	cmp ax,'xS'
	jz at386sx
	cmp ax,'xs'
	jz at386sx
	cmp ax,'Xs'
	jz at386sx

	cmp byte ptr ds:[si],'-'
	jnz at386_16				;Pas de vitesse derriäre !
	lea si,1[si]

	call get_freq
at386_16:
        pop si
	jmp short at386_skip
at386sx:
	pop si
	mov cs:[prm_f],'S'

at386_skip:
	ret
at386_analyse endp


;	Routine de prise de la vitesse (en Mhz !)
get_freq	proc	near
	push si
	push ax
	push bx
	mov ax,0
get_f0:
	mov bh,0
	mov bl,ds:[si]
	inc si
	sub bl,'0'
	cmp bx,9
	ja get_f1

;	Addition !!!
	push cx
	push dx
	mov cx,10
	mul cx
	pop dx
	pop cx
	add ax,bx
	cmp ax,60			;50 Mhz maxi !
	jna get_f0

get_f1:
;	Chargeons la vitesse d'horloge...
	mov cs:[prm_f],al
get_f2:
	pop bx
	pop ax
	pop si

	ret
get_freq	endp



	align	4
;	Table pour PC :
tab_PC	dw	04,00900,08,01300,10,01530,12,01840,00,00000,00,00000

tab_AT	dw	01,02700,02,02700,03,03600,06,02700,08,03600
	dw	10,04500,12,05500,16,07200,20,09000,24,11000
	dw	25,12000,00,00000,00,00000

tab_386	dw	12,06000,'S',07000,16,07500,20,09400,24,12000
	dw	25,12500,30,15000,33,16000
	dw	00,00000,00,00000


	align	4
prm_d   db      0               ;Flag Diagnostic
prm_a   db      0               ;Flag AT (vs. pc) (0=PC, 1=AT, 2=386)
prm_h   db      0               ;Flag HELP
prm_f	db	0		;FrÇquence en MÇgahertz...


chaine3	db	"    ****  SlowDown (c) 1990 Philippe Vigier  ****",13,10
	db	10
	db	10
	db	"    Utilitaire de ralentissement de PC 10Mhz, d'AT",13,10
	db	"    de micro Ö 386 & 486 Ö la vitesse d'une machine",13,10
	db	"    cible. Par dÇfaut ramäne la vitesse Ö celle d'un",13,10
	db	"    vÇnÇrable IBM PC-XT  (8088 Ö 4.77Mhz).",13,10
	db	10
	db	"$"

chaine4 db      "Machine plus lente que la machine cible !",13,10,"$"

chainek	db	"Cette vitesse d'horloge n'est pas rÇfÇrencÇe pour ce microprocesseur",13,10
	db	"    8088   :   4.77, 8 ou 10Mhz.",13,10
	db	"   80286   :   6, 8, 10, 12, 16, 20 ou 25Mhz.",13,10
	db	"   80386   :   12, 16, 20, 25 ou 33Mhz.",13,10
	db	"   80386SX :   16Mhz (Seule vitesse rÇfÇrencÇe).",13,10,10
	db	"$"


chaine1 db      "Votre machine fait $"
chaine2 db      " boucles par secondes.",13,10
	db      "   PC  4.77 Mhz  =   900  boucles",13,10
	db      "   PC    8  Mhz  =  1300  boucles",13,10
	db	"   PC   10  Mhz  =  1530  boucles",13,10
	db	10
	db      "   AT    6  Mhz  =  2700  boucles",13,10
	db      "   AT    8  Mhz  =  3600  boucles",13,10
	db      "   AT   10  Mhz  =  4500  boucles",13,10
	db      "   AT   12  Mhz  =  5500  boucles",13,10
	db	"   AT   16  Mhz  =  7200  boucles",13,10
	db	"   AT   20  Mhz  =  9000  bocules",13,10
	db	10
	db	"   386  12  Mhz  =  6000  boucles",13,10
	db      "   386  16  Mhz  =  7500  boucles",13,10
	db	"   386  20  Mhz  =  9400  boucles",13,10
	db      "   386  25  Mhz  > 12000  boucles",13,10
	db      "$"


;       Message d'aide !!!
synt	db	"    ****  SlowDown (c) 1990 Philippe Vigier  ****",13,10
	db      10
	db      " Ralentis toute machine Ö la vitesse d'un AT2 ou PC.",13,10
	db      10
	db      " Syntaxe :  SlowDown /Option",13,10
	db      10
	db      " Options :  /PC - Ramäne la vitesse Ö celle d'un IBM-PC  (r).",13,10
	db      "            /AT - Ramäne la vitesse Ö celle d'un IBM-AT2 (r).",13,10
	db      "            /D  - Diagnostic vitesse de votre machine.",13,10
	db	10
	db	" Options Çtendues :  /PCxx   - Ramäne Ö un PC Ö xx Mhz (4,8 ou 10 Mhz)",13,10
	db	"                     /AT3    - Ramäne Ö la vitesse d'un IBM-AT3 (r).",13,10
	db	"                     /ATxx   - Ramäne Ö la vitesse d'un AT Ö xx Mhz.",13,10
	db	"                               (6, 8, 10, 12, 16 ou 20Mhz disponible)",13,10
	db	"                     /386SX  - Ramäne Ö la vitesse d'un 386SX Ö 16Mhz.",13,10
	db	"                     /386-xx - Ramäne Ö la vitesse d'un 80386 Ö xx Mhz.",13,10
	db	"                               (12, 16, 20, 25 ou 33Mhz disponibles)",13,10
	db      13,10
	db      "$"


	align 4
fl_on	dw	-1
nb_actu dw      ?
nb_bcl  dw      ?

	align 4
bcl_at  dw      2800
bcl_pc  dw      0900

	align 4
tmp1    dw      ?
tmp2    dw      ?

old_int13       label   dword
ito     dw      ?
its     dw      ?


	end debut

