.386
include \masm32\include\masm32rt.inc  ; Подключение стандартных библиотек MASM32 для работы с консолью

.data
newgame BYTE 'we are playing?(y/n)', 0  ; Сообщение для начала игры
user_input BYTE 1 DUP(0)  ; Место для ввода пользователя
newline BYTE 0Dh, 0Ah, 0  ; Символ новой строки
star BYTE '-', 0  ; Символ для отображения игрового поля
head BYTE '@', 0  ; Символ головы змейки
count DWORD 30  ; Ширина игрового поля
count1 DWORD 20  ; Высота игрового поля
snak BYTE '*', 0  ; Символ еды

cord_X DWORD 3  ; Координата X головы змейки
cord_Y DWORD 1  ; Координата Y головы змейки
direction DWORD 1  ; Направление змейки (1 - вправо, 2 - вниз, 3 - влево, 4 - вверх)

snake_X DWORD 100 DUP(0)  ; Массив для хранения X координат змейки
snake_Y DWORD 100 DUP(0)  ; Массив для хранения Y координат змейки

snake_length DWORD 0  ; Длина змейки/количество очков
score_text BYTE 'Score: ', 0  ; Текст для отображения счета
score_str BYTE 10 DUP(0)  ; Строка для отображения счета

msg_title BYTE 'Сообщение', 0  ; Заголовок для msgbox
msg_gameover BYTE 'Выполнил Детков Александр ПИб-2', 0  ; Сообщение о завершении игры

food_X DWORD 100 DUP(0)  ; Массив для хранения X координат пищи
food_Y DWORD 100 DUP(0)  ; Массив для хранения Y координат пищи
food_count DWORD 0  ; Счетчик для пищи

.data?
hConsoleOutput DWORD ?  ; Дескриптор консольного вывода
dwWritten DWORD ?  ; Количество записанных символов
NumberOfCharsWritten DWORD ?  ; Количество записанных символов

old_cord_X DWORD ?  ; Старая координата X головы змейки
old_cord_Y DWORD ?  ; Старая координата Y головы змейки

.code

start:
    invoke AllocConsole  ; Выделение памяти для консоли
    invoke GetStdHandle, STD_OUTPUT_HANDLE  ; Получение дескриптора для вывода в консоль
    mov hConsoleOutput, eax  ; Сохранение дескриптора в переменную
    call hide_cursor  ; Скрытие курсора для улучшения восприятия игры

    invoke WriteConsole, hConsoleOutput, addr newgame, SIZEOF newgame - 1, addr NumberOfCharsWritten, 0  ; Выводим сообщение "Начать игру?"
    invoke GetStdHandle, STD_INPUT_HANDLE  ; Получаем дескриптор для ввода с клавиатуры
    mov ebx, eax  ; Сохраняем дескриптор
    invoke ReadConsole, ebx, addr user_input, 1, addr NumberOfCharsWritten, 0  ; Чтение ввода

    mov al, [user_input]  ; Чтение символа
    cmp al, 'y'  ; Если введен 'y', начинаем игру
    je start_game
    cmp al, 'n'  ; Если введен 'n', , завершаем игру
    jne game_over  ; Если введен неверный символ, завершаем игру

start_game:
    mov eax, 0  ; Очищаем консоль
    mov ecx, 80 * 25
    invoke FillConsoleOutputCharacter, hConsoleOutput, ' ', ecx, eax, addr dwWritten
    mov edx, 0
    xor edx, edx  ; Сброс курсора в начало
    invoke SetConsoleCursorPosition, hConsoleOutput, edx

    mov ebx, count1  ; Рисуем игровое поле
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

    call place_food  ; Генерируем пищу на поле
    jmp snake_start  ; Переходим к циклу игры

snake_start:
    ; Чтение состояния клавиш для изменения направления змейки
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

    ; В зависимости от направления выполняем движение змейки
    mov eax, direction
    cmp eax, 1
    je move_right
    cmp eax, 2
    je move_down
    cmp eax, 3
    je move_left
    cmp eax, 4
    je move_up

    jmp snake_start  ; Продолжаем цикл

set_direction_up:
    cmp direction, 2  ; Проверка, чтобы змейка не двигалась в противоположную сторону
    je snake_start
    mov direction, 4  ; Устанавливаем новое направление (вверх)
    jmp snake_start

