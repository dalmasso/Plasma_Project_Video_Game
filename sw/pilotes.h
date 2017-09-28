#include "plasma.h"

// cross compile : export PATH=/home/projplasma/plasma/gccmips_elf/:$PATH
// access directory : cd /cygdrive/c/Users/Polytech/Desktop/projplasma/plasma/tools
// compile : make pilotes
// simu plasma soft : dans tools, bin/mlite.exe test.bin
// create hard image : make toimage

#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)
#define MemoryRead(A) (*(volatile unsigned int*)(A))

#define SCREEN_W			640
#define SCREEN_H			480
#define BALL_LENGTH			34
#define BALL_HALF			BALL_LENGTH/2
#define OBST_W				79	
#define OBST_H				29			

#define BALL_MAX_COL		SCREEN_W-BALL_LENGTH
#define BALL_MIN_LINE		0
#define BALL_MAX_LINE		SCREEN_H

#define OBST_MIN_LINE		0
#define OBST_MAX_LINE		SCREEN_H-OBST_H

#define TIME_DEFAULT		14000
#define TIME_1				10000
#define TIME_2				7000
#define TIME_3				5000

// GPIOA IN MASK
#define ACCEL_Y				0x3FF
#define SW_2_0				0x1C00
#define BTNR				0x2000

// CONSTANT SHIFTS GPIOA IN
#define SHIFT_SW			10
#define SHIFT_BTNR			13

// CONSTANT SHIFTS GPIO_OUT
#define SHIFT_GPIO_OUT_10	10
#define SHIFT_GPIO_OUT_13	13
#define SHIFT_GPIO_OUT_20	20
#define SHIFT_GPIO_OUT_31	31

// GPIO OUT MASK
#define GPIO_OUT_9_0		0x3FF
#define GPIO_OUT_12_10		0x1C00
#define GPIO_OUT_19_13		0xFE000
#define GPIO_OUT_22_20		0x700000
#define GPIO_OUT_31			0x80000000


/*
* 12 downto 10 : 000 pos ball col
*                001 pos ball line
*                011 pos obst1 col
*                010 pos obst2 col
*                110 pos obst1 line
*                100 pos obst2 line                  
* NOTE : POSITION IN GRAY CODE TO AVOID INTERMEDIATE STATE OF BITS
* The cycle of position is according to the loop in software
*/
#define BALL_COL			0x0 //000
#define BALL_LINE			0x1 //001
#define OBST_COL			0x3 //011
#define OBST2_COL			0x2 //010
#define OBST_LINE			0x6 //110
#define OBST2_LINE			0x4 //100

// Using GRAY CODDE
#define DIGIT7				0x04 //100
#define DIGIT6				0x05 //101
#define DIGIT5				0x07 //111
#define DIGIT4				0x06 //110
#define DIGIT3				0x02 //010
#define DIGIT2				0x03 //011
#define DIGIT1				0x01 //001
#define DIGIT0				0x00 //000

#define CONV_SEG_0			0x40 //1000000
#define CONV_SEG_1			0x79 //1111001
#define CONV_SEG_2			0x24 //0100100
#define CONV_SEG_3			0x30 //0110000
#define CONV_SEG_4			0x19 //0011001
#define CONV_SEG_5			0x12 //0010010
#define CONV_SEG_6			0x02 //0000010
#define CONV_SEG_7			0x78 //1111000
#define CONV_SEG_8			0x00 //0000000
#define CONV_SEG_9			0x10 //0010000
#define CONV_SEG_OFF		0xFF //1111111

#define MODE_RST_ALL		4
#define MODE_RST_SCORE		3
#define MODE_SAVE			2
#define MODE_INCR			1
#define MODE_STEADY			0


void delay_1s(void);
void GPIOWrite_GAMEOV(int value);
void GPIOWrite_Position(int value, int select_pos);
void game (void);
void scorecontrol(int mode);
void digit(int mode, int number);
int convNumbTo7Seg(char value);


/******************************* LIBC **********************************/
void my_itoa(int num, char *dst, int base);
void *memset(void *dst, int c, unsigned long bytes);
int rand(void);
/***********************************************************************/


/*
int putchar(int value);
int puts(const char *string);
void print_hex(unsigned long num);
int puts(const char *string);
void Led(int value);
int SW(void);
int BTN(int select);
void Move_Image(int value);
int Screen_Sleep(int value);

void Led(int value)
{
	MemoryWrite(GPIO0_CLEAR, (~value) & 0xff); //clear
	MemoryWrite(GPIO0_OUT, value); //Change LEDs
}


int SW(void)
{
	return MemoryRead(GPIOA_IN) & 0x000000FF;
}


int BTN(int select)
{
	int value = 0;

	switch(select)
	{
	case 1: // R
		value = (MemoryRead(GPIOA_IN) & 0x00000800) >> 11;
		break;

	case 2: // L
		value = (MemoryRead(GPIOA_IN) & 0x00000400) >> 10;
		break;	

	case 3: // U
		value = (MemoryRead(GPIOA_IN) & 0x00000200) >> 9;
		break;

	case 4: // D
		value = (MemoryRead(GPIOA_IN) & 0x00000100) >> 8;
		break;

	default:
		value = 255;
		break;
	}

	return value;
}


void Move_Image(int value)
{
	// GPIO0 11 - 8 : line
	// GPIO0 15 - 12 : col
	MemoryWrite(GPIO0_CLEAR, (~(value<<8)) & 0xff00); //clear
	MemoryWrite(GPIO0_OUT, (value<<8)); //Change 
}

int Screen_Sleep(int value)
{
	Move_Image(value);

	// increment value
	value += 0x44;

	// Update value line
	if ((value & 0x0F) >= 0x0F) //640 - 240
		value = (value & 0xF0); // reset line

	// Update value col
	if ((value & 0xF0) >= 0x0F) //480 - 160
		value = (value & 0x0F); // reset col

	return value;
}
*/
/***********************************************************************/
