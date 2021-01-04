LCD_DATA    .eq     USER8255+PA ;USER8255 PA
LCD_CTRL    .eq     USER8255+3  ;USER8255 CONTROL
LCD_RS_SET  .eq     $01
LCD_RS_RES  .eq     $00
LCD_RW_SET  .eq     $03
LCD_RW_RES  .eq     $02
LCD_E_SET   .eq     $05
LCD_E_RES   .eq     $04
LCD_LINE1   .eq     $00+$80
LCD_LINE2   .eq     $40+$80
LCD_LINE3   .eq     $14+$80
LCD_LINE4   .eq     $54+$80

lcd_init:
        push    AF
        push    BC
        push    DE
        ; konfiguracja 8255 user
        ld      A,$82                   ; GA mode=0, PA-out, PCu-out, GB mode=0, PB-in, PCl-out
        out     (LCD_CTRL),A            ; konfiguracja na CTRL
        ; ustawienie linii ster. LCD na 0
        ld      A,LCD_RS_RES            ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ld      A,LCD_RW_RES            ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ld      A,LCD_E_RES             ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL

        ; inicjalizacja LCD
        ld      A,$FF                   ; LCD_DATA->0xFF
        out     (LCD_DATA),A
        ld      A,LCD_RS_RES            ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ld      A,LCD_RW_RES            ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ld      A,LCD_E_RES             ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ld      D,8                     ; 16ms
        call    delay
        ; initial write
        ld      C,$38                   ; LCD_DATA->0x38
        call    lcd_cmd
        ld      D,3                     ; 6ms
        call    delay

        call    lcd_cmd
        ld      D,1                     ; 2ms
        call    delay

        call    lcd_cmd

        ; send commands to set input mode, cursor,number of lines ,and etc.
	    ld 	HL,combegadr            ; set HL to point the first command
	    ld 	B,combegadr_len         ; put the number of commands to be sent in B
nextcom:
	    ld      C,(HL)
        call    lcd_cmd
        ld      D,1                     ; 2ms
        call    delay
	    inc 	hl		        ; point the next command
	    djnz 	nextcom		        ; loop till all commands are sent

        pop     DE
        pop     BC
        pop     AF
        ret

        ;lcd_cmd / lcd_data: input: C - data
lcd_cmd:
        push    AF
        ld      A,LCD_RS_RES            ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        jp      lcd_send
lcd_dat:
        push    AF
lcd_send:
        push    BC
        ld      A,C
        out     (LCD_DATA),A            ; data is in C
        ld      A,LCD_E_SET             ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ld      B,1                     ; 2ms
        call    delay
        ld      A,LCD_E_RES             ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        ;lcd data mode is default
        ld      A,LCD_RS_SET            ; BSR mode
        out     (LCD_CTRL),A            ; BSR na CTRL
        pop     BC
        pop     AF
        ret

        ;Set LCD line in which text should be displayed. Input: C - line num
lcd_line:
        push    AF
        ld      A,LCD_LINE1     ;check for line 1
        xor     C
        jp      Z,lcd_line_end
        ld      A,LCD_LINE2     ;check for line 2
        xor     C
        jp      Z,lcd_line_end
        ld      A,LCD_LINE3     ;check for line 3
        xor     C
        jp      Z,lcd_line_end
        ld      A,LCD_LINE4     ;check for line 4
        xor     C
        jp      Z,lcd_line_end
        ld      C,LCD_LINE1     ;jump to line 1 if argument out of range
lcd_line_end:
        call    lcd_cmd
        ld      D,3                     ; 6ms
        call    delay
        pop     AF
        ret

        ;Display text on LCD. Input: HL: address of text message, B: text length
lcd_text:
        push    AF
        push    BC
        push    DE
        ;check if line not too long
        ld      A,20    ;line is 20 character long
        sub     B
        jp      P,lcd_text_loop     ;jump to text display if len<=20
        ;if len>20 then truncate
        ld      B,20
lcd_text_loop:
        ld      C,(HL)
        call    lcd_dat
        ld      D,2                     ; 4ms
        call    delay
        inc     HL
        djnz    lcd_text_loop                    ; while(--B)

        pop     DE
        pop     BC
        pop     AF
        ret

;====================================================================
; commands and strings
combegadr:
	.db     $01,$02,$80,$0f,$06  	        ; clear display,return home,set DD RAM adress,
				        ; turn on display with cursor blinking,set entry mode
combegadr_len   .eq $-combegadr