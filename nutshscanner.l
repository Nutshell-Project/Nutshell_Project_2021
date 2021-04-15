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
struct aTable aliasTable;

int yylex(void);
extern std::unordered_map<std::string,std::string> aliases;
extern std::unordered_map<std::string,std::string> variables;

//extern int aliasCheck = 0;
//extern bool unaliasCheck;
extern bool runAlias;
bool quotes;



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



[\$\{]+          {  printf("YAY"); BEGIN(string_condition); } 
[ \t]			{ }
bye				{ return BYE; }
cd				{ return CD; }
alias			{ runAlias = true; return ALIAS; }
unalias			{ runAlias = true; unaliasCheck = true; return UNALIAS; }
setenv			{ runAlias = true; return SETENV; }
unsetenv		{ return UNSETENV; }
printenv        { return PRINTENV; }
~([/]{ANYCHAR}*)*                  { yylval.string = strdup(yytext); return STRING;}
[a-z]+		{
                //std::cout << "YYTEXT: " << yytext << std::endl;
                char* yycopy = strdup( yytext );
                //std::cout << runAlias << std::endl;
                if (!runAlias)
                {
                    if ( commandExist(yytext) )
                    {
				        printf("COMMAND\n");
                        yylval.string = strdup(yytext);
				        return COMMAND;
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
                    std::cout << runAlias << std::endl;
                    
                    if (!runAlias)
                    {
                        if ( commandExist(const_cast<char*>(aliases[yycopy].c_str())))
                        {
                            //printf("COMMANDDIF\n");
                            std::cout << "YYTEXT: " << yytext << std::endl;
                            yylval.string = strdup(const_cast<char*>(aliases[yycopy].c_str()));
                            return COMMAND;
                        }
                    }
                    else if (strcmp(yycopy, yytext) == 0) // so we don't freaaaaaaking run subAliases again if there no more nested aliases
                    {
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
"\n"                { return END; }
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
%%

bool commandExist(char* name)
{
    std::string str = std::string(name);
    std::string substr = str.substr(0, str.find(' '));
    char* s = const_cast<char*>(substr.c_str()); // don't ask why i'm doing it this way, i don't even know

//Doesn't work at the moment
    DIR *dir;
    struct dirent *ent;
    bool found = false;
    if ((dir = opendir ("/bin")) != NULL) {
        /* compare all the files and directories within directory */

        while ((ent = readdir (dir)) != NULL && !found) {
            if( strcmp(ent->d_name, s) == 0 )
            {
                found = true;
                printf ("%s\tFound!\n", s);
            }
        }
        closedir (dir);
    } else {
        /* could not open directory */
        perror ("");
    return EXIT_FAILURE;
    }
    return found;
}

