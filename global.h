#include "stdbool.h"
#include <limits.h>
#include <unordered_map>
#include <vector>
#include <string>

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

extern std::vector<std::string> myPaths;

extern bool comInProgress;

struct comNode{
	char* cmd; char* op1; char* op2;
	int numArgs;
	char** args;
	char* file_in; char* file_out;
	char* stdin; char* stdout; char* stderr;
	comNode* next;

	comNode(){
		cmd = NULL; op1 = NULL; op2 = NULL; numArgs = 0; args = new char*[numArgs+2]; file_in = NULL; file_out = NULL; stdin = NULL; stdout = NULL; stderr = NULL; next = NULL;
	};
	void changeCom(char* newcmd){
		cmd = new char[sizeof(newcmd)+1];
		strcpy(cmd, newcmd);
		if (args[0] != NULL)
			free(args[0]);
		args[0] = new char[sizeof(newcmd)+1];
		strcpy(args[0], newcmd);
	};
	void insertArg(char* arg){
		numArgs++;
		char** newArgs = new char*[numArgs+2];
		for(int i=0; i<numArgs; i++){
			newArgs[i] = new char[sizeof(args[i])+1];
			strcpy(newArgs[i], args[i]);
		}
		newArgs[numArgs] = new char[sizeof(arg)+1];
		strcpy(newArgs[numArgs], arg);
		free (args);
		args = newArgs;
	};
	void changeInput(char* input){
		stdin = new char[sizeof(input)+1];
		strcpy(stdin, input);
	};
	void changeOutput(char* output){
		stdout = new char[sizeof(output)+1];
		strcpy(stdout, output);
	};
	void changeStdError(char* error){
		stderr = new char[sizeof(error)+1];
		strcpy(stderr, error);
	};
	void changeOp1(char*option){
		op1 = new char[sizeof(option)+1];
		strcpy(op1, option);
	};
	void changeOp2(char*option){
		op2 = new char[sizeof(option)+1];
		strcpy(op2, option);
	};
};