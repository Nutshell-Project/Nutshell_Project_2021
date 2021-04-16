%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include <string>
#include <iostream>
#include "global.h"
#include <dirent.h>
#include <errno.h>
struct aTable aliasTable;
extern std::vector<std::string> myPaths;
bool comInProgress = false;

int yylex(void);
extern std::unordered_map<std::string,std::string> aliases;
extern std::unordered_map<std::string,std::string> variables;
extern std::vector<std::string> myPaths;

//extern int aliasCheck = 0;
//extern bool unaliasCheck;
extern bool runAlias;
// bool cd;


char* subAliases(char* name){
    // for (int i = 0; i < aliasIndex; i++) {
    //     if(strcmp(aliasTable.name[i], name) == 0) {
    //         return aliasTable.word[i];
    //     }
    // }
    //aliasCheck++;
    //std::cout << "ALIASCHECK: " << aliasCheck << std::endl;
    // for (auto& it : aliases)
    // {
        //if (it.first.compare(name) == 0)
        if (aliases.find(name) != aliases.end())
        {

            if (aliases.find(aliases[name]) == aliases.end()) // check if we even need to check again
            {
                return name;
            }
            
            //std::cout << "Subalias: " << it.second << " Alias: " << it.first << std::endl;
            printf("SUBALIAS COMING AT YA!\n");
            //return const_cast<char*>(it.second.c_str());
            return const_cast<char*>(aliases[name].c_str());
        }

            
   // }

    // if (aliases.find(name) != aliases.end())
    // {
    //     std::cout << "HI" << std::endl;
    //     //std::cout << "Subalias: " << it.second << " Alias: " << it.first << std::endl;
    //     return const_cast<char*>(aliases[name].c_str());
    // }

    // for (auto& it : aliases)
    // {
    //     if(strcmp(const_cast<char*>(it.first.c_str()), name) == 0)
    //         return const_cast<char*>(it.second.c_str());
            
    // }

    printf("JUST RETURNED NAME!");
    return name;
}
bool ifAlias(char* name){
    // for (int i = 0; i < aliasIndex; i++) {
    //     if(strcmp(aliases.name[i], name) == 0) {
    //         return true;
    //     }
    // }
    for (auto& it : aliases)
    {
        if (it.first.compare(name) == 0)
        {
            std::cout << "LOOKS LIKE AN ALIAS TO ME " << name << std::endl;
            return true;
        }
    }
    return false;
}
bool commandExist(char* name);

char* ifVar(char* name)
{

    for (auto& it : variables)
    {
        if (it.first.compare(name) == 0)
        {
            return const_cast<char*>(variables[name].c_str());
        }
    }

    return name;
}

%}
%array
%option noyywrap
%x string_condition


