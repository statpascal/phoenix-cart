#include <arpa/inet.h>
#include <cstdint>
#include <stdio.h>

int main (int argc, char **argv) {
    FILE *f = fopen (argv [1], "rb");
    std::uint8_t val;
    int count1 = 0;
    

    while (!feof (f)) {
        fread (&val, 1, 1, f);
        if (!count1)
            putchar ('(');
        printf ("$%02x", val);
        if (++count1 == 8) {
            count1 = 0;
            printf ("),\n");
        } else
            printf (", ");
    }
    fclose (f);
}