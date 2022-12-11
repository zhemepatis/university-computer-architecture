.model small

.stack 100h

.data
    buff db 200h dup(?)

    filename db 255 dup(0)
    filename_length db 0
    file_handle dw 0

    stats_file db "stats.txt", 0
    stats_handle dw 0
    
    quantity_marker db 23h
    empty_marker db 2eh
    empty_line db 1ah dup(2eh), 0dh, 0ah
    full_line db 1ah dup(23h), 0dh, 0ah
    stats_buff db 1ah dup(?), 0dh, 0ah

    newline db 13, 10
    error_msg1 db "No arguments were provided.", 24h
    error_msg2 db "Unable open the file named ", 24h
    help_msg db "This program accepts filenames as arguments and counts the frequency of letters in the files. The results are presented as an ASCII character graph in the 'stats.txt' file.", 24h

.code
    start:
        mov ax, @data
        mov ds, ax
    
        ; checking if there were arguments provided, if no, program is terminated
        xor cx, cx
        mov cl, es:[80h]
        cmp cl, 0h
        mov dx, offset error_msg1
        je print_error

        ; creating "stats.txt" file
        mov ax, 3c00h
        xor cx, cx
        mov dx, offset stats_file
        int 21h
        mov stats_handle, ax

        ; initialising "stats.txt"
        mov dx, offset full_line
        call print_line
        call return_to_start
        
        call cmd_line_args

        jmp terminate_program

        print_error:
            mov ah, 09h
            int 21h
            jmp terminate_program

        print_help:
            mov ah, 09h
            mov dx, offset help_msg
            int 21h

        terminate_program:
            ; closing "stats.txt"
            mov bx, file_handle
            call close_file

            ; terminating the application
            mov ax, 4c00h
            int 21h

        close_file:
            mov ax, 3e00h
            int 21h
            ret

        ; PROCEDURES
        cmd_line_args proc  ; procedure that checks arguments
            ; checking if help is needed
            mov cx, es:[82h]
            
            cmp cx, "?/"
            jne read_args

            mov cl, es:[84h]
            cmp cl, 0dh
            je print_help

            cmp cl, 20h
            je print_help
            
            ; no help was needed
            read_args:
                mov si, 0081h  
                xor cx, cx
                mov cl, es:[80h]

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

        operating_with_files proc     ; open file and read data
            ; opening input file
            mov ax, 3d00h
            mov dx, offset filename
            int 21h
            jc unable_open_file
            mov file_handle, ax

            mov dx, offset buff
            reading_data:
                ; reading data from input file
                mov ax, 3f00h
                mov cx, 200h
                mov bx, file_handle
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

            mov bx, file_handle
            call close_file

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

            exit_operating_with_files:
                ret
        operating_with_files endp

        altering_stats proc
            push ax  

            reading_stats:
                call read_line

                pop bx
                mov al, [quantity_marker]
                cmp [stats_buff + bx], al
                push bx
                jne reading_stats
                
                mov al, [empty_marker]
                mov [stats_buff + bx], al
                call set_back
                mov dx, offset stats_buff
                call print_line
                
                new_status:
                    call read_line
                    mov cx, ax
                    jcxz new_highscore

                    call set_back
                    pop bx
                    mov al, [quantity_marker]
                    mov [stats_buff + bx], al
                    mov dx, offset stats_buff
                    call print_line

                    jmp end_loop

                new_highscore:              
                    mov dx, offset empty_line
                    call print_line
                    call set_back
                
                    jmp new_status

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
                mov bx, stats_handle
                int 21h
                ret

            print_line:
                mov ax, 4000h
                mov bx, stats_handle
                mov cx, 1ch
                int 21h
                ret
            
            return_to_start:
                mov ax, 4200h
                mov bx, stats_handle
                xor cx, cx
                xor dx, dx
                int 21h
                ret

            set_back:
                mov ax, 4201h
                mov bx, stats_handle
                mov cx, -1h
                mov dx, -1ch
                int 21h
                ret

        altering_stats endp

    end start