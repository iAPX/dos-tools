
	.286
	.Model	Small
	Dosseg
	.stack	20000

	.code

	org	100h

Debut:
;	D‚but de l'ex‚cution, facile...
	mov	ax,@data
	mov	ds,ax
	assume	ds:@data, es:nothing, ss:stack
	mov	sp,19000

;	ChaŒne d'accueil :
	mov	dx,offset String_Accueil
	mov	ah,9
	int	21h

;	D‚tournement INT 3 :
	mov	ax,3503h
	int	21h
	mov	Int03_Seg,es
	mov	Int03_Off,bx

	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	dx,offset Int03
	mov	ax,2503h
	int	21h
	pop	ds

;	D‚tournement INT 4 :
	mov	ax,3504h
	int	21h
	mov	Int04_Seg,es
	mov	Int04_Off,bx

	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	dx,offset Int03		;La mˆme chose !!!
	mov	ax,2504h
	int	21h
	pop	ds

;	Positionne des drapeaux
	call	test_286

;	Calcule donc pour les NOP...
	call	test_Instruction
	mov	ax,Loop_Count
	mov	cx,400
	cmp	word ptr [Fl286],0	;4 tops sur un 8088 !!!!
	je	Label0a
	mov	cx,300
Label0a:
	mul	cx
	mov	Base_Cycle_Low,ax
	mov	Base_Cycle_High,dx

;	Pour chaque test....
Label0:
	mov	si,Text_Ptr
	lodsb
	or	al,al
	jz	Label1

	call	Test_Instruction
	call	Result

	jmp	short Label0

Label1:
;	Fin du test...
	mov	dx,offset String_Fini
	mov	ah,9
	int	21h

;	On rends le vecteur d'interruption 03
	push	ds
	mov	dx,INT03_Off
	mov	ds,INT03_Seg
	mov	ax,2503h
	int	21h
	pop	ds

;	On rends aussi le vecteur 04...
	push	ds
	mov	dx,Int04_Off
	mov	ds,Int04_Seg
	mov	ax,2504h
	int	21h
	pop	ds

	mov	ax,4C00h
	int	21h			;On termine correctement

Int08	proc
;	Proc‚dure simplifi‚e...
	push	ds
	push	ax
	mov	ax,@Data
	mov	ds,ax

	Inc	word ptr ds:[Int08_Count]	;Compte une IT de plus

	mov	al,20h
	out	20h,al				;R‚active IT's...

	pop	ax
	pop	ds
Int03:
;	Point d'accŠs pour tester INT3 / INT 03... et hop...
	iret
Int08	endp


Test_286	proc
;	Teste si c'est un 80286 (ou plus)...
	Pushf
	Mov	Word ptr [Fl286],0

	xor	ax,ax
	push	ax
	popf
	pushf
	pop	ax
	and	ax,0F000h
	cmp	ax,0F000h
	je	pas_386_286

	mov	Word ptr [Fl286],-1
Pas_386_286:
	popf
	ret
Test_286	endp


Result	proc
;	Quelques espaces...
	mov	ah,2
	mov	dl,32
	int	21h
	int	21h
	int	21h
	int	21h
	mov	dl,':'
	int	21h
	mov	dl,32
	int	21h

	cmp	Loop_Count,0
	jnz	Result_L1
;	286 ou 386-Aware, mais non satisfait !!!
	mov	dl,'*'
	int	21h
	int	21h

;	CRLF pour ‚jecter...
	mov	dl,13
	int	21h
	mov	dl,10
	int	21h

	ret

Result_L1:
;	Effectue le calcul du r‚sultat, rapidement svp...
	mov	ax,Base_Cycle_Low
	mov	dx,Base_Cycle_High
	mov	cx,Loop_Count
	div	cx
	add	ax,25
	mov	cl,50
	div	cl

;	AL contient le nombre de demi-cycles !!!
	push	ax
	shr	al,1		;Et maintenant les cycles !!!

