#include "pilotes.h"
#include "bootldr.h"


/******************************* LIBC **********************************/
void *memset(void *dst, int c, unsigned long bytes)
{
   unsigned int *Dst = (unsigned int*)dst;
   while((int)bytes-- > 0)
      *Dst++ = (unsigned int)c;
   return dst;
}


void my_itoa(int num, char *dst, int base)
{
   int digit,place;
   char c;

   for(place = 0; place <4; place++)
   {
      digit = (unsigned int)num % (unsigned int)base; // left digit

      if(digit < 10)
         c = (char)('0' + digit);
      else
         c = (char)('a' + digit - 10);

      dst[place] = c;
      num = (unsigned int)num / (unsigned int)base;
   }

   // Manage 000x
   if ( (dst[3] == '0') && (dst[2] == '0')  && (dst[1] == '0') )
    dst[3] = dst[2] = dst[1] = '-';

   // Manage 00xx
   else if ( (dst[3] == '0') && (dst[2] == '0'))
    dst[3] = dst[2] = '-';    

   // Manage 0xxx
   else if (dst[3] == '0')
    dst[3] = '-';   
}

// Use for pseudo random number generator (int = 32bits)
static uint32 Rand1=0x1f2bcda3, Rand2=0xdeafbeef, Rand3=0xc5134306;
int rand(void)
{
	int shift;
	Rand1 += 0x13423123 + Rand2;
	Rand2 += 0x2312fdea + Rand3;
	Rand3 += 0xf2a12de1;
	shift = Rand3 & 31;
	Rand1 = (Rand1 << (32 - shift)) | (Rand1 >> shift);
	Rand3 ^= Rand1;
	shift = (Rand3 >> 8) & 31;
	Rand2 = (Rand2 << (32 - shift)) | (Rand2 >> shift);

	Rand1 = Rand1 % (SCREEN_W - OBST_W);
	return Rand1;
}
/***********************************************************************/




// Delay
void delay_s(int mult)
{	
	unsigned long j = 0;
	for(j=0;j<(12500000*mult);j++){} // 25MHz, 4 instructions par cycle donc 25/4 mais pipeline !!
}


// Use for enable/disable gameover
void GPIOWrite_GAMEOV(int value)
{
	// Write value
	MemoryWrite(GPIO0_CLEAR, (~(value<<SHIFT_GPIO_OUT_31)) & GPIO_OUT_31); //clear
	MemoryWrite(GPIO0_OUT, (value<<SHIFT_GPIO_OUT_31)); //Change GPIO_OUT
}


// Use for change positions (ball, obst1, obst2)
void GPIOWrite_Position(int value, int select_pos)
{
	// Manage 2bits position
	MemoryWrite(GPIO0_CLEAR, (~(select_pos<<SHIFT_GPIO_OUT_10)) & GPIO_OUT_12_10); //clear
	MemoryWrite(GPIO0_OUT, (select_pos<<SHIFT_GPIO_OUT_10)); //Change GPIO_OUT 12 downto 10

	// Write value
	MemoryWrite(GPIO0_CLEAR, (~value) & GPIO_OUT_9_0); //clear
	MemoryWrite(GPIO0_OUT, value); //Change GPIO_OUT 9 downto 0
}

// Use for change digits (7,6,5,4,3,2,1,0)
void GPIOWrite_Digit(int value, int select_pos)
{
	// Manage 3bits digit selection
	MemoryWrite(GPIO0_CLEAR, (~(select_pos<<SHIFT_GPIO_OUT_20)) & GPIO_OUT_22_20); //clear
	MemoryWrite(GPIO0_OUT, (select_pos<<SHIFT_GPIO_OUT_20)); //Change GPIO_OUT 22 downto 20

	// Write value
	MemoryWrite(GPIO0_CLEAR, (~value<<SHIFT_GPIO_OUT_13) & GPIO_OUT_19_13); //clear
	MemoryWrite(GPIO0_OUT, (value<<SHIFT_GPIO_OUT_13)); //Change GPIO_OUT 19_13
}


/* Use for manage score
* mode MODE_RST_ALL		: reset all digits
* mode MODE_RST_SCORE   : reset score
* mode MODE_SAVE   		: save record
* mode MODE_INCR   		: increase score
* mode MODE_STEADY 		: steady score
*/
void scorecontrol(int mode)
{
	static int score = 0;	
	static int record = 0;
	static int update = 0;


	// Reset all digits
	if (mode == MODE_RST_ALL)
		digit(3,0);

	// Reset score
	if (mode == MODE_RST_SCORE)
	{
		score = 0;
		update = 0;

		// Reset score digits 3-0
		digit(0,score);
	}

	// To increase only one time
	if ( (mode == MODE_INCR) && (update == 1) )
	{
		score++;
		update = 0;
	}

	// Manage increase state (for next call)
	if (mode == MODE_STEADY)
		update = 1;

	// Manage score digits
	digit(0, score);

	// Save best record (4 record digits)
	if ( (mode == MODE_SAVE) && (record < score) )
	{
		record = score;
		digit(1, record);
	}
}


