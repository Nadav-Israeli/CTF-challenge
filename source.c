#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

void win() {
	printf("You win! here is your flag");
    system("/bin/cat flag.txt");
}

int main() {
    int length;
    char buf[64];

	scanf("%d", &length);
	if(length >= 64) {
		printf("message too long");
		return 0;
	}

	read(0, buf, length);
	printf("%s", buf);

	return 0;
}
