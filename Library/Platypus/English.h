! "English.h"
! Part of Platypus release 4.
! Copyright 2001 Anson Turner and Graham Nelson
! (not necessarily in that order).
! Comments to: anson@pobox.com


! Define the constant DIALECT_US before #including "First.h" to
! obtain American English (in your program).

System_file;

[ ThatorThose obj;   ! Used in the accusative

    switch(pron(obj)) {
        1,8: print "you";
        2: print "those";
        3: print "her";
        4: print "him";
        5: print "that";
        6: print "me";
        7: print "us";
    }
];

[ s obj;
    if (obj hasnt pluralname) print "s";
];

[ CThatorThose obj;   ! Used in the nominative

    switch(pron(obj)) {
        1,8: print "You";
        2: print "Those";
        3: print "She";
        4: print "He";
        5: print "That";
        6: print "I";
        7: print "We";
    }
];

[ CTheyreorThats obj;

    switch(pron(obj)) {
        1,8: print "You're ";
        2: print "They're ";
        3: print "She's ";
        4: print "He's ";
        5: print "That's ";
        6: print "I'm ";
        7: print "We're ";
    }
];

[ Thatsnotsomething x;
    print (ctheyreorthats) x,"not something #a-s# can ";
];

[ Pron obj     g;

    if (obj == player)                      ! These awful identity crises.
    {   if (player_perspective == 1)
        {   if (player has pluralname) return 7;
            return 6;
        }
        if (player_perspective == 2)
        {   if (player has pluralname) return 8;
            return 1;
        }
    }
    if (obj == actor && obj has quotedmode)
    {   if (obj has pluralname) return 7;
        return 6;
    }
    if (obj has pluralname) return 2;
    if (obj has female) return 3;
    if (obj has male) return 4;
    if (obj has neuter) return 5;
    if (obj has animate) g = LanguageAnimateGender;
    else g = LanguageInanimateGender;
    switch (g) {
        female: return 3;
        male: return 4;
        default: return 5;
    }       
];

        ! pronounpos(object)  ||  print (pronounpos) object
        ! Prints the appropriate possessive pronoun for the given object.

[ pronounpos x;

    switch(Pron(x)) {
        1,8: print "your";
        2: print "their";
        3: print "her";
        4: print "his";
        5: print "its";
        6: print "my";
        7: print "our";
    }
];

[ openorclosed x; if (x has open) print "open"; else print "closed"; ];

[ whichorwho x; if (x has animate) print "who"; else print "which"; ];

! ---------------------------------------------------------------------------
!   Vocabulary
! ---------------------------------------------------------------------------
Constant AGAIN1__WD   = 'again';
Constant AGAIN2__WD   = 'g//';
Constant AGAIN3__WD   = 'again';
Constant OOPS1__WD    = 'oops';
Constant OOPS2__WD    = 'o//';
Constant OOPS3__WD    = 'oops';
Constant UNDO1__WD    = 'undo';
Constant UNDO2__WD    = 'undo';
Constant UNDO3__WD    = 'undo';

Constant ALL1__WD     = 'all';
Constant ALL2__WD     = 'each';
Constant ALL3__WD     = 'every';
Constant ALL4__WD     = 'everything';
Constant ALL5__WD     = 'both';
Constant AND1__WD     = 'and';
Constant AND2__WD     = 'and';
Constant AND3__WD     = 'and';
Constant BUT1__WD     = 'but';
Constant BUT2__WD     = 'except';
Constant BUT3__WD     = 'but';
Constant ME__WD       = 'me';
Constant US__WD       = 'us';
Constant THEN1__WD    = 'then';
Constant THEN2__WD    = 'then';
Constant THEN3__WD    = 'then';

Constant AMUSING__WD  = 'amusing';
Constant FULLSCORE1__WD = 'fullscore';
Constant FULLSCORE2__WD = 'full';
Constant QUIT1__WD    = 'q//';
Constant QUIT2__WD    = 'quit';
Constant RESTART__WD  = 'restart';
Constant RESTORE__WD  = 'restore';

Constant NO1__WD      = 'n//';
Constant NO2__WD      = 'no';
Constant NO3__WD      = 'no';
Constant YES1__WD     = 'y//';
Constant YES2__WD     = 'yes';
Constant YES3__WD     = 'yes';

Constant NUMBER_OF_PRONOUNS = 4;
Array PronounWords --> 'it' 'him' 'her' 'them';
Array PronounGNAs -->
   !             a     i
   !             s  p  s  p
   !             mfnmfnmfnmfn                 
               $$001000001000
               $$100000100000
               $$010000010000
               $$000111000111;
Array PronounReferents --> NULL NULL NULL NULL;

Array LanguageNumbers table
    'one' 1 'two' 2 'three' 3 'four' 4 'five' 5
    'six' 6 'seven' 7 'eight' 8 'nine' 9 'ten' 10
    'eleven' 11 'twelve' 12 'thirteen' 13 'fourteen' 14 'fifteen' 15
    'sixteen' 16 'seventeen' 17 'eighteen' 18 'nineteen' 19 'twenty' 20;

! ---------------------------------------------------------------------------
!   Printing
! ---------------------------------------------------------------------------

Constant LanguageAnimateGender   = male;
Constant LanguageInanimateGender = neuter;

Constant LanguageContractionForms = 2;     ! English has two:
                                           ! 0 = starting with a consonant
                                           ! 1 = starting with a vowel

[ LanguageContraction text;
  if (text->0 == 'a' or 'e' or 'i' or 'o' or 'u'
                 or 'A' or 'E' or 'I' or 'O' or 'U') return 1;
  return 0;
];

Array LanguageArticles -->

 !   Contraction form 0:     Contraction form 1:
 !   Cdef   Def    Indef     Cdef   Def    Indef

     "The " "the " "a "      "The " "the " "an "          ! Articles 0
     "The " "the " "some "   "The " "the " "some ";       ! Articles 1

                   !             a           i
                   !             s     p     s     p
                   !             m f n m f n m f n m f n                 

