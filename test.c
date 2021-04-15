#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <vector>
#include <dirent.h>
#include <cstddef>
#include <string>





std::vector <std::string> myPaths;

void parsePaths(const char* path);
void printPaths();
bool commandExist(char* name);
void printArgs();
void printNode();
void insertCommandNode();
void computeCommand();

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



	comNode *nbcommand = NULL;

int main(int argc, char** argv)
{
	
	insertCommandNode();
	nbcommand->changeCom(argv[1]);
	nbcommand->insertArg(argv[2]);
	nbcommand->insertArg(argv[3]);
	nbcommand->changeInput(argv[1]);
	nbcommand->changeOutput(argv[2]);
	nbcommand->changeStdError(argv[3]);
	nbcommand->changeOp1(argv[2]);
	nbcommand->changeOp2(argv[3]);

	printNode();

	insertCommandNode();

	printNode();

	computeCommand();
	computeCommand();
	
	//insertArg(argv[2]);
	/*
	free(firstCom.args);
	firstCom.args = new char*[2];
	firstCom.command = new char[sizeof("/bin/ls")+1];
	strcpy(firstCom.command, "/bin/ls");
	strcpy(firstCom.args[0], "ls");
	firstCom.args[1] = NULL;
	firstCom.next = NextCom;

	printf("firstCom.command: [%s]\n", firstCom.command);
	if(NextCom->command != NULL)
		printf("NextCom.command: [%s]\n", NextCom->command);
	else
		printf("NextCom.command: []\n");
	*/

//	const char* path = getenv("PATH");
//	const char* home = getenv("HOME");
/*	if(path != NULL)
		printf("PATH :%s\n\n", path);
	else
		printf("PATH doesn't exist\n");
	if(home != NULL)
		printf("HOME :%s\n", home);
	else
		printf("HOME doesn't exist\n");
*/

/*
	int child = fork();
	if(child==0){
		char* arr[] = {"/bin/ls", "-l", "-a", NULL};
		execv("/bin/ls", arr);
	}
	else if(child>0)
	{
		wait(NULL);
	}
//	char* arr2[] = {"ls", "-l"};
//	printf("size=%ld\n", sizeof(arr2));
*/
/*
	parsePaths(path);
	printPaths;
	char* c = "/bin/ls";
	char* d = "ls";
	commandExist(c);
	commandExist(d);

	std::vector <std::string> strings;
	strings.push_back("Things");
	strings.push_back("are");
	strings.push_back("fine.");

	char** args = new char*[strings.size()+1];
	printf("error? size: %d\n", strings.size());
	for( int i= 0;i<strings.size();i++){
		args[i] = new char[sizeof(strings[i])];
		printf("\terror?\t strings[i]: [%s]\n", strings[i].c_str());
		strcpy(args[i], strings[i].c_str());
	}
	args[strings.size()] = NULL;

/*	std::string a("ab"), b("cd");
	a = a+b;
	printf("a+b = %s\n", a.c_str());
	*/
}


void printArgs()
{
	for (int i=0; i< nbcommand->numArgs+2;i++)
	{
		printf("\t[%s]", nbcommand->args[i]);
	}
	printf("\n");
}


void insertCommandNode(){
	/*
	comNode* newCom = new comNode();
	newCom->next = nbcommand;
	nbcommand = newCom;
	//Not correct
	*/
	
	comNode* newCom = new comNode();
	if(nbcommand == NULL)
		nbcommand = newCom;
	else{
		nbcommand->next = newCom;
	}
	printf("inserting node...\n\n");
	printArgs();
}

void computeCommand(){
	//replace runNBCommand();
	//run command
	//if only 1 command		
	printf("computing command..\n\n");
	if(nbcommand->next != NULL){
		comNode* temp = nbcommand;
		nbcommand = nbcommand->next;
		free (temp);
	}
	else{
		free( nbcommand);
		nbcommand = NULL;
	}
	printNode();
}

void printNode(){
	if(nbcommand != NULL){
		printf("cmd: \t\t[%s]\n", nbcommand->cmd);
		printf("op1: \t\t[%s]\n", nbcommand->op1);
		printf("op2: \t\t[%s]\n", nbcommand->op2);
		for(int i=0;i<nbcommand->numArgs+2;i++)
			printf("arg[%d]: \t[%s]\n", i, nbcommand->args[i]);
		printf("file_in: \t[%s]\n", nbcommand->file_in);
		printf("file_out: \t[%s]\n", nbcommand->file_out);
		printf("stdin: \t\t[%s]\n", nbcommand->stdin);
		printf("stdout: \t[%s]\n", nbcommand->stdout);
		printf("stderr: \t[%s]\n", nbcommand->stderr);
		if(nbcommand->next == NULL)
			printf("next: \t\t[NULL]\n");
		else
			printf("next: \t\t[oldCom]\n");
	}
	else
		printf("nbcommand is NULL\n");
}

/*
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

void printPaths(){
	for (int i=0;i<myPaths.size(); i++)
		printf("%d: [%s]\n", i, myPaths[i].c_str());
}


bool commandExist(char* name)
{
    DIR *dir;
    struct dirent *ent;
    bool found = false;

    // path_to_command/command
    if( name[0] == '/')
    {
        std::string str(name);
        std::string path = str.substr(0, str.find_last_of("/"));
        if ((dir = opendir (path.c_str())) != NULL) {
            //compare all the files and directories within directory
            std::string c_name = str.substr(str.find_last_of("/")+1);
            while ((ent = readdir (dir)) != NULL && !found) {
                if( strcmp(ent->d_name, c_name.c_str()) == 0 )
                {
                    found = true;
                    printf ("Found! [%s]\n", name);
					//Push to argument list
					//yylval.string = strdup(yytext);
                }
            }
            closedir (dir);
        } else {
            // could not open directory
			printf("Couldn't open directory\n");
            perror ("");
        	//return EXIT_FAILURE;
        }
    }
    else 
	{
		//Check all paths
		std::string c(name);
		for(int i=0;i<myPaths.size();i++){
			c = name;
			std::size_t f_pos = myPaths[i].find_last_of("/");
			if(f_pos != myPaths[i].length() - 1 || f_pos == std::string::npos){
				c = myPaths[i] + "/" + c;
			}
			else if (f_pos != std::string::npos)
				c = myPaths[i] + c;
			printf("New c: [%s]\n", c.c_str());
			char* temp = new char[c.length()+1];
			strcpy(temp, c.c_str());
			found = commandExist(temp);
			if(found){
				//yylval.string = strdup(c.c_str());
				//Push to arguments
				break;
			}
		}
	}
    return found;
}
*/