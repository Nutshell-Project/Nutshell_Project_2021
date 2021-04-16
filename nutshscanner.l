%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include <dirent.h>
#include <errno.h>
struct aTable aliasTable;
extern std::vector<std::string> myPaths;
bool comInProgress = false;


char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}
bool commandExist(char* name);

%}
%array
%option noyywrap
%x string_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR            [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
F_DName         [a-zA-Z0-9\}\{\[\]\)\(\^&'@,$=!-#%.+~_]+

%%

<string_condition>{ANYCHAR}+    { yylval.string = strdup(yytext); return STRING; }
<string_condition>[\"]          {BEGIN(INITIAL);}

[ \t]			{ }
bye				{ 
                    yylval.string = strdup(yytext); 
                    if(!comInProgress) {comInProgress = !comInProgress; return BYE;}
                    else return STRING;
                }
cd				{ 
                    yylval.string = strdup(yytext); 
                    if(!comInProgress) {comInProgress = !comInProgress; return CD;}
                    else return STRING;
                }
alias			{ 
                    yylval.string = strdup(yytext); 
                    if(!comInProgress) {comInProgress = !comInProgress; return ALIAS;}
                    else return STRING;
                }
unalias			{ 
                    yylval.string = strdup(yytext); 
                    if(!comInProgress) {comInProgress = !comInProgress; return UNALIAS;}
                    else return STRING;
                }
setenv			{ 
                    yylval.string = strdup(yytext); 
                    if(!comInProgress) {comInProgress = !comInProgress; return SETENV;}
                    else return STRING;
                }
unsetenv		{ 
                    yylval.string = strdup(yytext); 
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
                    yylval.string = strdup(yytext);
                    if (!comInProgress){
                        if (commandExist(yytext)){ comInProgress = true; return COMMAND; }
                    }
                    else return STRING;
        		}
"<"                 { yylval.string = strdup(yytext); return IO; }
">"[>]?             { yylval.string = strdup(yytext); return IO; }
"2>"(&1)?           { yylval.string = strdup(yytext); return IOR; }
"|"                 { comInProgress = false; return PIPE; }
"&"                 { return AMPERSAND; }
-[a-zA-Z0-9]*       { yylval.string = strdup(yytext); return STRING; }
-[a-zA-Z=a-zA-Z]*   { yylval.string = strdup(yytext); return STRING; }

"\n"                { comInProgress = false; return END; }
;		            { comInProgress = false; return END; }
[\"]                { BEGIN(string_condition); }
{CHAR}+             { if(ifAlias(yytext)) {
                        //printf("yytext: %s\n", yytext);
                        //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                            char *yycopy = strdup( subAliases(yytext) );
                            for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                                unput( yycopy[i] );
                            free( yycopy );
                        } else {
                            //printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                    }
.                   { printf("last resort: %s\n", yytext); yylval.string = strdup(yytext); return STRING;}
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