;	AL contient le nombre de cycles arrondi... yeap !!!
	xor	ah,ah
	mov	cl,10
	div	cl
	or	al,al
	mov	dl,32
	jz	Result_L0
	mov	dl,al
	add	dl,30h
Result_L0:
	push	ax
	mov	ah,2
	int	21h
	pop	dx
	mov	dl,dh
	add	dl,30h
	int	21h

;	Si 1/2 … afficher...
	pop	ax
	and	ax,1
	jz	Result_L2

;	Sort un espace et 1/2
	mov	ah,2
	mov	dl,20h
	int	21h
	mov	dl,171
	int	21h

Result_L2:
;	Un " cycles" CRLF  derriŠre
	mov	dx,offset string_cycle
	mov	ah,9
	int	21h

	ret
Result	endp

Code_Copy	proc
;	Copie du code en tenant juste compte des variables suivantes :
;	Test_Seg & Tab_Ptr

;	Effacement du buffer, sur 10Ko !!!
	cld
	les	di,dword ptr [Test_Off]
	mov	cx,5200
	xor	ax,ax
	rep stosw

;	Maintenant on place les codes au d‚but...
	cld				;Au cas o—...
	les	di,dword ptr [Test_Off]	;Pointeur d'‚critures
	mov	si,Tab_Ptr		;Pointeur de lecture !!!

	lodsw
	or	ax,ax
	jz	Code_Copy_L10

;	Copie d'un code d'initialisation...
	push	si
	push	ds

	mov	si,ax
	mov	ax,cs
	mov	ds,ax
	lodsb
	xor	cx,cx
	mov	cl,al
	dec	cl			;Eh oui !!!

	rep movsb

	pop	ds
	pop	si
	jmp	short Code_Copy_L10

Code_Copy_L10:
;	Copie du code r‚el now...
	push	word ptr ds:[si]
	push	ds

	mov	word ptr [Aware_286],0
	mov	cx,word ptr ds:[si+4]
	or	cx,cx
	jns	Code_Copy_L10a
	neg	cx			;286 Aware si <0 !!!
	mov	word ptr [Aware_286],-1
Code_Copy_L10a:

	mov	si,word ptr ds:[si+2]

	mov	ax,cs
	mov	ds,ax

	lodsb
	dec	al

Code_Copy_L11:
	push	cx
	push	si			;Copie CX fois le code de AL octets

	xor	cx,cx
	mov	cl,al
	rep movsb

	pop	si
	pop	cx
	loop	Code_Copy_L11

	pop	ds
	pop	si

	or	si,si
	jz	Code_Copy_L20

;	Copie du code de fin now...
	Push	ds

	mov	ax,cs
	mov	ds,ax
	lodsb
	xor	cx,cx
	mov	cl,al
	dec	cl

        rep movsb

	pop	ds

Code_Copy_L20:
;	Copie du Far Return :
	mov	al,0CBh
	stosb

;	On remet des segments corrects...
	mov	ax,@data
	mov	ds,ax
	mov	es,ax

;	On passe … l'instruction suivante...
	add	word ptr [Tab_Ptr],8

	ret
Code_Copy	endp


Test_Instruction	proc
;	Test de l'instruction courante...
	mov	si,Text_Ptr
TI_L00:
	lodsb
	or	al,al
	jz	TI_L01
	mov	dl,al
	mov	ah,02
	int	21h
	jmp	short TI_L00
TI_L01:
	mov	Text_Ptr,si

;	Copie du code...
	call	Code_Copy

	mov	word ptr [Loop_Count],0
	mov	word ptr [Int08_Count],-1

;	Test d'ex‚cution pour les 286, 386 & 486...
	cmp	Word ptr [Fl286],0
	jnz	TI_L02
	cmp	word ptr [Aware_286],0
	jz	TI_L02
	ret

TI_L02:
;	On d‚tourne les interruptions
	mov	ax,3508h
	int	21h
	mov	Int08_Seg,es
	mov	Int08_Off,bx

	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	dx,offset Int08
	mov	ax,2508h
	int	21h
	pop	ds

;	On attends le passage … z‚ro...
	xor	cx,cx
