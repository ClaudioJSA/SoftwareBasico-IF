.equ bufferSize, 20
.equ STDOUT, 1
.equ SYS_write, 1
.equ SYS_open, 2
.equ O_RDONLY, 0
.equ S_MODE, 0700
.equ SYS_close, 3
.equ SYS_read, 0
.equ char_size, 1
.equ O_WDONLY, 1
.equ SYS_creat,85
.section .bss
    .lcomm BUFFER, bufferSize
.section .data
    fNotFound: .string "Erro ao abrir arquivo de entrada.\n"
    notFoundLen: .quad 34
    fNotFound2: .string "Erro ao criar arquivo de saida. Mude o nome ou apague o existente.\n"
    notFoundLen2: .quad 68
    argsInsuf: .string "Quantidade de argumentos insuficientes. (.\\exe quantidade arquivoDeEntrada arquivoDeSaida) Total: 4\n"
    argsInsufLen: .quad 100
    qtdInv: .string "Quantidade de elementos contidos no arquivo passado por parametro e inválida.\n"
    qtdInvLen: .quad 79
    newLine: .string "\n"
    newLineLen: .quad 1
    separador: .byte 10
.section .text
.globl main

#Exibe mensagem de quantidade de argumentos insuficientes
argsInsuficientes:
   pushq %rbp
   movq %rsp, %rbp
   movq $SYS_write, %rax
   movq $STDOUT, %rdi
   movq $argsInsuf, %rsi
   movq argsInsufLen, %rdx
   syscall
   popq %rbp
   ret

#Exibe mensagem de numero de elementos passados no parametro invalido
qtd_invalida:
   pushq %rbp
   movq %rsp, %rbp
   movq $SYS_write, %rax
   movq $STDOUT, %rdi
   movq $qtdInv, %rsi
   movq qtdInvLen, %rdx
   syscall
   popq %rbp
   ret

#Exibe mensagem de arquivo não encontrado
file_not_found:
   pushq %rbp
   movq %rsp, %rbp
   movq $SYS_write, %rax
   movq $STDOUT, %rdi
   movq $fNotFound, %rsi
   movq notFoundLen, %rdx
   syscall
   popq %rbp
   ret

#Exibe mensagem de arquivo de saida já existente
file_not_found2:
   pushq %rbp
   movq %rsp, %rbp
   movq $SYS_write, %rax
   movq $STDOUT, %rdi
   movq $fNotFound2, %rsi
   movq notFoundLen2, %rdx
   syscall
   popq %rbp
   ret

f_fileSize:
#Retorna a quantidade de numeros no arquivo passado por argumento
    pushq %rbp
    movq %rsp, %rbp
    movq $-1, %rax                               #Retorna -1 se o argumento do tamanho do arquivo for inválido
    pushq %rbx
    #if:
        cmpb $45, (%rdi)                         #compara se o numero é negativo
        je endConvertNumber
        movq %rdi, %rbx
        while_fs:                                #Verifica se o valor digitado é um numero
            cmpb $0, (%rbx)
            je end_whilefs
            cmpb $48, (%rbx)                     #compara se o digito é um numero dentro do intervalo de 0 a 9
            jl endConvertNumber
            cmpb $57, (%rbx)                     #compara se o digito é um numero dentro do intervalo de 0 a 9
            jg endConvertNumber
            incq %rbx
            jmp while_fs
        end_whilefs:
        call f_converterCadeiaCaracteresLongLong
    endConvertNumber:
    cmpq $-1, %rax
    jne endfs
    pushq %rax
    call qtd_invalida
    popq %rax
    endfs:
    popq %rbx
    pop %rbp
    ret

