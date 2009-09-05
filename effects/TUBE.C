// Star,Tube, And All sort of Stars Effects by Sarwaz of Mistery
// September, 1995
#include <conio.h>
#include <math.h>
#define OrDistX 0   // The Distance of the Field from the origin
#define OrDistY 0
#define RangoX 20  // The Range of X (X dispersion of stars, it must be
		  // sqrt(RADCIRC)
#define VELOCIDAD 1    // Velocity of stars
#define RADCIRC 400    // Radius of the tube
#define LONGITUD 126   // Z max Distance (be carfull with palette too)
#define DISTPANT 10   // Z min Screen Distance
#define NUMEST 500     // Number of stars
#define FLONGSENO 80   // Sinus Rough Factor
#define Fdist 90     // Distance Factor (Zoom?)
#define getrandom( min, max ) ((rand() % (int)(((max)+1) - (min))) + (min))
int CentFacX=160+OrDistX;   // origin of coordinates (160,100 in the middle)
int CentFacY=100+OrDistY;

void putpixel(x,y,col)
unsigned int x,y;
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
	mov bx,x
	mov ax,y
	xchg ah,al
	add bx,ax
	shr ax,1
	shr ax,1
	add bx,ax
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
int i,cont1,Xn,Yn,Zo,Xo,Yo,indseno,Fmov1,Fmov2,indtmp;
short cont2;
int pos[NUMEST][3],tmp[NUMEST][2];
int seno[360];
int coseno[360];
// Calculo de la Tabla de senos
for(i=0; i<360; i++)
	{
		seno[i] = FLONGSENO*(sin(i * 3.14159265 / 180));
		coseno[i]=FLONGSENO*(cos(i * 3.14159265 / 180))*(-1);
	}



_asm{
	mov ax,13h
	int 10h
	}
for (cont2=127;cont2>0; cont2--)
{
	set_palette (0,0,(127-cont2)/2,cont2);
}

for (cont1=0; cont1<(NUMEST/2); cont1++)
{
	pos[cont1][0] = getrandom(-(RangoX),RangoX);
	pos[cont1][1]=Fdist*sqrt(RADCIRC-(pos[cont1][0]*pos[cont1][0]));
	pos[cont1][0]=Fdist*pos[cont1][0];
	//pos[cont1][1]=10;
	pos[cont1][2] = getrandom(1,LONGITUD);
}
for (cont1=(NUMEST/2); cont1<NUMEST;cont1++)
{
	 pos[cont1][0] = getrandom(-(RangoX),RangoX);
	 pos[cont1][1]=Fdist*(-1*(sqrt(RADCIRC-(pos[cont1][0]*pos[cont1][0]))));
	 pos[cont1][0]=Fdist*pos[cont1][0];
	// pos[cont1][1]=-10;
	pos[cont1][2] = getrandom(1,LONGITUD);
}



indseno=0;
while (!kbhit()) {
	Fmov1=seno[indseno];
	Fmov2=coseno[indseno];
	indseno=(indseno+1)%360;
	WaitRet();

	for (cont1=0;cont1<NUMEST;cont1++)
	{
	putpixel(tmp[cont1][0]+CentFacX,tmp[cont1][1]+CentFacY,0);
	}

	for (cont1=0; cont1<NUMEST; cont1++)
	{
	indtmp=((pos[cont1][2])+indseno)%360;
	Fmov1=seno[indtmp];
	Fmov2=coseno[indtmp];
	Xn = ((pos[cont1][0]) /(pos[cont1][2]))+Fmov2;
	Yn = ((pos[cont1][1]) /(pos[cont1][2]))+Fmov1;
	tmp[cont1][0]=Xn;
	tmp[cont1][1]=Yn;
	putpixel(Xn+CentFacX,Yn+CentFacY,pos[cont1][2]);
	pos[cont1][2]-=VELOCIDAD;

	if (pos[cont1][2] <= DISTPANT) {
		pos[cont1][2] = LONGITUD;
		}
	}
}
_asm {
	mov ax,3h
	int 10h
	}

}
