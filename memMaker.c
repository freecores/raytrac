/*
 *  memMaker.c
 *  memoryMaker
 *
 *  Created by julian on 23/02/11.
 *  GPL LICENSED
 *  The goal of this peace of code is to create a memory initialization file of random fixed point numbers
 *  in order to simulate RtEngine.
 *  Usage is 
 */

#include "memMaker.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <time.h>
#include <string.h>

char australia[]="DEPTH = %03d;\nWIDTH = %02d;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT\nBEGIN\n\n\0";
char canada[]="END;\n\0";
struct {
	int depth;
	int width;
	int dec;
	char *initialheader;
	char *end;
	
}memparam={0,0,0,australia,canada};	

//mpx memparam={0,0,australia};

void optParser(int argc, char ** argv){
	
	char a=0;
	int e=0,d=0,t=0;
	/*memparam.initialheader=australia;
	memparam.width=0;
	memparam.depth=0;*/
	while ((a=getopt(argc,argv,"t:e:d:"))!=-1){
		switch(a){
			case 't':
				if (t){
					fprintf (stderr, "error:Doble parametro t...\n");
					exit(-1);
				}
				t++;
				memparam.depth=atoi(optarg);
				break;
			case 'e':
				if (e){
					fprintf (stderr, "error:Doble parametro e...\n");
					exit(-1);
				}
				e++;
				memparam.width+=atoi(optarg);
				break;
			case 'd':
				if (d){
					fprintf (stderr,"error:Doble parametro d...\n");
					exit(-1);
				}
				d++;
				memparam.dec=atoi(optarg);
				memparam.width+=memparam.dec;
				
				break;
			case '?':
				fprintf(stderr,"error: WTF! %c !?\n",optopt);
				exit(-1);
				break;
		}
	}
	if (!e || !d || !t){
		fprintf(stderr,"uso: memMaker -t numeroDePosicionesDeMemoria -e numeroDeBitsParaLaRepresentacionEntera -d numeroDeBitsParaLaRepresentacionDecimal\n");
		exit(-1);
	}
	if ((e+d)>31){
		fprintf(stderr,"enteros + decimales no puede ser mayor a 31 bits!\n");
		exit(-1);
	}
}

int hexreq(long int x){
	return ((int)(log2(x)/4))+1;
}


void generatenums(void){
	
	int index;
	unsigned long int factor;
	float ffactor;
	char buff[1024],sign;
	int mask=pow(2,memparam.width+1)-1, depthpfw=hexreq(memparam.depth),widthpfw=((int)(memparam.width/4))+(memparam.width%4?1:0);
	srandom(time(0));
	for(index=0;index<memparam.depth ;index++){
		factor=random()&mask;
		sign=(factor&(1<<memparam.width))?'-':'+';
		ffactor=(factor&(1<<memparam.width))?(factor^(int)(pow(2,memparam.width+1)-1))+1:factor;
		ffactor/=pow(2,memparam.dec);
		memset(buff,0,1024);
		sprintf(buff,"%c0%dx : %c0%dx -- FIXED => %x . %x (%d . %d) FLOAT %c%f\n",
				'%',
				depthpfw,
				'%',
				widthpfw,
				factor>>memparam.dec,
				factor&(int)(pow(2,memparam.dec)-1),
				factor>>memparam.dec,
				factor&(int)(pow(2,memparam.dec)-1),
				sign,
				ffactor);
		fprintf(stderr,buff,index,factor);
	}

}		
void printmem(void){
	fprintf (stderr,memparam.initialheader,memparam.depth,memparam.width);
	generatenums();
	fprintf (stderr,memparam.end);

}

int main (int argc, char **argv){
	optParser(argc,argv);
	printmem();		
}	