Array LanguageGNAsToArticles --> 0 0 0 1 1 1 0 0 0 1 1 1;

Array PrintTableYou     -->
    "you"  "your"  "you"  "you're"  0   0    "have" "are" "yourself"   2;
Array PrintTableThey    -->
    "they" "their" "them" "they're" 0   0    "have" "are" "themselves" 3;
Array PrintTableShe     -->
    "she"  "her"   "her"  "she's"   "s" "es" "has"  "is"  "herself"    3;
Array PrintTableHe      -->
    "he"   "his"   "him"  "he's"    "s" "es" "has"  "is"  "himself"    3;
Array PrintTableIt      -->
    "it"   "its"   "it"   "it's"    "s" "es" "has"  "is"  "itself"     3;
Array PrintTableI       -->
    "I"    "my"    "me"   "I'm"     0   0    "have" "am"  "myself"     1;
Array PrintTableWe      -->
    "we"   "our"   "us"   "we're"   0   0    "have" "are" "ourselves"  1;
Array PrintTableYouPlur -->
    "you"  "your"  "you"  "you're"  0   0    "have" "are" "yourselves" 2;

Array accentchars2_ -> 
    '<' 'a' '<' 'e' '<' 'i' '<' 'o' '<' 'u'
    '<' 'A' '<' 'E' '<' 'I' '<' 'O' '<' 'U'
    ''' 'a' ''' 'e' ''' 'i' ''' 'o' ''' 'u'
    ''' 'A' ''' 'E' ''' 'I' ''' 'O' ''' 'U'
    '`' 'a' '`' 'e' '`' 'i' '`' 'o' '`' 'u'
    '`' 'A' '`' 'E' '`' 'I' '`' 'O' '`' 'U'
    ':' 'a' ':' 'e' ':' 'i' ':' 'o' ':' 'u'
    ':' 'A' ':' 'E' ':' 'I' ':' 'O' ':' 'U'
    ''' 'y' ''' 'Y' 'c' 'c' 'c' 'C'
    '-' 'a' '-' 'n' '-' 'o' '-' 'A' '-' 'N' '-' 'O'
    '/' 'o' '/' 'O' 'o' 'a' 'o' 'A'
    's' 's' '<' '<' '>' '>' 'a' 'e' 'A' 'E' 'o' 'e' 'O' 'E'
    't' 'h' 'T' 'h' 'e' 't' 'E' 't' 'L' 'L' '!' '!' '?' '?'
    'c' 't' 'b' 's' 'a' 't' '-' '-';
#ifdef TARGET_GLULX;
Array accentchars1_ -->
    $E2 $EA $EE $F4 $FB
    $C2 $CA $CE $D4 $DB
    $E1 $E9 $ED $F3 $FA
    $C1 $C9 $CD $D3 $DA
    $E0 $E8 $EC $F2 $F9
    $C0 $C8 $CC $D2 $D9
    $E4 $EB $EF $F6 $FC
    $C4 $CB $CF $D6 $DC
    $FD $DD
    $E7 $C7
    $E3 $F1 $F5 $C3 $D1 $D5
    $F8 $D8
    $E5 $C5
    $DF $AB $BB $E6 $C6 $3F $3F $3F $3F $3F $3F
    $A3 $A1 $BF
    $5E $5C $40 $7E;
#endif;
#ifndef TARGET_GLULX;
Array accentchars1_ -->
    "@^a" "@^e" "@^i" "@^o" "@^u"
    "@^A" "@^E" "@^I" "@^O" "@^U"
    "@'a" "@'e" "@'i" "@'o" "@'u"
    "@'A" "@'E" "@'I" "@'O" "@'U"
    "@`a" "@`e" "@`i" "@`o" "@`u"
    "@`A" "@`E" "@`I" "@`O" "@`U"
    "@:a" "@:e" "@:i" "@:o" "@:u"
    "@:A" "@:E" "@:I" "@:O" "@:U"
    "@'y" "@'Y"
    "@cc" "@cC"
    "@~a" "@~n" "@~o" "@~A" "@~N" "@~O"
    "@/o" "@/O"
    "@oa" "@oA"
    "@ss" "@<<" "@>>" "@ae" "@AE" "@oe" "@OE" "@th" "@Th" "@et" "@Et"
    "@LL" "@!!" "@??" "@@94" "@@92" "@@64" "@@126";
#endif;

[ HoldX;

    if (holdx_called == false)
    {   holdx_called = true;
        OpenBuffer(PrintBuffer);
    }
    else rfalse;
];

[ PrintX str obj     oo;

    if (str)
    {   HoldX(); 
        oo = lm_o; if (obj) lm_o = obj;
        print (string) str; PrintX();
        lm_o = oo;
        rtrue;
    }

    if (holdx_called == false) rfalse;
    holdx_called = false;
    CloseBuffer();
    printx_2();
];

[ GetPrintTable     np;

    np = last_name_printed; if (np == 0) np = actor;

    switch(Pron(np))
    {   1: code_table = PrintTableYou;
        2: code_table = PrintTableThey;
        3: code_table = PrintTableShe;
        4: code_table = PrintTableHe;
        5: code_table = PrintTableIt;
        6: code_table = PrintTableI;
        7: code_table = PrintTableWe;
        8: code_table = PrintTableYouPlur;
    }
];

#ifndef TARGET_GLULX;
[ PrintAccentChar addr     c1 c2 c;

    c1 = PrintBuffer -> addr;
    c2 = PrintBuffer -> (addr + 1);

    for (c = 0:c < 68:c++)
    {   if (c1 == accentchars2_->(c*2) && c2 == accentchars2_->(c*2+1))
        {   print (string) accentchars1_-->c; rtrue; }
    }
    print "*";
];
#endif;
#ifdef TARGET_GLULX;
[ PrintAccentChar addr     c1 c2 c;

    c1 = PrintBuffer -> addr;
    c2 = PrintBuffer -> (addr + 1);
    for (c = 0:c < 68:c++)
    {   if (c1 == accentchars2_->(c*2) && c2 == accentchars2_->(c*2+1))
        {   print (char) accentchars1_-->c; rtrue; }
    }
    print "*";
];
#endif;

