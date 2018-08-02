parser grammar gmParser;

options { tokenVocab=gmLexer; }

gmentries : gms (NEWLINE gms)* NEWLINE? EOF? ;
gms      : gm ( ENUMSEP gm )* ;
gm       : (gm_R1_R2
           | gm_range_with_base_repeated
           | gm_compound)
         ;

// TODO: this doesn't guarantee base1 == base2
gm_range_with_base_repeated
         : base1=WORD start=INTEGER RANGESEP base2=WORD end=INTEGER
         ;

// like AdipoR1/R2
// TODO: what if it's AdipoA1/R2 ?
gm_R1_R2
         : base=GM_R1_R2_BASE enum_suffix+=LETTER_UPPER_INTEGER ENUMSEP enum_suffix+=LETTER_UPPER_INTEGER
         ;

gm_compound
         : base=WORD suffixes*
         ;
suffixes : ((( enum_suffix=enum_suffix_typical ENUMSEP )* range_suffix ( ENUMSEP range_suffix )* ( ENUMSEP enum_suffix=enum_suffix_typical )*)+
           | enum_suffix_plus_sep+)
         ;

range_suffix    : start=INTEGER RANGESEP end=INTEGER;

enum_suffix_plus_sep
         : (enum_suffix=enum_suffix_typical ENUMSEP?)
         ;

enum_suffix_typical : ((INTEGER WORD+?) | INTEGER | WORD+?) ;
