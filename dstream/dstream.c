#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// uncomment to use old version, for early alpha PSX builds
// #define OLD_STREAM_VERSION
#include "dstream.h"

// most PSX sounds use 11025, but some are 22050 or 8000
#define VAG_RATE_HZ  11025

// max file types in command line
#define MAX_EXTENSIONS 8
int numexts = 0;
int extmode = 0;
char extensions[MAX_EXTENSIONS][4 + 1];

unsigned char *LoadBinaryFile(char *file, int *pdwSize)
{
	unsigned char *p;
	FILE *fp;
	int bufsize;

	fp = fopen(file, "rb");

	if(fp == NULL) {
		fprintf(stderr, "Can't open file %s\n", file);
		exit(-1);
	}

	fseek(fp, 0L, SEEK_END);
	bufsize = ftell(fp);
	p = (unsigned char *)malloc(sizeof(unsigned char) * (bufsize + 1));
	fseek(fp, 0L, SEEK_SET);
	fread(p, sizeof(char), bufsize, fp);
	fclose(fp);

	if(pdwSize != NULL) {
		*pdwSize = bufsize;
	}

	return p;
}

void DumpRegularFile(STREAM *pStream, unsigned char *pBin)
{
	FILE *pOutput;
	unsigned char *p;
	unsigned long checksum, computed;
	int i, filesize;

	pOutput = fopen(pStream->Name, "wb");

	if(pOutput == NULL) {
		fprintf(stderr, "Can't create file %s\n", pStream->Name);
		exit(-1);
	}

	if((int)pStream->Size <= 0) {
		printf("Warning: file %s is empty\n", pStream->Name);
		fclose(pOutput);
		return;
	}

	p = &pBin[pStream->Offset];
	checksum = ((unsigned long *)p)[0];
	p += 4; /* actual data after checksum */
	fwrite(p, sizeof(char), pStream->Size, pOutput);
	fclose(pOutput);

	p = LoadBinaryFile(pStream->Name, &filesize);

	computed = 0;
	for(i = 0; i < filesize; i++) { /* compute a Sum32 checksum, sum of all bytes */
		computed += p[i];
	}
	free(p);

	if(checksum != computed) {
		printf("Warning: %s checksum 0x%08X, computed 0x%08X\n", pStream->Name, checksum, computed);
	}
}

int SwapEndian32(int val)
{
	return ((val & 0xFF) << 24) | (((val >> 8) & 0xFF) << 16) | (((val >> 16) & 0xFF) << 8) | ((val >> 24) & 0xFF);
}

void WriteVAGHeader(FILE *pFile, STREAM *pStream)
{
	VagHeader fileHead;

	memset(&fileHead, 0, sizeof(fileHead));

	fileHead.magic = SwapEndian32(VAG_MAGIC);
	fileHead.version = SwapEndian32(4);
	fileHead.size = SwapEndian32(pStream->Size);
	fileHead.rate = SwapEndian32(VAG_RATE_HZ);
	strcpy(fileHead.name, pStream->Name);

	fwrite(&fileHead, sizeof(char), sizeof(fileHead), pFile);
}

void WriteVAGChunks(FILE *pFile, STREAM *pStream, unsigned char *pBin)
{
	int i, size;
	unsigned char *p;
	VagBlock *pBlock;

	p = &pBin[pStream->Offset];
	i = 0;
	while(i < (int)pStream->Size) {
		pBlock = (VagBlock *)p;
		size = pBlock->block_size - sizeof(VagBlock);
		p += sizeof(VagBlock);
		fwrite(p, sizeof(char), size, pFile);
		p += size;
		i += size;
	}
}

void DumpVagFile(STREAM *pStream, unsigned char *pBin)
{
	int written;
	FILE *pOutput;

	pOutput = fopen(pStream->Name, "wb");

	if(pOutput == NULL) {
		fprintf(stderr, "Can't create file %s\n", pStream->Name);
		exit(-1);
	}

	if((int)pStream->Size <= 0) {
		printf("Warning: file %s is empty\n", pStream->Name);
		fclose(pOutput);
		return;
	}

	WriteVAGHeader(pOutput, pStream);
	WriteVAGChunks(pOutput, pStream, pBin);

	written = ftell(pOutput);
	written -= sizeof(VagHeader);

	fclose(pOutput);

	if(written != (int)pStream->Size) {
		fprintf(stderr, "Didn't write correct bytes: %s\n", pStream->Name);
		fprintf(stderr, "Wrote %d, should have wrote %d\n", written, pStream->Size);
		exit(-1);
	}
}

int DumpByExt(STREAM *pStream, unsigned char *pBin)
{
	int i, j, l;
	char name[sizeof(pStream->Name) + 1];
	char ext[4 + 1];
	int found;

	memset(name, 0, sizeof(name));
	memset(ext, 0, sizeof(ext));

	sprintf(name, "%s", pStream->Name);
	l = strlen(name);

	for(i = 0; i < l; i++) {
		if(name[i] == '.') {
			i++;
			for(j = 0; j < sizeof(ext); j++) {
				if(name[j + i] != '\0') {
					ext[j] = name[j + i];
				}
			}
			strlwr(ext);
			if(extmode) {
				found = 0;
				for(j = 0; j < numexts && !found; j++) {
					found = strcmp(ext, extensions[j]) == 0;
				}
			} else {
				found = 1;
			}
			if(found) {
				printf("Dumping: %s\n", name);
				if(strcmp(ext, "vag") == 0) {
					DumpVagFile(pStream, pBin);
				} else {
					DumpRegularFile(pStream, pBin);
				}
				return 1;
			}
			break;
		}
	}

	return 0;
}

int main(int argc, char *argv[])
{
	char *pszDirFile, *pszBinFile;
	char **pszFileTypes;
	unsigned char *pDir, *pBin;
	LDIRS *ppDir;
	STREAM *pStream;
	int i, dircount, dumpcount;

	if(argc < 3 || argc > 3 + MAX_EXTENSIONS) {
		fprintf(stderr, "Usage: dstream [dir] [bin] [types...]\n");
		return 0;
	}
	pszDirFile = argv[1];
	pszBinFile = argv[2];
	pszFileTypes = NULL;
	if(argc > 3) {
		pszFileTypes = &argv[3];
		extmode = 1;
		numexts = argc - 3;
		if(numexts > MAX_EXTENSIONS) {
			numexts = MAX_EXTENSIONS;
		}
		memset(extensions, 0, sizeof(extensions));
		for(i = 0; i < numexts; i++) {
			strncpy(extensions[i], pszFileTypes[i], 4);
			strlwr(extensions[i]);
		}
	}

	pDir = LoadBinaryFile(pszDirFile, NULL);
	ppDir = (LDIRS *)pDir;

	if(ppDir->magic != SwapEndian32(LDIR_MAGIC)) {
		fprintf(stderr, "%s is not a valid DIR file\n", pszDirFile);
	} else {
		dircount = ppDir->ncount;
		pStream = &ppDir->stream;
		pBin = LoadBinaryFile(pszBinFile, NULL);
		dumpcount = 0;
		for(i = 0; i < dircount; i++) {
			if(DumpByExt(&pStream[i], pBin)) {
				dumpcount++;
			}
		}
		if(dumpcount != 0) {
			printf("Successfully dumped %d/%d files\n", dumpcount, dircount);
		} else {
			printf("No files found or error dumping");
		}
		free(pBin);
	}

	free(pDir);

	return 0;
}
