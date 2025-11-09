#include <iostream>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <cctype>

std::ofstream fout ("/home/goose/src/phoenix/keyin_fifo");
std::ifstream fin ("/home/goose/src/phoenix/rs232");
std::ofstream f ("/home/goose/log.txt");

void sendMove (const std::string &s) {
    f << "Sending to PHOENIX: " << s << std::endl;
    fout << s << std::endl;
    fout.flush ();
}

std::string getReply () {
    std::string s;
    char c;
    do {
        fin.clear ();
        if (fin >> c)
            if (c >= '0' && c <= 'Z')
                s.push_back (c);
    } while (s.length () != 4);
    f << "Receiving from PHOENIX: " << s << std::endl;
    std::transform (s.begin (), s.end (), s.begin (), [] (unsigned char c) { return std::tolower (c); });
    return s;
}

int main () {

    std::string s;
    
    std::getline (std::cin, s);
    f << s << std::endl;
    if (s == "uci")
        std::cout << "id name PHOENIX" << std::endl
                  << "id author Vorticon" << std::endl
                  << "option name OwnBook type check default true" << std::endl
                  << "uciok" << std::endl;
    std::getline (std::cin, s);
    f << s << std::endl;
    if (s == "isready")
        std::cout << "readyok" << std::endl;

    do {
        getline (std::cin, s);
        if (!s.empty ()) {
//            f << s << std::endl;
            if (s.substr (0, 23) == "position startpos moves") 
                sendMove (s.substr (s.size () - 4));
            if (s.substr (0, 2) == "go") 
                std::cout << "bestmove " << getReply ();
        }
    } while (s != "quit");
        
    
}