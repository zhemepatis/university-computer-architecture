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

        ; prints msg1
        mov cx, 20
        mov dx, offset msg1
        call print
        
        ; accepts user input
        mov dx, offset in_buff
        mov ah, 0ah
        int 21h

        xor cx, cx  ; makes cx equal to 0
        mov cl, [in_buff+1] ; moves input length into cl
        jcxz exit   ; if input was empty, then application stops

        xor bx, bx  ; makes bx equal to 0

        encrypting:
            ; getting new character to encrypt
            mov al, ds:[in_buff + 2 + bx]

            ;  checking whether the character is letter. If it is, then encrypting it.
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

        ; prints msg2
        mov cx, 21
        mov dx, offset msg2
        call print

        ; prints encrypted message
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