TI_L10:
	cmp	word ptr [Int08_Count],cx
	jnz	TI_L10

;	On fais un maximum de boucles...
TI_L20:
	call	dword ptr ds:[Test_Off]
	inc	word ptr [Loop_Count]
	cmp	word ptr [Int08_Count],0
	jz	TI_L20

;	On remet les interruptions...
	push	ds
	mov	dx,Int08_Off
	mov	ds,Int08_Seg
	mov	ax,2508h
	int	21h
	pop	ds

;	On remet … niveau le nombre d'appels
	Int	08h
	Int	08h

	ret
Test_Instruction	endp


;	Code d'initialisation pour 1000 boucles : rien !!!
;	Code de fin : rien !!!

;	Codes divers suivant les instructions :
Nop_Code:	db	Add_RR-Nop_Code
	nop
Add_RR:		db	Add_RI8-Add_RR
	add	bx,cx
Add_RI8:	db	Add_RI16-Add_RI8
	add	bx,2
Add_RI16:	db	Add_RM8-Add_RI16
	add	bx,12561
Add_RM8:	db	Add_RM16-Add_RM8
	add	bl,byte ptr [Var0]
Add_RM16:	db	Add_AI8-Add_RM16
	add	bx,word ptr [Var0]
Add_AI8:	db	Add_AI16-Add_AI8
	add	ax,2
Add_AI16:	db	Add_MI8-Add_AI16
	add	ax,12561
Add_MI8:	db	Add_MI16-Add_MI8
	add	byte ptr [Var0],2
Add_MI16:	db	Add_MR8-Add_MI16
	add	word ptr [Var0],12561
Add_MR8:	db	Add_MR16-Add_MR8
	add	byte ptr [Var0],bl
Add_MR16:	db	Cbw_Code-Add_MR16
	add	word ptr [Var0],bx

Cbw_Code:	db	Clc_Code-Cbw_Code
	Cbw
Clc_Code:	db      Inc_R8-Clc_Code
	Clc

Inc_R8:		db	Inc_R16-Inc_R8
	Inc	bl
Inc_R16:	db	Inc_M8-Inc_R16
	inc	bx
Inc_M8:		db	Inc_M16-Inc_M8
	inc	byte ptr [Var0]
Inc_M16:	db	Jc_False-Inc_M16
	inc	word ptr [Var0]

Jc_False:	db	Jc_True-Jc_False
	jnz	Jc_True
Jc_True:	db	Jmp_Short-Jc_True
	jz	Jmp_Short
Jmp_Short:	db	Les_M32-Jmp_Short
	jmp	short Les_M32

Les_M32:	db	Lea_M16-Les_M32
	les	di,dword ptr [Int08_Off]
Lea_M16:	db      Lea_R-Lea_M16
	lea	di,Var0
Lea_R:		db	Lea_RI-Lea_R
	lea	di,[bx]
Lea_RI:		db	Lea_RX-Lea_RI
	lea	di,4[bp]
Lea_RX:		db	Lea_RXI-Lea_RX
	lea	di,[bp][si]
Lea_RXI:	db	Mov_RR8-Lea_RXI
	Lea	di,4[bp][si]

Mov_RR8:	db	Mov_RR16-Mov_RR8
	mov	cl,ch
Mov_RR16:	db	Mov_MR8-Mov_RR16
	mov	cx,bx
Mov_MR8:	db	Mov_MR16-Mov_MR8
	mov	byte ptr [Var0],cl
Mov_MR16:	db	Mov_RM8-Mov_MR16
	mov	word ptr [Var0],cx
Mov_RM8:	db	Mov_RM16-Mov_RM8
	mov	cl,byte ptr [Var0]
Mov_RM16:	db	Mov_MI8-Mov_RM16
	mov	cx,word ptr [Var0]
Mov_MI8:	db      Mov_MI16-Mov_MI8
	mov	byte ptr [Var0],2
Mov_MI16:	db	Mov_RI8-Mov_MI16
	mov	word ptr [Var0],12654
