%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <iostream>
#include <string>
#include "global.h"
#include <sys/types.h>
#include <pwd.h>
#include <sys/wait.h>

int yylex(void);
int yyerror(char *s);
int runCD_home();
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runSetEnv(char* arg1, char* arg2);
int runUnSetenv(std::string name);
void runPrintEnv(void);
void runPrintAlias(void);
int runUnalias(std::string name);
int runCommand(char* name);
//struct aTable aliasTable;
bool unaliasCheck;
bool runAlias;
std::vector<char*> currentArgs;


std::unordered_map<std::string,std::string> aliases;

std::unordered_map<std::string,std::string> variables;

std::unordered_map<std::string, std::vector<char*>> commands;



%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS END SETENV UNSETENV PRINTENV COMMAND //INPUT

%%
cmd_line    :
	BYE END						{exit(1); return 1;}
	| CD END					{runCD_home(); return 1;}
	| CD STRING END				{runCD($2); return 1;}
	| ALIAS STRING STRING END	{runSetAlias($2, $3); return 1;}
	| ALIAS END					{runPrintAlias(); return 1;}
	| UNALIAS STRING END		{runUnalias($2); return 1;}
	| SETENV STRING STRING END	{runSetEnv($2, $3); return 1;}
	| UNSETENV STRING END		{return runUnSetenv($2);}
	| PRINTENV END				{runPrintEnv(); return 1;}
	| COMMAND END 				{runCommand($1); return 1;}
	| COMMAND arg				{ commands[$1] = currentArgs; runCommand($1); currentArgs.clear(); return 1;}

arg :
	//END 						{return 1;}
	/*|*/ STRING 				{currentArgs.push_back($1); printf("HELLO2");}
	| arg STRING				{currentArgs.push_back($2); printf("HELLO3");}

%%

int yyerror(char *s) {
	printf("%s\n",s);
	return 0;
}

int runCD_home(){
	struct passwd *pw = getpwuid(getuid());
	if(chdir(pw->pw_dir) == 0){
		getcwd(cwd, sizeof(cwd));
		strcpy(varTable.word[0], cwd);
	}
	return 1;
}

