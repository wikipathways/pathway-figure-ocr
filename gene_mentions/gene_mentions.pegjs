{
  function parseInt10(x) {
    return parseInt(x, 10);
  }
  function isEnumSuffixA1A_A1_1A_1_A(x) {
    return typeof x == "string" &&
      (x.match(/^[a-zA-Z]*[0-9]+[a-zA-Z]*|[a-zA-Z]$/) ||
	x.match(/^[a-zA-Z]$/));
  }
}

//*
GMEntries
= first:GMs rest:(Newline GMs)* {
  return first.concat(
    rest.map(gm => gm[1])
    .reduce((acc, g) => acc.concat(g), [])
  );
}

Newline
= "\n"

GMs
= first:GM rest:(EnumSep? GM)* {
  return first.concat(
    rest.map(gm => gm[1])
    .reduce((acc, g) => acc.concat(g), [])
  );
}

GM
= GMDoubleSuffix
/ GMCompound
/ GMSimple

// Needed to handle this case: AdipoR1/R2 => AdipoR1 & AdipoR2
GMDoubleSuffix
= base:GMDoubleSuffixBase suffix1:EnumSuffixR1 EnumSep suffix2:EnumSuffixR1 {
  if (suffix1.letter !== suffix2.letter) {
    return false;
  }
  return [
    base + suffix1.letter + suffix1.integer,
    base + suffix2.letter + suffix2.integer
  ];
}

GMDoubleSuffixBase
= [A-Za-z] [a-z]+ { return text(); }

EnumSuffixR1 = letter:[A-Z] integer:Integer {
  return {
    letter: letter,
    integer: integer
  };
}

GMCompound
= base:Base suffixes:List {
  return suffixes
  .map(s => base + s);
}

GMSimple
= base:Base suffix:EnumSuffix1A_1_A* {
  return [base + suffix];
}

Base
= (Integer "-")? Word "-"? { return text(); }
//*/

List
= EnumRangeMix
/ Enums

Enums
= first:EnumSuffix1A_1_A rest:EnumSuffix1A_1_A* {
  const integerSuffixMatch = first.match(/^([0-9]+)[a-zA-Z]+$/);
  return [first].concat(
  	rest
	.map(s => {
	  const lettersOnlyMatch = s.match(/^[a-zA-Z]+$/);
	  if (integerSuffixMatch && lettersOnlyMatch) {
	    return integerSuffixMatch[1] + lettersOnlyMatch[0];
	  } else {
	    return s;
	  }
	})
  );
}

EnumRangeMix
= start:(EnumSuffix1A_1_A EnumSep)* ranges:Ranges end:(EnumSep EnumSuffix1A_1_A)* {
  return start.map(n => n.filter(isEnumSuffixA1A_A1_1A_1_A))
	  .reduce((acc, g) => acc.concat(g), [])
	  .concat(ranges)
	  .concat(
	    end.map(n => n.filter(isEnumSuffixA1A_A1_1A_1_A))
	    .reduce((acc, g) => acc.concat(g), [])
	  )
}

Ranges
= first:Range rest:(EnumSep Range)* {
  return first.concat(rest.map(x => x[1]))
  .reduce((acc, r) => acc.concat(r), []);
}

Range
= start:Integer RangeSep end:Integer {
  const startInt = parseInt10(start);
  const endInt = parseInt10(end);
  return [...Array(1 + endInt - startInt).keys()]
  .map(d => (startInt + d));
}

RangeSep
= " "? RangeChar " "?

RangeChar
= [\-] / "to" / "through" / "thru"

EnumSuffix1A_1_A = EnumSuffix1A_1_A_sep
/ Integer
/ EnumSuffixSingleLetter

EnumSuffix1A_1_A_sep = result:(Integer EnumSep
/ EnumSuffixSingleLetter EnumSep
/ EnumSuffix1A EnumSep?) {
  return result[0];
}

// NOTE: includes suffixes like A or a
EnumSuffixSingleLetter = [a-zA-Z] & [^a-zA-Z0-9] { return text(); }

// NOTE: includes suffixes like 1A, 1a
EnumSuffix1A = Integer [A-Za-z] { return text(); }

EnumSep
= ","? " "? EnumWord " "?
/ " "? EnumChar " "?

EnumChar = [\/,&]

EnumWord = "or" / "and"

Word
= t:[A-Za-z]+ { return text(); }

Integer
= [0-9]+ { return text(); }