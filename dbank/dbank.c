#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// uncomment to use old version, for early alpha PSX builds
// #define OLD_BANK_VERSION
#include "dbank.h"

unsigned char *LoadBinaryFile(char *file, int *bufsize)
{
	unsigned char *p;
	FILE *fp;

	fp = fopen(file, "rb");

	if(fp == NULL) {
		fprintf(stderr, "Can't open file %s\n", file);
		exit(-1);
	}

	fseek(fp, 0L, SEEK_END);
	*bufsize = ftell(fp);
	p = (unsigned char *)malloc(sizeof(unsigned char) * (*bufsize + 1));
	fseek(fp, 0L, SEEK_SET);
	fread(p, sizeof(char), *bufsize, fp);
	fclose(fp);
	return p;
}

int SwapEndian32(int val)
{
	return ((val & 0xFF) << 24) | (((val >> 8) & 0xFF) << 16) | (((val >> 16) & 0xFF) << 8) | ((val >> 24) & 0xFF);
}

int GetVagRate(bank_entry *pBank, char *name)
{
	// experimental: seems to work but may not always be correct
	// return (int)(pBank->pitch * 10.7675);

	switch(pBank->pitch) {
	case 0x400:
		return 11025;
	case 0x2E7:
		return 8000;
	}

	fprintf(stderr, "%s: Unknown pitch 0x%04X\n", name, pBank->pitch);
	exit(-1);
}

void WriteVAGHeader(FILE *pFile, bank_entry *pBank, char *name)
{
	VagHeader fileHead;

	memset(&fileHead, 0, sizeof(fileHead));

	fileHead.magic = SwapEndian32('VAGp');
	fileHead.version = SwapEndian32(4);
	fileHead.size = SwapEndian32(pBank->len);
	fileHead.rate = SwapEndian32(GetVagRate(pBank, name));
	strcpy(fileHead.name, name);

	fwrite(&fileHead, sizeof(char), sizeof(fileHead), pFile);
}

void WriteVAGChunks(FILE *pFile, bank_entry *pBank, unsigned char *pBnk)
{
	unsigned char *p;

	p = &pBnk[pBank->offset];
	fwrite(p, sizeof(char), pBank->len, pFile);
}

void DumpVagFile(bank_entry *pBank, unsigned char *pBnk)
{
	int written;
	FILE *pOutput;
	char name[8 + 4 + 1];

	memset(name, 0, sizeof(name));
#ifndef OLD_BANK_VERSION
	sprintf(name, "%04X.VAG", pBank->Name);
#else
	strncpy(name, pBank->Name, sizeof(pBank->Name));
	sprintf(name, "%s.VAG", name);
#endif

	printf("Dumping: %s\n", name);

	pOutput = fopen(name, "wb");

	if(pOutput == NULL) {
		fprintf(stderr, "Can't create file %s\n", name);
		exit(-1);
	}

	WriteVAGHeader(pOutput, pBank, name);
	WriteVAGChunks(pOutput, pBank, pBnk);

	written = ftell(pOutput);
	written -= sizeof(VagHeader);

	fclose(pOutput);

	if(written != (int)pBank->len) {
		fprintf(stderr, "Didn't write correct bytes: %s\n", name);
		fprintf(stderr, "Wrote %d, should have wrote %d\n", written, pBank->len);
		exit(-1);
	}
}

int main(int argc, char *argv[])
{
	char *pszBofFile, *pszBnkFile;
	bank_entry *pBank;
	unsigned char *pBof, *pBnk;
	int i, bofcount, bnksize, dumpcount;

	if(argc != 3) {
		fprintf(stderr, "Usage: dbank [bof] [bnk]\n");
		return 0;
	}
	pszBofFile = argv[1];
	pszBnkFile = argv[2];

	pBof = LoadBinaryFile(pszBofFile, &bofcount);
	bofcount /= sizeof(bank_entry);

	if(bofcount <= 0) {
		fprintf(stderr, "%s is empty\n", pszBofFile);
		free(pBof);
		return 0;
	}

	pBank = (bank_entry *)pBof;
	pBnk = LoadBinaryFile(pszBnkFile, &bnksize);

	dumpcount = 0;
	for(i = 0; i < bofcount; i++) {
		if(pBank[i].len != 0) {
			DumpVagFile(&pBank[i], pBnk);
			dumpcount++;
		}
	}

	if(dumpcount != 0) {
		printf("Successfully dumped %d/%d files\n", dumpcount, bofcount);
	} else {
		printf("No files found or error dumping");
	}

	free(pBnk);
	free(pBof);

	return 0;
}
