%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <iostream>
#include <string>
#include "global.h"

int yylex(void);
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runSetEnv(char* arg1, char* arg2);
void runPrintAlias(void);
int runUnalias(std::string name);
//struct aTable aliasTable;

std::unordered_map<std::string,std::string> aliases;

%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS END SETENV

%%
cmd_line    :
	BYE END 		                {exit(1); return 1;}
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| ALIAS END						{runPrintAlias(); return 1;}
	| UNALIAS STRING END			{runUnalias($2); return 1;}
	| SETENV STRING STRING END		{runSetEnv($2, $3); return 1;}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int runCD(char* arg) {

	if (arg[0] != '/') { // arg is relative path
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			
			strcpy(varTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(varTable.word[0], arg);
			return 1;
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
}

int runSetAlias(char *name, char *word) {
	// for (int i = 0; i < aliasIndex; i++) {
	// 	if(strcmp(name, word) == 0){
	// 		printf("Error, expansion of \"%s\" would create a loop.\n", name);
	// 		return 1;
	// 	}
	// 	else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
	// 		printf("Error, expansion of \"%s\" would create a loop.\n", name);
	// 		return 1;
	// 	}
	// 	else if(strcmp(aliasTable.name[i], name) == 0) {
	// 		strcpy(aliasTable.word[i], word);
	// 		return 1;
	// 	}
	// }
	//strcpy(aliasTable.name[aliasIndex], name);
	//strcpy(aliasTable.word[aliasIndex], word);
	aliases[name] = word;	
	aliasIndex++;

	return 1;
}

int runSetEnv(char* arg1, char* arg2)
{
	//printf("PRINTENV WORKS FOR NOW\n");
	//printf("s", arg1);

	return 1;
}

void runPrintAlias(void)
{
	if (aliasIndex == 0)
	{
		printf("%s", "No aliases set\n");
		return;
	}
	// for (int i = 0; i < aliasIndex; i++)
	// {
	// 	printf("Alias name: %s; Alias word: %s\n", aliasTable.name[i], aliasTable.word[i]);
	// }
	for (auto& it : aliases)
	{
		std::cout << it.first << "=" << it.second << std::endl; 
	}
}

int runUnalias(std::string name)
{
	//std::cout << name << std::endl;
	for (auto& it : aliases)
	{
		//std::cout << it.first << " " << it.second << std::endl;
		if (it.first.compare(name) == 0)
		{

			aliases.erase(name);
			//std::cout << "ERASED ALIAS" << std::endl;
			aliasIndex--;
			return 1;
		}
		else
		{
			//std::cout << "Alias does not exist!" << std::endl;
			//return 1;
		}	
	}
	return 1;
}