/* Use to control 8 digits
*  mode 3 : RAZ all digits
*  mode 1 : digit 7 - 4
*  mode 0 : digit 3 - 0
*/
void digit(int mode, int number)
{
	char digit7_4[4] = {0};
	int digit7_4_sel[4] = {DIGIT4,DIGIT5,DIGIT6,DIGIT7};
	char digit3_0[4] = {0};
	int digit3_0_sel[4] = {DIGIT0,DIGIT1,DIGIT2,DIGIT3};
	int i = 0;

	// Reset all digits to 0
	if (mode == 3)
	{
		// Display on 3_0 digits
		for(i=0;i<4;i++)
			GPIOWrite_Digit(convNumbTo7Seg('-'), digit3_0_sel[i]);

		// Display on 7_4 digits
		for(i=0;i<4;i++)
			GPIOWrite_Digit(convNumbTo7Seg('-'), digit7_4_sel[i]);		
	}

	// Score digits. Parse each digit
	else if (mode == 0)
	{
		// Convert each digit into character
		my_itoa(number,digit3_0,10);

		// Display on 3_0 digits
		for(i=0;i<4;i++)
			GPIOWrite_Digit(convNumbTo7Seg(digit3_0[i]), digit3_0_sel[i]);
	}

	else
	{
		// Convert each digit into character
		my_itoa(number,digit7_4,10);

		// Display on 7_4 digits
		for(i=0;i<4;i++)
			GPIOWrite_Digit(convNumbTo7Seg(digit7_4[i]), digit7_4_sel[i]);
	}
}


// Use to convert number into 7seg code
int convNumbTo7Seg(char value)
{
	switch(value)
	{
		case '0' :
			value = CONV_SEG_0;
			break; 

		case '1' :
			value = CONV_SEG_1;
			break; 

		case '2' :
			value = CONV_SEG_2;
			break; 

		case '3' :
			value = CONV_SEG_3;
			break; 	

		case '4' :
			value = CONV_SEG_4;
			break;

		case '5' :
			value = CONV_SEG_5;
			break; 

		case '6' :
			value = CONV_SEG_6;
			break; 

		case '7' :
			value = CONV_SEG_7;
			break; 

		case '8' :
			value = CONV_SEG_8;
			break; 	

		case '9' :
			value = CONV_SEG_9;
			break;

		default: // "-"
			value = CONV_SEG_OFF;
			break;
	}
	return value;
}



