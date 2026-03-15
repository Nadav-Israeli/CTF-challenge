#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void win() {
    printf("You win! here is your flag");
    system("/bin/cat flag.txt");
}

void getData(char* buf, unsigned int len) {
    printf("enter buffer\n");
    read(0, buf, len);
}

int main() {
    int length;
    char buf[64];

    while (1) {
        printf("enter length\n");

        scanf("%d", &length);
        if (length > 64) {
            printf("message too long");
            return 0;
        }

        getData(buf, length);
        printf("%s\n", buf);
    }
}