#Converte caractere para longLongInt (%rdi recebe o endereço da string)
f_converterCadeiaCaracteresLongLong:
   pushq %rbp
   movq %rsp, %rbp
   subq $16, %rsp                  #-8(%rbp)=valorNegativo
   movq $1, -8(%rbp)               #inicia em 1
   movq $10, -16(%rbp)
   pushq %rbx
   movq %rdi, %rbx
   #if:
       cmpb $45, (%rdi)            #se a string a ser convertida for negativa valorNegativo recebe -1
       jne end_if
       movq $-1, -8(%rbp)
       incq %rbx
   end_if:
   movq $0, %rax
   while:
       cmpb $0, (%rbx)
       je end_while
       mulq -16(%rbp)
       movzbq (%rbx), %rdx
       subq $48, %rdx
       addq %rdx, %rax
       incq %rbx
       jmp while
   end_while:
   popq %rbx
   imulq -8(%rbp)                  #multiplica o numero convertido por valorNegativo
   addq $16, %rsp
   popq %rbp
   ret

#Le uma cadeia de caracteres de um arquivo (%rdi recebe o descritor do arquivo, %rsi recebe o buffer)
f_lerCadeiaCaracteres:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    movq %rsi, %rbx
    while_nEOL:
        movq $SYS_read, %rax
        movq $char_size, %rdx
        movq %rbx, %rsi
        syscall
        cmpq $0, %rax                           #verifica se chegou ao fim do arquivo
        je end_while_nEOL
        cmpb $10, (%rbx)                       #verifica se chegou ao final de uma linha
        je end_while_nEOL
        incq %rbx
        jmp while_nEOL
    end_while_nEOL:
    movb $0, (%rbx)
    popq %rbx
    popq %rbp
    ret

#Ler os numeros do arquivo e passa para o vetor(%rdi recebe o descritor do arquivo, %rsi recebe o vetor, %rdx recebe a quantidade de numeros)
f_lerNumerosParaVetor:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    movq $0, %rbx
    while_EF:
        pushq %rsi
        pushq %rdi
        pushq %rdx
        movq $BUFFER, %rsi
        call f_lerCadeiaCaracteres
        popq %rdx
        popq %rdi
        popq %rsi
        cmpq $0, %rax                           #verifica se chegou ao fim do arquivo
        je end_while_EF
        cmpq %rbx, %rdx                         #verifica se leu todos os numeros
        jle end_while_EF
        pushq %rdi
        pushq %rdx
        movq $BUFFER, %rdi
        call f_converterCadeiaCaracteresLongLong
        popq %rdx
        popq %rdi
        movq %rax, (%rsi)
        subq $8, %rsi
        incq %rbx
        jmp while_EF
    end_while_EF:
    popq %rbx
    popq %rbp
    ret

#Retorna em %rax o tamanho de uma string passada em %rdi
str_size:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    movq %rdi, %rbx
    movq $0, %rax
    while4:
        cmpb $0, (%rbx)
        je end_while4
        incq %rbx
        incq %rax
        jmp while4
    end_while4:
    popq %rbx
    popq %rbp
    ret

#Grava uma cadeia de caracteres no arquivo (%rdi = descritor do arquvo \\ %rsi = BUFFER)
f_gravarCadeiaDeCaracteres:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rdi
    movq %rsi, %rdi
    call str_size
    popq %rdi
    movq %rax, %rdx
    movb $10, (%rsi,%rax,1)
    movq $SYS_write, %rax
    syscall
    popq %rbp
    ret

#Pula uma linha no arquivo (%rdi = descritor do arquvo)
pular_linha:
    pushq %rbp
    movq %rsp, %rbp
    movq $SYS_write, %rax
    movq $newLine, %rsi
    movq newLineLen, %rdx
    syscall
    popq %rbp
    ret

#Grava os numeros do vetor no arquivo (%rdi recebe o descritor do arquivo, %rsi o vetor, %rdx o tamanho)
f_gravarNumerosParaArquivo:
    pushq %rbp
    movq %rsp, %rbp
    movq $0, %r8
    while5:
        cmpq %r8, %rdx
        je end_while5
        pushq %rdi
        pushq %rsi
        pushq %rdx
        pushq %r8
        movq (%rsi,%r8,8), %rdi
        movq $BUFFER, %rsi
        call f_converterLongLongCadeiaCaracteres
        popq %r8
        popq %rdx
        popq %rsi
        popq %rdi
        pushq %rsi
        pushq %rdx
        movq $BUFFER, %rsi
        call f_gravarCadeiaDeCaracteres
        popq %rdx
        popq %rsi
        pushq %rsi
        pushq %rdx
        call pular_linha
        popq %rdx
        popq %rsi
        incq %r8
        jmp while5
    end_while5:
    popq %rbp
    ret

