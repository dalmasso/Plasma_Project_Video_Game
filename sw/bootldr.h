/*--------------------------------------------------------------------
 * TITLE: Plasma Bootloader
 * AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
 * DATE CREATED: 12/17/05
 * FILENAME: bootldr.c
 * PROJECT: Plasma CPU core
 * COPYRIGHT: Software placed into the public domain by the author.
 *    Software 'as is' without warranty.  Author liable for nothing.
 * DESCRIPTION:
 *    Plasma bootloader.
 *--------------------------------------------------------------------*/
#include "plasma.h"

extern int putchar(int ch);
extern int puts(const char *string);
extern int getch(void);
extern int kbhit(void);

/*--------------------------------------------------------------------
 * TITLE: Plasma DDR Initialization
 * AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
 * DATE CREATED: 12/17/05
 * FILENAME: ddr_init.c
 * PROJECT: Plasma CPU core
 * COPYRIGHT: Software placed into the public domain by the author.
 *    Software 'as is' without warranty.  Author liable for nothing.
 * DESCRIPTION:
 *    Plasma DDR Initialization
 *    Supports 64MB (512Mb) MT46V32M16 by default.
 *    For 32 MB and 128 MB DDR parts change AddressLines and Bank shift:
 *    For 32 MB change 13->12 and 11->10.  MT46V16M16
 *    For 128 MB change 13->14 and 11->12. MT46V64M16
 *--------------------------------------------------------------------*/
#define DDR_BASE 0x10000000


//SD_A  <= address_reg(25 downto 13);  --address row
//SD_BA <= address_reg(12 downto 11);  --bank_address
//cmd   := address_reg(6 downto 4);    --bits RAS & CAS & WE
int DdrInitData[] = {
// AddressLines    Bank        Command
   (0x000 << 13) | (0 << 11) | (7 << 4),  //CKE=1; NOP="111"
   (0x400 << 13) | (0 << 11) | (2 << 4),  //A10=1; PRECHARGE ALL="010"
#ifndef DLL_DISABLE
   (0x000 << 13) | (1 << 11) | (0 << 4),  //enable DLL; BA="01"; LMR="000"
#else
   (0x001 << 13) | (1 << 11) | (0 << 4),  //disable DLL; BA="01"; LMR="000"
#endif
   (0x121 << 13) | (0 << 11) | (0 << 4),  //reset DLL, CL=2, BL=2; LMR="000"
   (0x400 << 13) | (0 << 11) | (2 << 4),  //A10=1; PRECHARGE ALL="010" 
   (0x000 << 13) | (0 << 11) | (1 << 4),  //AUTO REFRESH="001"
   (0x000 << 13) | (0 << 11) | (1 << 4),  //AUTO REFRESH="001
   (0x021 << 13) | (0 << 11) | (0 << 4)   //clear DLL, CL=2, BL=2; LMR="000"
};

int DdrInit(void)
{
   int i, j, k=0;
   for(i = 0; i < sizeof(DdrInitData)/sizeof(int); ++i)
   {
      MemoryWrite(DDR_BASE + DdrInitData[i], 0);
      for(j = 0; j < 4; ++j)
         ++k;
   }
   for(j = 0; j < 100; ++j)
      ++k;
   k += MemoryRead(DDR_BASE);  //Enable DDR
   return k;
}

typedef void (*FuncPtr)(void);
typedef unsigned long uint32;
typedef unsigned short uint16;


void FlashRead(uint16 *dst, uint32 byteOffset, int bytes)
{
   volatile uint32 *ptr=(uint32*)(FLASH_BASE + (byteOffset << 1));
   *ptr = 0xff;                   //read mode
   while(bytes > 0)
   {
      *dst++ = (uint16)*ptr++;
      bytes -= 2;
   }
}


void FlashWrite(uint16 *src, uint32 byteOffset, int bytes)
{
   volatile uint32 *ptr=(uint32*)(FLASH_BASE + (byteOffset << 1));
   while(bytes > 0)
   {
      *ptr = 0x40;                //write mode
      *ptr++ = *src++;            //write data
      while((*ptr & 0x80) == 0)   //check status
         ;
      bytes -= 2;
   }
}


void FlashErase(uint32 byteOffset)
{
   volatile uint32 *ptr=(uint32*)(FLASH_BASE + (byteOffset << 1));
   *ptr = 0x20;                   //erase block
   *ptr = 0xd0;                   //confirm
   while((*ptr & 0x80) == 0)      //check status
      ;
}


char *xtoa(unsigned long num)
{
   static char buf[12];
   int i, digit;
   buf[8] = 0;
   for (i = 7; i >= 0; --i)
   {
      digit = num & 0xf;
      buf[i] = digit + (digit < 10 ? '0' : 'A' - 10);
      num >>= 4;
   }
   return buf;
}