Global space_flag;
[ printx_2     c ch l wd e cf lch ch2 subflag;

    GetPrintTable();
    l = PrintBuffer-->0 + WORDSIZE;
    if (l > PRINT_BUFFER_SIZE)
        FatalError("Array overflowed with formatted text.");
    
    if (multiphase == 3)
        PrintBuffer->WORDSIZE = GetLowercase(PrintBuffer->WORDSIZE);
    
    for (c = WORDSIZE:c < l:c++)
    {
        ch = PrintBuffer->c;
        if (ch == '.' or '!' or '?') npflags->0 = 0;
        if (ch == '&')
        {   if (PrintBuffer->(c+1) == '&')
            {   print (char) ch;
                c++;
                continue;
            }
            PrintAccentChar(c+1);
            c = c + 2;
            continue;
        }
        if (ch == '#')
        {
            if (PrintBuffer->(c+1) == '#')
            {   print (char) ch;
                c++;
                continue;
            }
            e = FindByByte('#', PrintBuffer + c + 1, l - c - 1);
            if (e == -1) 
            {   #ifdef DEBUG;
                    "***Error: missing ~#~ in text.";
                #ifnot;
                    rtrue;
                #endif;
            }
            ch = PrintBuffer -> (c + 1);
            lch = GetLowercase(ch);
            subflag = 0;
            if (ch ~= lch)
            {   cf = 1;
                subflag = 1;
                PrintBuffer->(c + 1) = lch;
            }
            else cf = 0;
            if (PrintBuffer->(c + e - 1) == '-')
            {   ch2 = PrintBuffer->(c+e);
                wd = DictionaryLookup(PrintBuffer + c + 1, e - 2);
                if (wd == 'actor' or 'obj' or 'noun' or 'second'
                    or 'a//' or 'o//' or 'n//' or 'd//')
                {   if (ch2 == 'o') subflag = 3;
                    else if (ch2 == 's') subflag = 1;
                    else if (ch2 == 'x') subflag = -1;
                    else "***Error: illegal code extension #",
                        (address) wd,"-",(char) ch2,"#~.";
                }
                else 
                {   switch(ch2)
                    {   'a': last_name_printed = actor;
                        'o': if (multiphase == 0) last_name_printed = lm_o;
                        'n': last_name_printed = noun;
                        's','d': last_name_printed = second;
                        default: "***Error: illegal code extension #",
                                  (address) wd,"-",(char) ch2,"#~.";
                    }
                    GetPrintTable();
                }
            }
            else wd = DictionaryLookup(PrintBuffer + c + 1, e);
            if (wd == 0)
                "***Error: unknown print specifier word";
            if (multiphase == 3 && c == WORDSIZE) cf = 0;
            if (PrintSpecWord(wd, cf, subflag) == -1)
            {   if (multiphase == 1 or 3)
                {   if (cf) multiphase = -2; else multiphase = -1;
                    return;
                }
                if (multiphase == 2 or 4) multiphase = 5;
            }
            c = c + e + 1;
        }
        else if (multiphase == 2 or 4) continue;
        else if (ch == 13 or 10)
        {   if (stoplf == false) new_line; else print " ";
        }
        else if (multiphase && ch == '.' or '!' && c == l - 2) return;
        else if (ch == 16) ts(sbold);
        else if (ch == 14) ts(sroman);
        else print (char) ch;
    }
];

Array Byte3A -> 22;
    ! In names_printed:
    ! 1 - 8 hold names matching the objects' Pron values
    ! 9 holds the last object whose name was printed in a nominative case
    !      (for substituting reflexive pronouns)
Array names_printed --> 10;
    ! If a pronoun has been used in this sentence in place of an
    ! object name, we don't want to change the meaning of that pronoun.
    ! That is, we don't want:
    !   So-and-so takes the kazoo. She puts it in the hat. She takes it.
    !   She wears it.
    ! instead of:
    !   So-and-so takes the kazoo. She puts it in the hat. She takes the hat.
    !   She wears it.
    ! npflags is a bitmap indicating which pronouns have been used in the
    ! current sentence. 
Array npflags --> 1;
[ SetNamePrinted obj     n;
    n = Pron(obj);
    names_printed --> n = obj;
];
[ ClearNamesPrinted     c;
    for (c = 1:c < 10:c++) names_printed-->c = 0;
    npflags-->0 = 0;
];
[ PrintNameOrPronoun obj capflag sfl     n;

    last_name_printed = obj; GetPrintTable();
    
    n = Pron(obj);

    if ((sfl == -2)
        || ((code_table --> 9 == 3)
        && (names_printed-->n ~= obj)))
    {   if (capflag) print (The) obj; else print (the) obj; }
    else
    {   if (sfl == 2 && names_printed-->9 == obj)
            sfl = 8;
        PrintSpecWord2(sfl, capflag);
        SetBit(npflags, n);
        if (code_table --> 9 ~= 3 && HasBit(npflags, n) == 0)
            SetNamePrinted(obj);
        if (sfl == 0) names_printed-->9 = obj;
        return;
    }

    if (HasBit(npflags, n) == 0) SetNamePrinted(obj);
    if (sfl == 0) names_printed-->9 = obj;
];

