// smoke Effect By Sarwaz of Mistery
// The Fear : 55 minutes!!! ;)
#include <STDLIB.H>
#include <conio.h>

void palette ( char R, char G, char B, unsigned char col);
void getrandomline (void);
void rawpixel (unsigned int pos,unsigned char col);
void mode19 (void);
void calcpoints (void);
void setfirecolours (void);
void gotodos (void);
main () {
mode19 ();
setfirecolours ();
while (!kbhit()){
getrandomline ();
calcpoints ();

}
gotodos ();



return 0;
}
void gotodos (void)
{
asm {
	mov ax,3
	int 10h
	mov ax,4c00h
	int 21h
	}
}

void getrandomline (void)
{
int i;
unsigned char randomcolor;
for (i=0;i!=319;i++){
	rawpixel (63680+i,random(165)+90);
	}
}

void rawpixel (unsigned int pos,unsigned char col)

{
asm {
	mov ax,0a000h
	mov es,ax
	mov bx,pos
	mov cl,col
	mov es:[bx],cl
	}
}
void mode19 (void)
{
asm {
	mov ax,13h
	int 10h
	}
}
void calcpoints (void)
{
unsigned char sum;

_asm {
	mov ax,0a000h
	mov es,ax
	mov bx,48000
	xor ax,ax
      }
bucle: asm {
	mov cx,0
	mov al,es:[bx-320]
	add cx,ax
	mov al,es:[bx+319]
	add cx,ax
	mov al,es:[bx+321]
	add cx,ax
	mov al,es:[bx+320]
	add cx,ax
	shr cx,1
	shr cx,1
	mov es:[bx],cl
	inc bx
	cmp bx,63680
	jnz bucle
	}
}


void setfirecolours (void)
{
int i;
char red,green,blue;
for (i=255;i!=200;i--){
	palette (63,63,63,i);
	}

green=63;
red=63;
blue=63;
for (i=200;i!=137;i--){
	palette(red,green,blue,i);
	green--;
	red--;
	blue--;
	}
for (i=137;i!=74;i--){
	palette(0,0,0,i);
	red=red--;
	}
for (i=74;i!=0;i--){
	palette(0,0,0,i);
	}
}


void palette ( char R, char G, char B, unsigned char col)
{
asm {
	mov dx,3c8h
	mov al,col
	out dx,al
	inc dx
	mov al,R
	out dx,al
	mov al,G
	out dx,al
	mov al,B
	out dx,al
    }
}

