// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "global.h"
#include <unistd.h>
#include <cstddef>

extern char *getcwd(char *buf, size_t size);
int yyparse();
int aliasIndex, varIndex;
char cwd[PATH_MAX];
struct evTable varTable;
std::vector<std::string> myPaths;
void parsePaths(const char* path);
void clearPaths();

int main()
{
    aliasIndex = 0;
    varIndex = 0;

    getcwd(cwd, sizeof(cwd));

    strcpy(varTable.var[varIndex], "PWD");
    strcpy(varTable.word[varIndex], cwd);
    varIndex++;
    strcpy(varTable.var[varIndex], "HOME");
    strcpy(varTable.word[varIndex], cwd);
    varIndex++;
    strcpy(varTable.var[varIndex], "PROMPT");
    strcpy(varTable.word[varIndex], "nutshell");
    varIndex++;
    strcpy(varTable.var[varIndex], "PATH");
    const char* path = getenv("PATH");
    strcpy(varTable.word[varIndex], path);
    parsePaths(path);
    if(1){
    	std::string temp(cwd);
	    myPaths.push_back(temp);
    }
    varIndex++;



    system("clear");
    while(1)
    {
        printf("[%s~%s]>> ", varTable.word[2], varTable.word[0]);
        //printf("%s\n", getcwd(cwd, sizeof(cwd)));

        yyparse();
    }

    //Freeing memory
    clearPaths();
   return 0;
}

void parsePaths(const char* path){
	std::string str(path);
	std::string new_s;
	std::size_t found = str.find_first_of(":");
	int i = 0;

	//check if first character
	//Find and separate all words
	while(found != std::string::npos){
		if(found == 0){
			str = str.substr(found+1);
			found = str.find_first_of(":");
		}
		//printf( "%d: %s\n", i, str.substr(0, found).c_str());
		myPaths.push_back(str.substr(0,found).c_str());
		i++;
		str = str.substr(found+1);
		found = str.find_first_of(":");
	}
	//printf("%d: %s\n", i, str.c_str());
	myPaths.push_back(str.c_str());
}

void clearPaths(){
	int size = myPaths.size();
	for (int i=0;i<size;i++)
		myPaths.pop_back();
}