/*
    Game: T-Wrecks Cadillacs

    The idea for this game comes from a Button Bashers meeting at Blast Galaxy in Amsterdam,
    where trex and I played the old school beat 'm up Cadillacs and Dinosaurs. I wanted to
    create an 80s style arcade game for Commodore 64 in which you play as a T-Rex that goes
    on a rampage on the highway. 

    Merry Christmas OldDchool!
*/


.var music = LoadSid("../assets/cracktro.sid")

.var trex_animation_address = ($c400 - $c000) / 64 
.var misc_sprite_address = ($c900 - $c000) / 64
.var num_animation_frames = 3

.const KLA_CHARS = $3f40
.const KLA_COLORS = $4328

BasicUpstart2(entry)

/*
    Title screen setup:             VIC bank 0, multi-color bitmap mode
    Game setup:                     VIC bank 3, multi-color character mode
*/

entry: 
    sei

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


/*
    Title screen specific irq was necessary because C64 appearantly crashes when scrolling sprites 
    that have not been toggled on in $d015.
*/

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

init_game:
    sei 
    ldx #$ff                        // reset stack
    txs
    lda #$35                        // bank out BASIC and Kernel ROM 
    sta $01
    lda $DD00
    and #%11111100                  // mask VIC Bank 3 (C000 - $FFFF)
    sta $DD00
    lda #%00000010                  // set Screen RAM to C000, Character RAM to $C800
    sta $D018
    lda #%00010111                  // set multicolor mode
    sta $d016
    lda $d011
    lda #%00011011                  // disable bitmap mode       
    sta $d011



    lda #BLACK
    sta $d020                       // screen border color
    lda #BLACK
    sta $d021                       // screen background color

/*
    The game crashes when copying large amounts of data into color RAM while interrupts are enabled, so disable interrupts before copying into color RAM.
    This issue took me way too much time to figure out.
*/

    lda #%01111111                  // disable interrupt from CIA1
    sta $dc0d
    and $D011
    sta $D011  
    sta $dc0d                       // acknowledge pending interrupts from CIA1
    sta $dd0d
    lda #$fa                        // set raster line to 210
    sta $d012
    lda #<irq           
    sta $fffe
    lda #>irq
    sta $ffff
    lda #%00000001                  // enable raster interrupt
    sta $d01a

    ldx #0
!:
    lda map_color_data, x           
    sta $d800, x 
    lda map_color_data + 250, x     
    sta $d800 + 250, x 
    lda map_color_data + 500, x     
    sta $d800 + 500, x
    lda map_color_data + 750, x     
    sta $d800 + 750, x
    inx
    cpx #250
    bne !-

/*
    Sprites

    Index 0: T-Rex (high resolution sprite)
    Index 1: Small car (multicolor sprite)
    Index 2 & 3: Smediun car (multicolor sprite)
*/

    lda #%11111111                  // enable all 8 sprites
    sta $d015          
    lda #101111110                  // only sprite 0 is high resolution, the rest is multi-colored
    sta $d01c
    lda #WHITE                      // shared sprite color 1
    sta $d025
    lda #RED                        // shared sprite color 2
    sta $d026

/*
    Sprite 0: T-Rex 
*/

    lda #WHITE                      // sprite 0 color
    sta $d027
    lda #00
    sta $d010
    lda #180                        // X position
    sta $d000
    lda #100                        // Y position
    sta $d001
    lda #trex_animation_address
    sta $c3f8

/*
    Small car
*/

    lda #GRAY    
    sta $d028
    lda #misc_sprite_address + 0  
    sta $c3f9       
    lda #255     
    sta $d002
    lda #150  
    sta $d003    

/*
    Treasure
*/
    lda #YELLOW    
    sta $d02e
    lda #misc_sprite_address + 5  
    sta $c3ff
    lda #180     
    sta $d00e
    lda #180  
    sta $d00f    

/*
    ldx #7
    lda #200
    sta spr_x_pos + 7
    lda #100
    sta spr_y_pos + 7
    lda #SPD_0_50
    jsr set_sprite_speed
*/

    lda $d01e                       // clear colission flag

    ldx #0
    ldy #0
    lda #music.startSong - 1
    jsr music.init

    jsr ui_update_lives
    jsr ui_update_score

    cli                             // enable interrupts after initialization


