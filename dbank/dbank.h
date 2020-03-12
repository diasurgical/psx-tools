#ifndef __DBANK_H__
#define __DBANK_H__

typedef struct VagHeader {
	int magic;
	int version;
	int field8;
	int size;
	int rate;
	int field14;
	int field18;
	int field1C;
	char name[16];
} VagHeader;

#ifndef OLD_BANK_VERSION

typedef struct bank_entry {
	unsigned short Name;
	unsigned long offset;
	unsigned short len;
	unsigned short pitch;
} bank_entry;

#else

typedef struct bank_entry {
	unsigned char Name[8];
	unsigned long offset;
	unsigned short len;
	unsigned short pitch;
} bank_entry;

#endif

#endif
