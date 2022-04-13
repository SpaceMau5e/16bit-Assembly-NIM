;Devin Kaltenbaugh
;The Game of NIM
;Version: 2.3

org 100h

;Sets the window to graphics mode (320 x 200)
mov AL, 13h
mov AH, 0
int 10h

;Generates some Salt for RNG
mov AH, 00h
int 1Ah
       
mov AL, DL

rol AL, 1

and AL, 0000_1111b

mov storedRandom, AL

;Creates a program restart point
restartJmp:

;Clears the keybaord buffer
mov AH, 0Ch
mov AL, 0
int 21h

;Loads Main Menu
call mainMenuLoop

;Starts game
call gameLoop

ret

;The main menu loop
mainMenuLoop Proc
    
    mov numChar, 613
    mov renderYPos, 0
    mov renderXPos, 0
    mov background, 009h
    mov loadMap, 2222
    call renderMap ;Renders the title
    
    mov numChar, 408
    mov renderYPos, 15
    mov background, 00Fh
    mov loadMap, 2835
    call renderMap ;Renders the UI text
    
    call cursorPlayer1 ;Draws the cursor on the screen
    
    menuLoop:
    
    cmp turnTracker, 0
    jz continueMenuInputChecks:
        jmp menuLoopend:
    
    continueMenuInputChecks:
    mov AH, 1h
    int 16h ;Check for buffer input 
    jz no_mainmenuInput:
    
    mov AH, 0h
    int 16h ;Pulled buffered input
    
    call userInput ;Reads the users input
    
    no_mainmenuInput:
    jmp menuLoop:
    
    menuLoopend:
    ret
mainMenuLoop Endp

;The main game loop
gameLoop Proc
    
    mov numChar, 656
    mov renderYPos, 0
    mov renderXPos, 0
    mov background, 00Fh
    mov loadMap, 39
    call renderMap ;Renders the majority of the UI map
    
    mov numChar, 367
    mov renderYPos, 16
    mov background, 00Eh
    mov loadMap, 695
    call renderMap ;Renders the instruction text
    
    call cursorCenter ;Sets the cursor to the center amount
    mov cursorPos, 1
    
    mov numChar, 9
    mov renderYPos, 1
    mov renderXPos, 29
    mov background, 00Eh
    mov loadMap, 1442
    call renderMap  ;Renders the current player's turn
    
    mov numChar, 37
    mov renderYPos, 4
    mov renderXPos, 1
    mov background, 00Ch
    mov loadMap, 1451
    call renderMap ;Renders the game pieces
    
    cmp turnTracker, 2
    jnz startLoop:
        call computerMove
    
    ;Starts the infinite game loop
    startLoop:
    
    mov AH, 1h
    int 16h ;Check for buffer input 
    jz no_Input:
    
    mov AH, 0h
    int 16h ;Pulled buffered input
    
    call userInput ;Reads the users input
    
    no_Input:
    jmp startLoop: ;Keeps the loop going
    
    ret
gameLoop Endp

;Defines the input requirements for the render module
numChar DW 0
renderXPos DB 0
renderYPos DB 0

loadMap DW 0
background DB 0

;This module renders the given map to the screen
renderMap Proc
    
    mov AL, 1
    mov CX, numChar
    mov DL, renderXPos
    mov DH, renderYPos
    push CS
    pop ES
    lea BX, [renderMaps]
    add BX, loadMap
    mov BP, BX
    mov BH, 0
    mov BL, background
    mov AH, 13h
    int 10h
    
    ret
renderMap Endp

;Sets default starting position for selected move
selectedMove DB 1

;Takes the selected move and calls mathOps to make the move
userMove Proc
    
    checkMove0:
    cmp selectedMove, 0
    jnz checkMove1:
        mov take, 1
        mov lastMove, take1
        call mathOps
        jmp endMove:
    
    checkMove1:
    cmp selectedMove, 1
    jnz checkMove2:
        mov take, 2
        mov lastMove, take2
        call mathOps
        jmp endMove:
    
    checkMove2:
    mov take, 3
    mov lastMove, take3
    call mathOps
    
    ;Switches to the computer's turn
    endMove:
    inc turnTracker
    
    mov numChar, 9
    mov renderYPos, 1
    mov renderXPos, 29
    mov background, 00Bh
    mov loadMap, 1432
    call renderMap 
    
    call computerMove
    
    ret
userMove Endp