Mov_RI8:	db	Mov_RI16-Mov_RI8
	mov	cl,2
Mov_RI16:	db	Mov_MA16-Mov_RI16
	mov	cx,12653
Mov_MA16:	db	Mov_AM16-Mov_MA16
	mov	word ptr [Var0],ax
Mov_AM16:	db	Mov_SR16-Mov_AM16
	mov	ax,word ptr [Var0]

Mov_SR16:	db	Mov_SM16-Mov_SR16
	mov	es,bx
Mov_SM16:	db	Mov_RS16-Mov_SM16
	mov	es,word ptr [Var0]
Mov_RS16:       db	Mov_MS16-Mov_RS16
	mov	bx,es
Mov_MS16:	db	Mul_Pre-Mov_MS16
	mov	word ptr [Var0],es


Mul_Pre:	db	Div_Pre-Mul_Pre
	mov	ax,12653
	mov	bx,1
Div_Pre:	db	Mul16-Div_Pre
	mov	ax,123
	mov	bx,1
	xor	dx,dx

Mul16:		db	Mul32-Mul16
	Mul	bl
Mul32:		db	Div16-Mul32
	mul	bx
Div16:		db	Div32-Div16
	div	bl
Div32:		db	cmps_pre-Div32
	div	bx


Cmps_pre:	db	Cmps_b-Cmps_pre
	mov	si,0
	mov	di,0

Cmps_b:		db	Cmps_w-Cmps_b
	cmpsb
Cmps_w:		db	Enter_8-Cmps_w
	cmpsw

Enter_8:	db	Enter_16-Enter_8
	Enter	4,0
	Leave
Enter_16:	db	Entree_8-Enter_16
	Enter	543,0
	Leave
Entree_8:	db	Entree_16-Entree_8
	push	bp
	mov	bp,sp
	sub	sp,4
	mov	sp,bp
	pop	bp
Entree_16:	db	In_Pre-Entree_16
	push	bp
	mov	bp,sp
	sub	sp,543
	mov	sp,bp
	pop	bp


In_Pre:		db	In_AI-In_Pre
	mov	dx,1F0h

In_AI:		db	In_ADX-In_AI
	in	al,20h
In_ADX:		db	In_ADY-In_ADX
	in	al,dx
In_ADY:		db	Int3_Code-In_ADY
	in	ax,dx

Int3_Code:	db	Int_Code-Int3_Code
	int	3
Int_Code:	db	Jcxz_Pre-Int_Code
	int	4


Jcxz_Pre:	db	Jcxz_Code-Jcxz_Pre
	mov	cx,20000

Jcxz_Code:	db	Lods_byte-Jcxz_Code
	jcxz	Lods_Byte

Lods_Byte:	db	Lods_Word-Lods_Byte
	lodsb
Lods_Word:	db	Loop_Code-Lods_Word
	Lodsw

Loop_Code:	db	Movs_Pre-Loop_Code
	Loop	Movs_Pre


Movs_Pre:	db	Movs_Byte-Movs_Pre
	mov	si,0
	mov	di,0
	mov	ax,ds
	mov	es,ax

Movs_Byte:	db	Movs_Word-Movs_Byte
	movsb

Movs_Word:	db	Push_Post-Movs_Word
	movsw


Push_Post:	db	Push_R-Push_Post
	add	sp,2000		;R‚alignement de la pile !!!

Push_R:		db	Push_M-Push_R
	push	bx

Push_M:		db	Push_S-Push_M
	push	word ptr [Var0]

Push_S:		db	Push_I-Push_S
	push	es

Push_I:		db	Pop_Pre-Push_I
	push	123


Pop_Pre:	db	Pop_R-Pop_Pre
	sub	sp,2000		;D‚saligne !!!

Pop_R:		db	Pop_M-Pop_R
	pop	bx

Pop_M:		db	Pop_S-Pop_M
	pop	word ptr [Var0]

Pop_S:		db	Pusha_Post-Pop_S
	pop	es


