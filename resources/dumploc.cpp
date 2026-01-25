#include <arpa/inet.h>
#include <cstdint>
#include <stdio.h>

const char *piece [] = {"White Pawn", "Black Pawn", "Knight", "Bishop", "King Midgage", "King Endgame"};

int main (int argc, char **argv) {
    FILE *f = fopen (argv [1], "rb");
    std::int16_t val;
    int count1 = 0, count2 = 0, header = 0;
    

    while (!feof (f)) {
        fread (&val, 2, 1, f);
        printf ("%5d,", static_cast<std::int16_t> (ntohs (val)));
        if (++count1 == 8) {
            count1 = 0;
            putchar ('\n');
            if (++count2 == 8) {
                count2 = 0;
                printf (piece [header]);
                putchar ('\n');
                putchar ('\n');
                ++header;
            }
        }
    }
    fclose (f);
}