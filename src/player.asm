animate_player:
    dec trex_animation_counter
    bne !exit+
    lda #5                          // 5 vertical refreshes delay per animation frame
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

read_joystick2:
    lda is_attacking                // cancel walking animation if attacking
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
    bne check_fire_button
    jsr move_player_right
check_fire_button:
    lda $dc00
    and #%00010000   
    bne !+
    jsr press_fire
    rts
!:
    lda $dc00
    and #%00011111
    cmp #%00011111                  // check if up, down, left, right, fire are released
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
    lda #4                          // ATTACK (index 4 corresponds to spritesheet offset 15)
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