;Defines basic constants for input detection
left    equ 61h                                     
right   equ 64h
up      equ 77h
down    equ 73h
enter   equ 0Dh

;Defines hte cursors starting position
cursorPos DB 4

;Takes the users input and determines where to move it too
userInput Proc
    
    ;Checks for moving the cursor left
    checkLeft:
    cmp AL, left
    jnz checkRight:
        cmp cursorPos, 0
        jz invalidKey:
            cmp cursorPos, 3
            jz invalidKey:
                cmp cursorPos, 4
                jz invalidKey:
                
                    dec cursorPos
                    
                    cmp cursorPos, 2
                    jnle player1Title:
                    
                        dec selectedMove
                        
                        cmp selectedMove, 0
                        jnz notFarLeft:
                            call cursorFarLeft
                            
                            jmp invalidKey:    
                        
                        notFarLeft:
                        call cursorCenter
                    
                        jmp invalidKey:
                    
                    player1Title:    
                    call cursorPlayer1
                    jmp invalidKey: 
    
    ;Checks for moving the cursor right
    checkRight:
    cmp AL, right
    jnz checkUp:
        cmp cursorPos, 2
        jz invalidKey:
            cmp cursorPos, 3
            jz invalidKey:
                cmp cursorPos, 5
                jz invalidKey:
                          
                    inc cursorPos
                    
                    cmp cursorPos, 2
                    jnle player2Title:
                    
                        inc selectedMove
                        
                        cmp selectedMove, 2
                        jnz notFarRight:
                            call cursorFarRight
                            
                            jmp invalidKey:
                        
                        notFarRight:
                        call cursorCenter
                        
                        jmp invalidKey:
                        
                    player2Title:
                    call cursorPlayer2
                    jmp invalidKey:
    
    ;Checks for moving the cursor up
    checkUp:
    cmp AL, up
    jnz checkDown:
        cmp cursorPos, 3
        jl invalidKey:
            mov cursorPos, 1
            mov selectedMove, 1
            
            mov numChar, 41
            mov renderYPos, 12
            mov renderXPos, 0
            mov background, 000h
            mov loadMap, 1391
            call renderMap
            
            mov renderYPos, 14
            call renderMap
            
            call cursorCenter
            
            jmp invalidKey:
    
    ;Checks for moving the cursor down
    checkDown:
    cmp AL, down
    jnz checkEnter:
        cmp cursorPos, 3
        jnl invalidKey:
            mov cursorPos, 3
            
            mov numChar, 41
            mov renderYPos, 12
            mov renderXPos, 0
            mov background, 002h
            mov loadMap, 1309
            call renderMap
            
            mov renderYPos, 14
            mov loadMap, 1350
            call renderMap
            
            jmp invalidKey:
    
    ;Checks for clicking enter on the steal button
    checkEnter:
    cmp AL, enter
    jnz invalidKey:
        cmp cursorPos, 3
        jnz titleFarLeft:
            call userMove
            
            ;Reset cursor to select 2
            mov cursorPos, 1
            mov selectedMove, 1
            
            mov numChar, 41
            mov renderYPos, 12
            mov renderXPos, 0
            mov background, 000h
            mov loadMap, 1391
            call renderMap
            
            mov renderYPos, 14
            call renderMap
            
            call cursorCenter
            
            jmp invalidKey:
        
        titleFarLeft:    
        cmp cursorPos, 4
        jnz titleFarRight:
            mov turnTracker, 1
            jmp invalidKey:
        
        titleFarRight:
        cmp cursorPos, 5
        jnz invalidKey:
            mov turnTracker, 2
       
    invalidKey:   
    ret
userInput Endp

;The computers brain
computerMove Proc
    
    mov CX, 0Bh
    mov DX, 0A120h
    mov AH, 086h
    int 15h ;Wait roughly a second for dramatic reasons
    
    ;Preform some basic maths
    mov AX, 16
    mov CX, taken
    
    sub AX, CX
    
    mov CX, 4
    
    mov DX, 0
    div CX
    
    cmp DX, 0
    jnz rebalanceState:
        call lookUpTable ;Calls RNG lookup for a random move
        jmp callMathOps:
    
    rebalanceState:
    ;Decides the amount to take
    mov take, DX
    
    callMathOps:
    call mathOps ;Makes move
    
    ;Switches to the player's turn
    dec turnTracker
    
    mov numChar, 9
    mov renderYPos, 1
    mov renderXPos, 29
    mov background, 00Eh
    mov loadMap, 1442
    call renderMap
    
    ret
