%{
#include <stdio.h>

int yylex(); // Defined in lex.yy.c

int yyparse(); // Need this definition so that yyerror can call it

void yyerror(char* e) {
	printf("Error: %s\n", e);

	// NOTE: calling yyparse from within yyerror has consequences, and I only
	// realized this after I held and recorded the tutorial.

	// Since yyparse calls yyerror, if you call yyparse again then you're
	// recursing into yyerror and eating up stack space. This could lead to a
	// seg fault if called enough times. Instead, it's smarter to call yyparse
	// exclusively from your main method, and use yyerror to recover from and
	// report errors.

	// Leaving this in here to show it as a very simple example.

	yyparse();
}
%}

%token STRING_LITERAL NUMBER_LITERAL BOOLEAN_LITERAL NULL_LITERAL
%token UNDEFINED

%%

	/*
	Input is a list of objects. This makes yyparse work interactively, and it
	will print "Valid JSON" for each top-level JSON object it finds.
	*/
input:
	  %empty
	| input object { printf("Valid JSON\n"); } ;

object:
	  '{' key_value_list '}'
	| STRING_LITERAL
	| NUMBER_LITERAL
	| BOOLEAN_LITERAL
	| NULL_LITERAL ;

	/*
	A comma-separated list. Three different patterns here now, to represent
	lists with no items, one item, or multiple items.
	*/
key_value_list:
	  %empty
	| key_value
	| key_value_list ',' key_value ;

key_value:
	  STRING_LITERAL ':' object ;