Pusha_Post:	db	Pusha_Code-Pusha_Post
	add	sp,16000		;Rien que ‡a !!!

Pusha_Code:	db	Popa_Pre-Pusha_Code
	pusha


Popa_Pre:	db	Popa_Code-Popa_Pre
	sub	sp,16000		;Rien que ‡a !!!

Popa_Code:	db	End_Code-Popa_Code
	popa


Ror_R1:		db	Pre_CL1-Ror_R1
	Ror	bx,1
Pre_CL1:	db	Pre_CL8-Pre_CL1
	mov	cl,1
Pre_CL8:	db	Ror_RCL-Pre_CL8
	mov	cl,8
Ror_RCL:	db	Ror_RI2-Ror_RCL
	Ror	bx,cl
Ror_RI2:	db	Ror_RI8-ROR_RI2
	Ror	bx,2
Ror_RI8:	db	Ror_MCL-Ror_RI8
	Ror	bx,8
Ror_MCL:	db	Rep_Stos_Byte-ROR_MCL
	Ror	word ptr [Var0],cl

Rep_Stos_Byte:	db	Rep_Stos_Word-Rep_Stos_Byte
	mov	cx,1000
	mov	di,offset Storage+100
	mov	ax,ds
	mov	es,ax
	rep stosb

Rep_Stos_Word:	db	Rep_Movs_Byte-Rep_Stos_Word
	mov	cx,1000
	mov	di,offset Storage+100
	mov	ax,ds
	mov	es,ax
	rep stosw

Rep_Movs_Byte:	db	Rep_Movs_Word-Rep_Movs_Byte
	mov	cx,1000
	mov	di,Offset Storage+100
	mov	si,di
	mov	ax,ds
	mov	es,ax
	rep movsb

Rep_Movs_Word:	db	Rep_Cmps_Byte-Rep_Movs_Word
	mov	cx,1000
	mov	di,Offset Storage+100
	mov	si,di
	mov	ax,ds
	mov	es,ax
	rep movsw

Rep_Cmps_Byte:	db	Rep_Cmps_Word-Rep_Cmps_Byte
	mov	cx,1000
	mov	di,Offset Storage+100
	mov	si,di
	mov	ax,ds
	mov	es,ax
	repe cmpsb

Rep_Cmps_Word:	db	Rep_Scas_Byte-Rep_Cmps_Word
        mov	cx,1000
	mov	di,Offset Storage+100
	mov	si,di
	mov	ax,ds
	mov	es,ax
	repe cmpsw

Rep_Scas_Byte:	db	Rep_Scas_Word-Rep_Scas_Byte
	mov	cx,1000
	mov	di,Offset Storage+100
	mov	si,di
	mov	ax,ds
	mov	es,ax
	xor	ax,ax
	repe scasb

Rep_Scas_Word:	db	Xchg_RR-Rep_Scas_Word
	mov	cx,1000
	mov	di,Offset Storage+100
	mov	si,di
	mov	ax,ds
	mov	es,ax
	xor	ax,ax
	repe scasw

Xchg_RR:	db	Xchg_RM8-Xchg_RR
	xchg	bl,ch
Xchg_RM8:	db	Xchg_RM16-Xchg_RM8
	xchg	ch,Byte ptr [Var0]
Xchg_RM16:	db	Xchg_AR-Xchg_RM16
	xchg	cx,Word ptr [Var0]
Xchg_AR:	db	Xchg_AM-Xchg_AR
	xchg	ax,bx
Xchg_AM:	db	End_Code-Xchg_AM
	xchg	ax,word ptr [Var0]

End_Code:

	.data

	Even
;	Segment de base pour le test :
Test_Off	dw	Storage			;Pour Far Call [mem] !!!
Test_Seg	dw	@data

;	Variable de travail
Var0		dw	0
Var1		dw	0
Var2		dw	0

Nop_Count	dw	0		;Pour comparaison !!!

Int08_Off	dw	0		;Ancienne routine, sauv‚e !
Int08_Seg	dw	0
Int08_Count	dw	0		;Toujours … -1 au d‚part...