int runCD(char* arg) {

	if (arg[0] != '/') { // arg is relative path
		//Check if first char is '~'
		if(arg[0] == '~')
		{
			//Do something to replace part of path with user's home. 
			if (runCD_home())
			{
				//printf("SUCCESS\n");
				std::string str(arg);
				str = str.substr(2);
				strcat(varTable.word[0], "/");
				strcat(varTable.word[0], str.c_str());
			}
		}
		
		if(arg[0] != '~')
		{
			strcat(varTable.word[0], "/");
			strcat(varTable.word[0], arg);
		}

		if(chdir(varTable.word[0]) == 0) {
			getcwd(cwd, sizeof(cwd));
			strcpy(varTable.word[0], cwd);
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
	//for (int i = 0; i < aliasIndex; i++) {
	runAlias = false;
    std::cout << "SHOULD BE FALSE: " << runAlias << std::endl;


	std::cout << "NAME: " << name << " WORD: " << word << std::endl;
	if(strcmp(name, word) == 0){
		printf("Error, expansion of \"%s\" would create a loop1.\n", name);
		return 1;
	}
	else if( aliases.find(word) != aliases.end() ){
		if( strcmp(aliases[word].c_str(), name) == 0 )
		{
			printf("Error, expansion of \"%s\" would create a loop2.\n", name);
			return 1;
		}
	}
	// else if(strcmp(aliasTable.name[i], name) == 0) {
	// 	//strcpy(aliasTable.word[i], word);
	// 	printf("HERE");
	// 	return 1;
	// }
	//}
	//strcpy(aliasTable.name[aliasIndex], name);
	//strcpy(aliasTable.word[aliasIndex], word);
	aliases[name] = word;	
	aliasIndex++;
	return 1;
}

int runSetEnv(char* arg1, char* arg2)
{
	runAlias = false;
	variables[arg1] = arg2;
	
	return 1;
}

void runPrintAlias(void)
{
	runAlias = false;

	
	if (aliasIndex == 0)
	{
		printf("%s", "No aliases set\n");
		return;
	}
	// for (int i = 0; i < aliasIndex; i++)
	// {
	//	printf("Alias name: %s; Alias word: %s\n", aliasTable.name[i], aliasTable.word[i]);
	// }
	for (auto& it : aliases)
	{
		std::cout << it.first << "=" << it.second << std::endl; 
	}
}

int runUnalias(std::string name)
{
	runAlias = false;
	//std::cout << "UNALIAS" << std::endl;
	//std::cout << name << std::endl;
	for (auto& it : aliases)
	{

		std::cout << it.first << " " << it.second << " " << name << std::endl;
		if (it.first.compare(name) == 0) // for some reason it's it.second 
		{
			aliases.erase(it.first); // again some reason it's it.first; you would think name would == it.first but no; subAliases is weird
			std::cout << "ERASED ALIAS" << std::endl;
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

int runUnSetenv(std::string name)
{

	if (name.compare("PATH") == 0)
	{
		std::cout << "CAN'T UNSET PATH" << std::endl;
		return 1;
	}
	else if (name.compare("HOME") == 0)
	{
		std::cout << "CAN'T UNSET HOME" << std::endl;
		return 1;
	}
		
	//unaliasCheck = true;
	//std::cout << name << std::endl;
	for (auto& it : variables)
	{

		//std::cout << it.first << " " << it.second << " " << name << std::endl;
		if (it.first.compare(name) == 0) // for some reason it's it.second 
		{
			variables.erase(name); // again some reason it's it.first; you would think name would == it.first but no; subAliases is weird
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

void runPrintEnv(void)
{

	// for (int i = 0; i < aliasIndex; i++)
	// {
	//	printf("Alias name: %s; Alias word: %s\n", aliasTable.name[i], aliasTable.word[i]);
	// }
	for (auto& it : variables)
	{
		std::cout << it.first << "=" << it.second << std::endl; 
	}
}


int runCommand(char* name)
{

	//  std::string str = std::string(name);
    // std::string substr = str.substr(0, str.find(' '));
    // char* s = const_cast<char*>(substr.c_str());

	const char* path = "/bin/";
	char* catPath = (char*)malloc(1 + strlen(path) + strlen(name));
	strcpy(catPath, path);
	strcat(catPath, name);

	std::cout << catPath << std::endl;
	

	// char* arg[3] = {"HELLLOOO", NULL};
	std::cout << "WORKED: " << name << std::endl;
	auto vec = commands[name];
	int size = vec.size() + 1;
	char* args[size]; 
	args[0] = name;

	for (int i = 1; i < size; i++)
	{
		std::cout << "ARG: " << vec[i - 1] << std::endl; 
		args[i] = vec[i - 1];
	}
	args[size] = NULL;
	

	pid_t pid = fork();
	int status;
	std::cout << "PID: " << pid << std::endl;
	if (pid == 0)
	{
		std::cout << "I AM THE CHILD: " << pid << std::endl;
		

		if (execv(catPath, args) == -1) // this works
		{
			printf("WHHHHHHY");
		}
		printf(":((((((((999");
		_exit(0);
	}
	else if (pid > 0)
	{
		std::cout << "I AM THE PARENT: " << pid << std::endl;
		waitpid(pid, &status, 0);

	}
	else if (pid < 0) 
	{
        perror("In fork():");
    }
	else
	{
		printf("WELLL");
	}

	// will need to fork stuff obv; may not do stuff exactly like this but good proof of concept	
	// execv(arg[0], args); //this works
	//pid_t pid = fork();
	//execv(catPath, args); //this works


	free(catPath);

	return 1;
}
