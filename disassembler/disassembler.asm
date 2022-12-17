.model small

.stack 100h

.data
    in_file db 255 dup(0)
    in_handle dw 0

    res_file db 255 dup(0)
    res_handle dw 0

    filename_length db 0

    help_msg db "This is disassembly babe", 24h
    err1_msg db "Unable to open/create input/output file(s). Getting input from console.", 24h

.code 
    start:
        mov ax, @data
        mov ds, ax

        ; Checking if there were arguments provided
        xor ax, ax
        mov al, es:[80h]
        cmp al, 0h
        je read_from_console 
        
        ; Chekcing whether help is needed
        xor cx, cx
        mov cx, es:[82h]
        cmp cx, "?/"
        jne reading_args

        mov cl, es:[84h]
        cmp cl, 0dh
        je print_help

        cmp cl, 20h
        je print_help

        ; No help was needed
        reading_args:
            ; Prep for getting input filename
            mov si, 0081h  
            xor cx, cx
            mov cl, es:[80h]

            ; Getting input filename
            mov di, offset in_file
            call get_filename

            ; Opening input file
            mov ax, 3d00h
            mov dx, offset in_file
            int 21h
            jc unable_open_file
            mov in_handle, ax

        proceed_reading_args:
            ; Prep for getting output filename
            add si, bx
            xor cx, cx
            mov cl, es:[80h]
            sub cx, bx
            mov filename_length, 0h

            ; Getting output filename
            mov di, offset res_file
            call get_filename

            ; Creating output file
            mov ax, 3c00h
            xor cx, cx
            mov dx, offset res_file
            int 21h
            jc unable_open_file
            mov res_handle, ax

            jmp terminate_program

        unable_open_file:
            mov ah, 09h
            mov dx, offset err1_msg
            int 21h

        ; Reading from console input
        read_from_console:
            ; code to be inserted here


            jmp terminate_program

        print_help:
            mov ah, 09h
            mov dx, offset help_msg
            int 21h

        terminate_program:
            ; Terminating program 
            mov ax, 4c00h
            int 21h

        get_filename proc
            xor bx, bx
            reading_arg_line:
                push cx
                push bx

                ; Getting next arg line character, cheking whether it is space
                mov al, es:[si + bx]
                cmp al, 20h
                je process_space

                process_character:
                    xor cx, cx
                    mov cl, ds:[filename_length]
                    mov bx, cx
                    mov ds:[di + bx], al
                    inc filename_length

                    jmp proceed_getting_characters

                process_space:
                    ; Checking if filename length is equal to zero
                    ; If it is, proceed reading arg line
                    xor cx, cx
                    mov cl, ds:[filename_length]
                    cmp cx, 0h
                    je proceed_getting_characters

                    ; If it is not, end loop
                    pop bx
                    inc bx
                    pop cx
                    jmp exit_loop

                proceed_getting_characters:
                    pop bx
                    inc bx
                    pop cx
            loop reading_arg_line

            exit_loop:
                ret
        get_filename endp

    end start
