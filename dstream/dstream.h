#ifndef __DSTREAM_H__
#define __DSTREAM_H__

#include <stdint.h>

typedef struct VagBlock {
	uint16_t block_num;
	uint16_t unk02;
	uint16_t block_size; // sizeof(VagBlock) + VAG_CHUNK
	uint16_t unk06;
	uint8_t unk08[120];
} VagBlock;

#define VAG_MAGIC    0x56414770 // 'VAGp'
typedef struct VagHeader {
	int32_t magic;
	int32_t version;
	int32_t field8;
	int32_t size;
	int32_t rate;
	int32_t field14;
	int32_t field18;
	int32_t field1C;
	char name[16];
} VagHeader;

#ifndef OLD_STREAM_VERSION

typedef struct STREAM {
	uint32_t Offset;
	uint32_t Size;
	char Name[12];
} STREAM;

#else

typedef struct STREAM {
	uint32_t Offset;
	uint32_t unk04;
	uint32_t Size;
	uint32_t unk0c[3];
	char Name[12];
	uint32_t unk24[9];
} STREAM;

#endif

#define LDIR_MAGIC   0x4c444952 // 'LDIR'
typedef struct LDIRS {
	int32_t magic;
	int32_t ncount;
	STREAM stream;
} LDIRS;

#endif