unsigned long getnum(void)
{
   int i;
   unsigned long ch, ch2, value=0;
   for(i = 0; i < 16; )
   {
      ch = ch2 = getch();
      if(ch == '\n' || ch == '\r')
         break;
      if('0' <= ch && ch <= '9')
         ch -= '0';
      else if('A' <= ch && ch <= 'Z')
         ch = ch - 'A' + 10;
      else if('a' <= ch && ch <= 'z')
         ch = ch - 'a' + 10;
      else if(ch == 8)
      {
         if(i > 0)
         {
            --i;
            putchar(ch);
            putchar(' ');
            putchar(ch);
         }
         value >>= 4;
         continue;
      }
      putchar(ch2);
      value = (value << 4) + ch;
      ++i;
   }
   putchar('\r');
   putchar('\n');
   return value;
}


int boot(void)
{
   int i, j, ch;
   unsigned long address, value, count;
   FuncPtr funcPtr;
   unsigned char *ptr1;

   DdrInit();  //Harmless if SDRAM instead of DDR

   puts("\nGreetings from the bootloader ");
   puts(__DATE__);
   puts(" ");
   puts(__TIME__);
   puts(":\n");
   MemoryWrite(FLASH_BASE, 0xff);  //read mode
   if((MemoryRead(GPIOA_IN) & 1) && (MemoryRead(FLASH_BASE) & 0xffff) == 0x3c1c)
   {
      puts("Boot from flash\n");
      FlashRead((uint16*)RAM_EXTERNAL_BASE, 0, 1024*128);
      funcPtr = (FuncPtr)RAM_EXTERNAL_BASE;
      funcPtr();
   }
   for(;;)
   {
      puts("\nWaiting for binary image linked at 0x10000000\n");
      puts("Other Menu Options:\n");
      puts("1. Memory read word\n");
      puts("2. Memory write word\n");
      puts("3. Memory read byte\n");
      puts("4. Memory write byte\n");
      puts("5. Jump to address\n");
      puts("6. Raw memory read\n");
      puts("7. Raw memory write\n");
      puts("8. Checksum\n");
      puts("9. Dump\n");
      puts("F. Copy 128KB from DDR to flash\n");
      puts("> ");
      ch = getch();
      address = 0;
      if('0' <= ch && ch <= '9')
      {
         putchar(ch);
         puts("\nAddress in hex> ");
         address = getnum();
         puts("Address = ");
         puts(xtoa(address));
         puts("\n");
      }
      switch(ch)
      {
      case '1':
         value = MemoryRead(address);
         puts(xtoa(value));
         puts("\n");
         break;
      case '2':
         puts("\nValue in hex> ");
         value = getnum();
         puts(xtoa(value));
         MemoryWrite(address, value);
         break;
      case '3':
         value = *(unsigned char*)address;
         puts(xtoa(value));
         puts("\n");
         break;
      case '4':
         puts("\nValue in hex> ");
         value = getnum();
         puts(xtoa(value));
         *(unsigned char*)address = value;
         break;
      case '5':
         funcPtr = (FuncPtr)address;
         funcPtr();
         break;
      case '6':
         puts("\nCount in hex> ");
         count = getnum();
         for(i = 0; i < count; ++i)
         {
            ch = *(unsigned char*)(address + i);
            putchar(ch);
         }
         break;
      case '7':
         puts("\nCount in hex> ");
         count = getnum();
         for(i = 0; i < count; ++i)
         {
            ch = getch();
            *(unsigned char*)(address+i) = ch;
         }
         break;
      case '8':
         puts("\nCount in hex> ");
         count = getnum();
         value = 0;
         for(i = 0; i < count; ++i)
         {
            value += *(unsigned char*)(address+i);
         }
         puts(xtoa(value));
         putchar('\n');
         break;
      case '9':
         puts("\nCount in hex> ");
         count = getnum();
         value = 0;
         for(i = 0; i < count; i += 4)
         {
            if((i & 15) == 0)
               puts("\r\n");
            value = *(unsigned long*)(address+i);
            puts(xtoa(value));
            putchar(' ');
         }
         puts("\r\n");
         break;
      case 'F':
         puts("\nConfirm with 12345678> ");
         value = getnum();
         if(value == 0x12345678)
         {
            FlashErase(0);
            FlashWrite((uint16*)RAM_EXTERNAL_BASE, 0, 1024*128);
         }
         break;
      case 0x3c:   //raw test.bin file
         ptr1 = (unsigned char*)0x10000000;
         for(i = 0; i < 1024*1024; ++i)
         {
            ptr1[i] = (unsigned char)ch;
            for(j = 0; j < 32768; ++j)
            {
               if(kbhit())
                  break;
            }
            if(j >= 32768)
               break;       //assume end of file
            ch = getch();
         }
         funcPtr = (FuncPtr)0x10000000;
         funcPtr();
         break;
      }
   }
   return 0;
}