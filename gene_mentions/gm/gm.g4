/* converted on tue jul 31, 2018, 16:12 (utc-07) by pegjs-to-w3c v0.43 which is copyright (c) 2011-2017 by gunther rademacher <grd@gmx.net> */

grammar gm;

/*
*/
gmentries : gms (NEWLINE gms)* NEWLINE? EOF? ;
gms      : gm ( ENUMSEP gm )* ;
gm       : gmdoublesuffix
           | gmdoublerange
           | gmcompound
           | gmsimple
         ;
gmdoublerange
         : base INTEGER RANGESEP base INTEGER
         ;
gmdoublesuffix
         : gmdoublesuffixbase enumsuffixr1 ENUMSEP enumsuffixr1
         ;
gmcompound
         : base list
         ;
gmsimple : base enumsuffix1a_1_a* ;
base     : BASE ;
list     : enumrangemix
           | enums
         ;
enums    : enumsuffix1a_1_a+
         ;
enumrangemix
         : ( INTEGER ENUMSEP )* ranges ( ENUMSEP INTEGER )*
         ;
ranges   : range ( ENUMSEP range )*
         ;

range    : start RANGESEP end;
start : INTEGER ;
end : INTEGER ;

enumsuffix1a_1_a
         : enumsuffix1_or_a ENUMSEP
           | enumsuffix1a ENUMSEP?
           | enumsuffix1_or_a
         ;

enumsuffix1_or_a : INTEGER | CHAR ;
enumsuffix1a : INTEGER CHAR ;

gmdoublesuffixbase
         : CHAR WORDLOWER
         ;

enumsuffixr1
         : CHAR INTEGER
         ;
BASE     : ( INTEGER '-' )? WORD '-'? ;

ENUMSEP  : ( ','? ' '? ENUMWORD | ' '? ENUMCHAR ) ' '?
         ;
ENUMWORD : 'or'
           | 'and'
         ;

RANGESEP : ' '? ('-' | 'to' | 'through' | 'thru') ' '? ;

NEWLINE  : '\n' ;
ENUMCHAR : [/,&|] ;
WORD     : [A-Za-z]+ ;
WORDLOWER     : [a-z]+ ;
CHAR     : [A-Za-z] ;
CHARUPPER     : [A-Z] ;
INTEGER  : [0-9]+ ;
/* WS        :   [ \t\r\n]+ -> skip ; */
