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

    
;----------------------Macros---------------------
reinicio_tmr0 macro
    banksel PORTA
    movlw 100
    movf TMR0
    bcf T0IF
endm
  
;------------------Variables----------------------  
    
PSECT udata_shr ;variables que se protegen los bits de status 
W_TEMP: DS 1	    ;variables para el push-pop
STATUS_TEMP: DS 1

  var: DS 1	;valor para los displays
  flags: DS 1	;selector del multiplexado
  nibble: DS 2	
  display_var: DS 3 ;valor mostrado en los displays
    
  UNIDAD: DS 1	;variables que guardan el valor para cada display
  DECENA: DS 1
  CENTENA: DS 1
    
PSECT resVect, class=CODE, abs, delta=2
    
;---------------------Vector reset-------------------
ORG 00h
resetVec:
    PAGESEL setup 
    goto setup ;rutina de configuracion

    
PSECT code, delta=2, abs
    
;--------------------interrupciones------------
 
 ORG 04h
push:
    movwf W_TEMP ; copia W al registro temporal
    swapf STATUS, W ; intercambio de nibbles y guarda en W
    movwf STATUS_TEMP; guarda status en el registro temporal
 
isr: ; rutina de interrupcion
   
   ;contador push_buttons
   btfsc RBIF   ; al momento de detectar un cambio en el puerto B, se activa la bandera
   call cont_iocb
   
   ;salida displays multiplexados
   btfsc T0IF	   ;comprueba la bandera de tmr0
   call	 cont_tmr0
  
pop: 
    swapf STATUS_TEMP, W ;intercambio nibbles y guarda en W
    movwf STATUS	 ;mueve W a STATUS
    swapf W_TEMP, F	;intercambio nibbles y guarda en W temporal
    swapf W_TEMP, W	;intervambio nibbles y guarda en W
   
    retfie ;salida de la interrupcion
    
 
;----------------------subrutina interrupcion------------------    
cont_iocb:
    banksel PORTA   
    btfss PORTB, 0	;comprueba si el bit 0 del portb esta en 1 (presionado)
    incf PORTA		;incremento
    btfss PORTB, 1	;comprueba si el bit 0 del portb esta en 1 (presionado)
    decf PORTA		;decremento
    bcf RBIF		;reinicia la bandera de interrupcion
    return  
     
cont_tmr0:
    call selector_display
    reinicio_tmr0
    return
    
selector_display:
    clrf PORTD		;apagar los displays
    btfsc flags, 1	; si hay un bit 1x llama al display de unidad
    goto display_2
    btfsc flags, 0	; si hay un bit x1 llama al display de centena
    goto display_0	;si no salta al display de decena
    goto display_1
    return
    
display_0:  ;display unidad
    movf display_var, W	    ;W recibe el valor del display
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 1	    ;bit1 del multiplexeado enciende
    bcf flags, 0
    bsf flags, 1    ; bandera = 10
    return
    
display_1:
    movf display_var+1, W   ;W recibe el valor del display+1 (una localidad mayor)
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 0    ;bit0 del multiplexeado enciende
    bsf flags, 0
  //x flag, 1	    ;bandera = x1
    return

display_2:
    movf display_var+2, W   ;W recibe el valor del display+2 (una localidad mayor)
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 2    ;bit2 del multiplexeado enciende
    bcf flags, 0
    bcf flags, 1    ;bandera = 00 
    return
    
/*
toggle_display:
   movlw 1
   xorwf flags, F   ;cambio de bandera (solo aplica con 2 displays)
   return
  */ 
    
    ;hasta aqui llegue
    
ORG 100h
 
;---------------------Configuración--------------------------
setup:
    call config_io	    ;input/output
    call config_reloj	    ;oscilador/reloj
    call config_int_enable  ; interrupciones
    call config_iocrb	    ; interrupt-on-change
    call config_tmr0	;timer0
    
    
    banksel PORTA

 
 ;----------------------LOOP------------------------
