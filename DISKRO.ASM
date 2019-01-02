

	dosseg
	.8086
	.model	small
	.stack	100h

	.code
	org	0000h
debut:
	jmp	Initialisation

;	Ancien vecteur d'interruption de gestion Disque dur & Floppy
Int13_Off	dw	0
Int13_Seg	dw	0

;	Segment de la ram-vid‚o...
VideoSeg	dw	0B800h


Int13	proc	far
;	Nouvelle interruption....
	cmp	dl,0
	jz	Int13_Test
	cmp	dl,1
	jz	Int13_Test
	cmp	dl,2
	jz	Int13_Test
	cmp	dl,3
	jz	Int13_Test		;4 Floppy test‚s...

Int13_Go:
;	Saut … l'ancienne routine...
	jmp	dword ptr cs:[Int13_Off]

Int13_Test:
;	Teste le code fonction...
	cmp	ah,0
	jz	Int13_Go
	cmp	ah,1
	jz	Int13_Go
	cmp	ah,2
	jz	Int13_Go
	cmp	ah,8
	jz	Int13_Go
	cmp	ah,15h
	jz	Int13_Go
	cmp	ah,16h
	jz	Int13_Go
	cmp	ah,17h
	jz	Int13_Go

;	Autorisons donc les interruptions ?! C'est pas sage !!!
	sti

;	On va faire flasher le haut de l'‚cran....
	push	cx
	push	si
	push	ds

;	Inversion ‚tat de la premiŠre ligne de l'‚cran....
	mov	ds,cs:[VideoSeg]
	mov	si,1
	mov	cx,80
Int13_L0:
	not	byte ptr [si]
	inc	si
	inc	si
	loop	Int13_L0

;	Attente top horloge...
	mov	cx,0040h
	mov	ds,cx
	mov	cx,word ptr ds:[006Ch]
Int13_L1:
	cmp	cx,word ptr ds:[006Ch]
	jz	Int13_L1

;	On remet la ligne en l'‚tat....
	mov	ds,cs:[VideoSeg]
	mov	si,1
	mov	cx,80
Int13_L2:
	not	byte ptr [si]
	inc	si
	inc	si
	loop	int13_l2

	pop	ds
	pop	si
	pop	cx

;	On ne fais rien...
;	Erreur : Cy=1
;	Code "Read Only Drive" : AH=03
	mov	ah,03
	stc
	retf	2			;On d‚pile l'ancien Flag
Int13	endp



Initialisation:
;	Changeons le segment de VideoSeg au besoin
	mov	ax,0040h
	mov	es,ax
	mov	ax,word ptr es:[0063h]
	cmp	ax,3B4h
	jne	Not_Monochrome

	mov	cs:[VideoSeg],0B000h		;Ecran monochrome...
Not_Monochrome:

;	Routine de travail, qui "saute" d'ailleurs lors de l'installation
;	effective en r‚sident !!!

	mov	ax,cs
	mov	ds,ax
	mov	es,ax

;	Prise de l'ancien vecteur
	mov	ax,3513h
	int	21h
	mov	cs:[Int13_Seg],es
	mov	cs:[Int13_Off],bx

;	On place le nouveau vecteur...
	mov	ax,2513h
	mov	dx,offset Int13
	int	21h

;	On sort le message d'accueil et d'explication...
	mov	dx,offset Chaine
	mov	ah,9
	int	21h

;	On quitte en laissant le r‚sident...
	mov	ax,3100h
	mov	dx,offset Initialisation
	mov	cl,4
	shr	dx,cl
	add	dx,20h			;Plus 512 octets : PSP & zone libre...

	int	21h


Chaine	db	13,10
	db	"    ****  Floppy Read-Only (c) 1990 Philippe Vigier  ****",13,10
	db	10
	db	"    Cet utilitaire protŠgera assez efficacement vos lecteurs",13,10
	db	"    de disquettes contre les exactions de logiciels douteux",13,10
	db	"    ou d'attaques de virus. Il se contente d'interdire",13,10
	db	"    toute ‚criture sur les floppies, et n'est pas d‚sactivable",13,10
	db	"    ni par vous, NI PAR UN VIRUS .... Ce qui est essentiel !",13,10
	db	10
	db	"    Pour le d‚sactiver : il suffit de rebooter votre PC en",13,10
	db	"    appuyant sur le bouton d'initialisation (RESET), ou en",13,10
	db	"    tapant  CTRL-ALT-Suppr  sur votre clavier.",13,10
	db	10
	db	"    C'est la meilleure fa‡on de tester en toute s‚curit‚",13,10
	db	"    des logiciels re‡us ou t‚l‚charg‚s de sources non s–res",13,10
	db	"    voire d'assez mauvaise r‚putation. Si un logiciel essaie",13,10
	db	"    d'‚crire sur la disquette, le haut de l'‚cran va flasher",13,10
	db	"    un coup pour vous pr‚venir, et l'‚criture sera effectivement",13,10
	db	"    refus‚.",13,10
	db	10
	db	"    Nota bene : cet utilitaire ne protŠge pas votre disque dur.",13,10
	db	"                Il existe  ReadOnly.exe  qui fait ‡a trŠs bien !",13,10
	db	"                Cet utilitaire peut aussi ˆtre employ‚ aprŠs un",13,10
	db	"                mot-de-passe pour empˆcher des copies de vos donn‚es",13,10
	db	"                r‚sidentes dans le disque dur sur une disquette.",13,10
	db	10
	db	"$"


	End	debut

