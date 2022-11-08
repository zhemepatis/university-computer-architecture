.model small

.stack 100h

.data
    msg1 db "Enter your message: "
    msg2 db 10, 13, "Encrypted message: "

    in_buff db 255, ?, 255 dup(?)
    out_buff db 255, ?, 255 dup(?)

.code
    start:  
        mov ax, @data
        mov ds, ax

        ; printing msg1
        mov cx, 20
        mov dx, offset msg1
        call print
        
        ; accepting user input
        mov dx, offset in_buff
        mov ah, 0ah
        int 21h
        
        ; preparing for loop
        ; if cx is empty, terminating app
        xor cx, cx 
        mov cl, [in_buff+1]
        jcxz exit

        ; seting bx to 0, needed to know current position
        xor bx, bx

        encrypting:
            ; getting new character to encrypt
            mov al, ds:[in_buff + 2 + bx]

            ; checking whether the character is a letter
            ; if it is, then encrypting it
            cmp al, 41h
            jb proceed

            cmp al, 5ah
            jbe encrypt

            cmp al, 61h
            jb proceed             

            cmp al, 7ah
            ja proceed

            encrypt:
                add al, 2
                
                ; if letter is at the end of alphabet, hopping to to the start of it
                cmp al, 7ah
                ja letter_overflow

                cmp al, 63h
                jae proceed

                cmp al, 5ah
                jbe proceed

            letter_overflow:
                sub al, 26

            proceed:
                mov ds:[out_buff+2+bx], al
                inc bx                
        loop encrypting

        ; printing msg2
        mov cx, 21
        mov dx, offset msg2
        call print

        ; printing encrypted message
        mov cl, [in_buff+1]
        mov dx, offset out_buff+2  
        call print
        
        exit:
            mov ax, 4c00h
            int 21h

        print:
            mov bx, 1
            mov ah, 40h
            int 21h
            ret

    end start