#Converte um numero para uma cadeia decaractes e salva em um buffer
f_converterLongLongCadeiaCaracteres:                #%rdi = numero \\ %rsi = BUFFER
    pushq %rbp
    movq %rsp, %rbp
    movq $0, %r8        #negativo
    movq $0, %r9        #tamanho
    movq $10, %r10      #base
    #ifci1:
        cmpq $0, %rdi
        jne end_ifci1
        movb $48, (%rsi,%r9,1)
        incq %r9
        movb $0, (%rsi,%r9,1)
        jmp endwhileci2
    end_ifci1:
    #ifci2:
        cmpq $0, %rdi
        jg endifci2
        movq $1, %r8
        imulq $-1, %rdi
    endifci2:
    whileci1:
        cmpq $0, %rdi
        jle endwhileci1
        movq %rdi, %rax
        movq $0, %rdx
        idivq %r10
        movq %rax, %rdi
        addb $48, %dl
        movb %dl, (%rsi,%r9,1)
        incq %r9
        jmp whileci1
    endwhileci1:
    #ifci3:
        cmpq $1, %r8
        jne endifci3
        movb $45, (%rsi,%r9,1)
        incq %r9
    endifci3:
    movb $0, (%rsi,%r9,1)

    #Inverte a string
    movq $0, %r11       #i
    movq %r9, %r12      #j
    decq %r12
    whileci2:
        cmpq %r11, %r12
        jle endwhileci2
        movb (%rsi,%r11,1), %al
        movb (%rsi,%r12,1), %bl
        movb %bl, (%rsi,%r11,1)
        movb %al, (%rsi,%r12,1)
        incq %r11
        decq %r12
        jmp whileci2
    endwhileci2:
    popq %rbp
    ret

#Ordena o arquivo lido(%rdi recebe o vetor, %rsi recebe o left, %rdx recebe right)
quick_sort:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp                          #-8(%rbp) = left = i // -16(%rbp) = right = j // -24(%rbp) = x = a[(left + right) / 2] // 
    movq %rsi, -8(%rbp)     #i
    movq %rdx, -16(%rbp)    #j
    movq %rsi, -8(%rbp)     #i
    movq %rdx, -16(%rbp) 
    movq -8(%rbp), %rax
    addq -16(%rbp), %rax
    movq $2, %rbx
    pushq %rdx
    movq $0, %rdx
    idivq %rbx
    popq %rdx
    movq (%rdi,%rax,8), %rbx
    movq %rbx, -24(%rbp)  #x
    whileqs:
        movq -8(%rbp), %rbx
        cmpq -16(%rbp), %rbx
        jg endwhileqs
        whileqs2:
            movq -8(%rbp), %rbx
            movq (%rdi,%rbx,8), %rax
            cmpq -24(%rbp), %rax
            jge endwhileqs2
            cmpq -8(%rbp), %rdx
            jle endwhileqs2
            incq -8(%rbp)
            jmp whileqs2
        endwhileqs2:
        whileqs3:
            movq -16(%rbp), %rbx
            movq (%rdi,%rbx,8), %rax
            cmpq -24(%rbp), %rax
            jle endwhileqs3
            cmpq -16(%rbp), %rsi
            jge endwhileqs3
            decq -16(%rbp)
            jmp whileqs3
        endwhileqs3:
        #ifqs:
            movq -8(%rbp), %rbx
            cmpq -16(%rbp), %rbx
            jg endifqs
            movq (%rdi,%rbx,8), %rcx
            movq %rcx, -32(%rbp)
            movq -16(%rbp), %rcx
            movq (%rdi,%rcx,8), %rax
            movq %rax, (%rdi,%rbx,8)
            movq -32(%rbp), %rax
            movq %rax, (%rdi,%rcx,8)
            incq -8(%rbp)
            decq -16(%rbp)
        endifqs:
        jmp whileqs
    endwhileqs:
    ifqs2:
        cmpq -16(%rbp), %rsi
        jge endifqs2
        pushq %rsi
        pushq %rdx
        movq -16(%rbp), %rdx
        call quick_sort
        popq %rdx
        popq %rsi
    endifqs2:
    ifqs3:
        cmpq -8(%rbp), %rdx
        jle endifqs3
        pushq %rsi
        pushq %rdx
        movq -8(%rbp), %rsi
        call quick_sort
        popq %rdx
        popq %rsi
    endifqs3:
    addq $32, %rsp
    popq %rbp
    ret     

main:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp                                          #-8(%rbp) = quantidade de numeros na memoria \\ -16(%rbp) = descritor do arquivo \\ -24(%rbp) = argv

    movq %rsi, -24(%rbp)                                    #Salva argv na memoria

    #Verifica se a quantidade de argumentos é valida
    cmpq $4, %rdi                  
    jne not_valid

    #Converte o tamanho passado por argumento para int
    movq -24(%rbp), %rdi
    addq $8, %rdi
    movq (%rdi), %rdi
    call f_fileSize
    cmpq $-1, %rax
    je end
    movq %rax, -8(%rbp)                                     #Salva a quantidade na memoria     
    
    #Abre o arquivo de entrada de valores
    movq -24(%rbp), %rdi
    addq $16, %rdi
    movq (%rdi), %rdi
    movq $SYS_open, %rax
    movq $O_RDONLY, %rsi  
    movq $S_MODE, %rdx
    syscall
    cmpq $0, %rax                                           #Verifica se o arquivo foi aberto corretamente
    jl not_found
    movq %rax, -16(%rbp)                                    #Salva o descritor do arquivo

    #Aloca o espaço para guardar os valores na memoria
    movq -8(%rbp), %rax                         
    imulq $8, %rax
    subq %rax, %rsp

    #Lê os valores do arquivo e salva no vetor
    movq -16(%rbp), %rdi
    movq %rbp, %rsi
    subq $32, %rsi
    movq -8(%rbp), %rdx
    call f_lerNumerosParaVetor
    
    #Fecha o arquivoDeEntrada
    movq $SYS_close, %rax
    movq -16(%rbp), %rdi
    syscall

    #Ordena o vetor de numeros
    movq %rsp, %rdi
    movq $0, %rsi
    movq -8(%rbp), %rdx
    decq %rdx
    call quick_sort
    movq -40(%rbp), %rbx

    #Abre o arquivo de saida de valores
    movq -24(%rbp), %rdi
    addq $24, %rdi
    movq (%rdi), %rdi
    movq $SYS_creat, %rax
    movq $O_WDONLY, %rsi
    movq $S_MODE, %rdx
    syscall
    cmpq $0, %rax                                           #Verifica se o arquivo foi aberto corretamente
    jl not_found2
    movq %rax, -16(%rbp)                                    #Salva o descritor do arquivo

    #Grava os numeros no arquivo de saida
    movq -16(%rbp), %rdi
    movq %rsp, %rsi
    movq -8(%rbp), %rdx
    call f_gravarNumerosParaArquivo

    #Fecha o arquivoDeSaida
    movq $SYS_close, %rax
    movq -16(%rbp), %rdi
    syscall

    jmp desalocar_vetor

    not_found:
    call file_not_found
    jmp end

    not_found2:
    call file_not_found2
    jmp desalocar_vetor

    #Exibe a mensagem de quantidade de argumentos invalidos
    not_valid:
    call argsInsuficientes
    jmp end

    #Desaloca o vetor de longlong
    desalocar_vetor:
    movq -8(%rbp), %rax
    imulq $8, %rax
    addq %rax, %rsp

    end:
    addq $24, %rsp
    popq %rbp
    movq %rbx, %rdi
    movq $60, %rax
    syscall
