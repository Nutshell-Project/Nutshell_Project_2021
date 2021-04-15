%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
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
void runPrintAlias(void);
int runUnalias(std::string name);
//Command functions
//void runNBCommand(char* arg);
void printArgs();					//done
void printNode(comNode* nbcommand);	//done
void insertCommandNode();
void computeCommand();
void changeIOLocation(char* arg);	//done


//Variables for Command
bool fileIN_OUT = true;
bool bg = false;
extern comNode* nbcommand= new comNode();
int depth = 1;

//struct aTable aliasTable;

std::unordered_map<std::string,std::string> aliases;
%}

%union {char *string;}
%type<string> arg_list argument excess_string simple_command cmd q0
%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS END SETENV UNSETENV COMMAND IO IOR PIPE AMPERSAND

%%
cmd_line    :
	BYE END					{exit(1); return 1;}
	| CD END				{runCD_home(); return 1;}
	| CD STRING END				{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| ALIAS END				{runPrintAlias(); return 1;}
	| UNALIAS STRING END			{runUnalias($2); return 1;}
	| SETENV STRING STRING END		{runSetEnv($2, $3); return 1;}
	| UNSETENV STRING END			{return 1;}
	| simple_command			{return 1;}
	| excess_string END			{printf("EXCESS_STRING: %s\n", $1); return 1;}
	;
excess_string:
	STRING					{ strcpy($$, $1); }
	| excess_string STRING			{ strcat($1, $2); }
	;
simple_command:
	END						{ }
	| cmd q1 q0			{ $$ = $1; printf("command: [%s]\t[%s]\n", $1, $3); } ;
q0:
	END						{ }
	| PIPE simple_command	{ $$ = $2; computeCommand();} //Add code to account for PIPE and depth

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
			printf("Directory not found\n");
			return 1;
		}
	}
}

int runSetAlias(char *name, char *word) {
	// for (int i = 0; i < aliasIndex; i++) {
	//	if(strcmp(name, word) == 0){
	//		printf("Error, expansion of \"%s\" would create a loop.\n", name);
	//		return 1;
	//	}
	//	else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
	//		printf("Error, expansion of \"%s\" would create a loop.\n", name);
	//		return 1;
	//	}
	//	else if(strcmp(aliasTable.name[i], name) == 0) {
	//		strcpy(aliasTable.word[i], word);
	//		return 1;
	//	}
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
	//	printf("Alias name: %s; Alias word: %s\n", aliasTable.name[i], aliasTable.word[i]);
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

//Needs to be edited
/*
void runNBCommand(char* arg)
{
	//No need to parse path of command
	int size = myArguments.size();
	int child = fork();

	//Child
	if(child==0){
		char** args = convertArgs();
		std::string temp(arg);
		temp = temp.substr(temp.find_last_of("/")+1);
		char* t = new char[temp.length()+1];
		strcpy(t, temp.c_str());
		printf("t: [%s]\n", t);
		args[0] = new char[sizeof(t)];
		strcpy(args[0], t);
		try{
			execv(arg, args);
		}
		catch(...){
			printf("Didn't work..\n");
		}
		exit;
	}
	//Parent
	else if(child > 0){
		if(size>0)
			if(strcmp( myArguments[size-1], "&") != 0)
				wait(NULL);
	}
/*
	int child = fork();
	//Parent
	if (child>0){
		//Check if last argument == &
	printf("ERROR2\n");
		if(size>2)
		if(strcmp( myArguments[size-1], "&") != 0 ) // Source of error
			wait(NULL);
	}
	else if (child == 0){
		char* temp = new char[sizeof("ls")+1]; strcpy(temp, "ls");
		char* args[2] = {temp, NULL};
		execv(arg, args);
	}
*/
//}

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
	printNode(newCom);
	while(temp->next != NULL){	
		temp = temp->next;
	}

	temp->next = newCom;
	printf("######################################\tinserting node...\n\n");
	depth++;
	printArgs();
	printNode(nbcommand);
}

void computeCommand(){
	//replace runNBCommand();
	//compute nbcommand here
	printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\tcomputing command..\n\n");
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
	depth--;
	printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
	printNode(nbcommand);
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