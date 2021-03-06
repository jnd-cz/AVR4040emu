;====================  REGISTER USAGE  ====================

    ; R0:   .R0R1
    ; R1:   .R2R3
    ; R2:   .R4R5
    ; R3:   .R6R7
    ; R4:   .R8R9
    ; R5:   .RaRb
    ; R6:   .RcRd
    ; R7:   .ReRf
    ; R8:   .R10R11
    ; R9:   .R12R13
    ;R10:   .R14R15
    ;R11:   .R16R17
    ;R12:   .0
    ;R13:   .SRC
    ;R14:   .DCL
    ;R15:   .Command register

    ;R16:   .OPROPA Instruction decoding
    ;R17:    Math result
    ;R18:    Working/temp
    ;R19:    Working/temp
    ;R20:    ACC
    ;R21:    STATUS
    ;R22:   ?
    ;R23:   ?
    ;R24:   ?Temp pointer
    ;R25:   ?Temp pointer
    ;R26:   .Stack pointer (XL)
    ;R27:   .Stack pointer (XH)
    ;R28:   .Indirect pointer (YL)
    ;R29:   .Indirect pointer (YH)
    ;R30:   .Program counter LPM/SPM (ZL)
    ;R31:   .Program counter LPM/SPM (ZH)

init:
    ; clear registers
    
    ; set pointers
    ldi ZH, high(data4040start << 1)
    ldi ZL, low(data4040start << 1)
    ; 
    clt
    
instructiondecode:
    ; load next instruction
    ld r24, ZL  ; store to check page boundary
    lpm r16, Z+
    ; convert hex to bin?
    ;rcall intelhextobin

    ;decode tree start
    sbrc r16, 7
    ;1xxx decoded
    rjmp decodetree1xxx
    ;0xxx skipped
    sbrc r16, 6
    ;01xx
    rjmp decodetree01xx
    ;00xx
    sbrc r16, 5
    ;001x
    rjmp decodetree001x
    ;000x
    sbrc r16, 4
    ;0001
    rjmp decodetree0001
    ;0000
decodetree0000:
    ; MISC instructions
    sbrc r16, 3
    ;00001xxx
    rjmp decodetree00001xxx
    ;00000xxx
    sbrc r16, 2
    ;000001xx
    rjmp decodetree000001xx
    ;000000xx
    sbrc r16, 1
    ;0000001x
    rjmp decodetree0000001x
    ;0000000x
    sbrc r16, 0
    ;00000001
    rjmp decodetree00000001
    ;00000000

decodetree00000000:
    ; NOP
    nop
    rjmp decodetreeend
decodetree00000001:
    ; HLT
    ; TODO: set HALT and STOP flipflops and corresponding I/O
    sleep
    rjmp decodetreeend
decodetree0000001x:
    ;0000001x
    sbrc r16, 0
    ;00000011
    rjmp decodetree00000011
    ;00000010
decodetree00000010:
    ; BBS
    ; decrement stack pointer
    
    ; restore program counter
    
    ; restore SRC
    ; turn off INTA line
    
    ; restore index register bank (T flag)
    
    rjmp decodetreeend
decodetree00000011:
    ; LCR
    ; transfer command register contents to the accumulator
    mov r20, r15
    rjmp decodetreeend
decodetree000001xx:
    ;000001xx
    sbrc r16, 1
    ;0000011x
    rjmp decodetree0000011x
    ;0000010x
    sbrc r16, 0
    ;00000101
    rjmp decodetree00000101
    ;00000100
decodetree00000100:
    ; OR4
    ; logical or between R4 and ACC
    ; extract R4 from 8-bits
    mov r18, r2
    swap r18
    andi r18, 0x0F
    or r20, r18
    rjmp decodetreeend
decodetree00000101:
    ; OR5
    ; logical or between R5 and ACC
    ; extract R5 from 8-bits
    mov r18, r2
    andi r18, 0x0F
    or r20, r18
    rjmp decodetreeend
decodetree0000011x:
    ;0000011x
    sbrc r16, 0
    ;00000111
    rjmp decodetree00000111
    ;00000110