computerMove Endp

;Defines defaults for mathOps
take DW 0
taken DW 0

;Preforms the core math operations for the games logic
mathOps Proc
    
    mov AX, taken
    mov BX, take
    
    add AX, BX
    
    mov taken, AX
    
    ;Determines how to render the removal of game pieces
    cmp AX, 16
    jge overTook:
        mov DX, 2
        mul DX
        
        mov DX, 2
        add AX, DX
        
        mov numChar, AX
        jmp mathPrint:
    
    overTook:    
    mov numChar, 37
    
    ;Renders the removal of game pieces
    mathPrint:
    mov loadMap, 1
    mov renderYPos, 4
    mov renderXPos, 1
    mov background, 000h
    call renderMap    
    
    call checkWin ;Checks for a win
    
    ret
mathOps Endp

;Defines who starts the game and whos turn it is
turnTracker DB 0

;Checks to see if the game has reached a win state
checkWin Proc
    
    cmp taken, 16
    jnge noWin:
        cmp turnTracker, 1 ;Player win
        jnz player2:            
            mov numChar, 367
            mov renderYPos, 16
            mov renderXPos, 0
            mov background, 00Eh
            mov loadMap, 1488
            call renderMap
            
            call restart ;Triggers restart prompt
            
            jmp noWin:
        
        player2: ;Computer win        
        mov numChar, 367
        mov renderYPos, 16
        mov renderXPos, 0
        mov background, 00Eh
        mov loadMap, 1855
        call renderMap
        
        call restart ;Triggers restart prompt
    
    noWin:
    ret
checkWin Endp

;Handles restarting the game
restart Proc
    
    mov AH, 0Ch
    mov AL, 0
    int 21h ;Clears the keyboard buffer
    
    mov AH, 7
    int 21h ;Waits for user input before restarting
    
    ;Resets all variables
    mov selectedMove, 1
    mov cursorPos, 4
    mov take, 0
    mov taken, 0
    mov turnTracker, 0
    
    call saltGen
    
    jmp restartJmp: ;Jumps to the restart point
    
    ret
restart Endp


;Defines RNG variables
take1 equ 0000_1010b
take2 equ 0000_1001b
take3 equ 0000_0011b

lastMove DB 0000_1100b

storedRandom DB ?

;Random Number Generator (RNG) for the computer to make moves
lookUpTable Proc
    
    call saltGen
    
    mov AL, lastMove
    and AL, 0000_1111b

    mov BL, storedRandom
    and BL, AL

    mov BH, 0
    
    mov AL, randomData + BX
    mov AH, 0
    
    mov take, AX
    
    ret
lookUpTable Endp

saltGen Proc
    
    ;Generates some Salt for RNG
    mov AH, 00h
    int 1Ah
           
    mov AL, DL
    
    rol AL, 1
    
    add AL, storedRandom
    
    and AL, 0000_1111b
    
    mov storedRandom, AL

    ret
saltGen Endp

;RNG Lookup table
randomData DB 1,2,3,1
           DB 2,3,1,1
           DB 1,3,2,3
           DB 2,2,3,1
           

;These are frequently used renders so they were made into
;seperate modules to save space and reduce repeat code
cursorFarLeft Proc
    
    ;Renders the cursor on the far left option
    mov numChar, 41
    mov renderYPos, 8
    mov renderXPos, 0
    mov background, 00Dh
    mov loadMap, 1063
    call renderMap

    mov renderYPos, 10
    mov loadMap, 1104
    call renderMap
    
    ret
cursorFarLeft Endp

cursorFarRight Proc
    
    ;Renders the cursor on the far right option
    mov numChar, 41
    mov renderYPos, 8
    mov renderXPos, 0
    mov background, 00Dh
    mov loadMap, 1227
    call renderMap
                
    mov renderYPos, 10
    mov loadMap, 1268
    call renderMap
    
    ret
cursorFarRight Endp

cursorCenter Proc
    
    ;Renders the cursor on the center option
    mov numChar, 41
    mov renderYPos, 8
    mov renderXPos, 0
    mov background, 00Dh
    mov loadMap, 1145
    call renderMap
            
    mov renderYPos, 10
    mov loadMap, 1186
    call renderMap
    
    ret
cursorCenter Endp

