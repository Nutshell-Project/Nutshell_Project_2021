#include "stdbool.h"
#include <limits.h>
#include <unordered_map>
#include <vector>


struct evTable {
   char var[128][100];
   char word[128][100];
};

struct aTable {
	char name[128][100];
	char word[128][100];
   
};

extern char cwd[PATH_MAX];

extern struct evTable varTable;

extern struct aTable aliasTable;

extern int aliasIndex, varIndex;

char* subAliases(char* name);

extern std::unordered_map<std::string,std::string> aliases;

extern std::unordered_map<std::string,std::string> variables;

extern std::unordered_map<std::string, std::vector<char*>> commands;


extern bool unaliasCheck;

extern bool runAlias;