decodetree00000110:
    ; AN6
    ; logical and between R6 and ACC
    ; extract R6 from 8-bits
    mov r18, r3
    swap r18
    andi r18, 0x0F
    and r20, r18
    rjmp decodetreeend
decodetree00000111:
    ; AN7
    ; logical and between R7 and ACC
    ; extract R7 from 8-bits
    mov r18, r3
    andi r18, 0x0F
    and r20, r18
    rjmp decodetreeend
decodetree00001xxx:
    ;00001xxx
    sbrc r16, 2
    ;000011xx
    rjmp decodetree000011xx
    ;000010xx
    sbrc r16, 1
    ;0000101x
    rjmp decodetree0000101x
    ;0000100x
    sbrc r16, 0
    ;00001001
    rjmp decodetree00001001
    ;00001000
decodetree00001000:
    ; DB0
    ; select CM-ROM0, the first ROM bank, 0x1000-0x1FFF
    andi ZH, 0x1F
    ori ZH, 0x10
    rjmp decodetreeend
decodetree00001001:
    ; DB1
    ; select CM-ROM1, the second ROM bank, 0x2000-0x2FFF
    andi ZH, 0x2F
    ori ZH, 0x20
    rjmp decodetreeend
decodetree0000101x:
    ;0000101x
    sbrc r16, 0
    ;00001011
    rjmp decodetree00001011
    ;00001010
decodetree00001010:
    ; SB0
    ; use T flag, select register bank 0, use R0-R7, R8-Rf
    ; if bank 0 was set already, skip
    brtc decodetree00001010skip
    ; else switch bank registers and clear T flag
    movw r19:r18, r1:r0     ;16-bits = 4x4-bit registers at a time
    movw r1:r0, r9:r8
    movw r9:r8, r19:r19
    movw r19:r18, r3:r2
    movw r3:r2, r11:r10
    movw r11:r10, r19:r19
    clt
decodetree00001010skip:    
    rjmp decodetreeend
decodetree00001011:
    ; SB1
    ; use T flag, select register bank 1, use R10-R17, R8-Rf
    ; if bank 1 was set already, skip
    brts decodetree00001011end
    ; else switch bank registers and set T flag
    movw r19:r18, r1:r0     ;16-bits = 4x4-bit registers at a time
    movw r1:r0, r9:r8
    movw r9:r8, r19:r19
    movw r19:r18, r3:r2
    movw r3:r2, r11:r10
    movw r11:r10, r19:r19
    set
decodetree00001011end:
    rjmp decodetreeend
decodetree000011xx:
    ;000011xx
    sbrc r16, 1
    ;0000111x
    rjmp decodetree0000111x
    ;0000110x
    sbrc r16, 0
    ;00001101
    rjmp decodetree00001101
    ;00001100
decodetree00001100:
    ; EIN
    ; enable interrupt, set IE bit
    
    rjmp decodetreeend
decodetree00001101:
    ; DIN
    ; disable interrupt, clear IE bit
    
    rjmp decodetreeend
decodetree0000111x:
    ;0000111x
    sbrc r16, 0
    ;00001111
    rjmp decodetree00001111
    ;00001110
decodetree00001110:
    ; RPM
    
    rjmp decodetreeend
decodetree00001111:
    ; UNDEFINED
    nop
    rjmp decodetreeend

decodetree0001:
    ; JUMP conditional, page shift!
    sbrc r16, 3
    ;00011xxx
    rjmp decodetree00011xxx
    ;00010xxx
    sbrc r16, 2
    ;000101xx
    rjmp decodetree000101xx
    ;000100xx
    sbrc r16, 1
    ;0001001x
    rjmp decodetree0001001x
    ;0001000x
    sbrc r16, 0
    ;00010001
    rjmp decodetree00010001
    ;00010000

decodetree00010000:
    ; JCN 0, jump never, no operation
    nop
    rjmp decodetreeend
decodetree00010001:
    ; JNT, jump is test = 0 (Vss)
    
    rjmp decodetreeend