Int03_Off	dw	0		;Ancienne, … remettre...
Int03_Seg	dw	0
Int04_Off	dw	0
Int04_Seg	dw	0

Base_Cycle_Low	dw	0
Base_Cycle_High	dw	0
Aware_286	dw	0		;Necessite un 286 !!!
FL286		dw	0		;As-t'on un 80286 ?!

Loop_Count	dw	0
Text_Ptr	dw	Info_Rem	;Pointeur sur le texte
Tab_Ptr		dw	Info_Cycle	;Pointeur tableau des pointeurs !

Storage		db	20000 dup (0)	;Pour les instructions !!!

;	ChaŒnes utilis‚es....
String_accueil	db	13,10
		db	10
		db	"    ****  Cpu-Cycle  (c)  1990  Philippe Vigier  ****",13,10
		db	10
		db	"    Utilitaire de comptage des cycles CPU utilis‚s pour chaque",13,10
		db	"    instruction ou groupe d'instruction, sur la s‚rie des",13,10
		db	"    microprocesseurs  iNTEL  80x86,  NEC  V  et compatibles.",13,10
		db	10
		db	"    Il est aussi destin‚ … tester les ‚mulateurs de ces",13,10
		db	"    ces microprocesseurs, ainsi que les performances d'un micro",13,10
		db	"    op‚rant sous MS-DOS.",13,10
		db	10
		db	10
		db	"    Traitement en cours....",13,10
		db	10,"$"

String_Fini	db	10
		db	"    Traitement achev‚ !!!",13,10
		db	10
		db	"    ****  Cpu-Cycle  :  Fin d'ex‚cution...",13,10,10
		db	"$"

String_Cycle	db	" cycles.",13,10,"$"

Info_Rem	db	"ETALONNEMENT ...",13,10,0
		db	10
		db	"NOP                             ",0
		db	10
		db	"ADD Reg,Reg                     ",0
		db	"ADD Reg,Immediat      ( 8 bits) ",0
		db	"ADD Reg,Immediat      (16 bits) ",0
		db	"ADD Reg,M‚moire       ( 8 bits) ",0
		db	"ADD Reg,M‚moire       (16 bits) ",0
		db	"ADD AX,Imm‚diat       ( 8 bits) ",0
		db	"ADD AX,Imm‚diat       (16 bits) ",0
		db	"ADD M‚moire,Imm‚diat  ( 8 bits) ",0
		db	"ADD M‚moire,Imm‚diat  (16 bits) ",0
		db	"ADD M‚moire,Reg       ( 8 bits) ",0
		db	"ADD M‚moire,Reg       (16 bits) ",0
		db	10
		db	"CBW                             ",0
		db	"CLC                             ",0
		db	10
		db	"INC Reg               ( 8 bits) ",0
		db	"INC Reg               (16 bits) ",0
		db	"INC M‚moire           ( 8 bits) ",0
		db	"INC M‚moire           (16 bits) ",0
		db	10
		db	"Jcc                   (False)   ",0
		db	"Jcc                   (True )   ",0
		db	"JMP Short                       ",0
		db	10
		db	"LES M‚moire           (32 bits) ",0
		db	"LEA D‚placement                 ",0
		db	"LEA [Base]                      ",0
		db	"LEA [Base]D‚placement           ",0
		db	"LEA [Base][Index]               ",0
		db	"LEA [Base][Index]D‚placement    ",0
		db	10
		db	"MOV Reg,Reg           ( 8 bits) ",0
		db	"MOV Reg,Reg           (16 bits) ",0
		db	"MOV Mem,Reg           ( 8 bits) ",0
		db	"MOV Mem,Reg           (16 bits) ",0
		db	"MOV Reg,Mem           ( 8 bits) ",0
		db	"MOV Reg,Mem           (16 bits) ",0
		db	"MOV Mem,Imm           ( 8 bits) ",0
		db	"MOV Mem,Imm           (16 bits) ",0
		db	"MOV Reg,Imm           ( 8 bits) ",0
		db	"MOV Reg,Imm           (16 bits) ",0
		db	"MOV Mem,AX                      ",0
		db	"MOV  AX,Mem                     ",0
		db	10
		db	"MOV Seg,Reg                     ",0
		db	"MOV Seg,Mem                     ",0
		db	"MOV Reg,Seg                     ",0
		db	"MOV Mem,Seg                     ",0
		db	10
		db	"MUL Reg               ( 8 bits) ",0
		db	"MUL Reg               (16 bits) ",0
		db	"DIV Reg               ( 8 bits) ",0
		db	"DIV Reg               (16 bits) ",0
		db	10
		db	"CMPSB                           ",0
		db	"CMPSW                           ",0
		db	10
		db	"ENTER Imm,0           ( 8 bits) ",0
		db	"ENTER Imm,0           (16 bits) ",0
		db	"ENTER Imm,0  SIMULE   ( 8 bits) ",0
		db	"ENTER Imm,0  SIMULE   (16 bits) ",0
		db	10
		db	"IN AL,Imm‚diat                  ",0
		db	"IN AL,DX                        ",0
		db	"IN AX,DX                        ",0
		db	10
		db	"INT3                  (+ IRET)  ",0
		db	"INT Imm‚diat          (+ IRET)  ",0
		db	10
		db	"JCXZ                  (False)   ",0
		db	"JCXZ                  (True )   ",0
		db	10
		db	"LODSB                           ",0
		db	"LODSW                           ",0
		db	10
		db	"LOOP d‚placement                ",0
		db	10
		db	"MOVSB                           ",0
		db	"MOVSW                           ",0
		db	10
		db	"PUSH Registre                   ",0
		db	"PUSH M‚moire                    ",0
		db	"PUSH Segment                    ",0
		db	"PUSH Imm‚diat                   ",0
		db	"POP  Registre                   ",0
		db	"POP  M‚moire                    ",0
		db	"POP  Segment                    ",0
		db	"PUSHA                           ",0