/*
* Plasma signals
* GPIOOUT :
*          31 : enable game over
*		   30 downto 23 : ...
*		   22 downto 20 : select digit
*						  000 digit 0
*                		  001 digit 1
*                		  011 digit 2
*                		  010 digit 3
*                		  110 digit 4
*                		  111 digit 5
*                		  101 digit 6
*               		  100 digit 7
*          19 downto 13 : 7segments value
*          12 downto 10 : selection type of position
*                         000 pos ball col
*                         001 pos ball line
*                         011 pos obst1 col
*                         010 pos obst2 col
*                         110 pos obst1 line
*                         100 pos obst2 line  
*          9 downto 0 : positions (ball col/line, obst1 col/line, obst2 col/line)
*
* GPIOA_IN: 31 downto 14 : ...
*					  13 : BTNR (restart game)
*			12 downto 10 : SW (speed)
*           9 downto 0   : ACCEL_Y (ball_col)
*/
void game (void)
{
	int round = 0;
	int delay = 0;
	int timeout = 0;

	// Init Ball coordinates
	int ball_col = 0;
	int ball_line = 10;
	int last_ball_col = 0;
	
	// Init Obstacle 1 coordinates
	int obst1_col = 0;
	int obst1_line = 200;	

	// Init Obstacle 2 coordinates
	int obst2_col = 300;
	int obst2_line = 400;	

	// Init score
	scorecontrol(MODE_RST_SCORE);

	// Select Difficulty through SW (GPIOA 12-10)
	switch((MemoryRead(GPIOA_IN) & SW_2_0) >> SHIFT_SW)
	{
		case 1: // SW_2_0 = 001
			timeout = TIME_1;
			break;
		case 3: // SW_2_0 = 011
			timeout = TIME_2;
			break;
		case 7: // SW_2_0 = 111
			timeout = TIME_3;
			break;
		default:
			timeout = TIME_DEFAULT;
			break;		
	}

	// Disable GameOver
	GPIOWrite_GAMEOV(0);

	// Init column Ball position
	GPIOWrite_Position(ball_col,BALL_COL);

	// Init line Ball position
	GPIOWrite_Position(ball_line,BALL_LINE);

	// Init column Obstacle1 position
	GPIOWrite_Position(obst1_col,OBST_COL);

	// Init column Obstacle2 position
	GPIOWrite_Position(obst2_col,OBST2_COL);

	// Init line Obstacle1 position
	GPIOWrite_Position(obst1_line,OBST_LINE);

	// Init line Obstacle2 position
	GPIOWrite_Position(obst2_line,OBST2_LINE);


	for(round=0;;++round)
	{

		// Save previous ball column
		last_ball_col = ball_col;

		// Ball management (col) : Read Accelerometer Y (GPIOA 9-0)
		ball_col = (MemoryRead(GPIOA_IN) & ACCEL_Y);

		// Manage Right edge (left edge by FPGA)
		if (ball_col >= (SCREEN_W-BALL_LENGTH))
			ball_col = SCREEN_W-BALL_LENGTH; // Write Max ball position


		// Manage collision ball vs obst1
		if ( (ball_line <= obst1_line+OBST_H) && (ball_line+BALL_LENGTH > obst1_line) )
		{
			
			// Left edge obst1
			if ( (last_ball_col <= obst1_col) && (ball_col+BALL_LENGTH > obst1_col) )
				ball_col = obst1_col - BALL_LENGTH;

			// Right edge obst1
			if ( (last_ball_col >= obst1_col) && (ball_col < obst1_col+OBST_W) )
				ball_col = obst1_col+OBST_W;
			
		}

		// Manage collision ball vs obst2
		if ( (ball_line <= obst2_line+OBST_H) && (ball_line+BALL_LENGTH > obst2_line) )
		{

			// Left edge obst2
			if ( (last_ball_col <= obst2_col) && (ball_col+BALL_LENGTH > obst2_col) )
				ball_col = obst2_col - BALL_LENGTH;

			// Right edge obst2
			if ( (last_ball_col >= obst2_col) && (ball_col < obst2_col+OBST_W) )
				ball_col = obst2_col+OBST_W;
		}

		// Write ball_col
		GPIOWrite_Position(ball_col,BALL_COL);

		
		// Positions management
		// Delay
		delay++;

		if ( (ball_line > BALL_MIN_LINE) && (ball_line < BALL_MAX_LINE) && (delay == timeout) )
		{

			// Check ball and obstacle positions
			if ( ((ball_line+BALL_LENGTH == obst1_line) && (ball_col+BALL_HALF >= obst1_col ) && (ball_col+BALL_HALF < obst1_col+OBST_W)) ||
			     ((ball_line+BALL_LENGTH == obst2_line) && (ball_col+BALL_HALF >= obst2_col ) && (ball_col+BALL_HALF < obst2_col+OBST_W)) )
			{

				// Up ball
				GPIOWrite_Position(--ball_line,BALL_LINE);

				// increase score (only one time by obstacle)
				scorecontrol(MODE_INCR);
			
			}
			else
			{
				GPIOWrite_Position(++ball_line,BALL_LINE);
			
				// Enable increase score next obstacle
				scorecontrol(MODE_STEADY);
			}


			// New obstacle1
			if (obst1_line <= OBST_MIN_LINE)
			{
				obst1_line = SCREEN_H;
				obst1_col = rand();				
			}

			// New obstacle2
			if (obst2_line <= OBST_MIN_LINE)
			{
				obst2_line = SCREEN_H;
				obst2_col = rand();			
			}

			// To respect loop on code GRAY
			GPIOWrite_Position(obst1_col,OBST_COL);
			GPIOWrite_Position(obst2_col,OBST2_COL);

			// Up Obstacle 1 management (line)
			GPIOWrite_Position(--obst1_line,OBST_LINE);
			
			// Up Obstacle 2 management (line)
			GPIOWrite_Position(--obst2_line,OBST2_LINE);

			// Reset delay
			delay = 0;

		}
		
		// Manage GAME OVER
		if ( (ball_line <= BALL_MIN_LINE) || (ball_line >= BALL_MAX_LINE) )
		{
			GPIOWrite_GAMEOV(1);
			
			// Manage restart game BTNR (GPIOA 13)
			if ( (MemoryRead(GPIOA_IN) & BTNR) >> SHIFT_BTNR )
			{
				// Manage best score on 7segs
				scorecontrol(MODE_SAVE);

				// go out of loop
				break;
			}
		}

	}
}


int main(void)
{
	// LAUNCH BOOTLOADER ONLY TO CREATE IMAGE, SEND test.bin through UART (compiled program)
	//boot();

	// THEN, COMPILE THE SOFT BELOW
	int i = 0;

	// Init record & score
	scorecontrol(MODE_RST_ALL);

	// Start of Game (loop)
	for(i=0;;i++)
		game();
}


