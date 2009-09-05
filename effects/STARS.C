
#include <conio.h>
#include <math.h>
#define RADCIRC 100
#define LONGITUD 126
#define NUMEST 130
#define getrandom( min, max ) ((rand() % (int)(((max)+1) - (min))) + (min))
#define Fdist 150
void putpixel(x,y,col)
int x,y;
short col;
{

	_asm {
	cmp y,200
	jge fin
	cmp x,320
	jge fin
	cmp y,0
	jl fin
	cmp x,0
	jl fin
	mov ax,0A000h
	mov es,ax
	mov ax,320
	mov bx,y
	mul bx
	mov bx,ax
	add bx,x
	mov cl,col
	mov es:[bx],cl
	fin:
	}
}
void set_palette (r,g,b,col)
short r,g,b;
short col;
{
_asm{
	mov al,col
	mov dx,3c8h
	out dx,al
	inc dx
	mov al,r
	out dx,al
	mov al,g
	out dx,al
	mov al,b
	out dx,al
	}
}

void WaitRet (void)

{
_asm {
	mov dx,3dah
    }
dw: _asm {       in al,dx
		test al,8
		jz dw
	}
}




main()
{
int i,cont1,Xn,Yn,Zo,Xo,Yo,indseno,Fmov;
short cont2;
int pos[NUMEST][3],tmp[NUMEST][2];
int seno[360];
// Calculo de la Tabla de senos
for(i=0; i<360; i++)
	{
		seno[i] = 150*(sin(i * 3.14159265 / 180));
	}


_asm{
	mov ax,13h
	int 10h
	}
for (cont2=63;cont2>0; cont2--)
{
	set_palette (63-cont2,63-cont2,63-cont2,cont2);
}

for (cont1=0; cont1<NUMEST; cont1++)
{
	pos[cont1][0] = getrandom(-100,100);
	pos[cont1][1]=  getrandom(-100,100);
	pos[cont1][2] = getrandom(1,LONGITUD);
}
indseno=0;
while (!kbhit()) {
	Fmov=seno[indseno];
	indseno++;
	indseno=indseno%360;
	WaitRet();
	for (cont1=0;cont1<NUMEST;cont1++)
	{
	putpixel(tmp[cont1][0]+160,tmp[cont1][1]+100,0);
	}

	for (cont1=0; cont1<NUMEST; cont1++)
	{

	Xn = (Fdist*(pos[cont1][0]) /(pos[cont1][2]))+Fmov ;
	Yn = (Fdist*(pos[cont1][1]) /(pos[cont1][2]))+Fmov ;
	tmp[cont1][0]=Xn;
	tmp[cont1][1]=Yn;
	putpixel(Xn+160,Yn+100,pos[cont1][2]/2);
	pos[cont1][2]--;

	if (pos[cont1][2] <= 1) {
		pos[cont1][2] = LONGITUD;
		pos[cont1][0] = getrandom(-50,50);
		pos[cont1][1] = getrandom(-50,50);
		}
	}
}

_asm{
	mov ax,3h
	int 10h
	}
}