set_direction_down:
    cmp direction, 4
    je snake_start
    mov direction, 2  ; Устанавливаем новое направление (вниз)
    jmp snake_start

set_direction_left:
    cmp direction, 1
    je snake_start
    mov direction, 3  ; Устанавливаем новое направление (влево)
    jmp snake_start

set_direction_right:
    cmp direction, 3
    je snake_start
    mov direction, 1  ; Устанавливаем новое направление (вправо)
    jmp snake_start

move_up:
    dec cord_Y  ; Двигаем змейку вверх
    mov eax, cord_Y
    cmp eax, 0  ; Проверка на столкновение с верхней границей
    jl game_over
    jmp update_snake

move_down:
    inc cord_Y  ; Двигаем змейку вниз
    mov eax, cord_Y
    cmp eax, count1  ; Проверка на столкновение с нижней границей
    jge game_over
    jmp update_snake

move_left:
    dec cord_X  ; Двигаем змейку влево
    mov eax, cord_X
    cmp eax, 0  ; Проверка на столкновение с левой границей
    jl game_over
    jmp update_snake

move_right:
    inc cord_X  ; Двигаем змейку вправо
    mov eax, cord_X
    cmp eax, count  ; Проверка на столкновение с правой границей
    jge game_over
    jmp update_snake

update_snake:
    ; Обновляем положение змейки на экране
    mov eax, cord_X
    mov old_cord_X, eax
    mov eax, cord_Y
    mov old_cord_Y, eax

    ; Проверка на съеденную пищу
    mov eax, cord_X
    cmp eax, [food_X]
    jne not_eaten
    mov eax, cord_Y
    cmp eax, [food_Y]
    jne not_eaten

    call place_food  ; Генерируем новую пищу
    mov eax, snake_length
    inc eax
    mov snake_length, eax  ; Увеличиваем длину змейки
    jmp continue_game

not_eaten:
    ; Отображаем голову змейки
    mov eax, cord_X
    mov edx, cord_Y
    shl edx, 16
    or eax, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, eax
    invoke WriteConsole, hConsoleOutput, addr head, SIZEOF head - 1, addr NumberOfCharsWritten, 0

continue_game:
    invoke Sleep, 100  ; Пауза для замедления движения змейки
    call clean_snake  ; Очищаем старую позицию змейки
    call display_score  ; Отображаем текущий счет
    jmp snake_start  ; Продолжаем цикл игры

clean_snake:
    ; Очищаем старую позицию змейки
    mov eax, old_cord_X
    mov edx, old_cord_Y
    shl edx, 16
    or eax, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, eax
    invoke WriteConsole, hConsoleOutput, addr star, SIZEOF star - 1, addr NumberOfCharsWritten, 0
    ret

place_food:
    ; Генерация новой пищи на поле
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

    ; Отображаем пищу на экране
    mov eax, [food_X]
    mov edx, [food_Y]
    shl edx, 16
    or eax, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, eax
    invoke WriteConsole, hConsoleOutput, addr snak, SIZEOF snak - 1, addr NumberOfCharsWritten, 0

    ret

game_over:

    invoke MessageBoxA, 0, addr msg_gameover, addr msg_title, MB_OK  ; Сообщение о завершении игры
    invoke ExitProcess, 0  ; Завершение программы

hide_cursor:
    ; Скрытие курсора
    sub esp, sizeof CONSOLE_CURSOR_INFO
    mov eax, hConsoleOutput
    mov dword ptr [esp], 1
    mov dword ptr [esp + 4], 0
    invoke SetConsoleCursorInfo, eax, esp
    add esp, sizeof CONSOLE_CURSOR_INFO
    ret

display_score:
    ; Отображение текущего счета
    mov eax, count1
    mov edx, count
    mov ecx, 1
    mov ebx, ecx
    shl ebx, 16
    or ebx, edx
    invoke SetConsoleCursorPosition, hConsoleOutput, ebx
    invoke WriteConsole, hConsoleOutput, addr score_text, SIZEOF score_text - 1, addr NumberOfCharsWritten, 0

    mov eax, snake_length
    call itoa  ; Преобразование числа в строку

    invoke WriteConsole, hConsoleOutput, addr score_str, SIZEOF score_str - 1, addr NumberOfCharsWritten, 0
    ret

itoa:
    ; Преобразование целого числа в строку
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
