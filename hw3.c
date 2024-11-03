#include "preimplemented.h"
#include "implementation.h"


/* insert 명령어 처리 */
void insert_command(HashTable* HT) {
	Record newRecord;

	printf("Enter (title, artist, streams, dailyStreams) to insert : ");
	char line[MAX_LINE];
	fgets(line, MAX_LINE, stdin);
	sscanf(line, "%[^,],%[^,],%lld,%lld", newRecord.key, newRecord.artist, &newRecord.streams, &newRecord.dailyStreams);
	newRecord.link = -1;

	int result = insertHash(HT, newRecord);
	
	if (result == -1)
		printf("Insert failed\n");
	else
		printf("Insert success (probe count: %d)\n", result);

}


/* search 명령어 처리 */
void search_command(HashTable* HT) {
	printf("Enter title to search : ");
	char key[MAX_CHAR];

	fgets(key, MAX_CHAR, stdin);
	key[strcspn(key, "\n")] = 0;

	SearchRes result = searchHash(HT, key);
	if (result.success) {
		printf("Search success (probe count: %d)\n", result.probe_cnt);
		printf("Index: %d\n", result.index);
		printf("Title: %s\n", HT->table[result.index].key);
		printf("Artist: %s\n", HT->table[result.index].artist);
		printf("Streams: %lld\n", HT->table[result.index].streams);
		printf("Daily Streams: %lld\n", HT->table[result.index].dailyStreams);
	}
	else
		printf("Search failed\n");
}


/* delete 명령어 처리 */
void delete_command(HashTable* HT) {
	printf("Enter title to delete : ");
	char key[MAX_CHAR];

	fgets(key, MAX_CHAR, stdin);
	key[strcspn(key, "\n")] = 0;

	int chain_split = 0;
	int result = deleteHash(HT, key, &chain_split);

	if (result == -1)
		printf("Delete failed\n");
	else {
		printf("Delete success\n");
		printf("Chain split count: %d\n", chain_split);
		printf("Record move count: %d\n", result);
	}
}


/* main 함수 */
int main() {

	// 해시 테이블 생성
	HashTable* HT = createHashTable();
	constructHashTable(HT, "./data.csv");

	int command;

	// 명령어 입력 처리
	while (true) {
		printf("\n=================\n");
		printf("    1. insert\n");
		printf("    2. search\n");
		printf("    3. delete\n");
		printf("    0. exit\n");
		printf("=================\n>>> ");

		scanf("%d", &command);
		getchar();

		switch (command) {
		case 0:
			return 0;
		case 1:
			insert_command(HT);
			break;
		case 2:
			search_command(HT);
			break;
		case 3:
			delete_command(HT);
			break;
		default:
			printf("Invalid command\n");
		}
	}

	return 0;
}