decodetree0001001x:
    ;0001001x
    sbrc r16, 0
    ;00010011
    rjmp decodetree00010011
    ;00010010
decodetree00010010:
    ; JC, jump if carry = 1
    
    rjmp decodetreeend
decodetree00010011:
    ; JCN 3
    
    rjmp decodetreeend
decodetree000101xx:
    ;000101xx
    sbrc r16, 1
    ;0001011x
    rjmp decodetree0001011x
    ;0001010x
    sbrc r16, 0
    ;00010101
    rjmp decodetree00010101
    ;00010100
decodetree00010100:
    ; JZ, jump if accumulator = 0
    
    rjmp decodetreeend
decodetree00010101:
    ; JCN 5
    
    rjmp decodetreeend
decodetree0001011x:
    ;0001011x
    sbrc r16, 0
    ;00010111
    rjmp decodetree00010111
    ;00010110
decodetree00010110:
    ; JCN 6
    
    rjmp decodetreeend
decodetree00010111:
    ; JCN 7
    
    rjmp decodetreeend
decodetree00011xxx:
    ;00011xxx
    sbrc r16, 2
    ;000111xx
    rjmp decodetree000111xx
    ;000110xx
    sbrc r16, 1
    ;0001101x
    rjmp decodetree0001101x
    ;0001100x
    sbrc r16, 0
    ;00011001
    rjmp decodetree00011001
    ;00011000
decodetree00011000:
    ; JCN 8, jump always
    
    rjmp decodetreeend
decodetree00011001:
    ; JT, jump if test = 1 (Vdd)
    
    rjmp decodetreeend
decodetree0001101x:
    ;0001101x
    sbrc r16, 0
    ;00011011
    rjmp decodetree00011011
    ;00011010
decodetree00011010:
    ; JNC, jump is carry = 0
    
    rjmp decodetreeend
decodetree00011011:
    ; JCN 11
    
    rjmp decodetreeend
decodetree000111xx:
    ;000111xx
    sbrc r16, 1
    ;0001111x
    rjmp decodetree0001111x
    ;0001110x
    sbrc r16, 0
    ;00011101
    rjmp decodetree00011101
    ;00011100
decodetree00011100:
    ; JNZ, jump if accumulator != 0
    
    rjmp decodetreeend
decodetree00011101:
    ; JCN 13
    
    rjmp decodetreeend
decodetree0001111x:
    ;0001111x
    sbrc r16, 0
    ;00011111
    rjmp decodetree00011111
    ;00011110
decodetree00011110:
    ; JCN 14
    
    rjmp decodetreeend
decodetree00011111:
    ; JCN 15
    
    rjmp decodetreeend

decodetree001x:
    sbrc r16, 4
    ;0011
    rjmp decodetree0011
    ;0010

decodetree0010:
    ; FIM(0)/SRC(1) 
    ;0010xxxx
    sbrc r16, 0
    ;0010xxx1
    rjmp decodetree0010xxx1
    ;0010xxx0

decodetree0010xxx0:
    ; FIM
    ; fetch immediate data to selected register pair
    lsr r16
    andi r16, 0x07
    mov YL, r16
    ldi YH, 0
    lpm r16, Z+
    st Y, r16
    rjmp decodetreeend
decodetree0010xxx1:
    ; SRC
    ; move data from register pair into SRC register
    lsr r16
    andi r16, 0x07
    mov YL, r16
    ldi YH, 0
    ld r13, Y
    rjmp decodetreeend

decodetree0011:
    ; FIN(0)/JIN(1), page shift!
    ;0011xxxx
    sbrc r16, 0
    ;0011xxx1
    rjmp decodetree0011xxx1
    ;0011xxx0

decodetree0011xxx0:
    ; FIN
    
    rjmp decodetreeend
decodetree0011xxx1:
    ; JIN
    
    rjmp decodetreeend

decodetree01xx:
    sbrc r16, 5
    ;011x
    rjmp decodetree011x
    ;010x
    sbrc r16, 4
    ;0101
    rjmp decodetree0101
    ;0100