;		db	"POPA                            ",0
		db	10
		db	"ROR  Reg,1                      ",0
		db	"ROR  Reg,cl       (1 rotation ) ",0
		db	"ROR  Reg,cl       (8 rotations) ",0
		db	"ROR  Reg,2                      ",0
		db	"ROR  Reg,8                      ",0
		db	"ROR  M‚moire,cl   (1 rotation ) ",0
		db	"ROR  M‚moire,cl   (8 rotations) ",0
		db	10
		db	"REP STOSB          (par boucle) ",0
		db	"REP STOSW          (par boucle) ",0
		db	"REP MOVSB          (par boucle) ",0
		db	"REP MOVSW          (par boucle) ",0
		db	"REP CMPSB          (par boucle) ",0
		db	"REP CMPSW          (par boucle) ",0
		db	"REP SCASB          (par boucle) ",0
		db	"REP SCASW          (par boucle) ",0
		db	10
		db	"XCHG Reg,Reg                    ",0
		db      "XCHG Reg,M‚moire      ( 8 bits) ",0
		db	"XCHG Reg,M‚moire      (16 bits) ",0
		db	"XCHG  AX,Reg                    ",0
		db	"XCHG  AX,M‚moire                ",0

		db	0,0,0,0

;	Informations sur les routines … charger...
Info_Cycle	dw	0,0,Nop_Code,1000

		dw	0,0,Nop_Code,1000

		dw	0,0,Add_RR,1000
		dw	0,0,Add_RI8,1000
		dw	0,0,Add_RI16,1000
		dw	0,0,Add_RM8,1000
		dw	0,0,Add_RM16,1000
		dw	0,0,Add_AI8,1000
		dw	0,0,Add_AI16,1000
		dw	0,0,Add_MI8,1000
		dw	0,0,Add_MI16,1000
		dw	0,0,Add_MR8,1000
		dw	0,0,Add_MR16,1000

		dw	0,0,CBW_Code,1000
		dw	0,0,CLC_Code,1000

		dw	0,0,Inc_R8,1000
		dw	0,0,Inc_R16,1000
		dw	0,0,Inc_M8,1000
		dw	0,0,Inc_M16,1000

		dw	0,0,Jc_False,1000
		dw	0,0,Jc_True,1000
		dw	0,0,Jmp_Short,1000

		dw	0,0,Les_M32,1000
		dw	0,0,Lea_M16,1000
		dw	0,0,Lea_R,1000
		dw	0,0,Lea_RI,1000
		dw	0,0,Lea_RX,1000
		dw	0,0,Lea_RXI,1000

		dw	0,0,Mov_RR8,1000
		dw	0,0,Mov_RR16,1000
		dw	0,0,Mov_MR8,1000
		dw	0,0,Mov_MR16,1000
		dw	0,0,Mov_RM8,1000
		dw	0,0,Mov_RM16,1000
		dw	0,0,Mov_MI8,1000
		dw	0,0,Mov_MI16,1000
		dw	0,0,Mov_RI8,1000
		dw	0,0,Mov_RI16,1000
		dw	0,0,Mov_MA16,1000
		dw	0,0,Mov_AM16,1000

		dw	0,0,Mov_SR16,1000
		dw	0,0,Mov_SM16,1000
		dw	0,0,Mov_RS16,1000
		dw	0,0,Mov_MS16,1000

		dw	Mul_Pre,0,Mul16,1000
		dw	Mul_Pre,0,Mul32,1000
		dw	Div_Pre,0,Div16,1000
		dw	Div_Pre,0,Div32,1000

		dw	Cmps_Pre,0,Cmps_b,1000
		dw	Cmps_Pre,0,Cmps_w,1000

		dw	0,0,Enter_8,-1000
		dw	0,0,Enter_16,-1000
		dw	0,0,Entree_8,1000
		dw	0,0,Entree_16,1000

		dw	0,0,In_AI,1000
		dw	In_Pre,0,In_ADX,1000
		dw	In_Pre,0,In_ADY,1000

		dw	0,0,Int3_Code,1000
		dw	0,0,Int_Code,1000

		dw	Jcxz_Pre,0,Jcxz_Code,1000
		dw	0,0,Jcxz_Code,1000

		dw	0,0,Lods_Byte,1000
		dw	0,0,Lods_Word,1000

		dw	Jcxz_Pre,0,Loop_Code,1000

		dw	Movs_Pre,0,Movs_Byte,1000
		dw	Movs_Pre,0,Movs_Word,1000

		dw	0,Push_Post,Push_R,1000
		dw	0,Push_Post,Push_M,1000
		dw	0,Push_Post,Push_S,1000
		dw	0,Push_Post,Push_I,1000
		dw	Pop_Pre,0,Pop_R,1000
		dw	Pop_Pre,0,Pop_M,1000
		dw	Pop_Pre,0,Pop_S,1000
		dw	0,Pusha_Post,Pusha_Code,-1000
;		dw	Popa_pre,0,Popa_Code,-1000

		dw	0,0,Ror_R1,1000
		dw	Pre_CL1,0,Ror_RCL,1000
		dw	Pre_CL8,0,Ror_RCL,1000
		dw	0,0,Ror_RI2,-1000
		dw	0,0,Ror_RI8,-1000
		dw	Pre_CL1,0,Ror_MCL,1000
		dw	Pre_CL8,0,Ror_MCL,1000

		dw	0,0,Rep_Stos_Byte,1
		dw	0,0,Rep_Stos_Word,1
		dw	0,0,Rep_Movs_Byte,1
		dw	0,0,Rep_Movs_Word,1
		dw	0,0,Rep_Cmps_Byte,1
		dw	0,0,Rep_Cmps_Word,1
		dw	0,0,Rep_Scas_Byte,1
		dw	0,0,Rep_Scas_Word,1

		dw	0,0,Xchg_RR,1000
		dw	0,0,Xchg_RM8,1000
		dw	0,0,Xchg_RM16,1000
		dw	0,0,Xchg_AR,1000
		dw	0,0,Xchg_AM,1000

		End	Debut