CHAR            [~:.A-Za-z0-9!\/_-][~:.A-Za-z0-9!\/_-]*
ANYCHAR            [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
F_DName         [a-zA-Z0-9\}\{\[\]\)\(\^&'@,$=!-#%.+~_]+

%%

<string_condition>{ANYCHAR}+    { 
                                    runAlias = false; 
                                    if ( strcmp(ifVar(yytext), yytext) == 0 )
                                    {
                                        std::cout << "SAME" << std::endl;
                                        yylval.string = strdup(yytext); 
                                        return STRING;
                                    }
                                    else if ( strcmp(ifVar(yytext), yytext) != 0  )
                                    {
                                        std::cout << "OKKKK" << std::endl;
                                        if (ifAlias(ifVar(yytext)))
                                        {
                                            char* name = const_cast<char*>(variables[yytext].c_str());
                                            yylval.string = strdup(name); 
                                            return STRING;
                                        }
                                        
                                    }
    
    
                                    
                                    // std::cout << "yytext" << yytext << std::endl; 
                                    // yylval.string = strdup(yytext); 
                                    // return STRING; 
                                    
                                }



<string_condition>[\"]       {BEGIN(INITIAL);}
<string_condition>[\}]       { BEGIN(INITIAL);} 


<<EOF>>         {exit(0);}
[\$\{]+          {  printf("YAY"); BEGIN(string_condition); } 
[ \t]			{ }
bye				{ 
                    yylval.string = strdup(yytext); 
                    if(!comInProgress) {comInProgress = !comInProgress; return BYE;}
                    else return STRING;
                }
cd				{ 
                    yylval.string = strdup(yytext); cd = true;
                    if(!comInProgress) {comInProgress = !comInProgress; return CD;}
                    else return STRING;
                }
alias			{ 
                    yylval.string = strdup(yytext); runAlias = true; 
                    if(!comInProgress) {comInProgress = !comInProgress; return ALIAS;}
                    else return STRING;
                }
unalias			{ 
                    yylval.string = strdup(yytext); runAlias = true;
                    if(!comInProgress) {comInProgress = !comInProgress; return UNALIAS;}
                    else return STRING;
                }
setenv			{ 
                    yylval.string = strdup(yytext); runAlias = true;
                    if(!comInProgress) {comInProgress = !comInProgress; return SETENV;}
                    else return STRING;
                }
unsetenv		{ 
                    yylval.string = strdup(yytext); runAlias = true;
                    if(!comInProgress) {comInProgress = !comInProgress; return UNSETENV;}
                    else return STRING;
                }
[~.]?([/]{F_DName}*)*    {
			                if (!comInProgress){ if(commandExist(yytext)) { comInProgress = true; return COMMAND; }
                            }
                            else { yylval.string = strdup(yytext); return STRING;}
                        }
[/]({F_DName}+[/])*{F_DName}+       {
			                if (!comInProgress){ if(commandExist(yytext)) { comInProgress = true; return COMMAND; }
                            }
                            else { yylval.string = strdup(yytext); return STRING;}
                        }
[a-zA-Z]+		{
                //std::cout << "YYTEXT: " << yytext << std::endl;
                char* yycopy = strdup( yytext );
                //std::cout << runAlias << std::endl;
                if (!runAlias)
                {
                    std::string str = std::string(yytext);
                    std::string substr = str.substr(0, str.find(' '));
                    yycopy = const_cast<char*>(substr.c_str());
                    std::cout << "YYCOPY1: " << yycopy << std::endl;

                    if (!comInProgress && cd != true){
                        if (commandExist(yycopy)){ comInProgress = true; yylval.string = strdup(yycopy); return COMMAND; }
                    }
                }
                    
                
                else if (unaliasCheck)
                {
                    std::cout << "UNALIASCHECK" << std::endl;
                    unaliasCheck = false;
                    yylval.string = strdup(yytext);
                    return STRING;
                }
            //         	else
			// {
                if(ifAlias(yytext)) 
                {
                    //printf("yytext1: %s\n", yytext);
                    printf("IS AN ALIAS\n");
                    //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                    char *yycopy = strdup( subAliases(yytext) );
                    std::cout << yycopy << std::endl;
                    std::cout << "STRCMP:" << strcmp(yycopy, yytext) << std::endl;

                    
                    if (!runAlias)
                    {
                        std::string str = std::string(aliases[yycopy].c_str());
                        std::string substr = str.substr(0, str.find(' '));
                        char* temp = const_cast<char*>(substr.c_str());
                        std::cout << "YYCOPY2: " << yycopy << std::endl;
                        std::cout << "STR: " << str << std::endl;


                        if ( commandExist(temp) && 
                        
                        != true) //const_cast<char*>(aliases[temp].c_str())
                        {
                            //printf("COMMANDDIF\n");
                            std::cout << "YYTEXT: " << std::endl;
                            yylval.string = strdup(str.c_str());
                            return COMMAND;
                        }

                        if ( strcmp(yycopy, yytext) == 0 ) // so we don't run subAliases again if there no more nested aliases
                        {
                            printf("EHLLO\n");

                            yylval.string = strdup(yytext);
                            return STRING;
                        }
                    }
                    else if ( strcmp(yycopy, yytext) == 0 ) // so we don't run subAliases again if there no more nested aliases
                    {
                        printf("EHLLO\n");

                        yylval.string = strdup(yytext);
                        return STRING;
                    }

                    for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                    {
                        unput( yycopy[i] );
                        //std::cout << "YYCOPY[I]: " << yycopy[i] << std::endl;
                    }

                    free( yycopy );

                    } 
                    else 
                    {
                        //printf("yytext2: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                    };
				//yylval.string = strdup(yytext);
                //printf("GOES HERE INSTEAD\n");
                
				//return STRING;
			
			//}
		}
"<"                 { yylval.string = strdup(yytext); if(cd || runAlias || unaliasCheck) return STRING; else {  return IO; } }
">"[>]?             { yylval.string = strdup(yytext); if(cd || runAlias || unaliasCheck) return STRING; else {  return IO; } }
"2>"(&1)?           { yylval.string = strdup(yytext); if(cd || runAlias || unaliasCheck) return STRING; else {  return IOR; } }
"|"                 { if(cd || runAlias || unaliasCheck) return STRING; else { comInProgress = false; return PIPE;} }
"&"                 { if(cd || runAlias || unaliasCheck) return STRING; else { return AMPERSAND;} }
-[a-zA-Z0-9]*       { yylval.string = strdup(yytext); return STRING; }
-[a-zA-Z=a-zA-Z]*   { yylval.string = strdup(yytext); return STRING; }

"\n"                { comInProgress = false; return END; }
;		            { comInProgress = false; return END; }
[\"]                { BEGIN(string_condition); }
{CHAR}+             {   
                        std::cout << "YYTEXT2: " << yytext << std::endl;

                        if(ifAlias(yytext)) {
                        //printf("yytext1: %s\n", yytext);
                        printf("IT WORKS\n");
                        //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                            // char *yycopy = strdup( subAliases(yytext) );
                            // for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                            // {
                            //     unput( yycopy[i] );
                            //     //std::cout << "YYCOPY[I]: " << yycopy[i] << std::endl;
                            // }
                            // free( yycopy );
                        } else {
                            //printf("yytext2: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                    }
.                   { yylval.string = strdup(yytext); return STRING;} //printf("last resort: %s\n", yytext); 
%%
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
            /* compare all the files and directories within directory */
            std::string c_name = str.substr(str.find_last_of("/")+1);
            while ((ent = readdir (dir)) != NULL && !found) {
                if( strcmp(ent->d_name, c_name.c_str()) == 0 )
                {
                    found = true;
                    //printf ("Found! [%s]\n", name);
					          yylval.string = strdup(yytext);
                }
            }
            closedir (dir);
        } else {
            /* could not open directory */
			      printf("Couldn't open directory\n");
            printf("Error: [%s]\n", strerror(errno));
        	//return EXIT_FAILURE;
        }
    }
    else 
	{
		//Check all paths
		std::string c(name);
        int i=0;
        while(i<myPaths.size() && !found){
			c = name;
			std::size_t f_pos = myPaths[i].find_last_of("/");
			if(f_pos != myPaths[i].length() - 1 || f_pos == std::string::npos){
				c = myPaths[i] + "/" + c;
			}
			else if (f_pos != std::string::npos)
				c = myPaths[i] + c;
			//printf("New c: [%s]\n", c.c_str());
			char* temp = new char[c.length()+1];
			strcpy(temp, c.c_str());
			found = commandExist(temp);
			if(found){
				yylval.string = strdup(c.c_str());
				break;
			}
            i++;
		}
	}
    return found;
}