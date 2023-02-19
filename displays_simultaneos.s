; Archivo: Displays_simultaneos
; Dispositivo: PIC16F887
; Autor: Anderson Escobar
; Compilador: pic-as (v2.4), MPLABX V6.05
; 
; Programa: contador de botones y salida de displays simultaneos
; Hardware: leds (RA), botones (RB), displays (RC)
; 
; Creado: 16 feb, 2023
; Última modificación: 13 feb, 2023

PROCESSOR 16F887
#include <xc.inc>
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

PSECT udata_bank0 ;bytes a guardar
 cont_small: DS 1
 
  
PSECT resVect, class=CODE, abs, delta=2
;---------------------Vector reset-------------------
ORG 00h
resetVec:
    PAGESEL setup
    goto setup

    
PSECT code, delta=2, abs
ORG 100h

 
 
 
;---------------------Configuración-------------
 setup:
    call config_io	;configuracion de entradas/salidas
    call config_reloj	;configuracion del reloj
  //  call config_tmr0	;configuracion tmr0
  
  banksel PORTA
 
 ;----------------------LOOP------------------------
loop:
    btfss PORTB, 0 ;chequea si se presiona el boton
    call incrs_A 
    
    btfss PORTB, 1
    call dicrs_A
    
    goto loop 
    
 
  ;---------------subrutinas loop-------------------- 
incrs_A:
    call delay_small 
    btfss PORTB, 0  ;condicion antirebote
    goto $-1	    ;regresa a linea anterior
    incf PORTA
    return

    
dicrs_A:
    call delay_small 
    btfss PORTB, 1  ;condicion antirebote
    goto $-1	    ;regresa a linea anterior
    decf PORTA
    return

    
delay_small:
    movlw   150 
    movwf   cont_small 
    decfsz  cont_small, 1 
    goto    $-1 
    return 
   
   
    
    
 ;-----------------subrutinas setup---------------
 config_io:
    banksel ANSEL 
    clrf ANSEL 
    clrf ANSELH ;entradas digitales
    
    ;salidas
    banksel TRISA
    movlw 0b00000000
    movwf TRISA
    
    ;entradas
    bsf TRISB, 0
    bsf TRISB, 1
   
   ;config pullup 
    bcf OPTION_REG, 7	;habilita los pull-ups del puerto B
    bsf WPUB0	;pull-ups internos 1: enabled
    bsf WPUB1
   
    ;valor init
    banksel PORTA 
    clrf PORTA
    clrf PORTB 
   
    return
    
    
config_reloj:
    banksel OSCCON
    bsf IRCF2
    bcf IRCF1
    bcf IRCF0
    bsf SCS
    return

  /*  
config_tmr0:
    banksel OPTION_REG
    bcf T0CS	;mode: temporizador
    bcf PSA	;prescaler para temporizador
    
    bsf PS2
    bsf PS1
    bsf PS0
   
    banksel PORTA
    reinicio_tmr0
    return*/
  
  
  
 
 ;----------------------Macros---------------------
reinicio_tmr0 macro
    movlw 214
    movf TMR0
    bcf T0IF
endm

    
  
;----------------------Tabla---------------------
 /*tabla: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0X0F
    ADDWF PCL ;PCL + PCLATH (W con PCL) PCL adquiere ese nuevo valor y salta a esa linea
    ;valores que regresa
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
END
 
 
*/ 
 

    

END