loop:
    movf PORTA, W   ;W recibe el valor de PORTA (contador de botones de 8 bits)
    movwf var	    ;se mueve el valor a la variable 'var'
    call valor_displays	;se llama a la funcion que convierte el valor de cada display
			;en notación decimal
    
    ;limpieza de las variables
    CLRF UNIDAD
    CLRF CENTENA
    CLRF DECENA
    
    ;llama a las funciones que asignan el valor de los displays
    call conv_centena	
    call conv_decena
    call conv_unidad
    
 //   call separar_nibbles
  //  call preparar_displays
    goto loop 
;--------------------subrutina loop----------------    
/*separar_nibbles:
    movf var, W
    andlw 0x0F
    movwf nibble
    swapf var, W
    andlw 0X0F
    movwf nibble+1
    return
    
    
preparar_displays: 
    movf nibble, W
    call tabla
    movwf display_var
    
    movf nibble+1, W
    call tabla
    movwf display_var+1
    return
    */
    
 valor_displays:
    movf DECENA, W	;se mueve el valor de la variable a W
    call tabla		;manda el valor a la subrutina tabla
    movwf display_var	;el valor que retorna la subrutina se almacena en display_var
    
    movf CENTENA, W
    call tabla
    movwf display_var+1
    
    movf UNIDAD, W
    call tabla
    movwf display_var+2
    
    return
    
 conv_centena:	    
    movlw 100	    ;W recibe 100
    subwf var, F    ;restamos el valor var con W
    incf CENTENA    ;incremento variable centana
    btfsc STATUS, 0 ;verificación bit borrow
    goto $-4	    ;si carry=1 :vuelve al inicio de la subrutina
    decf CENTENA    ;si carry=0 : decrementa la variable centena (soluciona el overflow)
    movlw 100	    
    addwf var, F    ;restituye el valor de var (sin centena)
    return
    
 conv_decena:
     movlw 10	    ;W recibe 10
    subwf var, F    ;restamos el valor var con W
    incf DECENA	    ;incremento variable decena
    btfsc STATUS, 0 ;verificación bit borrow
    goto $-4	    ;si carry=1 :vuelve al inicio de la subrutina
    decf DECENA	    ;si carry=0 : decrementa la variable decena (soluciona el overflow)
    movlw 10	    
    addwf var, F    ;restituye el valor de var 
    return
    
 conv_unidad:
    movlw 1	    ;W recibe 10
    subwf var, F    ;restamos el valor var con W
    incf UNIDAD	    ;incremento variable decena
    btfsc STATUS, 0 ;verificación bit borrow
    goto $-4	    ;si carry=1 :vuelve al inicio de la subrutina
    decf UNIDAD	    ;si carry=0 : decrementa la variable decena (soluciona el overflow)
    movlw 1
    addwf var, F    ;restituye el valor de var
    return
 ;-----------------subrutinas setup---------------
config_iocrb:
    banksel TRISA
    bsf IOCB0   ;interrupt-on-change 1:enabled
    bsf IOCB1
    
    banksel PORTA
    movf PORTB, W ;cuando lee, termina la condicion de mismatch
    bcf RBIF
    return
 
config_io:
    banksel ANSEL 
    clrf ANSEL 
    clrf ANSELH ;entradas digitales
    
    ;salidas
    banksel TRISA
    clrf TRISA
    clrf TRISC
    bcf TRISD, 0
    bcf TRISD, 1
    bcf TRISD, 2
    
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
    clrf PORTC
    clrf PORTD
    return
    
    
config_reloj:
    banksel OSCCON
    bcf IRCF2
    bsf IRCF1
    bsf IRCF0	;500KHz
    bsf SCS
    return

config_int_enable:
    bsf GIE ;global interrupt enable
    bsf T0IE ; tmr0 interrupt enable
    bcf T0IF ; bandera interrupcion
    bsf RBIE  ; RB interrupt enable
    bcf RBIF ;bandera interrupcion
    return
    
   
config_tmr0:
    banksel OPTION_REG
    bcf T0CS	;mode: temporizador
    bcf PSA	;prescaler para temporizador
    
    bcf PS2
    bcf PS1
    bsf PS0	;256
   
    banksel PORTA
    reinicio_tmr0
    return
 
  
;----------------------Tabla---------------------
 tabla: 
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