mainloop:
    jmp mainloop
    rts

irq:
    pha
    txa
    pha
    tya
    pha
    lda #$ff        
    sta $d019       
    //lda #YELLOW     
    //sta $d020

    jsr music.play
    jsr update_cars
    jsr read_joystick2
    jsr handle_collisions

    //lda $d015
    //eor #%00000001                  // flicker
    //sta $d015 

    //lda #BLACK      
    //sta $d020
    pla             
    tay
    pla
    tax
    pla
    rti

/*
    Using bit patterns to determine when a sprite should scroll one pixel
    Parameters:
        X:      sprite number
    Returns:
        A:      either 0 (don't scroll) or 1 (scroll)
*/

calculate_scroll_speed:
    lda sprite_scroll_pattern, x    // load the movement pattern for the current sprite (sprite number from register X)
    lsr                             // shift the bit-pattern to the right, the right-most bit goes into the carry
    bcc !+           
    ora #%10000000                  // if the carry contains a 1, add it back into the pattern 
!:
    sta sprite_scroll_pattern, x    // save new bit order
    rts

handle_collisions:
    lda $d01e
    and #%00000011                  // mask bits 0 (player) and 1 (small car)
    cmp #%00000011                  // if both bits are set, then they're colliding
    bne !+
    lda i_frames                    // if i_frames > 0 then the player is already taking damage, so skip to flicking
    bne !+
    lda #100                        // set invincibility timer to 100 vertical refreshes (make sure it's an even number)
    sta i_frames
    dec num_lives
    bpl !+
    jsr game_over
!:
    lda i_frames
    beq !exit+
    dec i_frames                    // advance invincibility timer 
    lda $d015
    eor #%00000001                  // flicker sprite 0 (player)
    sta $d015
    jsr ui_update_lives
!exit:
    rts

ui_update_lives:
    ldx num_lives
    lda lives_char_table, x
    sta $c007                       // update map_data at index 7 (next to lives=) corresponding to num_lives
    rts

ui_update_score:
    rts

read_joystick2:
    lda is_attacking                // cancel walking animation if in attack
    beq !+
    jsr animate_player
    rts
!:
    lda $dc00    
    and #%00000001
    bne !+
    jsr move_player_up
    jmp check_fire_button
!:
    lda $dc00
    and #%00000010   
    bne !+
    jsr move_player_down
    jmp check_fire_button
!:
    lda $dc00
    and #%00000100  
    bne !+
    jsr move_player_left
    jmp check_fire_button
!:
    lda $dc00
    and #%00001000  
    bne !+
    jsr move_player_right
    jmp check_fire_button
check_fire_button:
    lda $dc00
    and #%00010000   
    bne !+
    jsr press_fire
!:
    lda $dc00
    cmp #%01111111  
    bne !+
    jsr player_idle
!:
    rts

move_player_up:
    dec $d001
    lda #3                          // direction == 3 means character is facing away
    sta trex_direction
    jsr animate_player
    rts

move_player_down:
    inc $d001
    lda #2                          // direction == 2 means character is facing the player
    sta trex_direction
    jsr animate_player
    rts

move_player_left:
    lda $d000
    bne !+
    lda $d010
    and #%11111110                  // wrap
    sta $d010
!:
    dec $d000
    lda #1                          // direction == 1 means character is facing left
    sta trex_direction
    jsr animate_player
    rts

move_player_right:
    inc $d000 
    bne !+  
    lda $d010
    ora #%00000001                  // wrap
    sta $d010
!:
    lda #0                          // direction == 0 means character is facing right
    sta trex_direction
    jsr animate_player
    rts

press_fire:
    lda is_attacking                // early exit if already in attack state
    bne !exit+ 
    lda #1                          // otherwise enter attack state
    sta is_attacking
    lda #4                          // ATTACK (Index 4 -> Offset 15)
    sta trex_direction
    
    lda #0
    sta trex_animation_frame

    lda #1
    sta trex_animation_counter
    jsr animate_player
!exit:
    rts

player_idle:
    lda #2
    sta trex_animation_frame
    jsr animate_player
    rts

