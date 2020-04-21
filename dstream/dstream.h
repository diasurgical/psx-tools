#ifndef __DSTREAM_H__
#define __DSTREAM_H__

typedef struct VagBlock {
	unsigned short block_num;
	unsigned short unk02;
	unsigned short block_size; // sizeof(VagBlock) + VAG_CHUNK
	unsigned short unk06;
	char unk08[120];
} VagBlock;

#define VAG_MAGIC    0x56414770 // 'VAGp'
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

#ifndef OLD_STREAM_VERSION

typedef struct STREAM {
	unsigned long Offset;
	unsigned long Size;
	unsigned char Name[12];
} STREAM;

#else

typedef struct STREAM {
	unsigned long Offset;
	int unk04;
	unsigned long Size;
	int unk0c[3];
	unsigned char Name[12];
	int unk24[9];
} STREAM;

#endif

#define LDIR_MAGIC   0x4c444952 // 'LDIR'
typedef struct LDIRS {
	int magic;
	int ncount;
	STREAM stream;
} LDIRS;

#endif
