        .cr     Z80
        .tf HD44780_demo.hex,int        ; kompilacja do intel hex
        .lf HD44780_demo.lst    ; poprosimy listing
        .sf HD44780_demo.sym    ; i tablice symboli

                                ; plik z deklaracjami 
        .in ca80.inc            ; procedur i stałych 
                                ; systemowych              

KBD_INPUT   .eq     USER8255+PB         ;USER8255 PB
KBD_OUTPUT  .eq     USER8255+PC         ;USER8255 PC5 - PC7
KBD_CTRL    .eq     USER8255+CTRL       ;USER8255 CONTROL
KBD_A_SET   .eq     $0B ;PC5
KBD_A_RES   .eq     $0A ;PC5
KBD_B_SET   .eq     $0D ;PC6
KBD_B_RES   .eq     $0C ;PC6
KBD_C_SET   .eq     $0F ;PC7
KBD_C_RES   .eq     $0E ;PC7

        .sm     code            ; typowy start kodu uzytkownika
        .or     $c000           ; bank U12, adres $C000
        ;
        ld      SP,$ff66                ; ustawienie stosu 
        ;
main:
        call    lcd_init

        ; print text
        ld      C,LCD_LINE1             ;line 1
        call    lcd_line
        ; point to the text
        ld      B,text_l1_len
        ld      HL,text_l1
        call    lcd_text

        ld      C,LCD_LINE2             ;line 2
        call    lcd_line
        ; point to the text
        ld      B,text_l2_len
        ld      HL,text_l2
        call    lcd_text

        ld      C,LCD_LINE3             ;line 3
        call    lcd_line
        ; point to the text
        ld      B,text_l3_len
        ld      HL,text_l3
        call    lcd_text

        ld      C,LCD_LINE4             ;line 4
        call    lcd_line
        ; point to the text
        ld      B,text_l4_len
        ld      HL,text_l4
        call    lcd_text

        ;===============================
        ;keyboard
        ; konfiguracja 8255 user
        ld      A,$82                   ; GA mode=0, PA-out, PCu-out, GB mode=0, PB-in, PCl-out
        out     (LCD_CTRL),A            ; konfiguracja na CTRL

        ld      A,KBD_A_RES+KBD_B_RES+KBD_C_RES ;set keyboard ABC selection inputs to 0
        out     (KBD_OUTPUT),A
        ld      D,1                     ; 2ms
        call    delay                   ;wait for a moment
loop:
        ld      B,8                     ;size of kbd address array
        ld      HL,kbd_addr             ;keyboard addressing array to HL
loop_1:
        in      A,(KBD_OUTPUT)          ;get state of lower half of PC (which is connected to LCD)
        ld      C,$0F
        and     C                       ;reset upper half
        ld      C,(HL)                  ;load kbd address
        or      C                       ;add kbd address to lower PC state
        out     (KBD_OUTPUT),A          ;send address
        ld      D,5                     ; 10ms
        call    delay                   ;wait for a moment
        in      A,(KBD_INPUT)           ;get keyboard state
        xor     $00                     ;test A for 0
        call    NZ,kbd_key_proc
        ld      D,5                     ; 10ms
        call    delay                   ;wait for a moment
        inc     HL
        djnz    loop_1
        jp      loop

        ;jp     $                       ; martwa pętla 
        rst     $30                     ; lub powrót do Monitora

kbd_key_proc:
        push    AF
        push    BC
        ;change 1-of-8 code got from kbd input to binary
        ld      B,A

        bit     0,B                     ;test for bit 0
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$01
        jp      kbd_key_proc_end
        bit     1,B                     ;test for bit 1
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$02
        jp      kbd_key_proc_end
        bit     2,B                     ;test for bit 2
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$03
        jp      kbd_key_proc_end
        bit     3,B                     ;test for bit 3
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$04
        jp      kbd_key_proc_end
        bit     4,B                     ;test for bit 4
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$05
        jp      kbd_key_proc_end
        bit     5,B                     ;test for bit 5
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$06
        jp      kbd_key_proc_end
        bit     6,B                     ;test for bit 6
        jr      Z,$+7                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$07
        jp      kbd_key_proc_end
        bit     7,B                     ;test for bit 7
        jr      Z,$+4                   ;if bit=0, then skip 4 bytes (jump + add A,nn)
        ld      A,$08

kbd_key_proc_end:
        add     (HL)                    ;add high byte from kbd select lines
        call    LBYTE
        .db     $20                     ;PWYS: 2 digits @ pos 0
        pop     BC
        pop     AF
        ret

;====================================================================
        ; additional routines & functions
        .in routines.inc
        .in lcd.inc

;====================================================================
text:
        ; Hello World !!!!
        .db     $48,$65,$6c,$6c,$6f,$20,$57,$6f,$72,$6c,$64,$20,$21,$21,$21
text_len        .eq $-text
text_l1:
        ; LINE 1
        .db     "Line 1"
text_l1_len     .eq $-text_l1
text_l2:
        ; LINE 2
        .db     "Line 2 is way too long"
text_l2_len     .eq $-text_l2
text_l3:
        ; LINE 3
        .db     "Line 3"
text_l3_len     .eq $-text_l3
text_l4:
        ; LINE 4
        .db     "Line 4"
text_l4_len     .eq $-text_l4

kbd_addr:
        .db     $00,$20,$40,$60,$80,$A0,$C0,$E0