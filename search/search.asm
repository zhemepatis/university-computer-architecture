.model small

.stack 100h

.data
    buff db 200h dup(?)

    filename db 255 dup(0)
    filename_length db 0
    file_handler dw 0

    stats_file db "stats.txt", 0
    stats_handler dw 0
    
    stats_buff db 1ah dup(?), 0dh, 0ah
    stats_init db 1ah dup(30h), 0dh, 0ah

    error_msg1 db "No arguments were provided. Terminating program.", 13, 10, 24h
    error_msg2 db "Unable open the file named ", 24h

    newline db 13, 10

.code
    start:
        mov ax, @data
        mov ds, ax

        ; creating "stats.txt" file
        mov ax, 3c00h
        mov dx, offset stats_file
        int 21h
        mov stats_handler, ax
    
        ; prep to read args
        xor cx, cx
        mov cl, es:[80h]                ; needed to know the length of arguments line

        cmp cl, 0h                      ; checking if there are arguments provided, if no - terminating the program
        mov dx, offset error_msg1
        je print_error

        ; creating & initialising stats file
        mov ax, 3c00h
        xor cx, cx
        mov dx, offset stats_file
        int 21h
        mov stats_handler, ax

        mov dx, offset stats_init
        call print_line
        call return_to_start
        
        mov si, 0081h                   ; argument line offset in memory block
        call cmd_line_args

        jmp terminate_program

        print_error:
            mov ah, 09h
            int 21h

        terminate_program:
            ; closing "stats.txt"
            mov bx, file_handler
            call close_file

            ; terminating the application
            mov ax, 4c00h
            int 21h

        close_file:
            mov ax, 3e00h
            int 21h
            ret

        ; PROCEDURES
        altering_stats proc
            push ax  

            reading_stats:
                call read_line
                mov cx, ax
                jcxz new_letter

                pop bx
                cmp [stats_buff + bx], 31h
                push bx
                jne reading_stats
                
                mov [stats_buff + bx], 30h
                call set_back
                mov dx, offset stats_buff
                call print_line
                
                new_status:
                    call read_line
                    mov cx, ax
                    jcxz new_highscore

                    call set_back
                    pop bx
                    mov [stats_buff + bx], 31h
                    mov dx, offset stats_buff
                    call print_line

                    jmp end_loop

                new_highscore:              
                    mov dx, offset stats_init
                    call print_line
                    call set_back
                
                    jmp new_status

                new_letter:
                    call return_to_start
                    call read_line
                    call return_to_start

                    pop bx
                    mov [stats_buff + bx], 31h
                    mov dx, offset stats_buff
                    call print_line

                end_loop:
                    call return_to_start
                    jmp exit_loop
            loop reading_stats

            exit_loop:
                ret

            read_line:
                mov dx, offset stats_buff
                mov ax, 3f00h
                mov cx, 1ch
                mov bx, stats_handler
                int 21h
                ret

            print_line:
                mov ax, 4000h
                mov bx, stats_handler
                mov cx, 1ch
                int 21h
                ret
            
            return_to_start:
                mov ax, 4200h
                mov bx, stats_handler
                xor cx, cx
                xor dx, dx
                int 21h
                ret

            set_back:
                mov ax, 4201h
                mov bx, stats_handler
                mov cx, -1h
                mov dx, -1ch
                int 21h
                ret

        altering_stats endp


        operating_with_files proc     ; open file and read data
            ; opening input file
            mov ax, 3d00h
            mov dx, offset filename
            int 21h
            jc unable_open_file
            mov file_handler, ax

            mov dx, offset buff
            reading_data:
                ; reading data from input file
                mov ax, 3f00h
                mov cx, 200h
                mov bx, file_handler
                int 21h

                mov cx, ax
                jcxz exit_operating_with_files

                xor bx, bx
                data_analysis:
                    push cx
                    push bx

                    mov al, [buff + bx]
                    
                    cmp al, 41h
                    jb proceed_data_analysis

                    cmp al, 5ah
                    jbe lower_letter

                    cmp al, 61h
                    jb proceed_data_analysis           

                    cmp al, 7ah
                    ja proceed_data_analysis

                    jmp stats

                    lower_letter:
                        add al, 20h

                    stats:
                        sub al, 61h
                        call altering_stats

                    proceed_data_analysis:
                        pop bx
                        inc bx
                        pop cx
                loop data_analysis
            loop reading_data

            jmp exit_operating_with_files

            unable_open_file:
                ; printing error message - err_msg2
                mov ah, 09h
                mov dx, offset error_msg2
                int 21h

                ; printing name of the file that caused the error
                mov ah, 40h
                mov bx, 0001h
                mov dx, offset filename
                xor cx, cx
                mov cl, filename_length
                int 21h

                ; printing newline
                mov ah, 40h
                mov bx, 0001h
                mov dx, offset newline
                mov cl, 02h
                int 21h

                ret

            exit_operating_with_files:
                ; closing input file
                mov bx, file_handler
                call close_file

                ret
        operating_with_files endp

  
        cmd_line_args proc  ; procedure reading filenames
            xor cx, cx
            mov cl, es:[80h]                ; needed to know the length of arguments line
            xor bx, bx
            reading_args:
                push cx
                push bx

                mov al, es:[si + bx]

                cmp al, 20h
                jne found_character
                jmp found_space

                found_character:
                    xor cx, cx
                    mov cl, ds:[filename_length]
                    mov bx, cx
                    mov ds:[filename + bx], al
                    inc filename_length

                    pop bx
                    push bx
                    inc bx
                    cmp bl, es:[80h]
                    jne proceed_reading_args

                    call operating_with_files

                    jmp proceed_reading_args

                found_space:
                    xor cx, cx
                    mov cl, ds:[filename_length]
                    cmp cx, 0h
                    je proceed_reading_args

                    call operating_with_files

                    ; resetting values
                    xor cx, cx
                    mov cl, ds:[filename_length]
                    xor bx, bx
                    reset_values:
                        mov ds:[filename_length + bx], 0h
                        inc bx
                    loop reset_values
                    mov ds:[filename_length], 0h

                proceed_reading_args:
                    pop bx
                    inc bx
                    pop cx
            loop reading_args

            ret
        cmd_line_args endp

    end start