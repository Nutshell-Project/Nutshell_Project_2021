%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include <dirent.h>
struct aTable aliasTable;


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

%%

<string_condition>{ANYCHAR}+    { yylval.string = strdup(yytext); return STRING; }
<string_condition>[\"]          {BEGIN(INITIAL);}

[ \t]			{ }
bye				{ return BYE; }
cd				{ return CD; }
alias			{ return ALIAS; }
unalias			{ return UNALIAS; }
setenv			{ return SETENV; }
unsetenv		{ return UNSETENV;}
~([/]{ANYCHAR}*)*                  { yylval.string = strdup(yytext); return STRING;}
[a-z]+		{
			char* yycopy = strdup( yytext);
			if (commandExist(yytext)){
				printf("COMMAND\n");
				return COMMAND;
                    	}
                    	else
			{
				yylval.string = strdup(yytext);
				return STRING;
			}
		}
"\n"                { return END; }
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
%%

bool commandExist(char* name)
{
//Doesn't work at the moment
    DIR *dir;
    struct dirent *ent;
    bool found = false;
    if ((dir = opendir ("/bin")) != NULL) {
        /* compare all the files and directories within directory */

        while ((ent = readdir (dir)) != NULL && !found) {
            if( strcmp(ent->d_name, name) == 0 )
            {
                found = true;
                printf ("%s\tFound!\n", name);
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