animate_player:
    dec trex_animation_counter
    bne !exit+
    lda #5                          // 5 vertical refreshes delay per frame
    sta trex_animation_counter
    lda #trex_animation_address
    clc
    adc trex_animation_frame
    ldx trex_direction
    adc animation_offset_table, x   // locate sprite range for current animation
    sta $C3F8
    inc trex_animation_frame        // advance to next animation frame
    lda trex_animation_frame
    cmp #num_animation_frames
    bcc !exit+
    lda #0                          // loop by resetting to the first sprite in the animation range
    sta trex_animation_frame
    lda is_attacking
    beq !+
    lda #0
    sta is_attacking
    sta trex_animation_frame
    lda #2                          // end attacking animation on down-facing frame
    sta trex_direction
    jmp !exit+
!:
    lda #0                          // reset animation loop
    sta trex_animation_frame
!exit:
    rts

update_cars:
    lda $d010
    and #%00000010                  // check if MSB is set for sprite 1 (small car)
    beq !+
    dec $d002
    lda $d002
    cmp #$ff                        // Did we wrap from 0 to 255?
    bne !exit+
    lda $d010
    and #%11111101                  // clear MSB bit for sprite 1
    sta $d010
    jmp !exit+
!:
    dec $d002
    lda $d002
    cmp #1                          // check if the sprite is near the border of the left side of the screen
    bcs !exit+
    dec num_lives
    bpl !+                          // is num_lives == 0 then jump to game_over subroutine
    jsr game_over
!:
    lda #94                         // respawn sprite 1 on the right side of the screen
    sta $d002
    lda $d010
    ora #%00000010                  // Set MSB
    sta $d010
    jsr ui_update_lives
!exit:
    rts

game_over:
    jmp reset_game    
    rts

reset_game:
    lda #$00                         
    sta $d015                       // disable all 8 sprites
    sta is_attacking                // reset game variables
    sta i_frames
    sta trex_animation_frame
    lda #$03
    sta num_lives
    jmp entry
    rts

trex_animation_frame:       .byte 0
trex_direction:             .byte 0
trex_animation_counter:     .byte 5
trex_walking_speed:         .byte 1
num_lives:                  .byte 3
is_attacking:               .byte 0
i_frames:                   .byte 0

animation_offset_table:     .byte 0, 3, 6, 9, 12
lives_char_table:           .byte 13, 4, 5, 6

/*
    Sprite scrolling patterns

    Sprite 0 [ player character ]   11111111
    Sprite 1 [ small car ]          10101010
    Sprite 2 [ medium car part A ]  10101010
    Sprite 3 [ medium car part B ]  10101010
    Sprite 4 [ small car ]          11111111
    Sprite 5 [ medium car part A ]  01010101
    Sprite 6 [ medium car part B ]  01010101
    Sprite 7 [ item ]               00000000
*/

sprite_scroll_pattern:      .byte $ff, $aa, $aa, $aa, $ff, $55, $55, $00

/*
    Memory layout

    $c000 - c3fff   Background map data
    $c400 - $7fff   T-Rex sprite data (high res)
    $c800 - $87ff   Background character data (multi-color)
    $c900 - $c9ff   Car and items sprite data (multi-clor)
    $d000 - $dfff   Background color data
*/

.pc=music.location "Music"
.fill music.size, music.getData(i)

* = $1FFE "title"                    // -2 bytes offset to clip off the header
.import binary "..\assets\title.kla"

*=$c000 "map data"
.import binary "..\assets\roads_map.bin"

*=$c400 "sprite data"
dino_sprite_data:
.import binary "..\assets\t-rex_24_21_sprites.bin"

*=$c800 "character data"
.import binary "..\assets\roads_characters.bin"

*=$C900 "More sprites data"
extra_sprites:
.import binary "../assets/misc_sprites.bin"

*=$8000 "mapcolor data"
map_color_data:
.import binary "..\assets\roads_colors.bin"

/*
    More sprites data indices:

    0   small car facing left
    1   front of large car facing left 
    2   back OF large car facing left
    3   small car facing right
    4   back of large car facing right
    5   front of large car facing right
    6   treasure chest
    7   star
    8   explosion
*/