decodetree0100:
    ; JUN
    ; 4-bit MSB, load to program counter high byte
    andi r16, 0x0F
    andi ZH, 0xF0
    or ZH, r16
    ; load program counter low byte from following instruction byte
    lpm Z+, r16
    mov ZL, r16
    rjmp decodetreeend

decodetree0101:
    ; JMS
    ; push program counter on stack
    ; load program counter like with JUN
    rjmp decodetreeend

decodetree011x:
    sbrc r16, 4
    ;0111
    rjmp decodetree0111
    ;0110
decodetree0110:
    ; INC

    rjmp decodetreeend

decodetree0111:
    ; ISZ, page shift!

    rjmp decodetreeend

decodetree1xxx:
    sbrc r16, 6
    ;11xx
    rjmp decodetree11xx
    ;10xx
    sbrc r16, 5
    ;101x
    rjmp decodetree101x
    ;100x
    sbrc r16, 4
    ;1001
    rjmp decodetree1001
    ;1000
decodetree1000:
    ; ADD

    rjmp decodetreeend

decodetree1001:
    ; SUB

    rjmp decodetreeend

decodetree101x:
    sbrc r16, 4
    ;1011
    rjmp decodetree1011
    ;1010
decodetree1010:
    ; LD

    rjmp decodetreeend

decodetree1011:
    ; XCH

    rjmp decodetreeend

decodetree11xx:
    sbrc r16, 5
    ;111x
    rjmp decodetree111x
    ;110x
    sbrc r16, 4
    ;1101
    rjmp decodetree1101
    ;1100
decodetree1100:
    ; BBL

    rjmp decodetreeend

decodetree1101:
    ; LDM
    andi r16, 0x0F
    mov r20, r16
    rjmp decodetreeend

decodetree111x:
    sbrc r16, 4
    ;1111
    rjmp decodetree1111
    ;1110
decodetree1110:
    ; MISC
    sbrc r16, 3
    ;11101xxx
    rjmp decodetree11101xxx
    ;11100xxx
    sbrc r16, 2
    ;111001xx
    rjmp decodetree111001xx
    ;111000xx
    sbrc r16, 1
    ;1110001x
    rjmp decodetree1110001x
    ;1110000x
    sbrc r16, 0
    ;11100001
    rjmp decodetree11100001
    ;11100000

decodetree11100000:
    ; WRM
    
    rjmp decodetreeend
decodetree11100001:
    ; WMP
    
    rjmp decodetreeend
decodetree1110001x:
    ;1110001x
    sbrc r16, 0
    ;11100011
    rjmp decodetree11100011
    ;11100010
decodetree11100010:
    ; WRR
    
    rjmp decodetreeend
decodetree11100011:
    ; WPM
    
    rjmp decodetreeend
decodetree111001xx:
    ;111001xx
    sbrc r16, 1
    ;1110011x
    rjmp decodetree1110011x
    ;1110010x
    sbrc r16, 0
    ;11100101
    rjmp decodetree11100101
    ;11100100
decodetree11100100:
    ; WR0
    
    rjmp decodetreeend
decodetree11100101:
    ; WR1
    
    rjmp decodetreeend
decodetree1110011x:
    ;1110011x
    sbrc r16, 0
    ;11100111
    rjmp decodetree11100111
    ;11100110
decodetree11100110:
    ; WR2
    
    rjmp decodetreeend
decodetree11100111:
    ; WR3
    
    rjmp decodetreeend
decodetree11101xxx:
    ;11101xxx
    sbrc r16, 2
    ;111011xx
    rjmp decodetree111011xx
    ;111010xx
    sbrc r16, 1
    ;1110101x
    rjmp decodetree1110101x
    ;1110100x
    sbrc r16, 0
    ;11101001
    rjmp decodetree11101001
    ;11101000
decodetree11101000:
    ; SBM
    
    rjmp decodetreeend
decodetree11101001:
    ; RDM
    
    rjmp decodetreeend
decodetree1110101x:
    ;1110101x
    sbrc r16, 0
    ;11101011
    rjmp decodetree11101011
    ;11101010
decodetree11101010:
    ; RDR
    
    rjmp decodetreeend
