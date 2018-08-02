lexer grammar gmLexer;

fragment LETTER_LOWER  : [a-z] ;
fragment LETTER_UPPER  : [A-Z] ;

fragment ENUMWORD : ('or'
           | 'and')
         ;

fragment ENUMCHAR : [/,&|] ;

// 1, 2, and 3
// 1, 2 and 3
// 1,2and3
// 1, 2 & 3
// 1,2|3
ENUMSEP  : ( ','? SPACE? ENUMWORD SPACE? )
	 | ( SPACE? ENUMCHAR SPACE? )
         ;

RANGESEP : (SPACE? ('-' | 'to' | 'through' | 'thru') SPACE?)
	 ;

GM_R1_R2_BASE
         : LETTER_UPPER LETTER_LOWER+
         ;

LETTER_UPPER_INTEGER
         : LETTER_UPPER INTEGER
         ;

NEWLINE  : '\n' ;
WORD     : (LETTER_LOWER | LETTER_UPPER)+ ;
INTEGER  : [0-9]+ ;
SPACE  : ' ' ;
/* WS        :   [ \t\r\n]+ -> skip ; */

//BASE_TYPICAL : (( INTEGER '-'? )? WORD '-'? ) ;
//BASE_TYPICAL     : (( INTEGER '-' WORD '-' ) | ( WORD '-' ) | WORD);
//fragment BASE     : ( INTEGER '-' )? WORD '-'? ;








//fragment STRING
//   : '"' (~ ('"' | '\n' | '\r'))* '"' | '\'' (~ ('\'' | '\n' | '\r'))* '\''
//   ;
//
//URL
//   : 'url'
//   ;
//
//LPAREN
//   : '('
//   ;
//
//RPAREN
//   : ')'
//   ;
//
//UrlStart
//   : URL LPAREN -> pushMode (URL_STARTED)
//   ;

//mode URL_STARTED;
//UrlEnd
//   : RPAREN -> popMode
//   ;
//
//Url
//   : STRING | (~ (')' | '\n' | '\r' | ';')) +
//   ;
