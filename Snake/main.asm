.386
include \masm32\include\masm32rt.inc  

.data
newgame BYTE 'we are playing?(y/n)', 0  
user_input BYTE 1 DUP(0)  
newline BYTE 0Dh, 0Ah, 0 
star BYTE '-', 0  
head BYTE '@', 0  
count DWORD 30  
count1 DWORD 20  
snak BYTE '*', 0  

cord_X DWORD 3 
cord_Y DWORD 1  
direction DWORD 1  

snake_X DWORD 100 DUP(0) 
snake_Y DWORD 100 DUP(0) 

snake_length DWORD 0 
score_text BYTE 'Score: ', 0  
score_str BYTE 10 DUP(0)  

msg_title BYTE 'YOU LOSE', 0  
msg_gameover BYTE 'GAME OVER!', 0  

food_X DWORD 100 DUP(0)  
food_Y DWORD 100 DUP(0) 
food_count DWORD 0  

.data?
hConsoleOutput DWORD ?  
dwWritten DWORD ?  
NumberOfCharsWritten DWORD ?  

old_cord_X DWORD ?  
old_cord_Y DWORD ?  

.code

start:
    invoke AllocConsole  
    invoke GetStdHandle, STD_OUTPUT_HANDLE  
    mov hConsoleOutput, eax  
    call hide_cursor  

    invoke WriteConsole, hConsoleOutput, addr newgame, SIZEOF newgame - 1, addr NumberOfCharsWritten, 0  
    invoke GetStdHandle, STD_INPUT_HANDLE  
    mov ebx, eax 
    invoke ReadConsole, ebx, addr user_input, 1, addr NumberOfCharsWritten, 0  

    mov al, [user_input] 
    cmp al, 'y' 
    je start_game
    cmp al, 'n'  
    jne game_over  

start_game:
    mov eax, 0  
    mov ecx, 80 * 25
    invoke FillConsoleOutputCharacter, hConsoleOutput, ' ', ecx, eax, addr dwWritten
    mov edx, 0
    xor edx, edx 
    invoke SetConsoleCursorPosition, hConsoleOutput, edx

    mov ebx, count1  
    for_loop:
        mov ecx, count
        push ebx
        for2_loop:
            push ecx
            invoke WriteConsole, hConsoleOutput, addr star, SIZEOF star - 1, addr NumberOfCharsWritten, 0
            pop ecx
            dec ecx
            cmp ecx, 0
            jg for2_loop
        invoke WriteConsole, hConsoleOutput, addr newline, SIZEOF newline - 1, addr NumberOfCharsWritten, 0
        pop ebx
        dec ebx
        cmp ebx, 0
        jg for_loop

    call place_food 
    jmp snake_start 

snake_start:
    invoke GetAsyncKeyState, VK_UP
    test ax, 8000h
    jnz set_direction_up

    invoke GetAsyncKeyState, VK_DOWN
    test ax, 8000h
    jnz set_direction_down

    invoke GetAsyncKeyState, VK_LEFT
    test ax, 8000h
    jnz set_direction_left

    invoke GetAsyncKeyState, VK_RIGHT
    test ax, 8000h
    jnz set_direction_right

    mov eax, direction
    cmp eax, 1
    je move_right
    cmp eax, 2
    je move_down
    cmp eax, 3
    je move_left
    cmp eax, 4
    je move_up

    jmp snake_start  

set_direction_up:
    cmp direction, 2  
    je snake_start
    mov direction, 4  
    jmp snake_start

set_direction_down:
    cmp direction, 4
    je snake_start
    mov direction, 2 
    jmp snake_start

set_direction_left:
    cmp direction, 1
    je snake_start
    mov direction, 3 
    jmp snake_start

set_direction_right:
    cmp direction, 3
    je snake_start
    mov direction, 1  
    jmp snake_start

move_up:
    dec cord_Y 
    mov eax, cord_Y
    cmp eax, 0 
    jl game_over
    jmp update_snake

move_down:
    inc cord_Y 
    mov eax, cord_Y
    cmp eax, count1 
    jge game_over
    jmp update_snake

move_left:
    dec cord_X  
    mov eax, cord_X
    cmp eax, 0 
    jl game_over
    jmp update_snake

move_right:
    inc cord_X  
    mov eax, cord_X
    cmp eax, count 
    jge game_over
    jmp update_snake

update_snake:
    mov eax, cord_X
    mov old_cord_X, eax
    mov eax, cord_Y
    mov old_cord_Y, eax

    mov eax, cord_X
    cmp eax, [food_X]
    jne not_eaten
    mov eax, cord_Y
    cmp eax, [food_Y]
    jne not_eaten

    call place_food  
    mov eax, snake_length
    inc eax
    mov snake_length, eax  
    jmp continue_game

not_eaten:
    mov eax, cord_X
    mov edx, cord_Y
    shl edx, 16
    or eax, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, eax
    invoke WriteConsole, hConsoleOutput, addr head, SIZEOF head - 1, addr NumberOfCharsWritten, 0

continue_game:
    invoke Sleep, 100  
    call clean_snake 
    call display_score  
    jmp snake_start 

clean_snake:
    mov eax, old_cord_X
    mov edx, old_cord_Y
    shl edx, 16
    or eax, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, eax
    invoke WriteConsole, hConsoleOutput, addr star, SIZEOF star - 1, addr NumberOfCharsWritten, 0
    ret

place_food:
    invoke GetTickCount
    mov eax, [food_count]
    add eax, 1
    mov [food_count], eax  

    invoke GetTickCount
    mov eax, edx
    xor edx, edx
    mov ecx, count
    div ecx
    mov [food_X], edx  

    invoke GetTickCount
    mov eax, edx
    xor edx, edx
    mov ecx, count1
    div ecx
    mov [food_Y], edx  

    mov eax, [food_X]
    mov edx, [food_Y]
    shl edx, 16
    or eax, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, eax
    invoke WriteConsole, hConsoleOutput, addr snak, SIZEOF snak - 1, addr NumberOfCharsWritten, 0

    ret

game_over:

    invoke MessageBoxA, 0, addr msg_gameover, addr msg_title, MB_OK 
    invoke ExitProcess, 0 

hide_cursor:
    sub esp, sizeof CONSOLE_CURSOR_INFO
    mov eax, hConsoleOutput
    mov dword ptr [esp], 1
    mov dword ptr [esp + 4], 0
    invoke SetConsoleCursorInfo, eax, esp
    add esp, sizeof CONSOLE_CURSOR_INFO
    ret

display_score:
    mov eax, count1
    mov edx, count
    mov ecx, 1
    mov ebx, ecx
    shl ebx, 16
    or ebx, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, ebx
    invoke WriteConsole, hConsoleOutput, addr score_text, SIZEOF score_text - 1, addr NumberOfCharsWritten, 0

    mov eax, snake_length
    call itoa 

    invoke WriteConsole, hConsoleOutput, addr score_str, SIZEOF score_str - 1, addr NumberOfCharsWritten, 0
    ret

itoa:
    mov ebx, 10
    lea ecx, score_str
    itoa_loop:
        xor edx, edx
        div ebx
        add dl, '0'
        mov [ecx], dl
        inc ecx
        test eax, eax
        jnz itoa_loop

    mov byte ptr [ecx], 0
    ret

end start
