#include < reg51.h >

  # define fimTempo 50 //timer = 0.2ms -> fimTempo=50*0.2ms=10ms
  # define zero 3 //3*0.2ms=0.6ms -> 0º
  # define centoOitenta 12 //12*0.2ms=2.4ms -> 180º
  # define atraso 50


sbit sensor = P3 ^ 2; //pino do sensor(single bit)
sbit servo = P1 ^ 0; //pino de controlo do servo motor(single bit)
sbit led = P1 ^ 1; //pino do LED(single bit)

unsigned char conta = 0; //contador que incrementa a cada 200us
unsigned char conta2 = 0;
unsigned char referencia = zero; //o servo motor começa nos 0º
unsigned char passo = 1;
//declaração de funções
void Init(void);

void Init(void) {
  //Configuracao Registo IE
  EA = 1; //ativa interrupcoes globais
  ET0 = 1; // ativa interrupcao a interrupção de overflow do temporizador 0
  EX0 = 1; // ativa interrupcao externa 0
  //Configuracao Registo TMOD
  TMOD &= 0xF0; //limpa os 4 bits mais significativos do temporizador 0 (8 bits – auto reload)
  TMOD |= 0x02; //modo 2 do timer 0, • No modo 2 o registo do contador é de 8-bit (TL1) com leitura automática
  //O overflow de TL1 envia um sinal para TF1 e lê o TL1 com o valor de TH1, que pode ser comandado por software;
  //A leitura de TH1 não altera o seu conteúdo;
  //Configuracao Timer 0
  TH0 = 0x37; //registos de contagem de 16-bit para temporizadores 0
  TL0 = 0x37;
  //Configuracao Registo TCON
  TR0 = 1; //comeca o timer 0
  IT0 = 1; //O sinal INT0 é detectado na transição
	//Na função como temporizador, o registo é incrementado por cada ciclo de máquina
}

//interrupcao externa
void External0_ISR(void) interrupt 0 {
  EX0 = 0;
}

//interrupcao tempo
void Timer0_ISR(void) interrupt 1 {
  conta++; //incrementa a cada contagem de 200us
}

void main(void) {
  //inicializações
  Init();

  while (1) { //atingiu o valor de referencia (0.6ms, 1.4ms ou 2.4ms)
    if (conta == referencia) {
      servo = 0; //coloca a saída a 0 até atingir os 20ms
    }
    //atingiu os 20ms
    if (conta == fimTempo) {
      conta = 0; //reinicia a contagem
      servo = 1; //impulso positivo até atingir o valor de referencia
      conta2++;  //incrementa 20ms na contagem do tempo de espera entre mudança de angulos
    }
    //o sensor detetou luz e modifica o valor de referencia
    if (sensor == 1) {
      led = 1;
      if (conta2 == atraso) {
					if(referencia == centoOitenta){ //Se servo está em 180º passo decrementará referencia
						passo = passo * -1;
						referencia = referencia + passo;
		}
					if(referencia == zero && passo == -1){ //Se servo está em 0º passo incrementará referencia
						passo = passo * -1;
						referencia = referencia + passo;
		}
					else{
						referencia = referencia + passo;
					}
        conta2 = 0;
      }
    }
    if (sensor == 0) {
      led = 0;
    }
  }
}
