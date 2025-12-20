start_title_screen:
    sei

    lda #$00                         
    sta $d015                       // disable all 8 sprites (in case of game reset)

    lda #$35                        // bank out BASIC and Kernel ROM 
    sta $01

    lda $dd00
    ora #%00000011                  // VIC bank 0 is used for the title screen
    sta $dd00

    lda #%01111111                  // disable interrupt from CIA1
    sta $dc0d
    and $D011
    sta $D011  
    sta $dc0d                       // acknowledge pending interrupts from CIA1
    sta $dd0d
    lda #$fa                        // set raster line to 210
    sta $d012
    lda #<title_irq      
    sta $fffe
    lda #>title_irq
    sta $ffff
    lda #%00000001                  // enable raster interrupt
    sta $d01a

    ldx #$00
!:
    lda KLA_CHARS, x
    sta $0400, x
    lda KLA_CHARS + $100, x
    sta $0400 + $100, x
    lda KLA_CHARS + $200, x
    sta $0400 + $200, x
    lda KLA_CHARS + $300, x
    sta $0400 + $300, x             // copy 1000 characters to SCREEN_RAM
    lda KLA_COLORS, x
    sta $d800, x
    lda KLA_COLORS + $100, x
    sta $d800 + $100, x
    lda KLA_COLORS  + $200, x
    sta $d800 + $200, x
    lda KLA_COLORS  + $300, x
    sta $d800 + $300, x             // copy 1000 colors to COLOR_RAM
    inx
    bne !-

    lda #%00011000                  // Toggle SCREEN_RAM at $0400, bitmap at $2000
    sta $d018

    lda #%00111000                  // 25 rows, bitmap mode
    sta $d011

    lda #%10111011                  // 40 columns, multicolor mode
    sta $d016

    lda #BLACK                      // set border and background color to black
    sta $d020
    sta $d021

    ldx #$00
    ldy #$00
    lda #music.startSong - 1
    jsr music.init
    
    cli
!:
  jmp !-  
  rts

title_irq:
    pha
    txa
    pha
    tya
    pha
    lda #$ff        
    sta $d019
    jsr music.play
    lda $dc00                       
    and #%00010000                  // check if fire button was pressed
    bne !+
    jsr init_game
!:
    pla             
    tay
    pla
    tax
    pla
    rti
