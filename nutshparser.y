%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string>
#include <iostream>
#include <string.h>
#include "global.h"
#include <sys/types.h>
#include <pwd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <glob.h>

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
//Command functions
void printArgs();					
void printNode(comNode* nbcommand);	
void insertCommandNode();
void computeCommand();
void changeIOLocation(char* arg);	
//Variables for Command
bool fileIN_OUT = true;
bool bg = false;
extern comNode* nbcommand= new comNode();
bool isPipe = false;
//////////////////////////////
//int runCommand(char* name);
//void parseNewPath(const char* path);

//struct aTable aliasTable;
bool unaliasCheck;
bool runAlias;
bool cd;
std::vector<char*> currentArgs;


std::unordered_map<std::string,std::string> aliases;

std::unordered_map<std::string,std::string> variables;

//std::unordered_map<std::string, std::vector<char*>> commands;

%}

%union {char *string;}
%type<string> arg_list argument excess_string simple_command cmd q0
%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS END SETENV UNSETENV PRINTENV COMMAND IO IOR PIPE AMPERSAND

%%
cmd_line    :
	BYE END						{exit(1); return 1;}
	| CD END					{runCD_home(); return 1;}
	| CD STRING END				{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| ALIAS END				{runPrintAlias(); return 1;}
	| UNALIAS STRING END			{runUnalias($2); return 1;}
	| SETENV STRING STRING END		{runSetEnv($2, $3); return 1;}
	| UNSETENV STRING END		{return runUnSetenv($2);}
  | PRINTENV END				{runPrintEnv(); return 1;}
	| simple_command			{return 1;}
	| excess_string END			{printf("EXCESS_STRING: %s\n", $1); return 1;}
	;
excess_string:
	STRING					{ strcpy($$, $1); }
	| excess_string STRING			{ strcat($1, $2); }
	;
simple_command:
	END						{ }
	| cmd q1 q0			{ $$ = $1;}; //printf("command: [%s]\t[%s]\n", $1, $3); 
q0:
	END						{ }
	| pipe simple_command	{ $$ = $2; computeCommand();} //Add code to account for PIPE and depth

q1:
	arg_list q3
	| io_modifier q4
	| background q5
	| io_descr q3
	| /*empty*/				{ insertCommandNode(); computeCommand(); }; //handle logic

q3:
	io_modifier q4
	| io_descr q3
	| background q5
	| /*empty*/				{ insertCommandNode(); computeCommand(); };

q4:
	file q3;

q5:
	/*empty*/				{ insertCommandNode(); computeCommand(); };


cmd:
	COMMAND					{ $$ = $1; nbcommand->changeCom($1); };

arg_list:
	argument
	| argument arg_list

argument:
	STRING		{ nbcommand->insertArg($1);}

file:
	STRING		{ changeIOLocation($1);};

io_modifier:
	IO			{
					if(strcmp($1, "<")==0){
						fileIN_OUT = true;
						nbcommand->changeInput($1);
					}
					else{
						fileIN_OUT = false;
						nbcommand->changeOutput($1);	//Need code for '>' vs ">>""
					}
				};

io_descr:
	IOR			{ nbcommand->changeStdError($1);};

background:
	AMPERSAND	{ bg = true;};

pipe:
	PIPE		{ isPipe = true; };		//for computeCommand
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
		myPaths.pop_back();
		std::string temp(cwd);
		myPaths.push_back(temp);
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
					char* temp = new char[str.length()+1];
					strcpy(temp, str.c_str());
					strcat(varTable.word[0], "/");
					strcat(varTable.word[0], temp);
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
      
			//printf("WHAT!!!1");

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

//For testing only
void printArgs()
{
	for (int i=0; i< nbcommand->numArgs+2;i++)
	{	
		if(nbcommand->args[i] != NULL)
			printf("\t[%s]", nbcommand->args[i]);
		else
			printf("\t[NULL]");
	}
	printf("\n");
}

//For testing only
void printNode(comNode* nbcommand){
	if(nbcommand != NULL){
		if(nbcommand->cmd != NULL) printf("cmd: \t\t[%s]\n", nbcommand->cmd);
		else	printf("cmd: \t\t[NULL]\n");
		for(int i=0;i<nbcommand->numArgs+2;i++)
			printf("arg[%d]: \t[%s]\n", i, nbcommand->args[i]);
		if(nbcommand->file_in != NULL) printf("file_in: \t[%s]\n", nbcommand->file_in);
		else	printf("file_in: \t[NULL]\n");
		if(nbcommand->file_out != NULL) printf("file_out: \t[%s]\n", nbcommand->file_out);
		else	printf("file_out: \t[NULL]\n");
		if(nbcommand->stdin != NULL) printf("stdin: \t\t[%s]\n", nbcommand->stdin);
		else	printf("stdin: \t\t[NULL]\n");
		if(nbcommand->stdout != NULL) printf("stdout: \t[%s]\n", nbcommand->stdout);
		else	printf("stdout: \t[NULL]\n");
		if(nbcommand->stderr != NULL) printf("stderr: \t[%s]\n", nbcommand->stderr);
		else	printf("stderr: \t[NULL]\n");
		if(nbcommand->next == NULL)
			printf("next: \t\t[NULL]\n");
		else
			printf("next: \t\t[nextCom]\n");
	}
	else
		printf("nbcommand is NULL\n");
}

void insertCommandNode(){
	comNode* newCom = new comNode();
	comNode* temp = nbcommand;
	//printNode(newCom);
	while(temp->next != NULL){	
		temp = temp->next;
	}

	temp->next = newCom;
	//printf("######################################\tinserting node...\n\n");
	//printArgs();
	//printNode(nbcommand);
}

void computeCommand(){
	//replace runNBCommand();
	//compute nbcommand here
	//printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\tcomputing command..\n\n");
	if( nbcommand->cmd != NULL){
		int status;
		pid_t pid = fork();
		if(pid == 0){
			//Child
			// if command in pipeline has input redirection
			if (nbcommand->stdin != NULL){
				if ( strcmp(nbcommand->stdin, "<") == 0 ) { 
					FILE *fdin = fopen(nbcommand->file_in, "a+");
					dup2(fileno(fdin), STDIN_FILENO);
					fclose(fdin);
				}
			}
			// if command in pipeline has output redirection
			if (nbcommand->stdout != NULL){
				int fdout;
				if ( strcmp(nbcommand->stdout, ">") == 0 ) {
					FILE *fdout = fopen(nbcommand->file_out, "w");
					dup2(fileno(fdout), STDOUT_FILENO);
					fclose(fdout);
				}
				else if ( strcmp(nbcommand->stdout, ">>") == 0 ) {
					FILE *fdout = fopen(nbcommand->file_out, "a");
					dup2(fileno(fdout), STDOUT_FILENO);
					fclose(fdout);
				}
			}
			if(execv(nbcommand->cmd, nbcommand->args) == -1)
				printf("Doesn't work...\n");
			_exit(0);
		}
		else if (pid > 0){
			//Child
			if(!bg)
				waitpid(pid, &status, 0);
		}
		else if (pid < 0){
			perror("In fork():");
		}
		else{
			printf("Weelll....\n");
		}
	}
	//remove node
	//nbcommand->reset();
	nbcommand = nbcommand->next;
	isPipe = false;
	//printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	//printNode(nbcommand);
	bg = false;
}

void changeIOLocation(char* arg){
	//True - input file, False - output file
	if(fileIN_OUT){
		nbcommand->file_in = new char[sizeof(arg)+1];
		strcpy(nbcommand->file_in, arg);
	}
	else{
		nbcommand->file_out = new char[sizeof(arg)+1];
		strcpy(nbcommand->file_out, arg);
	}
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