cursorPlayer1 Proc
    
    ;Renders the cursor on the player1 option
    mov numChar, 41
    mov renderYPos, 18
    mov renderXPos, 0
    mov background, 00Dh
    mov loadMap, 3243
    call renderMap
            
    mov renderYPos, 20
    mov loadMap, 3284
    call renderMap
    
    ret
cursorPlayer1 Endp

cursorPlayer2 Proc
    
    ;Renders the cursor on the player2 option
    mov numChar, 41
    mov renderYPos, 18
    mov renderXPos, 0
    mov background, 00Dh
    mov loadMap, 3325
    call renderMap
            
    mov renderYPos, 20
    mov loadMap, 3366
    call renderMap
    
    ret
cursorPlayer2 Endp


;This is the memory associated with UI and Visuals
renderMaps DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219 ;Removes Pieces
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,220,219,219,219,219,219,219,219,219,219,219,219,0Ah,0Dh
           DB 0,0,84,72,69,0,71,65,77,69,0,79,70,0,78,73,77,0,0,0,0,0,0,0,0,220,219,219,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,49,0,0,0,0,0,0,0,0,50,0,0,0,0,0,0,0,0,0,51,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB "                 Steal                 ",0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh ;Main UI Map
           DB 219,"=====================================",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"  The rules are simple. You must     ",219,0Ah,0Dh
           DB 219,"  steal 1, 2 or 3 pieces on your     ",219,0Ah,0Dh
           DB 219,"  turn with the goal of taking the   ",219,0Ah,0Dh
           DB 219,"  last piece, ",15,". Your controls for   ",219,0Ah,0Dh
           DB 219,"  navigating are w,a,s,d and enter.  ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"=====================================",219 ;Instructions
           DB 0,0,0,0,0,0,0,0,0,0,201,205,187,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh ;1
           DB 0,0,0,0,0,0,0,0,0,0,200,205,188,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,201,205,187,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh ;2
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,200,205,188,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,201,205,187,0,0,0,0,0,0,0,0Ah,0Dh ;3
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,200,205,188,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,201,205,205,205,205,205,187,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh ;Steal
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,200,205,205,205,205,205,188,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh ;Blank
           DB " Computer "
           DB "  Player  "
           DB "   | | | | | | | | | | | | | | | ",15,"   "
           DB 219,"=====================================",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"               You Win!              ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"      *Press any key to replay*      ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"=====================================",219 ;Player Win
           DB 219,"=====================================",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"          The Computer Wins!         ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"      *Press any key to replay*      ",219,0Ah,0Dh
           DB 219,"                                     ",219,0Ah,0Dh
           DB 219,"=====================================",219 ;Computer Win
           DB 219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,219,219,219,219,219,0,0,0,0,0,0,0,0,0,0,219,219,219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,219,0,219,219,219,219,0,0,0,219,0,0,0,0,0,219,0,219,0,0,0,219,219,219,219,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,219,0,219,219,0,0,0,0,0,219,0,0,223,219,219,0,219,219,219,220,219,219,219,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,219,223,219,219,223,223,0,0,0,219,0,0,0,219,219,223,219,219,0,219,0,219,219,223,223,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,219,0,219,219,219,219,0,0,0,0,219,219,219,0,219,0,219,219,0,219,0,219,219,219,219,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,219,219,219,0,0,0,0,0,0,0,219,0,0,0,219,219,219,219,219,0,0,0,0,0,219,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,0,219,219,219,219,0,0,0,219,219,0,0,219,0,219,0,219,219,0,0,0,219,219,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,0,219,219,220,220,0,0,0,219,0,219,0,219,0,219,0,219,0,219,220,219,0,219,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,219,0,0,0,219,219,0,0,0,0,0,219,0,0,219,219,0,219,0,219,0,0,219,0,0,219,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,219,219,219,0,219,0,0,0,0,0,219,0,0,0,219,219,219,219,219,0,0,219,0,0,219,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,219,0Ah,0Dh
           DB 219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219 ;Title
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB "       Player 1         Player 2       ",0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ;Turn Selection Panel
           DB 0,0,0,0,0,0,201,205,205,205,205,205,205,205,205,187,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh ;Player 1
           DB 0,0,0,0,0,0,200,205,205,205,205,205,205,205,205,188,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0Ah,0Dh
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,201,205,205,205,205,205,205,205,205,187,0,0,0,0,0,0,0Ah,0Dh ;Player 2
           DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,200,205,205,205,205,205,205,205,205,188,0,0,0,0,0,0,0Ah,0Dh     