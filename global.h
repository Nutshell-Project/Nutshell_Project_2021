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
	char* cmd;
	int numArgs;
	char** args;
	char* file_in; char* file_out;
	char* stdin; char* stdout; char* stderr;
	comNode* next;

	comNode(){
		cmd = NULL; numArgs = 0; args = new char*[numArgs+2]; args[0] = NULL; args[1] = NULL; file_in = NULL; file_out = NULL; stdin = NULL; stdout = NULL; stderr = NULL; next = NULL;
	};
	void changeCom(char* newcmd){
		std::string c(newcmd);
		std::string c_name = c.substr(c.find_last_of("/")+1);
		cmd = new char[sizeof(newcmd)+1];
		strcpy(cmd, newcmd);
		if (args[0] != NULL)
			free(args[0]);
		args[0] = new char[c_name.length()+1];
		strcpy(args[0], c_name.c_str());
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
		args[numArgs+1] = NULL;
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
	void reset(){
		free(cmd);
		cmd = NULL;
		numArgs = 2;
		char** newArgs = new char*[numArgs+2];
		for(int i=0;i<numArgs;i++){
			newArgs[i] = NULL;
		}
		free(args);
		args = newArgs;
		free(file_in); free(file_out); free(stdin); free(stdout); free(stderr); free(next);
		file_in = NULL; file_out = NULL; stdin = NULL; stdout = NULL; stderr = NULL; next = NULL;
	}
};

extern bool unaliasCheck;

extern bool runAlias;

extern bool cd;