decodetree11101011:
    ; ADM
    
    rjmp decodetreeend
decodetree111011xx:
    ;111011xx
    sbrc r16, 1
    ;1110111x
    rjmp decodetree1110111x
    ;1110110x
    sbrc r16, 0
    ;11101101
    rjmp decodetree11101101
    ;11101100
decodetree11101100:
    ; RD0
    
    rjmp decodetreeend
decodetree11101101:
    ; RD1
    
    rjmp decodetreeend
decodetree1110111x:
    ;1110111x
    sbrc r16, 0
    ;11101111
    rjmp decodetree11101111
    ;11101110
decodetree11101110:
    ; RD2
    
    rjmp decodetreeend
decodetree11101111:
    ; RD3
    
    rjmp decodetreeend

decodetree1111:
    ; MISC
    sbrc r16, 3
    ;11111xxx
    rjmp decodetree11111xxx
    ;11110xxx
    sbrc r16, 2
    ;111101xx
    rjmp decodetree111101xx
    ;111100xx
    sbrc r16, 1
    ;1111001x
    rjmp decodetree1111001x
    ;1111000x
    sbrc r16, 0
    ;11110001
    rjmp decodetree11110001
    ;11110000

decodetree11110000:
    ; CLB
    
    rjmp decodetreeend
decodetree11110001:
    ; CLC
    
    rjmp decodetreeend
decodetree1111001x:
    ;1111001x
    sbrc r16, 0
    ;11110011
    rjmp decodetree11110011
    ;11110010
decodetree11110010:
    ; IAC
    
    rjmp decodetreeend
decodetree11110011:
    ; CMC
    
    rjmp decodetreeend
decodetree111101xx:
    ;111101xx
    sbrc r16, 1
    ;1111011x
    rjmp decodetree1111011x
    ;1111010x
    sbrc r16, 0
    ;11110101
    rjmp decodetree11110101
    ;11110100
decodetree11110100:
    ; CMA
    
    rjmp decodetreeend
decodetree11110101:
    ; RAL
    
    rjmp decodetreeend
decodetree1111011x:
    ;1111011x
    sbrc r16, 0
    ;11110111
    rjmp decodetree11110111
    ;11110110
decodetree11110110:
    ; RAR
    
    rjmp decodetreeend
decodetree11110111:
    ; TCC
    
    rjmp decodetreeend
decodetree11111xxx:
    ;11111xxx
    sbrc r16, 2
    ;111111xx
    rjmp decodetree111111xx
    ;111110xx
    sbrc r16, 1
    ;1111101x
    rjmp decodetree1111101x
    ;1111100x
    sbrc r16, 0
    ;11111001
    rjmp decodetree11111001
    ;11111000
decodetree11111000:
    ; DAC
    
    rjmp decodetreeend
decodetree11111001:
    ; TCS
    
    rjmp decodetreeend
decodetree1111101x:
    ;1111101x
    sbrc r16, 0
    ;11111011
    rjmp decodetree11111011
    ;11111010
decodetree11111010:
    ; STC
    
    rjmp decodetreeend
decodetree11111011:
    ; DAA
    
    rjmp decodetreeend
decodetree111111xx:
    ;111111xx
    sbrc r16, 1
    ;1111111x
    rjmp decodetree1111111x
    ;1111110x
    sbrc r16, 0
    ;11111101
    rjmp decodetree11111101
    ;11111100
decodetree11111100:
    ; KBP
    
    rjmp decodetreeend
decodetree11111101:
    ; DCL
    
    rjmp decodetreeend
decodetree1111111x:
    ;1111111x
    sbrc r16, 0
    ;11111111
    rjmp decodetree11111111
    ;11111110
decodetree11111110:
    ; UNDEFINED
    nop
    rjmp decodetreeend
decodetree11111111:
    ; UNDEFINED
    nop
    rjmp decodetreeend

decodetreeend:
    ; increment PC
    ; wait for next cycle
    ; loop back
    rjmp instructiondecode

data4040start:
    ; 4040 binary starts here, aligned to 256 bytes
.org    0x1000  ; 4K
