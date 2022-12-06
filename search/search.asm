; 22 užduotis
; Parašykite programą, kurios parametrai - failų vardai. 
; Programa skaito kiekvieną iš nurodytų failų ir surenka kiekvienos abėcėlės raidės pasikartojimo statistiką. 
; Programa sukuria rezultatų failą, kuriame ASCII simbolių pagalba grafiškai pavaizduoja abėcėlės raidžių išsibarstymą: 
;   abscisių ašyje - visos abėcėlės raidės, ordinačių ašyje - pasikartojimų kiekis. 
; Taip tarsi gaunamas abėcėlės raidžių pasiskirstymo nagrinėjamuose failuose grafikas.

.model small

.stack 100h

.data
    input_file db "input.txt", 0
    input_fh dw 0 
    res_file db "stats.txt", 0
    res_fh dw 0

    buff db 200h dup(?)
    
    stats_buff db 1ah dup(?), 0dh, 0ah
    stats_init db 1ah dup(30h), 0dh, 0ah
    newline db 0dh, 0ah

    test_stats db 1ah dup(31h), 0dh, 0ah

    huh db "huh?$"

.code 
    start: 
        mov ax, @data
        mov ds, ax

        ; opening file "input.txt"
        mov ax, 3d00h
        mov dx, offset input_file
        int 21h
        mov input_fh, ax

        ; creating & initialising stats file
        mov ax, 3c00h
        xor cx, cx
        mov dx, offset res_file
        int 21h
        mov res_fh, ax

        mov dx, offset stats_init
        call print_line
        call return_to_start

        push 10h
        altering_stats:
            call read_line
            mov cx, ax
            jcxz new_letter

            pop bx
            cmp [stats_buff + bx], 31h
            push bx
            jne altering_stats
            
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
                jmp exit_altering_stats
        loop altering_stats

        exit_altering_stats:

        exit:
            mov bx, input_fh
            call close_file

            mov bx, res_fh
            call close_file

            mov ax, 4c00h
            int 21h 

        close_file:
            mov ax, 3e00h
            int 21h
            ret

        read_line:
            mov dx, offset stats_buff
            mov ax, 3f00h
            mov cx, 1ch
            mov bx, res_fh
            int 21h
            ret

        print_line:
            mov ax, 4000h
            mov bx, res_fh
            mov cx, 1ch
            int 21h
            ret
        
        return_to_start:
            mov ax, 4200h
            mov bx, res_fh
            xor cx, cx
            xor dx, dx
            int 21h
            ret

        set_back:
            mov ax, 4201h
            mov bx, res_fh
            mov cx, -1h
            mov dx, -1ch
            int 21h
            ret

        print_huh:
            mov dx, offset huh
            mov ah, 09h
            int 21h
            ret

    end start