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
void parseNewPath(const char* path);

//struct aTable aliasTable;
bool unaliasCheck;
bool runAlias;
bool cd;
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
	cd = false;
	if (arg[0] != '/') { // arg is relative path
		//Check if first char is '~'
		if(arg[0] == '~')
		{
			//Do something to replace part of path with user's home. 
			if (runCD_home())
			{
				//printf("SUCCESS\n");
				if( strlen(arg) > 1 )
				{
					std::string str(arg);
					str = str.substr(2);
					strcat(varTable.word[0], "/");
					strcat(varTable.word[0], str.c_str());
				}
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
			myPaths.pop_back();
			std::string temp(cwd);
			myPaths.push_back(temp);
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			strcpy(varTable.word[0], cwd);
			myPaths.pop_back();
			std::string temp(cwd);
			myPaths.push_back(temp);
			printf("WHAT!!!1");

			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(varTable.word[0], arg);
			myPaths.pop_back();
			std::string temp(cwd);
			myPaths.push_back(temp);
			return 1;
		}
		else {
			printf("WHAT!!!2");
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
	if ( strcmp(arg1, "PATH") == 0 )
	{
		parseNewPath(arg2);
	}
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

	auto vec = commands[name];
	int size;
	if (vec.size() == 0)
		size = 2;
	else
		size = vec.size() + 1;

	std::cout << "VEC SIZE: " << vec.size() << std::endl;
	char* args[size]; 
	std::vector<char*> aliasVector;
	int counter = 0;
	std::string str = std::string(name);
    // std::string substr = str.substr(0, str.find(' '));
    // char* s = const_cast<char*>(substr.c_str());

	size_t pos = 0;
	std::string delimiter = " ";
	std::string token = str.substr(0, pos);
	std::cout << "STR: " << str << std::endl;

	while ((pos = str.find(delimiter)) != std::string::npos) 
	{
		std::cout << "HERE" << std::endl;
		token = str.substr(0, pos);
		args[counter] = const_cast<char*>(token.c_str());
		std::cout << "TOKEN: " << token << std::endl;
		aliasVector.push_back(const_cast<char*>(token.c_str()));
		str.erase(0, pos + delimiter.length());
		counter++;
		
	}
	aliasVector.push_back(const_cast<char*>(str.c_str()));
	std::cout << "TOKEN: " << str << std::endl;



	const char* path = "/bin/";
	if (counter == 0)
		token = str;	
	char* catPath = (char*)malloc(1 + strlen(path) + strlen(const_cast<char*>(token.c_str())));
	strcpy(catPath, path);
	strcat(catPath, const_cast<char*>(token.c_str()));

	std::cout << "CATPATH:" << catPath << std::endl;
	
	args[0] = const_cast<char*>(token.c_str());

	std::cout << "COUNTER: " << counter << std::endl;
	std::cout << "SIZE: " << size << std::endl;

	if (vec.size() == 0 && counter != 0)
	{
		for (int i = counter; i < size; i++)
		{
			std::cout << "HERE1" << std::endl; 
		
			std::cout << "ARG: " << aliasVector[i] << std::endl; 
			args[i] = aliasVector[i];
		}

	}
	else
	{
		if (vec.size() != 0)
		{
			for (int i = 1; i < size; i++)
			{
				std::cout << "HERE2" << std::endl;
				std::cout << "ARG: " << vec[i - 1] << std::endl; 
				args[i] = vec[i - 1];
			}

		}
		else
		{
			size--;
		}
		
	}

	args[size] = NULL;
	



	for (int i = 0; i < size; i++)
	{
		std::cout << args[i] << std::endl;
	}


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
	str = std::string(name);

	aliasVector.clear();
	commands.erase(str);

	return 1;
}

void parseNewPath(const char* path)
{
	std::cout << "HERE WE ARE" << std::endl;
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