[ PrintSpecWord wd capflag sfl     v;

    if (multiphase == 2 or 4 && wd ~= 'obj' or 'o//') rfalse;
!    if (sfl == 0) { if (wd ~= 'actor' or 'a//' && capflag == 0) sfl = 2; }
    if (sfl == 0) { if (capflag == 0) sfl = 2; }
    else sfl--;
        
    switch(wd) {
        'actor','a//'   : PrintNameOrPronoun(actor, capflag, sfl); return;
        'obj','o//'   : if (multiphase) return -1;
                        PrintNameOrPronoun(lm_o, capflag, sfl); return;
        'noun','n//'  : PrintNameOrPronoun(noun, capflag, sfl); return;
        'second','d//': PrintNameOrPronoun(second, capflag, sfl); return;
        'his','its'     : v = 1;
        'him','ito'     : if (names_printed-->9 == last_name_printed) v = 8;
                          else v = 2;
        'he^s','it^s'   : v = 3;
        's//'           : v = 4;
        'es'            : v = 5;
        'has','have'    : v = 6;
        'is','are'      : v = 7;
        'himself', 'itself' : v = 8;
        'b//'   : ts(sbold); return;
        'r//'   : ts(sroman); return;
        'u//'   : ts(sunder); return;
        'f//'   : ts(sfixed); return;
        default: "***Error: unknown print specifier";
    }
    
    PrintSpecWord2(v, capflag);
];

[ PrintSpecWord2 idx capflag     str;

    str = code_table-->idx;
    if (str == 0) return;
    
    if (capflag == 0) print (string) str;
    else
    {   str.print_to_array(Byte3A);
        printcap(Byte3A, 1);
    }
];

        ! printcap(table, flag)
        ! Prints the text in table in all uppercase, or capitalizing the
        ! first character if flag is 1, all initial word letters if 2.

[ printcap table fl     t a ch;

    t = table-->0 + WORDSIZE;
    for (a = WORDSIZE:a < t:a++)
    {
        ch = table->a;
        if (ch ~= 10 or 13 or ' ' && fl < 3)
        {
            ch = GetUppercase(ch);
            if (fl == 1) fl = 4;
            else if (fl == 2) fl = 3;
        }
        if (ch == 10 or 13) new_line;
        else print (char) ch;
        if (ch == ' ' && fl == 3) fl = 2;
    }
];

