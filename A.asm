fimTempo		EQU		50					;timer = 0.2ms -> fimTempo=50*0.2ms=10ms
zero			EQU		3					;3*0.2ms=0.6ms -> 0º
centoOitenta	EQU		12					;12*0.2=2.4ms -> 180º
atraso			EQU		50
led 			EQU 	P1.1 				;pino do LED
servo 			EQU 	P1.0 				;pino de controlo do servo motor
sensor 			EQU 	P3.2 				;pino do sensor
conta			EQU		0					;contador que incrementa a cada 200us
conta2			EQU		0
referencia		EQU		3					;o servo motor começa nos 0º, anda de 20º em 20º
passo 			EQU 	1
											;Depois do reset
CSEG AT 0000h
JMP      inicial

											;Se ocorrer a interrupção externa 0
CSEG AT 0003h
JMP      externInterrupt

											;Tratamento da interrupção de temporização 0
CSEG AT 000Bh
JMP      timeInterrupt


CSEG AT 0050h
inicial:
MOV 	 SP,#7								;Endereço inicial da stack point
CALL     inicializacao						;Chamada a rotina inicializações
CALL	 externInterrupt					;Rotina para ativar a interrupção externa
CALL 	 timeInterrupt						;Rotina para ativar a interrupçao interna de tempo

contaReferencia:
MOV      A,R0
MOV		 B,R2
CJNE     A,B,contaFimTempo					;Atingiu o valor de referencia (0.6ms, 1.4ms ou 2.4ms)
CLR      servo								;coloca a saída a 0 até atingir os 20ms

contaFimTempo:
MOV      A,R0
CJNE     A,#fimTempo,sensor1				;Atingiu os 20ms
CLR      A									;Reinicia a contagem
MOV      R0,A						
SETB     servo								;Impulso positivo até atingir o valor de referencia
INC      R1									;Incrementa o conta2++

sensor1:
JNB      sensor,sensor0						;Verifica se o sensor, está ou não está, ativado
SETB     led								;O sensor detetou luz e modifica o valor de referencia
JMP 	 conta2Atraso						;Salta para a rotina indicada

conta2Atraso:
MOV      A,R1			
CJNE     A,#atraso,contaReferencia			;Salta para a rotina especificada se conta2 ainda atingiu o valor de atraso
JMP 	 referenciaCentoOitenta				;Salta para a rotina especificada
	
referenciaCentoOitenta:
MOV      A,R2								;Move para A o valor atual da referencia
CJNE	 A,#centoOitenta,referenciaZero		;Caso esteja a 180º continua, c.c. vê se está a 0º
MOV 	 A,R3								;Move para A o valor atual do passo (1)
MOV 	 B,#0xFF							;Move para B o valor -1
MUL		 AB									;Multiplica a passo por -1
MOV 	 R3,A								;Atualiza o passo
ADD 	 A,R2								;Soma o passo com a referencia (-1+12)
MOV 	 R2,A								;Atualiza a referencia (11)
JMP 	 limpaConta2

referenciaZero:
MOV 	 A,R2								;Move para A o valor atual da referencia
CJNE 	 A,#zero,elses						;Caso esteja a 0º continua, c.c. significa que esta noutro angulo qualquer
MOV      A,R3								;Move para A o valor atual do passo 
CJNE     A,#0xFF,elses						;Vê se o passo é -1 (isto porque inicialmente a 0º o passo é 1)
MOV 	 B,#0xFF							;Move para B o valor -1
MUL 	 AB									;Multiplica a passo por -1
MOV      R3,A								;Atualiza o passo
ADD 	 A,R2								;Soma o passo com a referencia (1+0)
MOV 	 R2,A								;Atualiza a referencia (1)
JMP 	 limpaConta2

elses:
MOV      A,R3								;Move para A o valor atual do passo 								
ADD      A,R2								;Soma o passo com a referencia								
MOV      R2,A								;Atualiza a referencia
JMP 	 limpaConta2

limpaConta2:	
CLR      A									;Limpa o conta2
MOV      R1,A

sensor0:
JB       sensor,contaReferencia				;Verifica se o sensor está ativado, e caso seja verdade, salta para a rotina indicada
CLR	 	 led								;Como o sensor esta desligado, o led também fica no mesmo estado
CLR		 EX0								;Desativa a interrupção externa 0 
JMP	     contaReferencia

inicializacao:
CLR      led								;O led no inicio esta desligado
SETB     sensor						
SETB     EA									;Ativa interrupcoes globais
SETB     ET0								;Ativa interrupcao timer 0
SETB     EX0								;Ativa interrupcao externa 0
ANL      TMOD,#0xF0							;Limpa os 4 bits do timer 0 (8 bits – auto reload)
ORL      TMOD,#0x02							;modo 2 do timer 0, • No modo 2 o registo do contador é de 8-bit (TL1) com leitura automática
											;O overflow de TL1 envia um sinal para TF1 e lê o TL1 com o valor de TH1, que pode ser comandado por software;
											;A leitura de TH1 não altera o seu conteúdo;
											;Configuracao Timer 0
MOV      TH0,#0x37							;registos de contagem de 16-bit para temporizadores 0
MOV      TL0,#0x37
SETB     TR0								;Comeca o timer 0
SETB     IT0								;Interrupcao externa activa a falling edge
											;O sinal INT0 é detectado na transição
											;Na função como temporizador, o registo é incrementado por cada ciclo de máquina
MOV 	 R0, #conta							;R0 fica encarregue de operar o conta
MOV 	 R1, #conta2						;R1 fica encarregue de operar o conta2
MOV 	 R2, #referencia					;R2 fica encarregue de operar a referencia
MOV 	 R3, #passo							;R3 fica encarregue de operar o passo
RET
    
externInterrupt: 							;Interrupcao externa
SETB     sensor								;O sensor é ativado, e assim efetua as rotinas consequentes
CLR 	 EX0								;Desativa a interrupção externa 0 
RETI

timeInterrupt:								;Interrupcao tempo
INC      R0						  			;Incrementa a cada contagem de 200us
RETI

END