[ ImplicitMessage act x y;

    print "(";
    switch(act)
    {
        ##Close:    print "closing";
        ##Disrobe:  print "removing";
        ##EnterIn:  print "getting into";
        ##EnterOn:  print "getting onto";
        ##Exit:     print "getting "; if (actor has under) print "out from under";
                    else if (actor has upon) print "off of"; 
                    else if (actor has inside) print "out of";
                    else if (parent(actor) && parent(actor) has animate)
                            print "away from";
                    else print "out of";
        ##Insert:   print "putting ",(the) x," into ",
                        (the) y;
                    if (action == ##Take) print " to make room";
                    x = 0;
        ##Open:     print "opening";
        ##Take:     print "taking";
        default:    print "doing something to";
    }
    if (x) print " ",(the) x;
    print ")^";
];

[ LanguageNumber n f;

  if (n == 0)    { print "zero"; rfalse; }
  if (n < 0)     { print "minus "; n=-n; }
  if (n >= 1000) { print (LanguageNumber) n/1000, " thousand"; n=n%1000; f=1; }
  if (n >= 100)  { if (f==1) print ", ";
                 print (LanguageNumber) n/100, " hundred"; n=n%100; f=1; }
  if (n == 0) rfalse;
  #ifndef DIALECT_US;
      if (f == 1) print " and ";
  #ifnot;
      if (f == 1) print " ";
  #endif;
  switch(n)
  {   1:  print "one";
      2:  print "two";
      3:  print "three";
      4:  print "four";
      5:  print "five";
      6:  print "six";
      7:  print "seven";
      8:  print "eight";
      9:  print "nine";
      10: print "ten";
      11: print "eleven";
      12: print "twelve";
      13: print "thirteen";
      14: print "fourteen";
      15: print "fifteen";
      16: print "sixteen";
      17: print "seventeen";
      18: print "eighteen";
      19: print "nineteen";
      20 to 99:
          switch(n/10)
          {  2: print "twenty";
             3: print "thirty";
             4: print "forty";
             5: print "fifty";
             6: print "sixty";
             7: print "seventy";
             8: print "eighty";
             9: print "ninety";
          }
          if (n % 10) print "-", (LanguageNumber) n % 10;
  }
];

[ LanguageTimeOfDay hours mins i;
   i=hours%12;
   if (i==0) i=12;
   if (i<10) print " ";
   print i, ":", mins/10, mins%10;
   if ((hours/12) > 0) print " pm"; else print " am";
];

[ IsMeWord wd;
    if (player has pluralname)
    {   if (wd == 'us' or 'ourselves' or 'selves') rtrue;
    } else if (wd == 'me' or 'myself' or 'self') rtrue;
    rfalse;
];

[ IsYouWord wd;
    if (actor has pluralname)
    {   if (wd == 'you' or 'yourselves') rtrue;
    } else if (wd == 'you' or 'yourself') rtrue;
    rfalse;
];

[ LanguageVerb i;
    switch(i) {
        'i//', 'inv', 'inventory': print "take inventory";
        'l//': print "look";
        'q//': print "quit";
        't//': print "get a list of exits";
        'x//': print "examine";
        'z//': print "wait";
        default: rfalse;
    }
];

Default NKEY__TX     = "N = next subject";
Default PKEY__TX     = "P = previous";
Default QKEY1__TX    = "  Q = resume game";
Default QKEY2__TX    = "Q = previous menu";
Default RKEY__TX     = "RETURN = read subject";

Default NKEY1__KY    = 'N';
Default NKEY2__KY    = 'n';
Default PKEY1__KY    = 'P';
Default PKEY2__KY    = 'p';
Default QKEY1__KY    = 'Q';
Default QKEY2__KY    = 'q';

Default SCORE__TX      = "Score: ";
Default MOVES__TX      = "Moves: ";
Default TIME__TX       = "Time: ";
Default CANTGO__TX     = "You can't go that way.";
Default FORMER__TX     = "your former self";
Default YOURSELF__TX   = "yourself";
Default YOURSELVES__TX = "yourselves";
Default MYSELF__TX     = "myself";
Default OURSELVES__TX  = "ourselves";
Default YOU__TX        = "you";
Default YOUPL__TX      = "you";
Default OURSELVES__TX  = "ourselves";
Default ME__TX         = "me";
Default US__TX         = "us";
Default DARKNESS__TX   = "Darkness";
Default THOSET__TX   = "those things";
Default THAT__TX     = "that";
Default THE__TX      = "the";
Default OR__TX       = " or ";
Default NOTHING__TX  = "nothing";
Default IS__TX       = " is";
Default ARE__TX      = " are";
Default IS2__TX      = "is ";
Default ARE2__TX     = "are ";
Default AND__TX      = " and ";
Default WHOM__TX     = "whom ";
Default WHICH__TX    = "which ";

Default PS__STR      = ". ";

[ LanguageLM n x1;

Prompt:  print "^>";
Miscellany: switch(n) {
    1: "(considering the first sixteen objects only)^";
    2: "Nothing to do!";
    3: print "*** You have died ***";
    4: print "*** You have won ***";
    5: print "^Would you like to RESTART, RESTORE a saved game";
       #IFDEF DEATH_MENTION_UNDO;
           print ", UNDO your last move";
       #ENDIF;
       if (child(AchievedTasks)) print ", repeat the FULL score for that game";
       #IFDEF AMUSING_PROVIDED;
       if (deadflag==2)
           print ", see some suggestions for AMUSING things to do";
       #ENDIF;
       " or QUIT?";
    6: "[Your interpreter does not provide ~undo~. Sorry!]";
    7: "~Undo~ failed. [Not all interpreters provide it.]";
    8: "Please give one of the answers above.";
    9: "^It is now pitch dark in here!";
    10: "I beg your pardon?";
    11: "[You can't ~undo~ what hasn't been done!]";
    12: "[Can't ~undo~ twice in succession. Sorry!]";
    13: "[Previous turn undone.]";
    14: "Sorry, that can't be corrected.";
    15: "Think nothing of it.";
    16: "~Oops~ can only correct a single word.";
    17: "It is pitch dark, and you can't see a thing.";
    20: "To repeat a command like ~frog, jump~, just say
         ~again~, not ~frog, again~.";
    21: "You can hardly repeat that.";
    22: "You can't begin with a comma.";
    23: "You seem to want to talk to someone, but I can't see whom.";
    24: names_printed-->9 = 0; "You can't talk to #o#.";
    25: "To talk to someone, try ~someone, hello~ or some such.";
    27: "I didn't understand that sentence.";
    28: print "I only understood you as far as wanting to ";
    29: "I didn't understand that number.";
    30: "You can't see any such thing.";
    31: "You seem to have said too little!";
    32: "You don't have that.";
    33: "You can't use multiple objects with that verb.";
    34: "You can only use multiple objects once on a line.";
    35: "I'm not sure what ~", (address) pronoun_word, "~ refers to.";
    36: "You excepted something not included anyway!";
    37: "That can only be done to something animate.";
    38: #ifdef DIALECT_US;
        "That's not a verb I recognize.";
        #ifnot;
        "That's not a verb I recognise.";
        #endif;
    39: "That's not something you need to refer to
           in the course of this game.";
    40: "You can't see ~", (address) pronoun_word,
        "~ (", (the) pronoun_obj, ") at the moment.";
    41: "I didn't understand the way that finished.";
    42: if (x1==0) print "None";
        else print "Only ", (languagenumber) x1;
        print " of those ";
        if (x1==1) print "is"; else print "are";
        " available.";
    43: "Nothing to do!";
    44: "There are none at all available!";
    45: print "Who do you mean, ";
    46: print "Which do you mean, ";
    47: "Sorry, you can only have one item here. Which exactly?";
    48: names_printed-->9 = 0; print "Whom do you want";
        if (actor ~= player || player_perspective ~= 2) print " #a-o#";
        print " to "; PrintCommand(); print "?^";
    49: names_printed-->9 = 0; print "What do you want";
        if (actor ~= player || player_perspective ~= 2) print " #a-o#";
        print " to "; PrintCommand(); print "?^";
    50: ;
    51: "(Since something dramatic has happened,
        your list of commands has been cut short.)";
    52: "^Type a number from 1 to ",x1,", 0 to redisplay or press ENTER.";
    53: "^[Please press SPACE.]";
    502: "(with #o#)";
    503: "No such object exists.";
    505: "No such room exists.";
    510: print (name) x1,": ";
    520: print "both?";
    521: print "all?";
    522: "#A# can only do that with things #a-s# #is# holding.";
    523: print "^[For ";
         if (x1 == -1) print "#his-a# accomplishments";
         else print "#o#";
         print ", #his-a# score has just gone ";
    524: print "^[#His-a# score has just gone ";
    525: if (x1 > 0) print "up"; else {x1 = -x1; print "down"; }
         print " by ", (languagenumber) x1," point";
         if (x1 ~= 1) print "s";
         ".]";
    526: print "#A# can't do anything with ";
         if (x1) "those."; else "that.";
}
ListMiscellany: switch(n) {
    1: print " (providing light)";
    2: print " (",(whichorwho) x1," #is-o# closed)";
    3: print " (closed and providing light)";
    4: print " (",(whichorwho) x1," #is-o# empty)";
    5: print " (empty and providing light)";
    6: print " (",(whichorwho) x1," #is-o# closed and empty)";
    7: print " (closed, empty and providing light)";
    8: print " (providing light and being worn";
    9: print " (providing light";
    10: print " (being worn";
    11: print " (",(whichorwho) x1," #is-o# ";
    12: print "open";
    13: print "open but empty";
    14: print "closed";
    15: print "closed and locked";
    16: print " and empty";
    17: print " (",(whichorwho) x1," #is-o# empty)";
    18: print " containing ";         ! ALWAYS & ENGLISH  -- but no longer used
    19: print "on ";                  ! RECURSE, ENGLISH & TERSE
    20: print "on top of ";           ! RECURSE & ENGLISH
    21: print "in ";                  ! RECURSE, ENGLISH, TERSE
    22: print "inside ";              ! RECURSE, ENGLISH
    50: print "under ";               ! RECURSE, ENGLISH, TERSE
    51: print "underneath ";          ! RECURSE, ENGLISH
    52: print "wearing ";
    54: print "carrying ";
    500: names_printed-->9 = 0; print " with #him-a#";
    501: print " (upon)";
    502: print " (inside)";
    503: print " (under)";
    504: print "#O# #is# wearing ";
    505: print " and carrying ";
    506: print "#O# #is# carrying ";
    507: print "On #o#"; 
         if (actor in lm_o && actor has upon) print " with #him-a#";
    508: print "Inside #o#";
         if (actor in lm_o && actor has inside) print " with #him-a#";
    509: print "Underneath #o#";
         if (actor in lm_o && actor has under) print " with #him-a#";
}

Answer, Ask: "There is no reply.";
Attack: "Violence won't help matters.";
Blow:   "#A# can't usefully blow #o#.";
Burn:   "This dangerous act would achieve little.";
Buy:    "Nothing is on sale.";
Climb, ClimbDown: "#A# can't climb #o#.";
Close: switch(n) {
    1: "#A# close#s# #o#.";
    2: print_ret (thatsnotsomething) x1,"close.";
    3: print_ret (ctheyreorthats) x1,"already closed.";
    4: "#N# close#s#.";
}
Consult: "#A# discover#s# nothing of interest in #o#.";
Cut:    "#A# can't cut #o# with #d#.";
Dig:    "Digging would achieve nothing here.";
Disrobe: switch(n) {
    1: "#A# take#s# off #o#.";
    2: "#He's# not wearing #o#.";
}
Drink:  "There's nothing suitable to drink here.";
Drop: switch(n) {
    1: if (multiflag && narrative_mode == 0) "Dropped.";
       "#A# drop#s# #o#.";
    2: "#O# #is# already here.";
    3: "#A# #is#n't holding #o#.";
    4: "#A# cannot drop #himself#.";
    5: "#A# will have to take #o# off first.";
}
Eat: switch(n) {
    1: "#A# eat#s# #o#. Not bad.";
    2: print_ret (ctheyreorthats) x1,"plainly inedible.";
}
Empty: switch(n) {
    1: "#O# can't contain things.";
    2: "#O# #is# closed.";
    3: "#O# #is# empty already.";
    4: "That isn't possible.";
}
Enter: switch(n) {
    2: print_ret (thatsnotsomething) x1, "enter.";
    3: "#He's# already there.";
    4: "You'll have to put #o# down first.";
    5: "#A# can't get there.";
    6: print "#A# will have to get ";
       if (noun has upon) print "on";
       else if (noun has inside) print "into";
       else if (noun has under) print "under";
       else if (parent(noun) && parent(noun) has animate) print "on";
       else print "into";
       " ",(the) parent(noun)," first.";
    7: print_ret (The) parent(noun)," might not appreciate that.";
}
EnterIn: switch(n) {
    1: "#A# get#s# into #o#.";
    2: "#He's# already in #o#.";
    3: print_ret (thatsnotsomething) x1,"get inside of.";
}
EnterOn: switch(n) {
    1: "#A# get#s# onto #o#.";
    2: "#He's# already on #o#.";
    3: print_ret (thatsnotsomething) x1,"get on top of.";
}
EnterUnder: switch(n) {
    1: "#A# get#s# under #o#.";
    2: "#He's# already beneath #o#.";
    3: print_ret (thatsnotsomething) x1,"crawl beneath.";
}
Examine: switch(n) {
    1: "Darkness, noun. An absence of light to see by.";
    2: if (x1 in Compass) "#A# notice#s# nothing new in that direction.";
        "#A# see#s# nothing special about #o#.";
    3: print "#O# #is# currently ";
    4: if (x1 has open) print "open"; else print "closed";
    5: print "switched "; if (x1 has on) print "on"; else print "off";
}
Exit: switch(n) {
    1: "But #a-s# #is#n't in anything at the moment.";
    2: "You'll have to open #o# first.";
    3: print "But #he's# not ";
       if (noun has supporter) print "on";
       else if (noun has container) print "in";
       else if (noun has hider) print "under";
       else print "in";
       " #n#.";
}
ExitFromInside: switch(n) {
    1: "#A# get#s# out of #o#.";
}
ExitFromUpon: switch(n) {
    1: "#A# get#s# off of #o#.";
}
ExitFromUnder: switch(n) {
    1: "#A# get#s# out from under #o#.";
}
Exits: switch(n) {
    1: "#A# can't see the exits.";
    2: "There don't appear to be any exits.";
    3: print "#A# can go ";
    4: print " to #o#";
    5: print "parts unknown"; rtrue;
    6: print "#A# can only go ";
}
Fill: "But there's no liquid here.";
FullScore: switch(n) {
    1: print "The score ";
        if (deadflag) print "was"; else print "is";
        " made up as follows:^";
    2: print "finding sundry items";
    3: print "visiting various places";
    4: print "total (out of ", maximum_score; ")";
}
GetOff: "But #he's# not on #o# at the moment.";
Give: switch(n) {
    1: "#A# juggle#s# #o# for a while, but do#es-a#n't achieve much.";
    3: "#O# do#es#n't seem interested.";
   }
Go: switch(n) {
    1: print "#A# will have to get ";
       if (actor has upon) print "off of";
       else if (actor has inside) print "out of";
       else if (actor has under) print "out from under";
       else if (parent(actor) has animate) print "away from";
       else print "out of";
       " #o# first.";
    2: "#A# can't go that way.";
    3: "#A# #are# unable to climb #o#.";
    4: "#A# #are# unable to descend by #o#.";
    5: "#A# can't, since #o# #is# in the way.";
    6: "#A# can't, since #o# lead#s# nowhere.";
    11: if (actor == player) print_ret (string) x1;
    15: "You'll have to say which compass direction to go in.";
}
GoToRoom: switch(n) {
    1: "#A# can't even see where #a-s# #is# now!";
    2: "That was easy.";
    3: "#He's# not certain how to get there from here.";
    4: "#A# #has# lost #his# way in the dark.";
    5: "That's not a place #a-s# #has# been.";
    6: "No movement to continue!";
    7: "#A# look#s# confused.";
    8: "^(going ",(name) x1,")";
}
Inv: switch(n) {

    !  1 = Nothing to list
    !  2 = Preface to held items
    !  3 = End of held items, if nothing else
    !  4 = Between held and invent_late held
    !  5 = Between held and worn
    !  6 = Between held and invent_late worn
    !  7 = After invent_late held, if nothing else
    !  8 = Between invent_late held and worn
    !  9 = Between invent_late held and invent_late worn
    ! 10 = Preface to worn items, when none held
    ! 11 = After worn, if nothing else
    ! 12 = Between worn and invent_late worn
    ! 13 = After invent_late worn

    1: "#A# do#es#n't have a thing.";

    2: print "#A# #is# carrying";
       if (inventory_style & NEWLINE_BIT) print ":^";
       else print " ";

    3, 11: if (inventory_style & ENGLISH_BIT) print ".";
           if (inventory_style & NEWLINE_BIT == 0) new_line;

    4, 12: if (inventory_style & ENGLISH_BIT) print ". ";

    5: if (inventory_style & ENGLISH_BIT) print ".";
       if (inventory_style & NEWLINE_BIT == 0) new_line;
       print "^#A# #is# wearing";
       if (inventory_style & NEWLINE_BIT) print ":^";
       else print " ";

    6: if (inventory_style & ENGLISH_BIT) print ".";
       if (inventory_style & NEWLINE_BIT == 0) new_line;
       new_line;

    7, 13: new_line;
                                                        
    8: new_line;
       print "^#A# #is# wearing";
       if (inventory_style & NEWLINE_BIT) print ":^";
       else print " ";

    9: if (inventory_style & NEWLINE_BIT == 0) new_line;
       new_line;

   10: print "#A# #is# wearing";
       if (inventory_style & NEWLINE_BIT) print ":^";
       else print " ";
}
Insert: switch(n) {
    1: "#A# put#s# #o# into #d#.";
    2: "#D# can't contain things.";
    3: "#A# #is#n't holding #o#.";
    4: "#O# #is# already there.";
    5: "#A# can't put something inside itself.";
    6: "#D# #is# closed.";
    7: "There is no more room in #d#.";
}
Jump: "#A# jump#s# on the spot.";
JumpOver: "#A# would achieve nothing by this.";
Kiss: "Keep your mind on the game.";
Leave: switch(n) {
    1: "That would be difficult.";
}
Listen: "#A# hear#s# nothing unexpected.";
LMode1: print_ret (string) Story, " is now in its normal ~brief~ printing mode,
            which gives long descriptions of places when they are first entered.";
LMode2: print_ret (string) Story, " is now in its ~verbose~ mode, which always
            gives long descriptions of locations.";
LMode3: print_ret (string) Story, " is now in its ~superbrief~ mode, which
            always gives short descriptions of locations.";
Lock: switch(n) {
    2: print_ret (thatsnotsomething) x1,"lock.";
    3: print_ret (ctheyreorthats) x1, "locked at the moment.";
    4: "First #a-s# will have to close #o#.";
    5: if (x1 has pluralname) print "Those don't ";
        else print "That doesn't ";
        "seem to fit the lock.";
    5001: "#A# lock#s# #o#.";
}
Look: switch(n) {
    3: print " (as #o-x#)";
    4: print " (on #o-x#)";
    5: print " (in #o-x#)";
    6: print " (under #o-x#)";
    7: print " (carried by #o-x#)";
    8: print " (worn by #o-x#)";
    500: print "^#A# can "; if (x1 > 1) print "also "; print "see";
    501: print " here";
}
LookOn: switch(n) {
    1: "There is nothing on #n#.";
}
LookUnder: switch(n) {
    1: "#A# find#s# nothing of interest.";
    2: "But it's dark.";
}
Mild, Scream: "#A# feel#s# a little better.";
No, Yes: "That was a rhetorical question.";
NotifyOff, NotifyOn:
    print "Score notification "; if (notify_mode) "on."; "off.";
Open: switch(n) {
    1: "#A# open#s# #o#.";
    2: print_ret (thatsnotsomething) x1,"open.";
    3: "#O# seem#s# to be locked.";
    4: print_ret (ctheyreorthats) x1,"already open.";
    5: print "#A# open#s# #o#, revealing ";
    6: "#A# will have to open #o# first.";
    7: "#N# open#s#.";
}
Order: "#A# #has# better things to do.";
Places: switch(n) {
    1: print "#A# #has# visited: ";
    2: print "^#A# also know#s# about: ";
}
Pray: "There is no reply.";
Pronouns: switch(n) {
    1: print "At the moment, ";
    2: print "means ";
    3: print "is unset";
    4: "no pronouns are known to the game.";
}
Pull, Push, Turn: switch(n) {
    1: if (x1 has pluralname) print "Those are ";
        else print "It is ";
        "fixed in place.";
    2: "#A# #is# unable to.";
    3: "Nothing obvious happens.";
    4: "That would be less than courteous.";
}
PushDir: switch(n) {
    1: "Is that the best you can think of?";
    2: print_ret (ctheyreorthats) second,"not a direction.";
    3: "Not that way #a-s# can't.";
}
PutOn: switch(n) {
    1: "#A# put#s# #o# on #d#.";
    2: "#A# can't put something on top of itself.";
    3: "Putting things on #d# would achieve nothing.";
    4: "#A# #has# to put #d# down before #a-s# can put
       things on top of #ito-s#.";
    5: "#A# #is#n't holding #o#.";
    6: "There is no more room on #d#.";
}
PutUnder: switch(n) {
    1: "#A# put#s# #o# under #d#.";
    2: print "#A# can't put something under itself.";
    3: "#A# can't put anything under #d#.";
    4: "There is no more room under #d#.";
    5: "#A# #is#n't holding #o#.";
    6: print "#A# #have# to put #d# down before #a-s# can put
       things on top of #ito-s#.";
}
Quit: switch(n)
{   1: print "Please answer yes or no.";
    2: print "Are you sure you want to quit? ";
}
Restart: switch(n)
{   1: print "Are you sure you want to restart? ";
    2: "Failed.";
}
Restore: switch(n)
{   1: "Restore failed.";
    2: "Ok.";
}
Rub:    "#A# achieve#s# nothing by this.";
Save: switch(n)
{   1: "Save failed.";
    2: "Ok.";
}
Score: if (deadflag) print "In that game you scored ";
          else print "You have so far scored ";
          print score, " out of a possible ", maximum_score,
          ", in ", turns, " turn";
          if (turns ~= 1) print "s"; return;
! Scream, see Mild.
ScriptOff: switch(n)
{   1: "Transcripting is already off.";
    2: "^End of transcript.";
    3: "Attempt to end transcript failed.";
}
ScriptOn: switch(n)
{   1: "Transcripting is already on.";
    2: "Start of a transcript of";
    3: "Attempt to begin transcript failed.";
}
Search: switch(n) {
    1: "But it's dark.";
    4: "#A# find#s# nothing of interest.";
    5: "#A# can't see inside, since #o-s# #is# closed.";
    6: print "#O# #is# empty";
       if (actor in lm_o && actor has inside)
           print " (except for #a#)";
       ".";
}
Set:    "No, #a-s# can't set ", (thatorthose) x1, ".";
SetTo:  "No, #a-s# can't set ", (thatorthose) x1, " to anything.";
Show: switch(n) {
    1: "#D# #is# unimpressed.";
}
Sing:   "#His# singing is abominable.";
Sleep: "#A# #is#n't feeling especially drowsy.";
Smell: "#A# smell#s# nothing unexpected.";
Sorry:  #ifdef DIALECT_US;
        "Oh, don't apologize.";
        #ifnot;
        "Oh, don't apologise.";
        #endif;
Squeeze: switch(n) {
    1: "That would hardly be appropriate.";
    2: "#A# achieve#s# nothing by this.";
}
Strong: "And so's your mother!";
Swim:   "There's nowhere to do that here.";
Swing:  "There's nothing sensible to swing here.";
SwitchOff: switch(n) {
    1: "#A# switch#es# #o# off.";
    2: print_ret (thatsnotsomething) x1,"switch.";
    3: print_ret (ctheyreorthats) x1,"already off.";
}
SwitchOn: switch(n) {
    1: "#A# switch#es# #o# on.";
    2: print_ret (thatsnotsomething) x1,"switch.";
    3: print_ret (ctheyreorthats) x1,"already on.";
}
Take: switch(n) {
    1: if (multiflag && narrative_mode == 0) "Taken.";
       "#A# take#s# #o#.";
    2: "#A# #is# always self-possessed.";
    3: "#O# might not care for that.";
    4: LMRaw(##Go, 1, x1);
    5: "#A# already #have# #o#.";
    6: if (multiphase) "#O# do#es#n't belong to #him#.";
       "#N# seem#s# to belong to #o#.";
    7: if (multiphase) "#O# #is# attached to something.";
       "#N# seem#s# to be a part of #o#.";
    8: "#O# #is#n't available.";
    10: "#O# #is#n't something #a-s# can carry around.";
    11: "#O# #is# fixed in place.";
    12: "#He's# carrying too many things already.";
    20: "#O# #is#n't there.";
    21: if (multiphase) "Taking #o# is impossible.";
        "What a fascinating concept.";
    22: print "#A# take#s# #n#, revealing ";
   }
Taste: "#A# taste#s# nothing unexpected.";
Tell: if (x1 == actor) "#A# talk#s# to #himself# a while.";
        "This provokes no reaction.";
Think: "You'll have to do that yourself.";
ThrowAt: switch(n)
{   1: "Futile.";
    2: "#His# conviction deserts #him# as #a-s# contemplate#s# this heinous act.";
}
Tie: "That would be pointless.";
Touch: switch(n) {
    1: "That might not be appreciated.";
    2: "#A# feel#s# nothing unexpected.";
    3: "If you think that'll help.";
}
Unlock: switch(n) {
    2: print_ret (thatsnotsomething) x1,"unlock.";
    3: print_ret (ctheyreorthats) x1, "unlocked at the moment.";
    4: if (x1 has pluralname) print "Those don't ";
       else print "That doesn't ";
       "seem to fit the lock.";
    5001: "#A# unlock#s# #o# with #d#.";
}
Verify:  switch(n)
{   1: "The game file has verified as intact.";
    2: "The game file did not verify as intact,
        and may be corrupt.";
}
Wait: "Time passes.";
Wake: "#A# #is#n't sleeping.";
WakeOther: "That seems unnecessary.";
Wave: "#A# look#s# ridiculous waving #o#.";
WaveHands: "Hi!";
Wear: switch(n) {
    1: "#A# put#s# #o# on.";
    2: print_ret (thatsnotsomething) x1,"wear.";
    4: "#He's# already wearing ", (thatorthose) x1, ".";
}
! Yes, see No.
];
