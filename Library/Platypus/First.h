! "First.h"
! Part of Platypus release 4.
! Copyright 2001 Anson Turner and Graham Nelson
! (not necessarily in that order).
!
! Comments to: anson@pobox.com
!
! Please excuse the mess.

!     Table of contents
!     -----------------
!     Attributes                sec:01
!     Common properties         sec:02
!     Scope routines            sec:06


System_file;

Constant platypus_version = "release 4";

#ifndef TARGET_GLULX;
    Constant NULL = $ffff;
    Constant WORD_HIGHBIT = $8000;
#endif;
#ifdef TARGET_GLULX;
    Constant NULL = $ffffffff;
    Constant WORD_HIGHBIT = $80000000;
#endif;

#ifndef WORDSIZE;
    Constant WORDSIZE = 2;
#endif;

IFDEF INFIX; IFNDEF DEBUG; Constant DEBUG; ENDIF; ENDIF;
IFDEF STRICT_MODE; IFNDEF DEBUG; Constant DEBUG; ENDIF; ENDIF;

Default MAXIMUM_OPEN_BUFFERS 5;

Array buffer_addresses  table MAXIMUM_OPEN_BUFFERS;
#ifndef TARGET_GLULX;
Array buffer_offsets    table MAXIMUM_OPEN_BUFFERS;
Array buffer_saved_data table MAXIMUM_OPEN_BUFFERS;
#endif;
#ifdef TARGET_GLULX;
Global current_buffer;
#endif;
Global buffers_open;

Constant FIRST_PERSON  = 1;
Constant SECOND_PERSON = 2;
Constant THIRD_PERSON  = 3;

Global holdx_called;
Global last_name_printed;
Global stoplf;
Global multicount;
Global multiphase;
Global narrative_mode = false;
Global player_perspective = SECOND_PERSON;
Global code_table;
Global header_printed;
Global the_owner;
Global parsing_ahead;
Global ignore_darkness;
Global grammar_line;

Constant PLURAL_BIT =   8;

! ============================================================================
!      ATTRIBUTES                                                       sec:01
! ============================================================================

Attribute animate;   Attribute clothing;    Attribute edible;
Attribute openable;  Attribute switchable;  Attribute talkable;

Attribute container;
Attribute hider;
Attribute supporter;

Attribute inside;
Attribute upon;
Attribute under;
Attribute worn;

Attribute concealed;
Attribute general;
Attribute light;
Attribute locked;
Attribute moved;
Attribute on;
Attribute open;
Attribute proper;
Attribute static;
Attribute transparent;
Attribute visited;
Attribute workflag;
Attribute workflag2;

Attribute activedaemon;
Attribute activetimer;

Attribute male;
Attribute female;
Attribute neuter;
Attribute pluralname;

Attribute void;

Attribute quotedmode;

Attribute known;
Attribute secret;

! ============================================================================
!      COMMON PROPERTIES                                                sec:02
! ============================================================================

    ! Parsing

Property additive adjective;
Property grammar;
Property parse_name 0;
Property possessive;
Property words 0;

    ! Reactions

Property additive meddle_early           NULL;
Property additive meddle                 NULL;
Property additive meddle_late            NULL;
Property additive meddle_late_late       NULL;
Property additive respond_early          NULL;
Property additive respond                NULL;
Property additive respond_late           NULL;
Property additive respond_early_indirect NULL;
Property additive respond_indirect       NULL;
Property additive respond_late_indirect  NULL;

    ! Output

Property additive messages;
Property description;
Property invent;
Property list_together;
Property plural;
Property inside_description;
Property additive describe NULL;
Property cant_go;
Property article "a";
Property articles;
Property short_name 0;
Property short_name_indef 0;

    ! Daemons, etc.

Property additive daemon NULL;
Property time_left;
Property additive time_out NULL;
Property additive each_turn NULL;

    ! Capacities

Property inside_capacity 100;
Property upon_capacity 100;
Property under_capacity 100;

    ! Scope

Property additive add_to_scope;
Property found_in;
Property shared;

    ! Rooms

Property dirs;
Property fpsa;

    ! And the rest...

Property points 0;
Property additive orders;
Property number;
Property location;



Constant MAX_PATH_LENGTH = 32;
Array PathMovesA --> MAX_PATH_LENGTH;
Array PathRoomsA --> MAX_PATH_LENGTH;

Global moving_player;
Global PathLengthG;

#IFDEF RUNTIME_DICTIONARY_MAX_WORDS;
#ifndef TARGET_GLULX;
Constant RUNTIME_DICTIONARY_BYTES = RUNTIME_DICTIONARY_MAX_WORDS * 9 + 7;
#endif;
#ifdef TARGET_GLULX;
Constant RUNTIME_DICTIONARY_BYTES =
    ((RUNTIME_DICTIONARY_MAX_WORDS + 1) * (7 + DICT_WORD_SIZE)) + 4;
#endif;
Array RuntimeDictionary -> RUNTIME_DICTIONARY_BYTES;
#ENDIF;

Global maximum_score;

Default PRINT_BUFFER_SIZE = 2050;
Array PrintBuffer -> PRINT_BUFFER_SIZE;

Default BYTE1A_SIZE = 162;
Default BYTE2A_SIZE = 162;

Array Byte1A -> BYTE1A_SIZE;
Array Byte2A -> BYTE2A_SIZE;


Global desc_used;
Global finding_path;

Global action_failed;

Global numspec;
Global indef_mode_spec;
Constant DEFINITE_MODE = 0;
Constant INDEFINITE_MODE = 1;

Constant BIT16 = -32768;
Constant MINUS1 = -1;

Constant LOWER_TO_UPPER = 'A' - 'a';
Constant UPPER_TO_LOWER = 'a' - 'A';

!Constant react_after;
!Constant react_before;

! ************

Constant Grammar__Version = 2;
IFNDEF VN_1610;
Message fatalerror "***  needs Inform v6.10 or later to work ***";
ENDIF;

Fake_action ExitFromInside;
Fake_action ExitFromUpon;
Fake_action ExitFromUnder;
Fake_Action Listing;
Fake_Action WhichOne;
Fake_Action Alphabetizing;
Fake_Action Order;
Fake_Action TheSame;
Fake_Action PluralFound;
Fake_Action ListMiscellany;
Fake_Action Miscellany;
Fake_Action Prompt;
Fake_Action NotUnderstood;

IFDEF NO_PLACES;
Fake_Action Places;
ENDIF;

[ Main; InformLibrary.play(); ];

! ----------------------------------------------------------------------------

! ============================================================================
!   Global variables and their associated Constant and Array declarations
! ----------------------------------------------------------------------------
Global sline1;                       ! Must be second
Global sline2;                       ! Must be third
                                     ! (for status line display)
! ------------------------------------------------------------------------------
!   Z-Machine and interpreter issues
! ------------------------------------------------------------------------------
#ifndef TARGET_GLULX;
Global top_object;                   ! Largest valid number of any tree object
Global standard_interpreter;         ! The version number of the Z-Machine
                                     ! Standard which the interpreter claims
                                     ! to support, in form (upper byte).(lower)
#endif;
Global undo_flag;                    ! Can the interpreter provide "undo"?
Global just_undone;                  ! Can't have two successive UNDOs
#ifndef TARGET_GLULX;
Global transcript_mode;              ! true when game scripting is on
#IFDEF DEBUG;
Global xcommsdir;                    ! true if command recording is on
#ENDIF;
#endif;
#ifdef TARGET_GLULX;
Constant GG_MAINWIN_ROCK  201;
Constant GG_STATUSWIN_ROCK  202;
Constant GG_QUOTEWIN_ROCK  203;
Constant GG_SAVESTR_ROCK 301;
Constant GG_SCRIPTSTR_ROCK 302;
Constant GG_COMMANDWSTR_ROCK 303;
Constant GG_COMMANDRSTR_ROCK 304;
Constant GG_SCRIPTFREF_ROCK 401;
Constant GG_STATUSWIN_SIZE  1; !### make overridable
Array gg_event --> 4;
Array gg_arguments --> 8;
Global gg_mainwin = 0;
Global gg_statuswin = 0;
Global gg_quotewin = 0;
Global gg_scriptfref = 0;
Global gg_scriptstr = 0;
Global gg_savestr = 0;
Global gg_statuswin_cursize = 0;
IFDEF DEBUG;
Global gg_commandstr = 0;
Global gg_command_reading = 0; ! true if gg_commandstr is being replayed
ENDIF;
#endif; ! TARGET_GLULX

! ------------------------------------------------------------------------------
!   Time and score
! ------------------------------------------------------------------------------
Global turns = 1;                    ! Number of turns of play so far
Global the_time = NULL;              ! Current time (in minutes since midnight)
Global time_rate = 1;                ! How often time is updated
Global time_step;                    ! By how much

Global score;                        ! The current score
Global last_score;                   ! Score last turn (for testing for changes)
Global notify_mode = true;           ! Score notification

! ------------------------------------------------------------------------------
!   The player
! ------------------------------------------------------------------------------
Global player;                       ! Which object the human is playing through
Global deadflag;                     ! Normally 0, or false; 1 for dead;
                                     ! 2 for victorious, and higher numbers
                                     ! represent exotic forms of death
! ------------------------------------------------------------------------------
!   Light and room descriptions
! ------------------------------------------------------------------------------
Global lightflag = true;             ! Is there currently light to see by?
Global visibility_ceiling;           ! Highest object in tree visible from
                                     ! the player's point of view (usually
                                     ! the room, sometimes darkness, sometimes
                                     ! a closed non-transparent container).

Global lookmode = 1;                 ! 1=standard, 2=verbose, 3=brief room descs
Global print_player_flag;            ! If set, print something like "(as Fred)"
                                     ! in room descriptions, to reveal whom
                                     ! the human is playing through
Global lastdesc;                     ! Value of location at time of most recent
                                     ! room description printed out
! ------------------------------------------------------------------------------
!   List writing  (style bits are defined as Constants in "verblibm.h")
! ------------------------------------------------------------------------------
Global c_style;                      ! Current list-writer style
Global lt_value;                     ! Common value of list_together
Global listing_together;             ! Object number of one member of a group
                                     ! being listed together
Global listing_size;                 ! Size of such a group
Global wlf_indent;                   ! Current level of indentation printed by
                                     ! WriteListFrom routine

Global inventory_stage = 1;          ! 1 or 2 according to the context in which
                                     ! "invent" routines of objects are called
Global inventory_style;              ! List-writer style currently used while
                                     ! printing inventories

! ------------------------------------------------------------------------------

Global lm_n;                         ! Parameters used by LibraryMessages
Global lm_o;                         ! mechanism

IFDEF DEBUG;
Global debug_flag;                   ! Bitmap of flags for tracing actions,
                                     ! calls to object routines, etc.
Global x_scope_count;                ! Used in printing a list of everything
                                     ! in scope
ENDIF;
! ------------------------------------------------------------------------------
!   Action processing
! ------------------------------------------------------------------------------
Global action;                       ! Action currently being asked to perform
Global inp1;                         ! 0 (nothing), 1 (number) or first noun
Global inp2;                         ! 0 (nothing), 1 (number) or second noun
Global noun;                         ! First noun or numerical value
Global second;                       ! Second noun or numerical value

Global keep_silent;                  ! If true, attempt to perform the action
                                     ! silently (e.g. for implicit takes,
                                     ! implicit opening of unlocked doors)
! ==============================================================================
!   Parser variables: first, for communication to the parser
! ------------------------------------------------------------------------------
Global parser_trace = 0;             ! Set this to 1 to make the parser trace
                                     ! tokens and lines
Global parser_action;                ! For the use of the parser when calling
Global parser_one;                   ! user-supplied routines
Global parser_two;                   !
Array  inputobjs       --> 16;       ! For parser to write its results in
Global parser_inflection;            ! A property (usually "name") to find
                                     ! object names in
! ------------------------------------------------------------------------------
!   Parser output
! ------------------------------------------------------------------------------
Global actor;                        ! Person asked to do something
Global actors_location;              ! Like location, but for the actor
Global meta;                         ! Verb is a meta-command (such as "save")

Array  multiple_object --> 64;       ! List of multiple parameters
Array  multiple_outcome --> 64;
Global multiflag;                    ! Multiple-object flag
Global toomany_flag;                 ! Flag for "multiple match too large"
                                     ! (e.g. if "take all" took over 100 things)

Global special_word;                 ! Dictionary address for "special" token
Global special_number;               ! Number typed for "special" token
Global parsed_number;                ! For user-supplied parsing routines
Global consult_from;                 ! Word that a "consult" topic starts on
Global consult_words;                ! ...and number of words in topic

! ------------------------------------------------------------------------------
!   Error numbers when parsing a grammar line
! ------------------------------------------------------------------------------
Global etype;                        ! Error number on current line
Global best_etype;                   ! Preferred error number so far
Global nextbest_etype;               ! Preferred one, if ASKSCOPE_PE disallowed

Constant STUCK_PE     = 1;
Constant UPTO_PE      = 2;
Constant NUMBER_PE    = 3;
Constant CANTSEE_PE   = 4;
Constant TOOLIT_PE    = 5;
Constant NOTHELD_PE   = 6;
Constant MULTI_PE     = 7;
Constant MMULTI_PE    = 8;
Constant VAGUE_PE     = 9;
Constant EXCEPT_PE    = 10;
Constant ANIMA_PE     = 11;
Constant VERB_PE      = 12;
Constant SCENERY_PE   = 13;
Constant ITGONE_PE    = 14;
Constant JUNKAFTER_PE = 15;
Constant TOOFEW_PE    = 16;
Constant NOTHING_PE   = 17;
Constant NONEHELD_PE  = 18;
Constant ASKSCOPE_PE  = 19;
! ------------------------------------------------------------------------------
!   Pattern-matching against a single grammar line
! ------------------------------------------------------------------------------
Array pattern --> 32;                ! For the current pattern match
Global pcount;                       ! and a marker within it
Array pattern2 --> 32;               ! And another, which stores the best match
Global pcount2;                      ! so far
Constant PATTERN_NULL = NULL;       ! Entry for a token producing no text

Array  line_ttype-->32;              ! For storing an analysed grammar line
Array  line_tdata-->32;
Array  line_token-->32;

Global parameters;                   ! Parameters (objects) entered so far
Global nsns;                         ! Number of special_numbers entered so far
Global special_number1;              ! First number, if one was typed
Global special_number2;              ! Second number, if two were typed
! ------------------------------------------------------------------------------
!   Inferences and looking ahead
! ------------------------------------------------------------------------------
Global params_wanted;                ! Number of parameters needed
                                     ! (which may change in parsing)

Global inferfrom;                    ! The point from which the rest of the
                                     ! command must be inferred
Global inferword;                    ! And the preposition inferred
Global dont_infer;                   ! Another dull flag

Global action_to_be;                 ! (If the current line were accepted.)
Global action_reversed;              ! (Parameters would be reversed in order.)
Global advance_warning;              ! What a later-named thing will be
! ------------------------------------------------------------------------------
!   At the level of individual tokens now
! ------------------------------------------------------------------------------
Global found_ttype;                  ! Used to break up tokens into type
Global found_tdata;                  ! and data (by AnalyseToken)
Global token_filter;                 ! For noun filtering by user routines

#ifndef TARGET_GLULX;
Constant REPARSE_CODE = 10000;       ! Signals "reparse the text" as a reply
                                     ! from NounDomain
#endif;
#ifdef TARGET_GLULX;
Constant REPARSE_CODE = $40000000;   ! The parser rather gunkily adds addresses
                                     ! to REPARSE_CODE for some purposes.
                                     ! And expects the result to be greater
                                     ! than REPARSE_CODE (signed comparison).
                                     ! So Glulx Inform is limited to a single
                                     ! gigabyte of storage, for the moment.
#endif; ! TARGET_

Global lookahead;                    ! The token after the one now being matched

Global multi_mode;                   ! Multiple mode
Global multi_wanted;                 ! Number of things needed in multitude
Global multi_had;                    ! Number of things actually found
Global multi_context;                ! What token the multi-obj was accepted for

Global indef_mode;                   ! "Indefinite" mode - ie, "take a brick"
                                     ! is in this mode
Global indef_cases;                  ! Possible gender and numbers of them
Global indef_type;                   ! Bit-map holding types of specification
Global indef_wanted;                 ! Number of items wanted (100 for all)
Global indef_guess_p;                ! Plural-guessing flag

Global allow_plurals;                ! Whether plurals presently allowed or not

Global take_all_rule;                ! Slightly different rules apply to
                                     ! "take all" than other uses of multiple
                                     ! objects, to make adjudication produce
                                     ! more pragmatically useful results
                                     ! (Not a flag: possible values 0, 1, 2)

Global dict_flags_of_noun;           ! Of the noun currently being parsed
                                     ! (a bitmap in #dict_par1 format)
Global pronoun_word;                 ! Records which pronoun ("it", "them", ...)
                                     ! caused an error
Global pronoun_obj;                  ! And what obj it was thought to refer to
Global pronoun__word;                ! Saved value
Global pronoun__obj;                 ! Saved value
! ------------------------------------------------------------------------------
!   Searching through scope and parsing "scope=Routine" grammar tokens
! ------------------------------------------------------------------------------
Constant PARSING_REASON        = 0;  ! Possible reasons for searching scope
Constant TALKING_REASON        = 1;
Constant EACH_TURN_REASON      = 2;
Constant MEDDLE_EARLY_REASON   = 3;
Constant MEDDLE_LATE_REASON    = 4;
Constant LOOPOVERSCOPE_REASON  = 5;
Constant TESTSCOPE_REASON      = 6;
Constant MEDDLE_REASON = 20;
Constant MEDDLE_LATE_LATE_REASON = 21;

Global scope_reason = PARSING_REASON; ! Current reason for searching scope

Global scope_token;                  ! For "scope=Routine" grammar tokens
Global scope_error;
Global scope_stage;                  ! 1, 2 then 3

Global ats_flag = 0;                 ! For add_to_scope routines
Global ats_hls;                      !

! ------------------------------------------------------------------------------
!   The match list of candidate objects for a given token
! ------------------------------------------------------------------------------
Constant MATCH_LIST_SIZE = 64;
Array  match_list    --> MATCH_LIST_SIZE; ! An array of matched objects so far
Array  match_classes --> MATCH_LIST_SIZE; ! An array of equivalence classes for them
Array  match_scores  --> MATCH_LIST_SIZE; ! An array of match scores for them
Global number_matched;               ! How many items in it?  (0 means none)
Global number_of_classes;            ! How many equivalence classes?
Global match_length;                 ! How many words long are these matches?
Global match_descriptors;
Global match_from;                   ! At what word of the input do they begin?
Global bestguess_score;              ! What did the best-guess object score?
! ------------------------------------------------------------------------------
!   Low level textual manipulation
! ------------------------------------------------------------------------------
#ifndef TARGET_GLULX;

Constant INPUT_BUFFER_LEN = 120;     ! Length of buffer array (although we
                                     ! leave an extra byte to allow for
                                     ! interpreter bugs)

Array  buffer    -> 121;             ! Buffer for parsing main line of input
Array  parse     -> 65;              ! Parse table mirroring it
Array  buffer2   -> 121;             ! Buffers for supplementary questions
Array  parse2    -> 65;              !
Array  buffer3   -> 121;             ! Buffer retaining input for "again"

#endif;
#ifdef TARGET_GLULX;

Constant INPUT_BUFFER_LEN = 260;     ! No extra byte necessary
Constant MAX_BUFFER_WORDS = 20;
Constant PARSE_BUFFER_LEN = 244;     ! 4 + MAX_BUFFER_WORDS*4;

Array  buffer    -> INPUT_BUFFER_LEN;
Array  parse     -> PARSE_BUFFER_LEN;
Array  buffer2   -> INPUT_BUFFER_LEN;
Array  parse2    -> PARSE_BUFFER_LEN;
Array  buffer3   -> INPUT_BUFFER_LEN;

#endif; ! TARGET_

Constant COMMA_WORD = ', ';          ! An "untypeable word" used to substitute
                                     ! for commas in parse buffers
Constant QUOTE_WORD = '" ';          ! And likewise for quotation marks

Global wn;                           ! Word number within "parse" (from 1)
Global num_words;                    ! Number of words typed
Global verb_word;                    ! Verb word (eg, take in "take all" or
                                     ! "dwarf, take all") - address in dict
Global verb_wordnum;                 ! its number in typing order (eg, 1 or 3)
Global usual_grammar_after;          ! Point from which usual grammar is parsed
                                     ! (it may vary from the above if user's
                                     ! routines match multi-word verbs)

Global oops_from;                    ! The "first mistake" word number
Global saved_oops;                   ! Used in working this out
Array  oops_workspace -> 64;         ! Used temporarily by "oops" routine

Global held_back_mode;               ! Flag: is there some input from last time
Global hb_wn;                        ! left over?  (And a save value for wn.)
                                     ! (Used for full stops and "then".)
! ----------------------------------------------------------------------------
Array PowersOfTwo_TB                 ! Used in converting case numbers to
  --> $$100000000000                 ! case bitmaps
      $$010000000000
      $$001000000000
      $$000100000000
      $$000010000000
      $$000001000000
      $$000000100000
      $$000000010000
      $$000000001000
      $$000000000100
      $$000000000010
      $$000000000001;

! ============================================================================
!  Constants, and one variable, needed for the language definition file
! ----------------------------------------------------------------------------
Constant POSSESS_PK  = $100;
Constant DEFART_PK   = $101;
Constant INDEFART_PK = $102;
Global short_name_case;
! ----------------------------------------------------------------------------
Include "language__";                !  The natural language definition,
                                     !  whose filename is taken from the ICL
                                     !  language_name variable
! ----------------------------------------------------------------------------
#ifndef LanguageCases;
Constant LanguageCases = 1;
#endif;

! ============================================================================
! "Darkness" is not really a place: but it has to be an object so that the
!  location-name on the status line can be "Darkness".
! ----------------------------------------------------------------------------
Object thedark "(thedark)"
  has proper,
  with initial 0,
       short_name DARKNESS__TX,
       description
       [;  return L__M(##Miscellany, 17);
       ];

! ============================================================================
!  The definition of the token-numbering system used by Inform.
! ----------------------------------------------------------------------------

Constant ILLEGAL_TT        = 0;      ! Types of grammar token: illegal
Constant ELEMENTARY_TT     = 1;      !     (one of those below)
Constant PREPOSITION_TT    = 2;      !     e.g. 'into'
Constant ROUTINE_FILTER_TT = 3;      !     e.g. noun=CagedCreature
Constant ATTR_FILTER_TT    = 4;      !     e.g. edible
Constant SCOPE_TT          = 5;      !     e.g. scope=Spells
Constant GPR_TT            = 6;      !     a general parsing routine

Constant NOUN_TOKEN        = 0;      ! The elementary grammar tokens, and
Constant HELD_TOKEN        = 1;      ! the numbers compiled by Inform to
Constant MULTI_TOKEN       = 2;      ! encode them
Constant MULTIHELD_TOKEN   = 3;
Constant MULTIEXCEPT_TOKEN = 4;
Constant MULTIINSIDE_TOKEN = 5;
Constant CREATURE_TOKEN    = 6;
Constant SPECIAL_TOKEN     = 7;
Constant NUMBER_TOKEN      = 8;
Constant TOPIC_TOKEN       = 9;

Constant GPR_FAIL          = -1;     ! Return values from General Parsing
Constant GPR_PREPOSITION   = 0;      ! Routines
Constant GPR_NUMBER        = 1;
Constant GPR_MULTIPLE      = 2;
Constant GPR_REPARSE       = REPARSE_CODE;
Constant GPR_NOUN          = $ff00;
Constant GPR_HELD          = $ff01;
Constant GPR_MULTI         = $ff02;
Constant GPR_MULTIHELD     = $ff03;
Constant GPR_MULTIEXCEPT   = $ff04;
Constant GPR_MULTIINSIDE   = $ff05;
Constant GPR_CREATURE      = $ff06;

Constant ENDIT_TOKEN       = 15;     ! Value used to mean "end of grammar line"

[ AnalyseToken token;

    if (token == ENDIT_TOKEN)
    {   found_ttype = ELEMENTARY_TT;
        found_tdata = ENDIT_TOKEN;
        return;
    }

    found_ttype = (token->0) & $$1111;
    found_tdata = (token+1)-->0;
];

#ifndef TARGET_GLULX;
[ UnpackGrammarLine line_address i;
  for (i = 0 : i < 32 : i++)
  {   line_token-->i = ENDIT_TOKEN;
      line_ttype-->i = ELEMENTARY_TT;
      line_tdata-->i = ENDIT_TOKEN;
  }
  action_to_be = 256*(line_address->0) + line_address->1;
  action_reversed = ((action_to_be & $400) ~= 0);
  action_to_be = action_to_be & $3ff;
  line_address--;
  params_wanted = 0;
  for (i=0::i++)
  {   line_address = line_address + 3;
      if (line_address->0 == ENDIT_TOKEN) break;
      line_token-->i = line_address;
      AnalyseToken(line_address);
      if (found_ttype ~= PREPOSITION_TT) params_wanted++;
      line_ttype-->i = found_ttype;
      line_tdata-->i = found_tdata;
  }
  return line_address + 1;
];
#endif;
#ifdef TARGET_GLULX;
[ UnpackGrammarLine line_address i;
  for (i = 0 : i < 32 : i++)
  {   line_token-->i = ENDIT_TOKEN;
      line_ttype-->i = ELEMENTARY_TT;
      line_tdata-->i = ENDIT_TOKEN;
  }
  @aloads line_address 0 action_to_be;
  action_reversed = (((line_address->2) & 1) ~= 0);
  line_address = line_address - 2;
  params_wanted = 0;
  for (i=0::i++)
  {   line_address = line_address + 5;
      if (line_address->0 == ENDIT_TOKEN) break;
      line_token-->i = line_address;
      AnalyseToken(line_address);
      if (found_ttype ~= PREPOSITION_TT) params_wanted++;
      line_ttype-->i = found_ttype;
      line_tdata-->i = found_tdata;
  }
  return line_address + 1;
];
#endif; ! TARGET_

#ifndef TARGET_GLULX;
[ Tokenise__ buf par     da;

    buf -> (2 + buf -> 1) = 0;
    #ifdef RuntimeDictionary;
        @tokenise buf par RuntimeDictionary;
        da = $08 --> 0;
        @tokenise buf par da 1; 
    #endif;
    #ifndef RuntimeDictionary;
        da = $08 --> 0;
        @tokenise buf par da;
    #endif;
];
#endif;
#ifdef TARGET_GLULX;
Array gg_tokenbuf -> DICT_WORD_SIZE;

[ GGWordCompare str1 str2 ix jx;
  for (ix=0 : ix < DICT_WORD_SIZE : ix++) {
    jx = (str1->ix) - (str2->ix);
    if (jx ~= 0)
      return jx;
  }
  return 0;
];

[ Tokenise__ buf tab
    cx numwords len bx ix wx wpos wlen val res dictlen entrylen;

  len = buf-->0;
  buf = buf + WORDSIZE;

  ! First, split the buffer up into words. We use the standard Infocom
  ! list of word separators (comma, period, double-quote).

  cx = 0;  numwords = 0;
  while (cx < len) {
    while (cx < len && buf->cx == ' ') cx++;
    if (cx >= len) break;
    bx = cx;
    if (buf->cx == '.' or ',' or '"') cx++;
    else while (cx < len && buf->cx ~= ' ' or '.' or ',' or '"')
        cx++;
    tab-->(numwords*3 + 2) = (cx - bx);
    tab-->(numwords*3 + 3) = WORDSIZE + bx;
    numwords++;
    if (numwords >= MAX_BUFFER_WORDS)
      break;
  }
  tab-->0 = numwords;  

  ! Now we look each word up in the dictionary.

  dictlen = #dictionary_table-->0;
  entrylen = DICT_WORD_SIZE + 7;

  for (wx = 0 : wx < numwords : wx++) {
    wlen = tab-->(wx*3+2);
    wpos = tab-->(wx*3+3);

    ! Copy the word into the gg_tokenbuf array, clipping to DICT_WORD_SIZE
    ! characters and lower case.

    if (wlen > DICT_WORD_SIZE) wlen = DICT_WORD_SIZE;
    cx = wpos - WORDSIZE;
    for (ix = 0 : ix < wlen : ix++) {
      gg_tokenbuf->ix = glk($00A0, buf->(cx+ix));
    }
    for ( : ix < DICT_WORD_SIZE : ix++) {
      gg_tokenbuf->ix = 0;
    }

    val = #dictionary_table + WORDSIZE;
    @binarysearch gg_tokenbuf DICT_WORD_SIZE val entrylen dictlen
      1 1 res;
#ifdef RuntimeDictionary;
    if (res == 0)
    {   val = RuntimeDictionary + WORDSIZE;
        @linearsearch gg_tokenbuf DICT_WORD_SIZE val entrylen MINUS1 1 3 res;
    }
#endif;
    tab-->(wx*3+1) = res;
  }
];
#endif;

! ============================================================================
!  The InformParser object abstracts the front end of the parser.
!
!  InformParser.parse_input(results)
!  returns only when a sensible request has been made, and puts into the
!  "results" buffer:
!
!  --> 0 = The action number
!  --> 1 = Number of parameters
!  --> 2, 3, ... = The parameters (object numbers), but
!                  0 means "put the multiple object list here"
!                  1 means "put one of the special numbers here"
!
! ----------------------------------------------------------------------------

Object InformParser "(Inform Parser)"
  with parse_input
       [ results; Parser__parse(results);
       ], has proper;

! ----------------------------------------------------------------------------
!  The Keyboard routine actually receives the player's words,
!  putting the words in "a_buffer" and their dictionary addresses in
!  "a_table".  It is assumed that the table is the same one on each
!  (standard) call.
!
!  It can also be used by miscellaneous routines in the game to ask
!  yes-no questions and the like, without invoking the rest of the parser.
!
!  Return the number of words typed
! ----------------------------------------------------------------------------

#ifndef TARGET_GLULX;
[ KeyboardPrimitive  a_buffer a_table;
  read a_buffer a_table;
];
#endif;
#ifdef TARGET_GLULX;
[ KeyCharPrimitive win nostat done res ix jx ch;
  ix = jx; ix = ch; ! squash compiler warnings
  if (win == 0)
    win = gg_mainwin;
#IFDEF DEBUG;
  if (gg_commandstr ~= 0 && gg_command_reading ~= false) {
    ! get_line_stream
    done = glk($0091, gg_commandstr, gg_arguments, 31);
    if (done == 0) {
      glk($0044, gg_commandstr, 0); ! stream_close
      gg_commandstr = 0;
      gg_command_reading = false;
      ! fall through to normal user input.
    }
    else {
      ! Trim the trailing newline
      if (gg_arguments->(done-1) == 10)
        done = done-1;
      res = gg_arguments->0;
      if (res == '\') {
        res = 0;
        for (ix=1 : ix<done : ix++) {
          ch = gg_arguments->ix;
          if (ch >= '0' && ch <= '9') {
            @shiftl res 4 res;
            res = res + (ch-'0');
          }
          else if (ch >= 'a' && ch <= 'f') {
            @shiftl res 4 res;
            res = res + (ch+10-'a');
          }
          else if (ch >= 'A' && ch <= 'F') {
            @shiftl res 4 res;
            res = res + (ch+10-'A');
          }
        }
      }
      jump KCPContinue;
    }
  }
#ENDIF;
  done = false;
  glk($00D2, win); ! request_char_event
  while (~~done) {
    glk($00C0, gg_event); ! select
    switch (gg_event-->0) {
      5: ! evtype_Arrange
        if (nostat) {
          glk($00D3, win); ! cancel_char_event
          res = $80000000;
          done = true;
          break;
        }
        DrawStatusLine();
      2: ! evtype_CharInput
        if (gg_event-->1 == win) {
          res = gg_event-->2;
          done = true;
        }
    }
    HandleGlkEvent(gg_event, 1);
  }
#IFDEF DEBUG;
  if (gg_commandstr ~= 0 && gg_command_reading == false) {
    if (res < 32 || res >= 256 || (res == '\' or ' ')) {
      glk($0081, gg_commandstr, '\'); ! put_buffer_char
      done = 0;
      jx = res;
      for (ix=0 : ix<8 : ix++) {
        @ushiftr jx 28 ch;
        @shiftl jx 4 jx;
        ch = ch & $0F;
        if (ch ~= 0 || ix == 7) done = 1;
        if (done) {
          if (ch >= 0 && ch <= 9)
            ch = ch + '0';
          else
            ch = (ch - 10) + 'A';
          glk($0081, gg_commandstr, ch); ! put_buffer_char
        }
      }
    }
    else {
      glk($0081, gg_commandstr, res); ! put_buffer_char
    }
    glk($0081, gg_commandstr, 10); ! put_char_stream (newline)
  }
#ENDIF;
.KCPContinue;
  return res;
];
[ KeyboardPrimitive  a_buffer a_table done;
#IFDEF DEBUG;
  if (gg_commandstr ~= 0 && gg_command_reading ~= false) {
    ! get_line_stream
    done = glk($0091, gg_commandstr, a_buffer+WORDSIZE,
      (INPUT_BUFFER_LEN-WORDSIZE)-1);
    if (done == 0) {
      glk($0044, gg_commandstr, 0); ! stream_close
      gg_commandstr = 0;
      gg_command_reading = false;
      print "[Command replay complete.]^";
      ! fall through to normal user input.
    }
    else {
      ! Trim the trailing newline
      if ((a_buffer+WORDSIZE)->(done-1) == 10)
        done = done-1;
      a_buffer-->0 = done;
      glk($0086, 8); ! set input style
      glk($0084, a_buffer+WORDSIZE, done); ! put_buffer
      glk($0086, 0); ! set normal style
      print "^";
      jump KPContinue;
    }
  }
#ENDIF;
  done = false;
  glk($00D0, gg_mainwin, a_buffer+WORDSIZE, INPUT_BUFFER_LEN-WORDSIZE, 
    0); ! request_line_event
  while (~~done) {
    glk($00C0, gg_event); ! select
    switch (gg_event-->0) {
      5: ! evtype_Arrange
        DrawStatusLine();
      3: ! evtype_LineInput
        if (gg_event-->1 == gg_mainwin)
          done = true;
    }
    HandleGlkEvent(gg_event, 0);
  }
  a_buffer-->0 = gg_event-->2;
#IFDEF DEBUG;
  if (gg_commandstr ~= 0 && gg_command_reading == false) {
    ! put_buffer_stream
    glk($0085, gg_commandstr, a_buffer+WORDSIZE, a_buffer-->0); 
    glk($0081, gg_commandstr, 10); ! put_char_stream (newline)
  }
#ENDIF;
.KPContinue;
  Tokenise__(a_buffer,a_table);
  ! It's time to close any quote window we've got going.
  if (gg_quotewin) {
    glk($0024, gg_quotewin, 0); ! close_window
    gg_quotewin = 0;
  }
];
#endif; ! TARGET_

[ Keyboard  a_buffer a_table  nw i w w2 x1 x2;

    DisplayStatus();
    .FreshInput;

!  Save the start of the buffer, in case "oops" needs to restore it
!  to the previous time's buffer

    CopyBytes(a_buffer, oops_workspace, 64);

!  In case of an array entry corruption that shouldn't happen, but would be
!  disastrous if it did:

#ifndef TARGET_GLULX;
   a_buffer->0 = INPUT_BUFFER_LEN;
   a_table->0 = 15;  ! Allow to split input into this many words
#endif; ! TARGET_

!  Print the prompt, and read in the words and dictionary addresses

    L__M(##Prompt);
    header_printed = 0;
    last_name_printed = 0;
    ClearNamesPrinted();
    AfterPrompt();
    DrawStatusLine();
    KeyboardPrimitive(a_buffer, a_table);
#ifndef TARGET_GLULX;
    nw=a_table->1;
#endif;
#ifdef TARGET_GLULX;
    nw=a_table-->0;
#endif; ! TARGET_

!  If the line was blank, get a fresh line
    if (nw == 0)
    { L__M(##Miscellany,10); jump FreshInput; }

!  Unless the opening word was "oops", return

    w=a_table-->1;
    if (w == OOPS1__WD or OOPS2__WD or OOPS3__WD) jump DoOops;

!  Undo handling

    if ((w == UNDO1__WD or UNDO2__WD or UNDO3__WD) && (nw==1))
    {   if (turns==1)
        {   L__M(##Miscellany,11); jump FreshInput;
        }
        if (undo_flag==0)
        {   L__M(##Miscellany,6); jump FreshInput;
        }
        if (undo_flag==1) jump UndoFailed;
#ifndef TARGET_GLULX;
        ! The just_undone check shouldn't be done in Glulx, as multiple
        ! undo is possible.
        if (just_undone==1)
        {   L__M(##Miscellany,12); jump FreshInput;
        }
        @restore_undo i;
#endif;
#ifdef TARGET_GLULX;
        @restoreundo i;
        i = (~~i);
#endif; ! TARGET_
        if (i==0)
        {   .UndoFailed;
            L__M(##Miscellany,7);
        }
        jump FreshInput;
    }
#ifndef TARGET_GLULX;
    @save_undo i;
#endif;
#ifdef TARGET_GLULX;
    @saveundo i;
    if (i == -1) {
        GGRecoverObjects();
        i = 2;
    }
    else {
        i = (~~i);
    }
#endif; ! TARGET_
    just_undone=0;
    undo_flag=2;
    if (i==-1) undo_flag=0;
    if (i==0) undo_flag=1;
    if (i==2)
    {

#ifndef TARGET_GLULX;
        style bold;
#endif;
#ifdef TARGET_GLULX;
        glk($0086, 4); ! set subheader style
#endif; ! TARGET_
        print (name) player.location, "^";
#ifndef TARGET_GLULX;
        style roman;
#endif;
#ifdef TARGET_GLULX;
        glk($0086, 0); ! set normal style
#endif; ! TARGET_
        L__M(##Miscellany,13);
        just_undone=1;
        jump FreshInput;
    }

    return nw;

    .DoOops;
    if (oops_from == 0)
    {   L__M(##Miscellany,14); jump FreshInput; }
    if (nw == 1)
    {   L__M(##Miscellany,15); jump FreshInput; }
    if (nw > 2)
    {   L__M(##Miscellany,16); jump FreshInput; }

!  So now we know: there was a previous mistake, and the player has
!  attempted to correct a single word of it.

    CopyBytes(a_buffer, buffer2, INPUT_BUFFER_LEN);
#ifndef TARGET_GLULX;
    x1 = a_table->9; ! Start of word following "oops"
    x2 = a_table->8; ! Length of word following "oops"
#endif;
#ifdef TARGET_GLULX;
    x1 = a_table-->6; ! Start of word following "oops"
    x2 = a_table-->5; ! Length of word following "oops"
#endif; ! TARGET_

!  Repair the buffer to the text that was in it before the "oops"
!  was typed:

    CopyBytes(oops_workspace, a_buffer, 64);
    Tokenise__(a_buffer,a_table);

!  Work out the position in the buffer of the word to be corrected:

#ifndef TARGET_GLULX;
    w = a_table->(4*oops_from + 1); ! Start of word to go
    w2 = a_table->(4*oops_from);    ! Length of word to go
#endif;
#ifdef TARGET_GLULX;
    w = a_table-->(3*oops_from);      ! Start of word to go
    w2 = a_table-->(3*oops_from - 1); ! Length of word to go
#endif; ! TARGET_

!  Write spaces over the word to be corrected:

    for (i=0:i<w2:i++) a_buffer->(i+w) = ' ';

    if (w2 < x2)
    {   ! If the replacement is longer than the original, move up...

        for (i=INPUT_BUFFER_LEN:i>=w+x2:i--)
            a_buffer->i = a_buffer->(i-x2+w2);

        ! ...increasing buffer size accordingly.

#ifndef TARGET_GLULX;
        a_buffer->1 = (a_buffer->1) + (x2-w2);
#endif;
#ifdef TARGET_GLULX;
        a_buffer-->0 = (a_buffer-->0) + (x2-w2);
#endif; ! TARGET_
    }

!  Write the correction in:

    CopyBytes(buffer2 + x1, a_buffer + w, x2);

    Tokenise__(a_buffer,a_table);
#ifndef TARGET_GLULX;
    nw=a_table->1;
#endif;
#ifdef TARGET_GLULX;
    nw=a_table-->0;
#endif; ! TARGET_

    return nw;
];

! ----------------------------------------------------------------------------
!  To simplify the picture a little, a rough map of the main routine:
!
!  (A)    Get the input, do "oops" and "again"
!  (B)    Is it a direction, and so an implicit "go"?  If so go to (K)
!  (C)    Is anyone being addressed?
!  (D)    Get the verb: try all the syntax lines for that verb
!  (E)    Break down a syntax line into analysed tokens
!  (F)    Look ahead for advance warning for multiexcept/multiinside
!  (G)    Parse each token in turn (calling ParseToken to do most of the work)
!  (H)    Cheaply parse otherwise unrecognised conversation and return
!  (I)    Print best possible error message
!  (J)    Retry the whole lot
!  (K)    Last thing: check for "then" and further instructions(s), return.
!
!  The strategic points (A) to (K) are marked in the commentary.
!
!  Note that there are three different places where a return can happen.
! ----------------------------------------------------------------------------

[ Parser__parse  results   syntax line num_lines line_address i j k
                           token l m;

!  **** (A) ****

    if (held_back_mode == 1)
    {   held_back_mode = 0;
        Tokenise__(buffer,parse);
        jump ReParse;
    }

  .ReType;

    Keyboard(buffer,parse);

  .ReParse;

    parser_inflection = name;
    grammar_line = 0;

!  Initially assume the command is aimed at the player, and the verb
!  is the first word

    #ifndef TARGET_GLULX; num_words = parse->1; #endif;
    #ifdef TARGET_GLULX; num_words = parse-->0; #endif;

    wn = 1;
    #ifdef LanguageToInformese;
        LanguageToInformese();
    #endif;
    Tokenise__(buffer,parse);

    verb_wordnum=1;
    actor=player;
    actors_location = ScopeCeiling(actor);
    usual_grammar_after = 0;

    BeforeParsing();

    #ifndef TARGET_GLULX;
        num_words = parse->1;
    #endif;
    #ifdef TARGET_GLULX;
        num_words = parse-->0;
    #endif;

    k=0;
#ifdef DEBUG;
    if (parser_trace>=2)
    {   print "[ ";
        for (i=0:i<num_words:i++)
        {
#ifndef TARGET_GLULX;
            j=parse-->(i*2 + 1);
#endif;
#ifdef TARGET_GLULX;
            j=parse-->(i*3 + 1);
#endif; ! TARGET_
            k=WordAddress(i+1);
            l=WordLength(i+1);
            print "~"; for (m=0:m<l:m++) print (char) k->m; print "~ ";

            if (j == 0) print "?";
            else
            {   
#ifndef TARGET_GLULX;
                if (UnsignedCompare(j, 0-->4)>=0
                    && UnsignedCompare(j, 0-->2)<0) print (address) j;
                else print j;
#endif;
#ifdef TARGET_GLULX;
                if (j->0 == $60) print (address) j;
                else print j;
#endif; ! TARGET_
            }
            if (i ~= num_words-1) print " / ";
        }
        print " ]^";
    }
#endif;

  .AlmostReParse;

    scope_token = 0;
    action_to_be = NULL;

!  Begin from what we currently think is the verb word

  .BeginCommand;
    wn=verb_wordnum;
    verb_word = NextWordStopped();

!  If there's no input here, we must have something like
!  "person,".

    if (verb_word==-1)
    {   best_etype = STUCK_PE; jump GiveError; }

    if (verb_word == COMMA_WORD) { L__M(##Miscellany,22); jump ReType; }

!  Now try for "again" or "g", which are special cases:
!  don't allow "again" if nothing has previously been typed;
!  simply copy the previous text across

    if (verb_word==AGAIN2__WD or AGAIN3__WD) verb_word=AGAIN1__WD;
    if (verb_word==AGAIN1__WD)
    {   if (actor~=player)
        {   L__M(##Miscellany,20); 
            jump ReType;
        }
#ifndef TARGET_GLULX;
        if (buffer3->1==0)
        {   L__M(##Miscellany,21); jump ReType; }
#endif;
#ifdef TARGET_GLULX;
        if (buffer3-->0==0)
        {   L__M(##Miscellany,21); jump ReType; }
#endif; ! TARGET_
        CopyBytes(buffer3, buffer, 120);
        jump ReParse;
    }

!  Save the present input in case of an "again" next time

    if (verb_word ~= AGAIN1__WD)
        CopyBytes(buffer, buffer3, 120);

    if (usual_grammar_after == 0)
    {   i = RunRoutines(actor, grammar);
        #ifdef DEBUG;
        if (parser_trace>=2 && actor.grammar~=0 or NULL)
            print " [Grammar property returned ", i, "]^";
        #endif;
        if (i < 0) { usual_grammar_after = verb_wordnum; i = -i; }
        if (i == 1)
        {   results-->0 = action;
            results-->1 = noun;
            results-->2 = second;
            rtrue;
        }
        if (i) { verb_word = i; wn--; verb_wordnum--; }
        else
        {   wn = verb_wordnum; verb_word=NextWord();
        }
    }
    else usual_grammar_after=0;

!  **** (B) ****

    #ifdef LanguageIsVerb;
    if (verb_word==0)
    {   i = wn; verb_word=LanguageIsVerb(buffer, parse, verb_wordnum);
        wn = i;
    }
    #endif;

!  If the first word is not listed as a verb, it must be a direction
!  or the name of someone to talk to

    if (verb_word == 0 || ((verb_word->#dict_par1) & 1) == 0)
    {

!  So is the first word an object contained in the special object "compass"
!  (i.e., a direction)?  This needs use of NounDomain, a routine which
!  does the object matching, returning the object number, or 0 if none found,
!  or REPARSE_CODE if it has restructured the parse table so the whole parse
!  must be begun again...

        wn=verb_wordnum; indef_mode = false; token_filter = 0;
        l = NounDomain(compass, 0); if (l == REPARSE_CODE) jump ReParse;

!  If it is a direction, send back the results:
!  action=GoSub, no of arguments=1, argument 1=the direction.

        if (l)
        {   results-->0 = ##Go;
            action_to_be = ##Go;
            results-->1 = 1;
            results-->2 = l;
            jump LookForMore;
        }

!  **** (C) ****

!  Only check for a comma (a "someone, do something" command) if we are
!  not already in the middle of one.  (This simplification stops us from
!  worrying about "robot, wizard, you are an idiot", telling the robot to
!  tell the wizard that she is an idiot.)

        if (actor==player)
        {   for (j=2:j<=num_words:j++)
            { i = NextWord(); if (i == COMMA_WORD) jump Conversation; }

            verb_word = UnknownVerb(verb_word);
            if (verb_word) jump VerbAccepted;
        }

        best_etype=VERB_PE; jump GiveError;

!  NextWord nudges the word number wn on by one each time, so we've now
!  advanced past a comma.  (A comma is a word all on its own in the table.)

      .Conversation;
        j=wn-1;

!  Use NounDomain (in the context of "animate creature") to see if the
!  words make sense as the name of someone held or nearby

        wn=1; lookahead = HELD_TOKEN;
        scope_reason = TALKING_REASON;
        l = NounDomain(player, 6);
        scope_reason = PARSING_REASON;
        if (l==REPARSE_CODE) jump ReParse;

        if (l==0) { L__M(##Miscellany,23); jump ReType; }

!  The object addressed must at least be "talkable" if not actually "animate"
!  (the distinction allows, for instance, a microphone to be spoken to,
!  without the parser thinking that the microphone is human).

        if (l hasnt animate or talkable)
        {   L__M(##Miscellany, 24, l); jump ReType; }

!  Check that there aren't any mystery words between the end of the person's
!  name and the comma (eg, throw out "dwarf sdfgsdgs, go north").

        if (wn~=j)
        {   L__M(##Miscellany, 25); jump ReType; }

!  The player has now successfully named someone.  Adjust "him", "her", "it":

        PronounNotice(l);

!  Set the global variable "actor", adjust the number of the first word,
!  and begin parsing again from there.

        verb_wordnum=j+1;

!  Stop things like "me, again":

        if (l == player)
        {   wn = verb_wordnum;
            if (NextWordStopped() == AGAIN1__WD or AGAIN2__WD or AGAIN3__WD)
            {   L__M(##Miscellany,20); jump ReType;
            }
        }

        actor=l;
        actors_location=ScopeCeiling(l);
        #ifdef DEBUG;
        if (parser_trace>=1)
            print "[Actor is ", (the) actor, " in ",
                (name) actors_location, "]^";
        #endif;
        jump BeginCommand;
    }

!  **** (D) ****

   .VerbAccepted;

!  We now definitely have a verb, not a direction, whether we got here by the
!  "take ..." or "person, take ..." method.  Get the meta flag for this verb:

    meta=((verb_word->#dict_par1) & 2)/2;

!  You can't order other people to "full score" for you, and so on...

    if (meta==1 && actor~=player)
    {   best_etype=VERB_PE; meta=0; jump GiveError; }

!  Now let i be the corresponding verb number, stored in the dictionary entry
!  (in a peculiar 255-n fashion for traditional Infocom reasons)...

    i=$ff-(verb_word->#dict_par2);

!  ...then look up the i-th entry in the verb table, whose address is at word
!  7 in the Z-machine (in the header), so as to get the address of the syntax
!  table for the given verb...

#ifndef TARGET_GLULX;
    syntax=(0-->7)-->i;
#endif;
#ifdef TARGET_GLULX;
    syntax=(#grammar_table)-->(i+1);
#endif; ! TARGET_

!  ...and then see how many lines (ie, different patterns corresponding to the
!  same verb) are stored in the parse table...

    num_lines=(syntax->0)-1;

!  ...and now go through them all, one by one.
!  To prevent pronoun_word 0 being misunderstood,

   pronoun_word = NULL; pronoun_obj = NULL;

   #ifdef DEBUG;
   if (parser_trace>=1)
   {    print "[Parsing for the verb '", (address) verb_word,
              "' (", num_lines+1, " lines)]^";
   }
   #endif;

   best_etype=STUCK_PE; nextbest_etype=STUCK_PE;

!  "best_etype" is the current failure-to-match error - it is by default
!  the least informative one, "don't understand that sentence".
!  "nextbest_etype" remembers the best alternative to having to ask a
!  scope token for an error message (i.e., the best not counting ASKSCOPE_PE).


!  **** (E) ****

    line_address = syntax + 1;

    for (line = 0:line <= num_lines:line++)
    {   
        for (i = 0 : i < 32 : i++)
        {   line_token-->i = ENDIT_TOKEN;
            line_ttype-->i = ELEMENTARY_TT;
            line_tdata-->i = ENDIT_TOKEN;
        }
        
        grammar_line = line + 1;

!  Unpack the syntax line from Inform format into three arrays; ensure that
!  the sequence of tokens ends in an ENDIT_TOKEN.

        line_address = UnpackGrammarLine(line_address);

        #ifdef DEBUG;
        if (parser_trace >= 1)
        {   if (parser_trace >= 2) new_line;
            print "[line ", line; DebugGrammarLine();
            print "]^";
        }
        #endif;

!  We aren't in inferring mode, and haven't entered any parameters
!  on the line yet, or any special numbers; the multiple object is
!  still empty.

        inferfrom=0;
        parameters=0;
        nsns=0; special_word=0; special_number=0;
        multiple_object-->0 = 0;
        multi_context = 0;
        etype=STUCK_PE;

!  Put the word marker back to just after the verb

        wn=verb_wordnum+1;

!  **** (F) ****
!  There are two special cases where parsing a token now has to be
!  affected by the result of parsing another token later, and these
!  two cases (multiexcept and multiinside tokens) are helped by a quick
!  look ahead, to work out the future token now.  We can only carry this
!  out in the simple (but by far the most common) case:
!
!      multiexcept <one or more prepositions> noun
!
!  and similarly for multiinside.

        advance_warning = NULL; indef_mode = false;
        parsing_ahead = true;
        for (i=0,m=false,pcount=0:(line_token-->pcount ~= ENDIT_TOKEN):pcount++)
        {   scope_token = 0;

            if (line_ttype-->pcount ~= PREPOSITION_TT) i++;

            if (line_ttype-->pcount == ELEMENTARY_TT)
            {   if (line_tdata-->pcount == MULTI_TOKEN) m=true;
                if (line_tdata-->pcount
                    == MULTIEXCEPT_TOKEN or MULTIINSIDE_TOKEN  && i==1)
                {   !   First non-preposition is "multiexcept" or
                    !   "multiinside", so look ahead.

                    #ifdef DEBUG;
                    if (parser_trace>=2) print " [Trying look-ahead]^";
                    #endif;

                    !   We need this to be followed by 1 or more prepositions.

                    pcount++;
                    if (line_ttype-->pcount == PREPOSITION_TT)
                    {   while (line_ttype-->pcount == PREPOSITION_TT)
                            pcount++;

                        if ((line_ttype-->pcount == ELEMENTARY_TT)
                            && (line_tdata-->pcount == NOUN_TOKEN))
                        {
                            !  Advance past the last preposition

                            while (wn <= num_words)
                            {   if (NextWord() == line_tdata-->(pcount-1))
                                {   l = NounDomain(actor, NOUN_TOKEN);
                                    parsing_ahead++;
                                    #ifdef DEBUG;
                                    if (parser_trace>=2)
                                    {   print " [Advanced to ~noun~ token: ";
                                        if (l==REPARSE_CODE)
                                            print "re-parse request]^";
                                        if (l==1) print "but multiple found]^";
                                        if (l==0) print "error ", etype, "]^";
                                        if (l>=2) print (the) l, "]^";
                                    }
                                    #endif;
                                    if (l==REPARSE_CODE) jump ReParse;
                                    if (l>=2) advance_warning = l;
                                }
                            }
                        }
                    }
                    break;
                }
            }
        }

        parsing_ahead = false;

!  Slightly different line-parsing rules will apply to "take multi", to
!  prevent "take all" behaving correctly but misleadingly when there's
!  nothing to take.

        take_all_rule = 0;
        if (m && params_wanted==1 && action_to_be==##Take)
            take_all_rule = 1;

!  And now start again, properly, forearmed or not as the case may be.
!  As a precaution, we clear all the variables again (they may have been
!  disturbed by the call to NounDomain, which may have called outside
!  code, which may have done anything!).

        inferfrom = 0;
        parameters=0;
        nsns=0; special_word=0; special_number=0;
        multiple_object-->0 = 0;
        etype=STUCK_PE;
        wn=verb_wordnum+1;

!  **** (G) ****
!  "Pattern" gradually accumulates what has been recognised so far,
!  so that it may be reprinted by the parser later on

        for (pcount=1::pcount++)
        {   pattern-->pcount = PATTERN_NULL; scope_token=0;

            token = line_token-->(pcount-1);
            lookahead = line_token-->pcount;

            #ifdef DEBUG;
                if (parser_trace >= 2)
                print " [line ", line, " token ", pcount, " word ", wn, " : ",
                    (DebugToken) token, "]^";
            #endif;

            if (token ~= ENDIT_TOKEN)
            {   scope_reason = PARSING_REASON;
                AnalyseToken(token);
                l = ParseToken__(found_ttype, found_tdata, pcount - 1, token);
                while (l<-200) l = ParseToken__(ELEMENTARY_TT, l + 256);
                scope_reason = PARSING_REASON;

                if (l==GPR_PREPOSITION)
                {   if (found_ttype~=PREPOSITION_TT
                        && (found_ttype~=ELEMENTARY_TT
                            || found_tdata~=TOPIC_TOKEN)) params_wanted--;
                    l = true;
                }
                else
                if (l<0) l = false;
                else
                if (l~=GPR_REPARSE)
                {   if (l==GPR_NUMBER)
                    {   if (nsns==0) special_number1=parsed_number;
                        else special_number2=parsed_number;
                        nsns++; l = 1;
                    }
                    if (l==GPR_MULTIPLE) l = 0;
                    results-->(parameters+2) = l;
                    parameters++;
                    pattern-->pcount = l;
                    l = true;
                }

                #ifdef DEBUG;
                if (parser_trace >= 3)
                {   print "  [token resulted in ";
                    if (l==REPARSE_CODE) print "re-parse request]^";
                    if (l==0) print "failure with error type ", etype, "]^";
                    if (l==1) print "success]^";
                }
                #endif;

                if (l==REPARSE_CODE) jump ReParse;
                if (l==false)    break;
            }
            else
            {

!  If the player has entered enough already but there's still
!  text to wade through: store the pattern away so as to be able to produce
!  a decent error message if this turns out to be the best we ever manage,
!  and in the mean time give up on this line

!  However, if the superfluous text begins with a comma or "then" then
!  take that to be the start of another instruction

                if (wn <= num_words)
                {   l = NextWord();
                    if (l == COMMA_WORD)
                    {   if (NextWord() ~= THEN1__WD or THEN2__WD or THEN3__WD
                            or AND1__WD or AND2__WD or AND3__WD)
                            wn--;
                    }
                    if (l == THEN1__WD or THEN2__WD or THEN3__WD or COMMA_WORD
                        or AND1__WD or AND2__WD or AND3__WD)
                    {   held_back_mode = true; hb_wn = wn - 1; }
                    else
                    {   CopyWords(pattern, pattern2, 32);
                        pcount2 = pcount;
                        etype = UPTO_PE; break;
                    }
                }

!  Now, we may need to revise the multiple object because of the single one
!  we now know (but didn't when the list was drawn up).

                if (parameters >= 1 && results-->2 == 0)
                {   l=ReviseMulti(results-->3);
                    if (l) { etype=l; break; }
                }
                if (parameters >= 2 && results-->3 == 0)
                {   l = ReviseMulti(results-->2);
                    if (l) { etype = l; break; }
                }

!  To trap the case of "take all" inferring only "yourself" when absolutely
!  nothing else is in the vicinity...

                if (take_all_rule == 2 && results-->2 == actor)
                {   best_etype = NOTHING_PE; jump GiveError;
                }

                #ifdef DEBUG;
                if (parser_trace >= 1)
                    print "[Line successfully parsed]^";
                #endif;

!  The line has successfully matched the text.  Declare the input error-free...

                oops_from = 0;

!  ...explain any inferences made (using the pattern)...

                if (inferfrom)
                {   print "("; PrintCommand(inferfrom); print ")^";
                }

!  ...copy the action number, and the number of parameters...

                results-->0 = action_to_be;
                results-->1 = parameters;

!  ...reverse first and second parameters if need be...

                if (action_reversed && parameters==2)
                {   i = results-->2; results-->2 = results-->3;
                    results-->3 = i;
                    if (nsns == 2)
                    {   i = special_number1; special_number1=special_number2;
                        special_number2=i;
                    }
                }

!  ...and to reset "it"-style objects to the first of these parameters, if
!  there is one (and it really is an object)...

                if (parameters > 0 && results-->2 >= 2)
                    PronounNotice(results-->2);

!  ...and return from the parser altogether, having successfully matched
!  a line.

                if (held_back_mode==1) { wn=hb_wn; jump LookForMore; }
                rtrue;
            }
        }

!  The line has failed to match.
!  We continue the outer "for" loop, trying the next line in the grammar.

        if (etype>best_etype) best_etype=etype;
        if (etype~=ASKSCOPE_PE && etype>nextbest_etype) nextbest_etype=etype;

!  ...unless the line was something like "take all" which failed because
!  nothing matched the "all", in which case we stop and give an error now.

        if (take_all_rule == 2 && etype==NOTHING_PE) break;
   }

!  The grammar is exhausted: every line has failed to match.

!  **** (H) ****

  .GiveError;
        etype=best_etype;

!  Errors are handled differently depending on who was talking.

!  If the command was addressed to somebody else (eg, "dwarf, sfgh") then
!  it is taken as conversation which the parser has no business in disallowing.

    if (actor ~= player)
    {   if (usual_grammar_after > 0)
        {   verb_wordnum = usual_grammar_after;
            jump AlmostReParse;
        }
        wn = verb_wordnum;
        special_word = NextWord();
        if (special_word == COMMA_WORD)
        {   special_word = NextWord();
            verb_wordnum++;
        }
        special_number = TryNumber(verb_wordnum);
        results-->0 = ##NotUnderstood;
        results-->1 = 1;
        results-->2 = actor;
        consult_from = verb_wordnum;
        consult_words = num_words - consult_from + 1;
        rtrue;
    }

!  **** (I) ****

!  If the player was the actor (eg, in "take dfghh") the error must be printed,
!  and fresh input called for.  In three cases the oops word must be jiggled.

    if (ParserError(etype)) jump ReType;
    pronoun_word = pronoun__word; pronoun_obj = pronoun__obj;

    switch(etype) {
        STUCK_PE   : L__M(##Miscellany, 27); oops_from = 1;
        UPTO_PE    : L__M(##Miscellany, 28);
                     CopyWords(pattern2, pattern, 32);
                     pcount = pcount2;
                     PrintCommand(0); print ".^";
        NUMBER_PE  : L__M(##Miscellany, 29);
        CANTSEE_PE : L__M(##Miscellany, 30); oops_from = saved_oops;
        TOOLIT_PE  : L__M(##Miscellany, 31);
        NOTHELD_PE : L__M(##Miscellany, 32); oops_from = saved_oops;
        MULTI_PE   : L__M(##Miscellany, 33);
        MMULTI_PE  : L__M(##Miscellany, 34);
        VAGUE_PE   : L__M(##Miscellany, 35);
        EXCEPT_PE  : L__M(##Miscellany, 36);
        ANIMA_PE   : L__M(##Miscellany, 37);
        VERB_PE    : L__M(##Miscellany, 38);
        SCENERY_PE : L__M(##Miscellany, 39);
        ITGONE_PE  : if (pronoun_obj == NULL) L__M(##Miscellany, 35);
                     else L__M(##Miscellany, 40);
        JUNKAFTER_PE : L__M(##Miscellany, 41);
        TOOFEW_PE    :  L__M(##Miscellany, 42, multi_had);
        NOTHING_PE   : if (multi_wanted==100) L__M(##Miscellany, 43);
                       else L__M(##Miscellany, 44);
        NONEHELD_PE  : L__M(##Miscellany, 522);
        ASKSCOPE_PE  : scope_stage = 3;
                       if (indirect(scope_error) == -1)
                       {   best_etype=nextbest_etype; jump GiveError;  }
    }

!  **** (J) ****

!  And go (almost) right back to square one...

    jump ReType;

!  ...being careful not to go all the way back, to avoid infinite repetition
!  of a deferred command causing an error.


!  **** (K) ****

!  At this point, the return value is all prepared, and we are only looking
!  to see if there is a "then" followed by subsequent instruction(s).

   .LookForMore;

   if (wn>num_words) rtrue;

   i=NextWord();
   if (i == THEN1__WD or THEN2__WD or THEN3__WD or COMMA_WORD
       or AND1__WD or AND2__WD or AND3__WD)
   {   if (wn > num_words)
       {   held_back_mode = false; return; }
       i = WordAddress(verb_wordnum);
       j = WordAddress(wn);
       for (:i<j:i++) i->0 = ' ';
       i = NextWord();
       if (i==AGAIN1__WD or AGAIN2__WD or AGAIN3__WD)
       {   !   Delete the words "then again" from the again buffer,
           !   in which we have just realised that it must occur:
           !   prevents an infinite loop on "i. again"

           i = WordAddress(wn-2)-buffer;
           if (wn > num_words) j = 119; else j = WordAddress(wn)-buffer;
           for (:i<j:i++) buffer3->i = ' ';
       }
       Tokenise__(buffer,parse); held_back_mode = true; return;
   }
   best_etype=UPTO_PE; jump GiveError;
];

! ----------------------------------------------------------------------------
!  CreatureTest: Will this person do for a "creature" token?
! ----------------------------------------------------------------------------

[ CreatureTest obj;
  if (obj has animate) rtrue;
  if (obj hasnt talkable) rfalse;
  if (action_to_be == ##Ask or ##Answer or ##Tell or ##AskFor) rtrue;
  rfalse;
];

[ PrepositionChain wd index;

  if (line_tdata-->index == wd) return wd;
  if ((line_token-->index)->0 & $20 == 0) return -1;
  do
  {   if (line_tdata-->index == wd) return wd;
      index++;
  }
  until ((line_token-->index == ENDIT_TOKEN)
         || (((line_token-->index)->0 & $10) == 0));
  return -1;
];

! ----------------------------------------------------------------------------
!  ParseToken(type, data):
!      Parses the given token, from the current word number wn, with exactly
!      the specification of a general parsing routine.
!      (Except that for "topic" tokens and prepositions, you need to supply
!      a position in a valid grammar line as third argument.)
!
!  Returns:
!    GPR_REPARSE  for "reconstructed input, please re-parse from scratch"
!    GPR_PREPOSITION  for "token accepted with no result"
!    $ff00 + x    for "please parse ParseToken(ELEMENTARY_TT, x) instead"
!    0            for "token accepted, result is the multiple object list"
!    1            for "token accepted, result is the number in parsed_number"
!    object num   for "token accepted with this object as result"
!    -1           for "token rejected"
!
!  (A)            Analyse the token; handle all tokens not involving
!                 object lists and break down others into elementary tokens
!  (B)            Begin parsing an object list
!  (C)            Parse descriptors (articles, pronouns, etc.) in the list
!  (D)            Parse an object name
!  (E)            Parse connectives ("and", "but", etc.) and go back to (C)
!  (F)            Return the conclusion of parsing an object list
! ----------------------------------------------------------------------------

[ IsALinkWord wd;
    if (wd == COMMA_WORD or AND1__WD or AND2__WD or AND3__WD
        or THEN1__WD or THEN2__WD or THEN3__WD)
        rtrue;
    rfalse;
];

[ ParseToken given_ttype given_tdata token_n     x y;
  x = lookahead; lookahead = NOUN_TOKEN;
  y = ParseToken__(given_ttype,given_tdata,token_n);
  if (y == GPR_REPARSE) Tokenise__(buffer,parse);
  lookahead = x; return y;
];

[ ParseToken__ given_ttype given_tdata token_n
             token l o i j k and_parity single_object desc_wn many_flag
             token_allows_multiple wd2;

!  **** (A) ****

   token_filter = 0;

   switch(given_ttype)
   {   ELEMENTARY_TT:
           switch(given_tdata)
           {   SPECIAL_TOKEN:
                   l = TryNumber(wn);
                   special_word = NextWord();
                   #ifdef DEBUG;
                   if (l ~= -1000)
                       if (parser_trace >= 3)
                           print "  [Read special as the number ", l, "]^";
                   #endif;
                   if (l == -1000)
                   {   #ifdef DEBUG;
                       if (parser_trace >= 3)
                         print "  [Read special word at word number ", wn, "]^";
                       #endif;
                       l = special_word;
                   }
                   parsed_number = l; return GPR_NUMBER;

               NUMBER_TOKEN:
                   l = TryNumber(wn++);
                   if (l == -1000) { etype = NUMBER_PE; return GPR_FAIL; }
                   #ifdef DEBUG;
                   if (parser_trace>=3) print "  [Read number as ", l, "]^";
                   #endif;
                   parsed_number = l; return GPR_NUMBER;

               CREATURE_TOKEN:
                   if (action_to_be == ##Answer or ##Ask or ##AskFor or ##Tell)
                       scope_reason = TALKING_REASON;

               TOPIC_TOKEN:
                   consult_from = wn;
                   if ((line_ttype-->(token_n+1) ~= PREPOSITION_TT)
                       && (line_token-->(token_n+1) ~= ENDIT_TOKEN))
                       RunTimeError(13);
                   do o=NextWordStopped();
                   until (o == -1 || PrepositionChain(o, token_n+1) ~= -1);
                   wn--;
                   consult_words = wn - consult_from;
                   if (consult_words == 0) return GPR_FAIL;
                   return GPR_PREPOSITION;
           }

       PREPOSITION_TT:
!  Is it an unnecessary alternative preposition, when a previous choice
!  has already been matched?
           if ((token->0) & $10) return GPR_PREPOSITION;

!  If we've run out of the player's input, but still have parameters to
!  specify, we go into "infer" mode, remembering where we are and the
!  preposition we are inferring...

           if (wn > num_words)
           {   if (inferfrom == 0 && parameters<params_wanted)
               {   inferfrom = pcount; inferword = token;
                   pattern-->pcount = REPARSE_CODE + Dword__No(given_tdata);
               }

!  If we are not inferring, then the line is wrong...

               if (inferfrom == 0) return -1;

!  If not, then the line is right but we mark in the preposition...

               pattern-->pcount = REPARSE_CODE + Dword__No(given_tdata);
               return GPR_PREPOSITION;
           }

           o = NextWord();

           pattern-->pcount = REPARSE_CODE + Dword__No(o);

!  Whereas, if the player has typed something here, see if it is the
!  required preposition... if it's wrong, the line must be wrong,
!  but if it's right, the token is passed (jump to finish this token).

           if (o == given_tdata) return GPR_PREPOSITION;
           if (PrepositionChain(o, token_n) ~= -1)
               return GPR_PREPOSITION;
           return -1;

       GPR_TT:
           l=indirect(given_tdata);
           #ifdef DEBUG;
           if (parser_trace>=3)
               print "  [Outside parsing routine returned ", l, "]^";
           #endif;
           return l;

       SCOPE_TT:
           scope_token = given_tdata;
           scope_stage = 1;
           l = indirect(scope_token);
           #ifdef DEBUG;
           if (parser_trace>=3)
               print "  [Scope routine returned multiple-flag of ", l, "]^";
           #endif;
           if (l==1) given_tdata = MULTI_TOKEN; else given_tdata = NOUN_TOKEN;

       ATTR_FILTER_TT:
           token_filter = 1 + given_tdata;
           given_tdata = NOUN_TOKEN;

       ROUTINE_FILTER_TT:
           token_filter = given_tdata;
           given_tdata = NOUN_TOKEN;
   }

   token = given_tdata;

!  **** (B) ****

!  There are now three possible ways we can be here:
!      parsing an elementary token other than "special" or "number";
!      parsing a scope token;
!      parsing a noun-filter token (either by routine or attribute).
!
!  In each case, token holds the type of elementary parse to
!  perform in matching one or more objects, and
!  token_filter is 0 (default), an attribute + 1 for an attribute filter
!  or a routine address for a routine filter.

   token_allows_multiple = false;
   if (token == MULTI_TOKEN or MULTIHELD_TOKEN or MULTIEXCEPT_TOKEN
                or MULTIINSIDE_TOKEN) token_allows_multiple = true;

   many_flag = false; and_parity = true; dont_infer = false;

!  **** (C) ****
!  We expect to find a list of objects next in what the player's typed.

  .ObjectList;

   #ifdef DEBUG;
   if (parser_trace>=3) print "  [Object list from word ", wn, "]^";
   #endif;

!  Take an advance look at the next word: if it's "it" or "them", and these
!  are unset, set the appropriate error number and give up on the line
!  (if not, these are still parsed in the usual way - it is not assumed
!  that they still refer to something in scope)

    o=NextWord(); wn--;

    pronoun_word = NULL; pronoun_obj = NULL;
    l = PronounValue(o);
    if (l ~= 0)
    {   pronoun_word = o; pronoun_obj = l;
        if (l == NULL)
        {   !   Don't assume this is a use of an unset pronoun until the
            !   descriptors have been checked, because it might be an
            !   article (or some such) instead

            if (ParseEarlyDescriptor(thedark, o) ~= -1
                || ParseStandardDescriptor(thedark, o) ~= -1)
                jump AssumeDescriptor;
            pronoun__word = pronoun_word; pronoun__obj = pronoun_obj;
            etype = VAGUE_PE; return GPR_FAIL;
        }
    }

    .AssumeDescriptor;

    if ((player_perspective == 2 && IsMeWord(o))
        || (player_perspective == 1 && IsYouWord(o)))
    {   pronoun_word = o; pronoun_obj = player;
    }

    allow_plurals = true; desc_wn = wn;

    .TryAgain;
    ResetDescriptors();
    .TryAgain2;

!  **** (D) ****

!  This is an actual specified object, and is therefore where a typing error
!  is most likely to occur, so we set:

    oops_from = wn;

!  We use NounDomain, giving it the token number as context, and two places to look:
!  among the actor's possessions, and in the present location.

    i = multiple_object-->0;
    #ifdef DEBUG;
    if (parser_trace>=3)
        print "  [Calling NounDomain on actor]^";
    #endif;
    l = NounDomain(actor, token);
    if (l == REPARSE_CODE) return l;                  ! Reparse after Q&A
    if (l==0) { etype=CantSee(); jump FailToken; }

    #ifdef DEBUG;
    if (parser_trace>=3)
    {   if (l>1)
            print "  [ND returned ", (the) l, "]^";
        else
        {   print "  [ND appended to the multiple object list:^";
            k=multiple_object-->0;
            for (j=i+1:j<=k:j++)
                print "  Entry ", j, ": ", (The) multiple_object-->j,
                      " (", multiple_object-->j, ")^";
            print "  List now has size ", k, "]^";
        }
    }
    #endif;

    if (l == 1)
    {   if (~~many_flag)
        {   many_flag = true;
        }
        else                                  ! Merge with earlier ones
        {   k=multiple_object-->0;            ! (with either parity)
            multiple_object-->0 = i;
            for (j=i+1:j<=k:j++)
            {   if (and_parity) MultiAdd(multiple_object-->j);
                else MultiSub(multiple_object-->j);
            }
            #ifdef DEBUG;
            if (parser_trace>=3)
                print "  [Merging ", k-i, " new objects to the ",
                    i, " old ones]^";
            #endif;
        }
    }
    else
    {   ! A single object was indeed found

        if (token==CREATURE_TOKEN && CreatureTest(l) == false)
        {   etype=ANIMA_PE; jump FailToken; } !  Animation is required

        if (~~many_flag)
            single_object = l;
        else
        {   if (and_parity) MultiAdd(l); else MultiSub(l);
            #ifdef DEBUG;
            if (parser_trace>=3)
                print "  [Combining ", (the) l, " with list]^";
            #endif;
        }
    }



!  The following moves the word marker to just past the named object...

    wn = oops_from + match_length;

!  **** (E) ****

!  Object(s) specified now: is that the end of the list, or have we reached
!  "and", "but" and so on?  If so, create a multiple-object list if we
!  haven't already (and are allowed to).

    .NextInList;

    o=NextWord();

! Allow for ", then"

    wd2 = NextWord(); wn--;

    if (o == COMMA_WORD && IsALinkWord(wd2))
    {   o = wd2; wn++; wd2 = NextWord(); wn--; }

! Only consider a comma or "and" to be a continuation of the list if the token
! allows for multiple objects, and the next word is not a verb.

    if ((o== BUT1__WD or BUT2__WD or BUT3__WD)
        || (IsALinkWord(o)
            && token_allows_multiple && wd2 && WordIsVerb(wd2) == false))
    {

        #ifdef DEBUG;
        if (parser_trace>=3) print "  [Read connective '", (address) o, "']^";
        #endif;

        if (~~token_allows_multiple)
        {   etype=MULTI_PE; jump FailToken;
        }

        if (o==BUT1__WD or BUT2__WD or BUT3__WD) and_parity = 1-and_parity;

        if (~~many_flag)
        {   multiple_object-->0 = 1;
            multiple_object-->1 = single_object;
            many_flag = true;
            #ifdef DEBUG;
            if (parser_trace>=3)
                print "  [Making new list from ", (the) single_object, "]^";
            #endif;
        }
        dont_infer = true; inferfrom=0;           ! Don't print (inferences)
        jump ObjectList;                          ! And back around
    }

    wn--;   ! Word marker back to first not-understood word

!  **** (F) ****

!  Happy or unhappy endings:

    .PassToken;

    if (many_flag)
    {   single_object = GPR_MULTIPLE;
        multi_context = token;
    }
    else
    {   if (indef_mode==1 && indef_type & PLURAL_BIT ~= 0)
        {   if (indef_wanted<100 && indef_wanted>1)
            {   multi_had=1; multi_wanted=indef_wanted;
                etype=TOOFEW_PE;
                jump FailToken;
            }
        }
    }
    return single_object;

    .FailToken;

!  If we were only guessing about it being a plural, try again but only
!  allowing singulars (so that words like "six" are not swallowed up as
!  Descriptors)

    if (allow_plurals && indef_guess_p==1)
    {   allow_plurals=false; wn=desc_wn; 
        if (token_allows_multiple == false) best_etype = MULTI_PE;
        jump TryAgain;
    }
    return -1;
];

! ----------------------------------------------------------------------------
!  NounDomain does the most substantial part of parsing an object name.
!
!  It returns:
!
!   0    if no match at all could be made,
!   1    if a multiple object was made,
!   k    if object k was the one decided upon,
!   REPARSE_CODE if it asked a question of the player and consequently rewrote
!        the player's input, so that the whole parser should start again
!        on the rewritten input.
!
!   In the case k=1, the multiple objects are added to multiple_object by
!   hand (not by MultiAdd, because we want to allow duplicates).
! ----------------------------------------------------------------------------

[ NounDomain obj context    first_word i j k l
                                        answer_words marker pj;
#ifdef DEBUG;
  if (parser_trace>=4)
  {   print "   [NounDomain called at word ", wn, "^";
      print "   ";
      if (indef_mode)
      {    print "seeking indefinite object^";
           print "   number wanted: ";
           if (indef_wanted == 100) print "all"; else print indef_wanted;
      }
  }

#endif;

  match_length = 0; match_descriptors = 0; number_matched = 0; 
  match_from = wn;

  SearchScope(obj, context);

#ifdef DEBUG;
  if (parser_trace>=4) print "   [ND made ", number_matched, " matches]^";
#endif;

  wn=match_from + match_length;

!  If nothing worked at all, leave with the word marker skipped past the
!  first unmatched word...

  if (number_matched==0) { wn++; rfalse; }

!  Suppose that there really were some words being parsed (i.e., we did
!  not just infer).  If so, and if there was only one match, it must be
!  right and we return it...

  if (match_from <= num_words)
  {   if (number_matched==1) { i=match_list-->0; return i; }

!  ...now suppose that there was more typing to come, i.e. suppose that
!  the user entered something beyond this noun.  If nothing ought to follow,
!  then there must be a mistake, (unless what does follow is just a full
!  stop, and or comma)

      if (wn<=num_words)
      {   i=NextWord(); wn--;
          if (i ~=  AND1__WD or AND2__WD or AND3__WD or COMMA_WORD
                 or THEN1__WD or THEN2__WD or THEN3__WD
                 or BUT1__WD or BUT2__WD or BUT3__WD
                 && lookahead == ENDIT_TOKEN) rfalse;
      }
  }

!  Now look for a good choice, if there's more than one choice...

  number_of_classes=0;

  if (number_matched == 1) i = match_list-->0;
  if (number_matched > 1)
  {   i=Adjudicate(context);
      if (i==-1) rfalse;
      if (i==1) rtrue;       !  Adjudicate has made a multiple
                             !  object, and we pass it on
  }

!  If i is non-zero here, one of two things is happening: either
!  (a) an inference has been successfully made that object i is
!      the intended one from the user's specification, or
!  (b) the user finished typing some time ago, but we've decided
!      on i because it's the only possible choice.
!  In either case we have to keep the pattern up to date,
!  note that an inference has been made and return.
!  (Except, we don't note which of a pile of identical objects.)

  if (i)
  {   if (dont_infer) return i;
      if (inferfrom == 0) inferfrom=pcount;
      pattern-->pcount = i;
      return i;
  }

!  If we get here, there was no obvious choice of object to make.  If in
!  fact we've already gone past the end of the player's typing (which
!  means the match list must contain every object in scope, regardless
!  of its name), then it's foolish to give an enormous list to choose
!  from - instead we go and ask a more suitable question...

  if (match_from > num_words) jump Incomplete;

!  Now we print up the question, using the equivalence classes as worked
!  out by Adjudicate() so as not to repeat ourselves on plural objects...

  if (context==CREATURE_TOKEN)
      L__M(##Miscellany, 45); else L__M(##Miscellany, 46);

  l = action; action = ##WhichOne;
  j=number_of_classes; marker=0;
! Add an extra item to the count if we'll be ending with "or all"
! or "or both".
    if (context == MULTI_TOKEN or MULTIHELD_TOKEN or MULTIEXCEPT_TOKEN
        or MULTIINSIDE_TOKEN)
        j++;
    for (i=1:i<=number_of_classes:i++)
    {     
        while (match_classes-->marker ~= i or -i) marker++;
        k=match_list-->marker;

        if (match_classes-->marker > 0) PrintSpecName(k); else PrintSpecName(k, 1);
         !   print (the) k; else print (a) k;

        if (i < j - 1)  print ", ";
        if (i == j - 1) print (string) OR__TX;
    }
    if (j > number_of_classes) ! Print "or all" or "or both" if appropriate.
    {   if (number_matched == 2) L__M(##Miscellany, 520);
        else L__M(##Miscellany, 521);
    }
    else print "?";
    new_line;
  action = l;

!  ...and get an answer:

  .WhichOne;
#ifndef TARGET_GLULX;
  for (i=2:i<INPUT_BUFFER_LEN:i++) buffer2->i=' ';
#endif; ! TARGET_ZCODE
  answer_words=Keyboard(buffer2, parse2);

  first_word=(parse2-->1);

!  Take care of "all", because that does something too clever here to do
!  later on:

  if (first_word == ALL1__WD or ALL2__WD or ALL3__WD or ALL4__WD or ALL5__WD)
  {   
      if (context == MULTI_TOKEN or MULTIHELD_TOKEN or MULTIEXCEPT_TOKEN
                     or MULTIINSIDE_TOKEN)
      {   l=multiple_object-->0;
          for (i=0:i<number_matched && l+i<63:i++)
          {   k=match_list-->i;
              multiple_object-->(i+1+l) = k;
          }
          multiple_object-->0 = i+l;
          rtrue;
      }
      L__M(##Miscellany, 47);
      jump WhichOne;
  }

!  If the first word of the reply can be interpreted as a verb, then
!  assume that the player has ignored the question and given a new
!  command altogether.
!  (This is one time when it's convenient that the directions are
!  not themselves verbs - thus, "north" as a reply to "Which, the north
!  or south door" is not treated as a fresh command but as an answer.)

  #ifdef LanguageIsVerb;
  if (first_word==0)
  {   j = wn; first_word=LanguageIsVerb(buffer2, parse2, 1); wn = j;
  }
  #endif;
    if (first_word)
    {   j = first_word->#dict_par1;
        if (j & 1 && first_word ~= 'long' or 'short' or 'normal' 
                          or 'brief' or 'full' or 'verbose'
            && (parse2->1 > 1
                || ParseStandardDescriptor(thedark, first_word) == -1))
        {   CopyBuffer(buffer, buffer2);
            return REPARSE_CODE;
        }
    }

!  Now we insert the answer into the original typed command, as
!  words additionally describing the same object
!  (eg, > take red button
!       Which one, ...
!       > music
!  becomes "take music red button".  The parser will thus have three
!  words to work from next time, not two.)

#ifndef TARGET_GLULX;

  k = WordAddress(match_from) - buffer; l=buffer2->1+1; 
  for (j=buffer + buffer->0 - 1: j>= buffer+k+l: j--)
      j->0 = 0->(j-l);
  for (i=0:i<l:i++) buffer->(k+i) = buffer2->(2+i);
  buffer->(k+l-1) = ' ';
  buffer->1 = buffer->1 + l;
  if (buffer->1 >= (buffer->0 - 1)) buffer->1 = buffer->0;

#endif;
#ifdef TARGET_GLULX;

  k = WordAddress(match_from) - buffer;
  l = (buffer2-->0) + 1;
  for (j=buffer+INPUT_BUFFER_LEN-1 : j >= buffer+k+l : j--)
      j->0 = j->(-l);
  for (i=0:i<l:i++) 
      buffer->(k+i) = buffer2->(WORDSIZE+i);
  buffer->(k+l-1) = ' ';
  buffer-->0 = buffer-->0 + l;
  if (buffer-->0 > (INPUT_BUFFER_LEN-WORDSIZE)) 
      buffer-->0 = (INPUT_BUFFER_LEN-WORDSIZE);

#endif; ! TARGET_

!  Having reconstructed the input, we warn the parser accordingly
!  and get out.

  return REPARSE_CODE;

!  Now we come to the question asked when the input has run out
!  and can't easily be guessed (eg, the player typed "take" and there
!  were plenty of things which might have been meant).

  .Incomplete;

  if (context==CREATURE_TOKEN)
      L__M(##Miscellany, 48); else L__M(##Miscellany, 49);

#ifndef TARGET_GLULX;
  for (i=2:i<INPUT_BUFFER_LEN:i++) buffer2->i=' ';
#endif; ! TARGET_ZCODE
  answer_words=Keyboard(buffer2, parse2);

  first_word=(parse2-->1);
  #ifdef LanguageIsVerb;
  if (first_word==0)
  {   j = wn; first_word=LanguageIsVerb(buffer2, parse2, 1); wn = j;
  }
  #endif;

!  Once again, if the reply looks like a command, give it to the
!  parser to get on with and forget about the question...

  if (first_word)
  {   j=first_word->#dict_par1;
      if (j & 1)
      {   CopyBuffer(buffer, buffer2);
          return REPARSE_CODE;
      }
  }

!  ...but if we have a genuine answer, then:
!
!  (1) we must glue in text suitable for anything that's been inferred.

  if (inferfrom)
  {   for (j = inferfrom: j<pcount: j++)
      {   pj = pattern-->j;
          if (pj == PATTERN_NULL) continue;

#ifndef TARGET_GLULX;
          i=2+buffer->1; (buffer->1)++; buffer->(i++) = ' ';
#endif;
#ifdef TARGET_GLULX;
          i = WORDSIZE + buffer-->0;
          (buffer-->0)++; buffer->(i++) = ' ';
#endif; ! TARGET_

          #ifdef DEBUG;
          if (parser_trace >= 5)
            print "[Gluing in inference with pattern code ", pattern-->j, "]^";
          #endif;

          parse2-->1 = 0;

          ! An inferred object.  Best we can do is glue in a pronoun.
          ! (This is imperfect, but it's very seldom needed anyway.)

          if (pj >= 2 && pj < REPARSE_CODE)
          {   PronounNotice(pj);
              for (k = 0 : k < NUMBER_OF_PRONOUNS : k++)
                 if (pj == PronounReferents-->k)
                 {   parse2-->1 = PronounWords-->k;
                     if (parser_trace >= 5)
                        print "[Using pronoun '", (address) parse2-->1,"']^";
                     break;
                 }
          }
          else
          {   ! An inferred preposition.
              parse2-->1 = No__Dword(pj - REPARSE_CODE);
              #ifdef DEBUG;
              if (parser_trace >= 5)
                  print "[Using preposition '", (address) parse2-->1, "']^";
              #endif;
          }

          ! parse2-->1 now holds the dictionary address of the word to glue in.

          if (parse2-->1)
          {   k = buffer + i;
#ifndef TARGET_GLULX;
              OpenBuffer(k);
              print (address) parse2-->1;
              CloseBuffer();
              k = k-->0;
              CopyBytes(buffer + i + 2, buffer + i, k);
              i = i + k; buffer->1 = i - 2;
#endif;
#ifdef TARGET_GLULX;
              k = PrintAnyToArray(buffer+i, INPUT_BUFFER_LEN-i, parse2-->1);
              i = i + k; buffer-->0 = i - WORDSIZE;
#endif; ! TARGET_
          }
      }
  }

!  (2) we must glue the newly-typed text onto the end.

#ifndef TARGET_GLULX;
  i=2+buffer->1; (buffer->1)++; buffer->(i++) = ' ';
  for (j=0: j<buffer2->1: i++, j++)
  {   buffer->i = buffer2->(j+2);
      (buffer->1)++;
      if (buffer->1 == INPUT_BUFFER_LEN) break;
  }    
#endif;
#ifdef TARGET_GLULX;
  i = WORDSIZE + buffer-->0;
  (buffer-->0)++; buffer->(i++) = ' ';
  for (j=0: j<buffer2-->0: i++, j++)
  {   buffer->i = buffer2->(j+WORDSIZE);
      (buffer-->0)++;
      if (buffer-->0 == INPUT_BUFFER_LEN) break;
  }    
#endif; ! TARGET_

#ifndef TARGET_GLULX;

!  (3) we fill up the buffer with spaces, which is unnecessary, but may
!      help incorrectly-written interpreters to cope.

  for (:i<INPUT_BUFFER_LEN:i++) buffer->i = ' ';

#endif; ! TARGET_ZCODE

  return REPARSE_CODE;
];

! ----------------------------------------------------------------------------
!  The Adjudicate routine tries to see if there is an obvious choice, when
!  faced with a list of objects (the match_list) each of which matches the
!  player's specification equally well.
!
!  To do this it makes use of the context (the token type being worked on).
!  It counts up the number of obvious choices for the given context
!  (all to do with where a candidate is, except for 6 (animate) which is to
!  do with whether it is animate or not);
!
!  if only one obvious choice is found, that is returned;
!
!  if we are in indefinite mode (don't care which) one of the obvious choices
!    is returned, or if there is no obvious choice then an unobvious one is
!    made;
!
!  at this stage, we work out whether the objects are distinguishable from
!    each other or not: if they are all indistinguishable from each other,
!    then choose one, it doesn't matter which;
!
!  otherwise, 0 (meaning, unable to decide) is returned (but remember that
!    the equivalence classes we've just worked out will be needed by other
!    routines to clear up this mess, so we can't economise on working them
!    out).
!
!  Returns -1 if an error occurred
! ----------------------------------------------------------------------------
Constant SCORE__CHOOSEOBJ = 1000;
Constant SCORE__IFGOOD = 500;
Constant SCORE__UNCONCEALED = 100;
Constant SCORE__BESTLOC = 60;
Constant SCORE__NEXTBESTLOC = 40;
Constant SCORE__NOTCOMPASS = 20;
Constant SCORE__NOTSCENERY = 10;
Constant SCORE__NOTACTOR = 5;
Constant SCORE__GNA = 1;
Constant SCORE__DIVISOR = 20;
Constant SCORE__LOGICAL = 100;

[ Adjudicate context i j k good_flag good_ones last n flag offset sovert;

#ifdef DEBUG;
  if (parser_trace>=4)
  {   print "   [Adjudicating match list of size ", number_matched,
          " in context ", context, "^";
      print "   ";
      if (indef_mode)
      {   print "   indefinite number wanted: ";
          if (indef_wanted == 100) print "all"; else print indef_wanted;
          new_line;
          print "   most likely GNAs of names: ", indef_cases, "^";
      }
      else print "definite object^";
  }
#endif;

  j=number_matched-1; good_ones=0; last=match_list-->0;
  for (i=0:i<=j:i++)
  {   n=match_list-->i;
      match_scores-->i = 0;

      good_flag = false;

      switch(context) {
          HELD_TOKEN, MULTIHELD_TOKEN:
              if (n in actor) good_flag = true;
          MULTIEXCEPT_TOKEN:
              if (advance_warning == -1) {
                  good_flag = true;
              } else {
                  if (n ~= advance_warning) good_flag = true;
              }
          MULTIINSIDE_TOKEN:
              if (advance_warning == -1) {
                  if (n notin actor) good_flag = true;
              } else {
                  if (n in advance_warning) good_flag = true;
              }
          CREATURE_TOKEN: if (CreatureTest(n)==1) good_flag = true;
          default: good_flag = true;
      }

      if (good_flag) {
          match_scores-->i = SCORE__IFGOOD;
          good_ones++; last = n;
      }
  }
  if (good_ones==1) return last;

  ! If there is ambiguity about what was typed, but it definitely wasn't
  ! animate as required, then return anything; higher up in the parser
  ! a suitable error will be given.  (This prevents a question being asked.)
  !
  if (context==CREATURE_TOKEN && good_ones==0) return match_list-->0;

  if (indef_mode==0) indef_type=0;

  ScoreMatchL(context);
  if (number_matched == 0) return -1;

  if (indef_mode == 0)
  {   !  Is there now a single highest-scoring object?
      i = SingleBestGuess();
      if (i >= 0)
      {   
#ifdef DEBUG;
          if (parser_trace>=4)
              print "   Single best-scoring object returned.]^";
#endif;
          return i;
      }
  }

  if (indef_mode==1 && indef_type & PLURAL_BIT ~= 0)
  {   if (context ~= MULTI_TOKEN or MULTIHELD_TOKEN or MULTIEXCEPT_TOKEN
                     or MULTIINSIDE_TOKEN)
      {   etype=MULTI_PE; return -1; }
      i=0; offset=multiple_object-->0; sovert = -1;
      for (j=BestGuess():j~=-1 && i<indef_wanted
           && i+offset<63:j=BestGuess())
      {   flag=0;
          if (j hasnt concealed or worn && j ~= actor) flag=1;
          if (sovert == -1) sovert = bestguess_score/SCORE__DIVISOR;
          else {
              if (indef_wanted == 100
                  && bestguess_score/SCORE__DIVISOR < sovert) flag=0;
          }
          if (context==MULTIHELD_TOKEN or MULTIEXCEPT_TOKEN && j notin actor)
          { flag=0; etype = NONEHELD_PE; }
          if (action_to_be == ##Take && j in actor) flag=0;
          k = 0;
          if (j provides disambiguate) k = j.disambiguate(flag);
          if (k == 0) k = ChooseObjects(j, flag);
          if (k==1) flag=1; else { if (k==2) flag=0; }
          if (flag==1)
          {   i++; multiple_object-->(i+offset) = j;
#ifdef DEBUG;
              if (parser_trace>=4) print "   Accepting it^";
#endif;
          }
          else
          {   i=i;
#ifdef DEBUG;
              if (parser_trace>=4) print "   Rejecting it^";
#endif;
          }
      }
      if (i<indef_wanted && indef_wanted<100)
      {   etype=TOOFEW_PE; multi_wanted=indef_wanted;
          multi_had=i;
          return -1;
      }
      multiple_object-->0 = i+offset;
      multi_context=context;
#ifdef DEBUG;
      if (parser_trace>=4)
          print "   Made multiple object of size ", i, "]^";
#endif;
      return 1;
  }

  for (i=0:i<number_matched:i++) match_classes-->i=0;

  n=1;
  for (i=0:i<number_matched:i++)
      if (match_classes-->i==0)
      {   match_classes-->i=n++; flag=0;
          for (j=i+1:j<number_matched:j++)
              if (match_classes-->j==0
                  && Identical(match_list-->i, match_list-->j)==1)
              {   flag=1;
                  match_classes-->j=match_classes-->i;
              }
          if (flag==1) match_classes-->i = 1-n;
      }
  n--; number_of_classes = n;

#ifdef DEBUG;
  if (parser_trace>=4)
  {   print "   Grouped into ", n, " possibilities by name:^";
      for (i=0:i<number_matched:i++)
          if (match_classes-->i > 0)
              print "   ", (The) match_list-->i,
                  " (", match_list-->i, ")  ---  group ",
                  match_classes-->i, "^";
  }
#endif;

  if (indef_mode == 0)
  {   if (n > 1)
      {   k = -1;
          for (i=0:i<number_matched:i++)
          {   if (match_scores-->i > k)
              {   k = match_scores-->i;
                  j = match_classes-->i; j=j*j;
                  flag = 0;
              }
              else
              if (match_scores-->i == k)
              {   if ((match_classes-->i) * (match_classes-->i) ~= j)
                      flag = 1;
              }
          }
          if (flag)
          {
#ifdef DEBUG;
              if (parser_trace>=4)
                  print "   Unable to choose best group, so ask player.]^";
#endif;
              return 0;
          }
#ifdef DEBUG;
          if (parser_trace>=4)
              print "   Best choices are all from the same group.^";
#endif;          
      }
  }

!  When the player is really vague, or there's a single collection of
!  indistinguishable objects to choose from, choose the one the player
!  most recently acquired, or if the player has none of them, then
!  the one most recently put where it is.

  if (n==1) dont_infer = true;
  return BestGuess();
];

! ----------------------------------------------------------------------------
!  ReviseMulti  revises the multiple object which already exists, in the
!    light of information which has come along since then (i.e., the second
!    parameter).  It returns a parser error number, or else 0 if all is well.
!    This only ever throws things out, never adds new ones.
! ----------------------------------------------------------------------------

[ ReviseMulti second_p  i low;

#ifdef DEBUG;
  if (parser_trace>=4)
      print "   Revising multiple object list of size ", multiple_object-->0,
            " with 2nd ", (name) second_p, "^";
#endif;

  if (multi_context==MULTIEXCEPT_TOKEN or MULTIINSIDE_TOKEN)
  {   for (i=1, low=0:i<=multiple_object-->0:i++)
      {   if ( (multi_context==MULTIEXCEPT_TOKEN
                && multiple_object-->i ~= second_p)
               || (multi_context==MULTIINSIDE_TOKEN
                   && multiple_object-->i in second_p))
          {   low++; multiple_object-->low = multiple_object-->i;
          }
      }
      multiple_object-->0 = low;
  }

  if (multi_context==MULTI_TOKEN && action_to_be == ##Take)
  {   for (i=1, low=0:i<=multiple_object-->0:i++)
          if (ScopeCeiling(multiple_object-->i)==ScopeCeiling(actor))
              low++;
#ifdef DEBUG;
      if (parser_trace>=4)
          print "   Token 2 plural case: number with actor ", low, "^";
#endif;
      if (take_all_rule==2 || low>0)
      {   for (i=1, low=0:i<=multiple_object-->0:i++)
          {   if (ScopeCeiling(multiple_object-->i)==ScopeCeiling(actor))
              {   low++; multiple_object-->low = multiple_object-->i;
              }
          }
          multiple_object-->0 = low;
      }
  }

  i=multiple_object-->0;
#ifdef DEBUG;
  if (parser_trace>=4)
      print "   Done: new size ", i, "^";
#endif;
  if (i==0) return NOTHING_PE;
  return 0;
];

! ----------------------------------------------------------------------------
!  ScoreMatchL  scores the match list for quality in terms of what the
!  player has vaguely asked for.
! ----------------------------------------------------------------------------

[ ScoreMatchL context its_owner its_score obj i j a_s l_s;

#ifdef DEBUG;
  if (parser_trace>=4) print "   Scoring match list: indef mode ", indef_mode, ":^";
#endif;

  a_s = SCORE__NEXTBESTLOC; l_s = SCORE__BESTLOC;
  if (context == HELD_TOKEN or MULTIHELD_TOKEN or MULTIEXCEPT_TOKEN) {
      a_s = SCORE__BESTLOC; l_s = SCORE__NEXTBESTLOC;
  }

    for (i=0: i<number_matched: i++)
    {
        obj = match_list-->i; its_owner = parent(obj); its_score=0;

        its_score = 0;
        if (obj hasnt concealed) its_score = SCORE__UNCONCEALED;

        if (its_owner==actor) its_score = its_score + a_s;
        else if (its_owner==actors_location) its_score = its_score + l_s;
        else if (its_owner~=compass) its_score = its_score + SCORE__NOTCOMPASS;

        its_score = its_score + SCORE__LOGICAL * ScoreMatchLogical(obj);

        if (obj provides disambiguate)
            its_score = its_score + SCORE__CHOOSEOBJ * obj.disambiguate(2);

        its_score = its_score + SCORE__CHOOSEOBJ * ChooseObjects(obj, 2);

        if (obj hasnt concealed || obj hasnt static)
            its_score = its_score + SCORE__NOTSCENERY;
        if (obj ~= actor) its_score = its_score + SCORE__NOTACTOR;

          !   A small bonus for having the correct GNA,
          !   for sorting out ambiguous articles and the like.

          if (indef_cases & (PowersOfTwo_TB-->(GetGNAOfObject(obj))))
              its_score = its_score + SCORE__GNA;

          match_scores-->i = match_scores-->i + its_score;
#ifdef DEBUG;
          if (parser_trace >= 4)
          {  print "     ", (The) match_list-->i," (", match_list-->i, ")";
             if (its_owner) print " in ",(the) its_owner;
             print " : ", match_scores-->i, " points^";
          }
#endif;
      }

  for (i=0:i<number_matched:i++)
  {   while (match_list-->i == -1)
      {   if (i == number_matched-1) { number_matched--; break; }
          for (j=i:j<number_matched:j++)
          {   match_list-->j = match_list-->(j+1);
              match_scores-->j = match_scores-->(j+1);              
          }
          number_matched--;
      }
  }
];

! ----------------------------------------------------------------------------
!  ScoreMatchLogical(object, context)
!  Alters the object's match score based on how sensible a choice it
!  would be, considering the action to be performed.
! ----------------------------------------------------------------------------

[ ScoreMatchLogical obj     o1 p;

    p = parameters + parsing_ahead;

    switch(p)
    {
        0:
        switch(action_to_be)
        {   ##Close:
                if (obj has openable)
                {   if (obj has open) return 2;
                    return 1;
                }
            ##Disrobe:
                if (obj has clothing)
                {   if (obj in actor && obj has worn)
                        return 2;
                    return 1;
                }
            ##Eat, ##Taste: if (obj has edible) return 1;
            ##Enter: if (obj provides allow_entry) return 1;
            ##EnterIn:
                if (obj has container)
                {   if (obj provides allow_entry
                        && obj.allow_entry(inside)) return 2;
                    return 1;
                }
            ##EnterOn:
                if (obj has supporter)
                {   if (obj provides allow_entry
                        && obj.allow_entry(upon)) return 2;
                    return 1;
                }
            ##EnterUnder:
                if (obj has hider)
                {   if (obj provides allow_entry
                        && obj.allow_entry(under)) return 2;
                    return 1;
                }
            ##GoToRoom:
                if (actor ofclass Actors && obj ~= actor.location)
                    return 1;
            ##Kiss, ##WakeOther:
                if (obj has animate) return 1;
            ##Lock:
                if (obj provides with_key)
                {   if (obj hasnt locked) return 2;
                    return 1;
                }
            ##LookOn:
                if (obj has supporter) return 1;
            ##LookUnder:
                if (obj has hider)
                {   if (obj hasnt transparent) return 2;
                    return 1;
                }
            ##Open:
                if (obj has openable)
                {   if (obj hasnt open) return 2;
                    return 1;
                }
            ##Search:
                if (obj has container)
                {   if (obj has open && obj notin actor) return 2;
                    return 1;
                }
            ##Switch: if (obj has switchable) return 1;
            ##SwitchOff:
                if (obj has switchable)
                {   if (obj has on) return 2;
                    return 1;
                }
            ##SwitchOn:
                if (obj has switchable)
                {   if (obj hasnt on) return 2;
                    return 1;
                }
            ##TakeFromUnder:
                if (obj has under) return 1;
            ##Unlock:
                if (obj provides with_key)
                {   if (obj has locked) return 2;
                    return 1;
                }
            ##Wear: 
                if (obj has clothing)
                {   if (obj notin actor || obj hasnt worn)
                        return 2;
                    return 1;
                }
        }
        1:
        o1 = inputobjs-->2;
        switch(action_to_be)
        {   ##Insert:
                if (obj has container) return 1;
!            ##Lock, ##Unlock:
!                if (o1 && o1 provides with_key
!                    && o1.with_key == obj) return 1;
            ##PutOn:
                if (obj has supporter) return 1;
            ##PutUnder, ##TakeFromUnder:
                if (obj has hider) return 1;
            ##Take:
                if (obj has container or supporter)
                {   if (HasVisibleContents(obj)) return 2;
                    return 1;
                }
        }

    }
    rfalse;
];

! ----------------------------------------------------------------------------
!  BestGuess makes the best guess it can out of the match list, assuming that
!  everything in the match list is textually as good as everything else;
!  however it ignores items marked as -1, and so marks anything it chooses.
!  It returns -1 if there are no possible choices.
! ----------------------------------------------------------------------------

[ BestGuess  earliest its_score best i;

  earliest=0; best=-1;
  for (i=0:i<number_matched:i++)
  {   if (match_list-->i >= 0)
      {   its_score=match_scores-->i;
          if (its_score>best) { best=its_score; earliest=i; }
      }
  }
#ifdef DEBUG;
  if (parser_trace>=4)
  {   if (best<0)
          print "   Best guess ran out of choices^";
      else
          print "   Best guess ", (the) match_list-->earliest,
                " (", match_list-->earliest, ")^";
  }
#endif;
  if (best<0) return -1;
  i=match_list-->earliest;
  match_list-->earliest=-1;
  bestguess_score = best;
  return i;
];

! ----------------------------------------------------------------------------
!  SingleBestGuess returns the highest-scoring object in the match list
!  if it is the clear winner, or returns -1 if there is no clear winner
! ----------------------------------------------------------------------------

[ SingleBestGuess     earliest its_score best i;

  earliest = -1; best = -1000;
  for (i = 0:i < number_matched:i++)
  {   its_score = match_scores-->i;
      if (its_score == best) { earliest = -1; }
      if (its_score > best) { best = its_score; earliest = match_list-->i; }
  }
  bestguess_score = best;
  return earliest;
];

        ! Identical (object 1, object 2)
        ! Modified to check adjectives.

[ Identical o1 o2     i j;

    if (o1 == o2) rtrue;
    if (0 == o1 or o2) rfalse;
    if (o1 in compass || o2 in compass) rfalse;    

!  What complicates things is that o1 or o2 might have a parsing routine,
!  so the parser can't know from here whether they are or aren't the same.
!  If they have different parsing routines, we simply assume they're
!  different.  If they have the same routine (which they probably got from
!  a class definition) then the decision process is as follows:
!
!     the routine is called (with self being o1, not that it matters)
!       with noun and second being set to o1 and o2, and action being set
!       to the fake action TheSame.  If it returns -1, they are found
!       identical; if -2, different; and if >=0, then the usual method
!       is used instead.

  if (o1.parse_name || o2.parse_name)
  {   if (o1.parse_name ~= o2.parse_name) rfalse;
      parser_action = ##TheSame; parser_one = o1; parser_two = o2;
      j = wn; i = RunRoutines(o1, parse_name); wn = j;
      if (i == -1) rtrue;
      if (i == -2) rfalse;
  }

    if (o1 provides words)
    {   if ((~~(o2 provides words)) || o1.words ~= o2.words) rfalse;
        parser_action = ##TheSame;
        parser_one = o1; parser_two = o2;
        j = wn; i = RunRoutines(o1, words); wn = j;
        if (i == -1) rtrue;
        rfalse;
    }

!  This is the default algorithm: do they have the same words in their
!  name and adjective properties?

    if (TestPropsMatch(o1, o2, name)
        && TestPropsMatch(o1, o2, adjective)) rtrue;
    rfalse;
];

[ TestPropsMatch x y pr     ad1 ad2 l1 l2 c;

    ad1 = x.&pr;      ad2 = y.&pr;
    l1  = x.#pr / WORDSIZE;  l2  = y.#pr / WORDSIZE;

    for (c = 0:c < l1:c++)
        if (WordInProperty(ad1-->c, y, pr) == 0) rfalse;
    for (c = 0:c < l2:c++)
        if (WordInProperty(ad2-->c, x, pr) == 0) rfalse;
];

! ----------------------------------------------------------------------------
!  PrintCommand reconstructs the command as it presently reads, from
!  the pattern which has been built up
!
!  If from is 0, it starts with the verb: then it goes through the pattern.
!  The other parameter is "emptyf" - a flag: if 0, it goes up to pcount:
!  if 1, it goes up to pcount-1.
!
!  Note that verbs and prepositions are printed out of the dictionary:
!  and that since the dictionary may only preserve the first six characters
!  of a word (in a V3 game), we have to hand-code the longer words needed.
!
!  (Recall that pattern entries are 0 for "multiple object", 1 for "special
!  word", 2 to REPARSE_CODE-1 are object numbers and REPARSE_CODE+n means the
!  preposition n)
! ----------------------------------------------------------------------------

[ PrintCommand from i k spacing_flag;

    if (from==0)
    {   i=verb_word;
        if (LanguageVerb(i) == 0 && PrintVerb(i) == 0)
            print (address) i;
        from++;
        spacing_flag = true;
  }

  for (k=from:k<pcount:k++)
  {   i=pattern-->k;
      if (i == PATTERN_NULL) continue;

      if (spacing_flag) print (char) ' ';
      if (i==0) { print (string) THOSET__TX; jump TokenPrinted; }
      if (i==1) { print (string) THAT__TX; jump TokenPrinted; }
      if (i>=REPARSE_CODE) print (address) No__Dword(i-REPARSE_CODE);
      else if (actor ~= player && i == player && player_perspective ~= 3)
          thatorthose(actor);
      else print (the) i;
!      else PrintSpecName(i);
      .TokenPrinted;
      spacing_flag = true;
  }
];

!#ifdef COMMENT;
[ PrintSpecName x f     y;

    if (~~(x ofclass Object)) rfalse;
    y = parent(x);
    if (y == 0) { print (the) x; return; }
    if (~~(y ofclass Object))
    {   if (f) print (a) x; else print (the) x;
        rtrue;
    }

    if (f) print (a) x; else print (the) x;

];
!#endif;

! ----------------------------------------------------------------------------
!  The CantSee routine returns a good error number for the situation where
!  the last word looked at didn't seem to refer to any object in context.
! ----------------------------------------------------------------------------

[ CantSee  w e;

    saved_oops = oops_from;

    if (scope_token) { scope_error = scope_token; return ASKSCOPE_PE; }

    wn--; w=NextWord();
    e=CANTSEE_PE;
    if (w == pronoun_word)
    {   pronoun__word = pronoun_word; pronoun__obj = pronoun_obj;
        e = ITGONE_PE;
    }
    if (etype > e) return etype;
    return e;
];

! ----------------------------------------------------------------------------
!  The MultiAdd routine adds object "o" to the multiple-object-list.
!
!  This is only allowed to hold 63 objects at most, at which point it ignores
!  any new entries (and sets a global flag so that a warning may later be
!  printed if need be).
! ----------------------------------------------------------------------------

[ MultiAdd o     i;

  i = multiple_object-->0;
  if (i == 63) { toomany_flag = 1; rtrue; }

  if (FindInTable(o, multiple_object) ~= -1) rtrue;

  i++;
  multiple_object-->i = o;
  multiple_object-->0 = i;
];

! ----------------------------------------------------------------------------
!  The MultiSub routine deletes object "o" from the multiple-object-list.
!
!  It returns 0 if the object was there in the first place, and 9 (because
!  this is the appropriate error number in Parser()) if it wasn't.
! ----------------------------------------------------------------------------

[ MultiSub o     i j k;

    i = multiple_object-->0;
    j = FindInTable(o, multiple_object);
    if (j == -1) return 9;

    for (k = j:k <= i:k++)
        multiple_object-->k = multiple_object-->(k + 1);
    multiple_object-->0 = i - 1;
    rfalse;
];

! ----------------------------------------------------------------------------
!  The MultiFilter routine goes through the multiple-object-list and throws
!  out anything without the given attribute "attr" set.
! ----------------------------------------------------------------------------

[ MultiFilter attr     i j o;
  .MFiltl;
  i = multiple_object-->0;
  for (j = 1:j <= i:j++)
  {   o = multiple_object-->j;
      if (o hasnt attr) { MultiSub(o); jump Mfiltl; }
  }
];

! ----------------------------------------------------------------------------
!  The UserFilter routine consults the user's filter (or checks on attribute)
!  to see what already-accepted nouns are acceptable
! ----------------------------------------------------------------------------

[ UserFilter obj;

  if (token_filter > 0 && token_filter < 49)
  {   if (obj has (token_filter-1)) rtrue;
      rfalse;
  }
  noun = obj;
  return indirect(token_filter);
];

! ----------------------------------------------------------------------------
!  MoveWord copies word at2 from parse buffer b2 to word at1 in "parse"
!  (the main parse buffer)
! ----------------------------------------------------------------------------

#ifndef TARGET_GLULX;

[ MoveWord at1 b2 at2 x y;
  x=at1*2-1; y=at2*2-1;
  parse-->x++ = b2-->y++;
  parse-->x = b2-->y;
];

#endif;
#ifdef TARGET_GLULX;

[ MoveWord at1 b2 at2 x y;
  x=at1*3-2; y=at2*3-2;
  parse-->x++ = b2-->y++;
  parse-->x++ = b2-->y++;
  parse-->x = b2-->y;
];

#endif; ! TARGET_

! ============================================================================
!      SCOPE ROUTINES                                                   sec:06
!
!   SearchScope   (focus[, context])
!   ScopeWithin   (obj[, focus])
!   ScopeCeiling  (focus)
!   PlaceInScope  (obj)
!   ScopeAll      ()
!   TestScope     (obj[, focus])
!   LoopOverScope (routine[, focus])
!
!   focus is the object for which scope is being determined, and defaults
!   to the current =actor=.
! ============================================================================

[ SearchScope obj context     x y x2 y2 ceiling;

!  Everything is in scope to the debugging commands

    #ifdef DEBUG;
    if (scope_reason == PARSING_REASON
        && verb_word == 'purloin' or 'tree' or 'abstract'
                        or 'gonear' or 'scope' or 'showobj')
    {   ScopeAll();
        rtrue;
    }
    #endif;

!  First, a scope token gets priority here:

    if (scope_token)
    {   scope_stage = 2;
        if (indirect(scope_token)) rtrue;
    }

!  Next, call any user-supplied routine adding things to the scope,
!  which may circumvent the usual routines altogether if they return true:

    if (obj == actor && InScope(actor)) rtrue;

!  Ensure that an actor's location is in scope, if it is not the scope
!  ceiling but the scope reason is each_turn or a meddle property.

    ceiling = ScopeCeiling(obj);

    if (obj ofclass Actors && obj.location
        && ceiling ~= obj.location
        && scope_reason ~= PARSING_REASON or TALKING_REASON
                           or TESTSCOPE_REASON or LOOPOVERSCOPE_REASON)
            PlaceInScope(obj.location);

!  Enable the ScopeCogs:

    x = child(ScopeGizmo);
    while (x)
    {   y = sibling(x);
        if (x.join_scope(obj)) PlaceInScope(x);
        x = y;
    }

!  If the context is MULTIINSIDE_TOKEN, only look within the specified
!  object:

    if (context == MULTIINSIDE_TOKEN && advance_warning ~= -1)
    {   ScopeWithin(advance_warning);
        return;
    }

!  Directions:

    if (indef_mode == 0 && scope_reason == PARSING_REASON
        && context ~= CREATURE_TOKEN)
        ScopeWithin(compass, compass);

!  Determining what's in scope to a floating object:

    if (obj in FloatingHome)
    {   x = child(Map);
        while (x)
        {   y = sibling(x);
            if (IsFoundIn(obj, x)) ScopeWithin(x);
            x = y;
        }
        
    !  Floating objects are in scope to each other if they float in any
    !  of the same locations:
        
        x = child(FloatingHome);
        while (x)
        {   y = sibling(x);
            if (x ~= obj)
            {   x2 = child(Map);
                while (x2)
                {   y2 = sibling(x2);
                    if (IsFoundIn(obj, x2) && IsFoundIn(x, x2))
                    {   ScopeWithin(x);
                        break;
                    }
                    x2 = y2;
                }
            }
            x = y;
        }
    }

!  Determining what floating objects are in scope to this (non-floating)
!  object:

    else if (ceiling in Map)
    {   x = child(FloatingHome);
        while (x)
        {   y = sibling(x);
            if (IsFoundIn(x, ceiling)) ScopeWithin(x);
            x = y;
        }
    }

!  And now the basics:

    ScopeWithin(ceiling, obj);
    if (ceiling == thedark)
        ScopeWithin(obj, obj);
];

[ ScopeWithin obj focus     x y c focus_relation is_enclosed pos;

!  Putting the object itself in scope...

    #ifdef DONT_SCOPE_ROOMS;
        if (obj notin Map
            || scope_reason ~= PARSING_REASON or TALKING_REASON
                               or TESTSCOPE_REASON or LOOPOVERSCOPE_REASON)
        PlaceInScope(obj);
    #endif;
    
    #ifndef DONT_SCOPE_ROOMS;
        PlaceInScope(obj);
    #endif;

!  ...along with anything it specifically adds to scope:

    if (obj provides add_to_scope)
    {   if (metaclass(obj.&add_to_scope-->0) == Routine)
            obj.add_to_scope();
        else
            for (c = 0:c < obj.#add_to_scope / WORDSIZE:c++)
            {   x = obj.&add_to_scope-->c;
                if (x) ScopeWithin(x);
            }
    }
    
!  Simplest case: all children of a transparent object or a room
!  are in scope and all of an object's own children are in scope
!  to it:

    if (obj has transparent || focus == obj || obj in Map)
    {   x = child(obj);
        while (x)
        {   y = sibling(x);
            if (positionof(x) ~= -1) ScopeWithin(x, focus);
            x = y;
        }
        return;
    }

!  Determine the relative position of the focus (if any) to the object:

    if (focus) focus_relation = IndirectlyContains(obj, focus);
    if (obj has container && obj hasnt open)
        is_enclosed = true;

!  Now determine which contents are in scope, and scope them and their
!  contents:

    x = child(obj);
    while (x)
    {   y = sibling(x);
        pos = positionof(x);
        if (pos ~= 0 or -1)
            if (is_enclosed == false
                || (pos == inside && focus_relation == inside)
                || (pos ~= inside && focus_relation ~= inside))
                    ScopeWithin(x, focus);
        x = y;
    }
];

[ ScopeCeiling thing     par pos;

    if (parent(thing) == 0 or Map or FloatingHome)
        return thing;
    if (ignore_darkness == false && InDark(thing))
        return thedark;

    par = parent(thing);
    pos = PositionOf(thing);

    while (par && pos ~= -1
        && (par has transparent
        || pos == upon or under or worn
        || (pos == inside && par has open)))
        {   thing = par; pos = PositionOf(thing); par = parent(thing); }

    return par;
];

        ! PlaceInScope (object)

[ PlaceInScope thing     s p1 a;

    s = scope_reason; p1 = parser_one;
    #ifdef DEBUG;
        if (parser_trace>=6)
        {   print "[PlaceInScope on ",(the) thing," with reason = ",
                scope_reason," p1 = ",parser_one," p2 = ",parser_two, "]^";
        }
    #endif;
    switch(scope_reason)
    {   PARSING_REASON, TALKING_REASON:
            wn = match_from;
            TryGivenObject(thing);
        MEDDLE_EARLY_REASON:
            if (thing.meddle_early == 0 or NULL) return;
            #ifdef DEBUG;
                if (parser_trace>=2)
                {   print "[Considering meddle_early for ", (the) thing, "]^"; }
            #endif;
            a = RunRoutines(thing, meddle_early);
            if (parser_one == 0) parser_one = a;
        MEDDLE_LATE_REASON:
            if (thing.meddle_late == 0 or NULL) return;
            #ifdef DEBUG;
                if (parser_trace>=2)
                    print "[Considering meddle_late for ", (the) thing, "]^";
            #endif;
            a = RunRoutines(thing, meddle_late);
            if (parser_one == 0) parser_one = a;
        MEDDLE_LATE_LATE_REASON:
            if (thing.meddle_late_late == 0 or NULL) return;
            #ifdef DEBUG;
                if (parser_trace >= 2)
                    print "[Considering meddle_late_late for ",(the) thing,"]^";
            #endif;
            a = RunRoutines(thing, meddle_late_late);
            if (parser_one == 0) parser_one = a;
        MEDDLE_REASON:
            if (thing.meddle == 0 or NULL) return;
            #ifdef DEBUG;
                if (parser_trace >= 2)
                    print "[Considering meddle for ",(the) thing,"]^";
            #endif;
            a = RunRoutines(thing, meddle);
            if (parser_one == 0) parser_one = a;
        EACH_TURN_REASON:
            if (thing.each_turn == 0 or NULL) return;
            #ifdef DEBUG;
                if (parser_trace>=2)
                {   print "[Considering each_turn for ", (the) thing, "]^"; }
            #endif;
            PrintOrRun(thing, each_turn);
        TESTSCOPE_REASON:
            if (thing == parser_one) parser_two = 1;
        LOOPOVERSCOPE_REASON:
            indirect(parser_one, thing); parser_one = p1;
    }
    scope_reason = s;
];

[ ScopeAll     x;

    objectloop(x ofclass Object)
        if (parent(x) == 0 || parent(x) ofclass Object)
            PlaceInScope(x);
];

[ TestScope obj act     old_scope_reason old_parser_one old_parser_two rv;

    old_parser_one = parser_one; old_parser_two = parser_two;
    parser_one = obj; parser_two = 0;
    old_scope_reason = scope_reason; scope_reason = TESTSCOPE_REASON;
    if (act == 0) act = player;
    SearchScope(act); rv = parser_two;
    scope_reason = old_scope_reason;
    parser_one = old_parser_one; parser_two = old_parser_two;
    return rv;
];

[ LoopOverScope routine act     old_parser_one old_scope_reason;

  old_parser_one = parser_one; old_scope_reason = scope_reason;
  parser_one = routine;
  if (act == 0) act = player;
  scope_reason = LOOPOVERSCOPE_REASON;
  SearchScope(act);
  parser_one = old_parser_one; scope_reason = old_scope_reason;
];


! ---------------------------------  end:03  ---------------------------------

        ! MakeMatch (object, quality)

[ MakeMatch obj quality     du;

    du = desc_used;
    desc_used = 0;

    #ifdef DEBUG;
        if (parser_trace>=6) print "    Match with quality ",quality,"^";
    #endif;

    if (token_filter && UserFilter(obj)==0)
    {   
        #ifdef DEBUG;
            if (parser_trace>=6)
                print "    Match filtered out: token filter ", token_filter, "^";
        #endif;
        rtrue;
    }

    if (quality < match_length)
        rtrue;

    if (quality > match_length)
    {
        match_length = quality; number_matched = 0; 
    }
    else
    {
        if (number_matched >= MATCH_LIST_SIZE) rtrue;
        if (match_descriptors > du)
            number_matched = 0;
        else  
            if (du > match_descriptors) rtrue;
        else
            if (FindByWord(obj, match_list, number_matched) ~= -1) rtrue;
    }
    match_list-->number_matched++ = obj;
                match_descriptors = du;
                       indef_mode = indef_mode_spec;
                     indef_wanted = numspec;
    if (indef_mode && indef_wanted > 1)
        indef_type = indef_type | PLURAL_BIT;
    else
        indef_type = indef_type & (~PLURAL_BIT);


    #ifdef DEBUG;
        if (parser_trace >= 6) print "   Match added to list^";
    #endif;
];

! ----------------------------------------------------------------------------
!  TryGivenObject tries to match as many words as possible in what has been
!  typed to the given object, obj.  If it manages any words matched at all,
!  it calls MakeMatch to say so, then returns the number of words (or 1
!  if it was a match because of inadequate input).
! ----------------------------------------------------------------------------

[ TryGivenObject obj threshold k w j x;

#ifdef DEBUG;
   if (parser_trace>=5)
       print "    Trying ", (the) obj, " (", obj, ") at word ", wn, "^";
#endif;

   dict_flags_of_noun = 0;

!  If input has run out then always match, with only quality 0 (this saves
!  time).

   if (wn > num_words)
   {   indef_mode_spec = 0;
       MakeMatch(obj, 0);
       #ifdef DEBUG;
       if (parser_trace >= 5) print "      Matched (0)^";
       #endif;
       return 1;
   }

   parser_action = NULL;

   w = NounWord();

   if (w==1 && player==obj) { k=1; jump MMbyPN; }

   if (w == obj)
   {   k=1; jump MMbyPN; }

   j=--wn;

   x = obj; while (x && (x hasnt animate) && parent(x)) x = parent(x);
   if (x has animate) the_owner = x; else the_owner = 0;

   threshold = ParseObj(obj);
#ifdef DEBUG;
   if (threshold>=0 && parser_trace>=5)
       print "    ParseObj returned ", threshold, "^";
#endif;
    k = threshold;
    if (k) jump MMbyPN;

   .NoWordsMatch;
    rfalse;

   .MMbyPN;

   if (parser_action == ##PluralFound)
       dict_flags_of_noun = dict_flags_of_noun | 4;

   if (dict_flags_of_noun & 4)
   {   if (~~allow_plurals) k=0;
       else 
       { indef_mode_spec = 1;
         if (numspec == 0) numspec = 100;
       }
   }

   #ifdef DEBUG;
       if (parser_trace>=5)
       {   print "    Matched (", k, ")^";
       }
   #endif;
   MakeMatch(obj,k);
   return k;
];

        ! WordInProperty (word,object,property)

[ WordInProperty w obj prop;

    if (FindByWord(w, obj.&prop, obj.#prop / WORDSIZE) == -1)
        rfalse;
];

#ifndef TARGET_GLULX;

[ DictionaryLookup address length;

    CopyBytes(address, buffer2 + 2, length);
    buffer2 -> 1 = length;
    Tokenise__(buffer2, parse2);
    return parse2-->1;
];

#endif;
#ifdef TARGET_GLULX;

[ DictionaryLookup b l i;
  for (i=0:i<l:i++) buffer2->(WORDSIZE+i) = b->i;
  buffer2-->0 = l;
  Tokenise__(buffer2,parse2);
  return parse2-->1;
];

#endif; ! TARGET_

! ----------------------------------------------------------------------------
!  NounWord (which takes no arguments) returns:
!
!   0  if the next word is unrecognised or does not carry the "noun" bit in
!      its dictionary entry,
!   1  if a word meaning "me",
!   an object number if the next word is a pronoun referring to an object
!       or NULL if it is unset
!   the address in the dictionary if it is a recognised noun.
!
!  The "current word" marker moves on one.
! ----------------------------------------------------------------------------

[ NounWord     i s;

    i = NextWord();
    if (i==0) rfalse;
    if ((player_perspective == 2 && IsMeWord(i))
        || (player_perspective == 1 && IsYouWord(i)))
        rtrue;
    s = PronounValue(i); if (s) return s;
    if ((i->#dict_par1)&128 == 0) rfalse;
    return i;
];

! ----------------------------------------------------------------------------
!  NextWord (which takes no arguments) returns:
!
!  0            if the next word is unrecognised,
!  COMMA_WORD   if it is a comma character
!  THEN1_WORD   if it is a full stop
!  QUOTE_WORD   if it is a double quote
!  or the dictionary address if it is recognised.
!  The "current word" marker is moved on.
!
!  NextWordStopped does the same, but returns -1 when input has run out
! ----------------------------------------------------------------------------

#ifndef TARGET_GLULX;

[ NextWord     i j k;
   if (wn > parse->1) { wn++; rfalse; }
   i=wn*2-1; wn++;
   j=parse-->i;
   if (j == ',//') return COMMA_WORD;
   if (j == './/') return THEN1__WD;
   if (j == 0)
   {    k=wn * 4 - 3; i = buffer->(parse->k);
        if (i == '"') return QUOTE_WORD;
   }
   return j;
];   

[ NextWordStopped;
   if (wn > parse->1) { wn++; return -1; }
   return NextWord();
];

[ WordAddress wordnum;
   return buffer + parse->(wordnum*4+1);
];

[ WordLength wordnum;
   return parse->(wordnum*4);
];

#endif;
#ifdef TARGET_GLULX;

[ NextWord i j;
   if (wn > parse-->0) { wn++; rfalse; }
   i=wn*3-2; wn++;
   j=parse-->i;
   if (j == ',//') return COMMA_WORD;
   if (j == './/') return THEN1__WD;
   if (j == '"//') return QUOTE_WORD;
   return j;
];   

[ NextWordStopped;
   if (wn > parse-->0) { wn++; return -1; }
   return NextWord();
];

[ WordAddress wordnum;
   return buffer + parse-->(wordnum*3);
];

[ WordLength wordnum;
   return parse-->(wordnum*3-1);
];

#endif; ! TARGET_


! ----------------------------------------------------------------------------
!  TryNumber is the only routine which really does any character-level
!  parsing, since that's normally left to the Z-machine.
!  It takes word number "wordnum" and tries to parse it as an (unsigned)
!  decimal number, returning
!
!  -1000                if it is not a number
!  the number           if it has between 1 and 4 digits
!  10000                if it has 5 or more digits.
!
!  (The danger of allowing 5 digits is that Z-machine integers are only
!  16 bits long, and anyway this isn't meant to be perfect.)
!
!  Using NumberWord, it also catches "one" up to "twenty".
!
!  Note that a game can provide a ParseNumber routine which takes priority,
!  to enable parsing of odder numbers ("x45y12", say).
! ----------------------------------------------------------------------------

[ TryNumber wordnum   i j num len tot;

    i = wn; wn = wordnum; j = NextWord(); wn = i;
    j = NumberWord(j); if (j >= 1) return j;

#ifndef TARGET_GLULX;
   i=wordnum*4+1; j=parse->i; num=j+buffer; len=parse->(i-1);
#endif;
#ifdef TARGET_GLULX;
   i=wordnum*3; j=parse-->i; num=j+buffer; len=parse-->(i-1);
#endif; ! TARGET_

    tot = ParseNumber(num, len);  if (tot) return tot;

    return ParseDigits(num, len);
];

[ ParseDigits addr len     mul tot d;

    len--;
    if (len > 3) return -1000;
    mul = 1;
    for (:len >= 0:len--)
    {   d = GetDigitValue(addr->len);
        if (d == -1) return -1000;
        tot = tot + mul * d;
        mul = mul * 10;
    }
    return tot;
];

[ GetGNAOfObject obj     case gender;

   if (obj hasnt animate) case = 6;
   if (obj has male) gender = male;
   if (obj has female) gender = female;
   if (obj has neuter) gender = neuter;
   if (gender == 0)
   {   if (case == 0) gender = LanguageAnimateGender;
       else gender = LanguageInanimateGender;
   }
   if (gender == female) case++;
   if (gender == neuter) case = case + 2;
   if (obj has pluralname) case = case + 3;
   return case;
];

! ----------------------------------------------------------------------------
!  Converting between dictionary addresses and entry numbers
! ----------------------------------------------------------------------------

#ifndef TARGET_GLULX;

[ Dword__No w; return (w-(0-->4 + 7))/9; ];
[ No__Dword n; return 0-->4 + 7 + 9*n; ];

#endif;
#ifdef TARGET_GLULX;

! In Glulx, dictionary entries *are* addresses.
[ Dword__No w; return w; ];
[ No__Dword n; return n; ];

#endif; ! TARGET_

        ! CopyBuffer (bto, bfrom)
        ! Modified to use @copy_table.

#ifndef TARGET_GLULX;
[ CopyBuffer bto bfrom      size;

    size=bto->0;
    bto++; bfrom++;
    @copy_table bfrom bto size;
];
#endif;
#ifdef TARGET_GLULX;
[ CopyBuffer bto bfrom;
    CopyWords(bfrom, bto, INPUT_BUFFER_LEN);
];
#endif;

! ============================================================================

[ PronounsSub     x y c d;

    L__M(##Pronouns, 1);

    c = NUMBER_OF_PRONOUNS;
    if (player_perspective == 2) c++;
    for (d = 0, x = 0 : x < NUMBER_OF_PRONOUNS : x++)
    {   print "~", (address) PronounWords-->x,"~ ";
        y = PronounReferents-->x;
        if (y == NULL) L__M(##Pronouns, 3);
        else { L__M(##Pronouns, 2); print (the) y; }
        d++;
        if (d < c - 1) print ", ";
        if (d == c - 1) print (string) AND__TX;
    }
    if (player_perspective == 2)
    {   print "~";
        if (player has pluralname) print (address) US__WD;
        else print (address) ME__WD;
        print "~ "; L__M(##Pronouns, 2);
        print (the) player;
    }
  ".";
];

[ SetPronoun dword value      idx;

    idx = FindByWord(dword, PronounWords, NUMBER_OF_PRONOUNS);
    if (idx ~= -1)
    {   PronounReferents-->idx = value;
        return;
    }
    RunTimeError(14);
];

[ PronounValue dword     idx;

    idx = FindByWord(dword, PronounWords, NUMBER_OF_PRONOUNS);
    if (idx ~= -1) return PronounReferents-->idx;
    rfalse;
];

[ PronounNotice obj     x bm;

   if (obj == player && player_perspective ~= 3) return;

   bm = PowersOfTwo_TB-->(GetGNAOfObject(obj));

   for (x = 0 : x < NUMBER_OF_PRONOUNS : x++)
       if (bm & (PronounGNAs-->x) ~= 0)
           PronounReferents-->x = obj;
];

! ============================================================================
!  End of the parser proper: the remaining routines are its front end.
! ----------------------------------------------------------------------------

[ CommandActor x y     a n s;

    n = noun; s = second;
    noun = x; second = y;
    a = RunRoutines(player, orders);
    if (a == 0)
    {
        a = RunRoutines(actor, orders);
        if (a == 0)
        {
            if (action == ##NotUnderstood)
            {   actor = player;
                action = ##Answer;
                rtrue;
            }
            L__M(##Order, 1, actor);
        }
    }
    noun = n; second = s;
    rfalse;
];


Object InformLibrary "(Inform Library)"
  with
    play [ i j k l;

#ifndef TARGET_GLULX;
       standard_interpreter = $32-->0;
       transcript_mode = ((0-->8) & 1);
#endif;
#ifdef TARGET_GLULX;
       GGInitialise();
#endif; ! TARGET_

        ChangeDefault(cant_go, CANTGO__TX);
        ChangeDefault(dirs, RoutFalse);

#ifndef TARGET_GLULX;
       buffer->0 = INPUT_BUFFER_LEN;
       buffer2->0 = INPUT_BUFFER_LEN;
       buffer3->0 = INPUT_BUFFER_LEN;
       parse->0 = 64;
       parse2->0 = 64;
#endif; ! TARGET_ZCODE

        player = PLAYER_OBJECT;
        actor = player;

#ifndef TARGET_GLULX;
        top_object = #largest_object - 255;
#endif;

        #ifdef LanguageInitialise;
            LanguageInitialise();
        #endif;

        j = StartupRoutines();

        last_score = score;
        objectloop(i ofclass Actors)
        {
            if (i.location) { move i to i.location; SetDefaultPosition(i); }
            i.location = rootof(i);
        }

        objectloop (i in player) give i moved;

        if (j ~= 2) Banner();

        lightflag = (~~(InDark(player)));
        <Look>;

       for (i=1:i<=100:i++) j=random(i);

       while (~~deadflag)
       {   
           .very__late__error;

           if (score ~= last_score)
           {   if (notify_mode) NotifyTheScore(); last_score=score; }

           .late__error;

           inputobjs-->0 = 0; inputobjs-->1 = 0;
           inputobjs-->2 = 0; inputobjs-->3 = 0; meta=false;

           !  The Parser writes its results into inputobjs and meta,
           !  a flag indicating a "meta-verb".  This can only be set for
           !  commands by the player, not for orders to others.

           InformParser.parse_input(inputobjs);

           action=inputobjs-->0;

           !  --------------------------------------------------------------

           !  Convert "P, tell me about X" to "ask P about X"

           if (action==##Tell && inputobjs-->2==player && actor~=player)
           {   inputobjs-->2=actor; actor=player; action=##Ask;
           }

           !  Convert "ask P for X" to "P, give X to me"

           if (action==##AskFor && inputobjs-->2~=player && actor==player)
           {   actor=inputobjs-->2; inputobjs-->2=inputobjs-->3;
               inputobjs-->3=player; action=##Give;
           }

           !  For old, obsolete code: special_word contains the topic word
           !  in conversation

           if (action==##Ask or ##Tell or ##Answer)
               special_word = special_number1;

           !  --------------------------------------------------------------

           multiflag = false;

          .begin__action;
           inp1 = 0; inp2 = 0; i=inputobjs-->1;
           if (i>=1) inp1=inputobjs-->2;
           if (i>=2) inp2=inputobjs-->3;

           !  inp1 and inp2 hold: object numbers, or 0 for "multiple object",
           !  or 1 for "a number or dictionary address"

           if (inp1 == 1) noun = special_number1; else noun = inp1;
           if (inp2 == 1)
           {   if (inp1 == 1) second = special_number2;
               else second = special_number1;
           } else second = inp2;

           !  --------------------------------------------------------------
           !  Generate the action...

            if ((i == 0)
               || (i == 1 && inp1 ~= 0)
               || (i == 2 && 0 ~= inp1 or inp2))
            {   
                if (actor ~= player)
                {   if (CommandActor(noun, second)) jump begin__action; }
                else
                    self.begin_action(action, noun, second, 0);
               jump turn__end;
           }

           !  ...unless a multiple object must be substituted.  First:
           !  (a) check the multiple list isn't empty;
           !  (b) warn the player if it has been cut short because too long;
           !  (c) generate a sequence of actions from the list
           !      (stopping in the event of death or movement away).

           multiflag = true;
           j=multiple_object-->0;
           if (j==0) { L__M(##Miscellany,2); jump late__error; }
           if (toomany_flag)
           {   toomany_flag = false; L__M(##Miscellany,1); }
            i = player.location;
            for (k = 1:k <= j:k++)
            {   if (deadflag) break;
                if (player.location ~= i)
                {   L__M(##Miscellany, 51);
                    break;
                }
                multicount = k;
                l = multiple_object-->k;
                PronounNotice(l);
                if (actor == player)
                {
                    if (inp1 == 0)
                        self.begin_action(action, l, second, 0);
                    else
                        self.begin_action(action, noun, l, 0);
                }
                else
                    if (inp1 == 0)
                        CommandActor(l, second);
                    else
                        CommandActor(noun, l);
            }

           !  --------------------------------------------------------------

           .turn__end;

           if (meta) continue;
           if (~~deadflag) self.end_turn_sequence();
       }

           if (deadflag~=2) AfterLife();
           if (deadflag==0) jump very__late__error;

           print "^^    ";
#ifndef TARGET_GLULX;
           style bold;
#endif;
#ifdef TARGET_GLULX;
           glk($0086, 5); ! set alert style
#endif; ! TARGET_
           if (deadflag == 1) L__M(##Miscellany, 3);
           if (deadflag == 2) L__M(##Miscellany, 4);
           if (deadflag>2)  DeathMessage();
#ifndef TARGET_GLULX;
           style roman;
#endif;
#ifdef TARGET_GLULX;
           glk($0086, 0); ! set normal style
#endif; ! TARGET_
           print "^^^";
           FullScoreSub();
           DisplayStatus();
           AfterGameOver();
       ],

       end_turn_sequence
       [;

           IncrementTime();
           RunDaemons();
           if (deadflag) return;

           scope_reason = EACH_TURN_REASON; verb_word = 0;
           SearchScope(player);
           scope_reason = PARSING_REASON;
           if (deadflag) return;

           TimePasses();
           if (deadflag) return;

           AdjustLight();
           if (deadflag) return;

           NoteObjectAcquisitions();
       ],

        begin_action
        [ a n s source   sa sn ss;

            sa = action; sn = noun; ss = second;
            action = a; noun = n; second = s;

            if (source == 0) actor = player;
			if (actor == player)
				last_name_printed = 0;

            #IFDEF DEBUG;
                if (debug_flag & 2) TraceAction(source);
            #ENDIF;
            if (action < 4096)
            {   if (actor == 0) actor = player;
#ifndef TARGET_GLULX;
                if (meta)
                    indirect(#actions_table-->action);
                else
                    actor.perform(a, n, s);
#endif;
#ifdef TARGET_GLULX;
                if (meta)
                    indirect(#actions_table-->(action + 1));
                else
                    actor.perform(a, n, s);
#endif;
            }
            action = sa; noun = sn; second = ss;
        ],
  has  proper;

[ AfterGameOver i;
   .RRQPL;
   L__M(##Miscellany,5);
   .RRQL;
   print "> ";
#ifndef TARGET_GLULX;
   temp_global=0;
   read buffer parse DrawStatusLine;
#endif;
#ifdef TARGET_GLULX;
   KeyboardPrimitive(buffer, parse);
#endif; ! TARGET_
   i=parse-->1;
   if (i==QUIT1__WD or QUIT2__WD) quit;
   if (i==RESTART__WD)      @restart;
   if (i==RESTORE__WD)      { RestoreSub(); jump RRQPL; }
   if (i==FULLSCORE1__WD or FULLSCORE2__WD && child(AchievedTasks))
   {   new_line; FullScoreSub(); jump RRQPL; }
#ifdef AMUSING_PROVIDED;
   if (deadflag==2 && i==AMUSING__WD)
   {   new_line; Amusing(); jump RRQPL; }
#endif;
   if (i==UNDO1__WD or UNDO2__WD or UNDO3__WD)
   {   if (undo_flag==0)
       {   L__M(##Miscellany,6);
           jump RRQPL;
       }
       if (undo_flag==1) jump UndoFailed2;
#ifndef TARGET_GLULX;
       @restore_undo i;
#endif;
#ifdef TARGET_GLULX;
       @restoreundo i;
       i = (~~i);
#endif; ! TARGET_
       if (i==0)
       {   .UndoFailed2; L__M(##Miscellany,7);
       }
       jump RRQPL;
   }
   L__M(##Miscellany,8);
   jump RRQL;
];

[ IncrementTime;

    turns++;
    if (the_time ~= NULL)
    {   if (time_rate >= 0) the_time = the_time + time_rate;
        else
        {   time_step--;
            if (time_step == 0)
            {   the_time++;
                time_step = -time_rate;
            }
        }
        the_time = the_time % 1440;
    }
];

[ RunDaemons     x;

    objectloop(x)
    {   if (x has activedaemon)
        {   #ifdef DEBUG;
                if (debug_flag & 4)
                    print (name) x," daemon^";
            #endif;
            RunRoutines(x, daemon);
        }

        if (x has activetimer)
        {   #ifdef DEBUG;
                if (debug_flag & 4) print (name) x," timer with ",
                    x.time_left," turns to go^";
            #endif;
            if (x.time_left == 0)
            {   give x ~activetimer;
                if (x provides time_out) RunRoutines(x, time_out);
                else RunTimeError(6, x);
            }
            else
                x.time_left = x.time_left - 1;
        }
    }
];

[ R_Process a i j;
    InformLibrary.begin_action(a, i, j, 1);
];

[ NoteObjectAcquisitions     i;

    objectloop (i in player && i hasnt moved)
    {   give i moved ~concealed ~under ~upon ~inside;
        if (i provides points)
        {   finding_items.points = finding_items.points + i.points;
            if (finding_items notin AchievedTasks)
                Achieved(finding_items);
            else
            {   give finding_items general;
                score = score + i.points;
            }
      }
  }
];
! ----------------------------------------------------------------------------

Constant ZRegion = Z__Region;

[ PrintOrRun obj prop flag;

  if (obj.#prop > WORDSIZE) return RunRoutines(obj,prop);
  if (obj.prop == 0 or NULL) rfalse;
  switch(metaclass(obj.prop))
  {   Class, Object, nothing: return RunTimeError(2,obj,prop);
      String: print (string) obj.prop; if (flag==0) new_line; rtrue;
      Routine: return RunRoutines(obj,prop);
  }
];

[ ValueOrRun obj prop;
  if (obj.prop < 256) return obj.prop;
  return RunRoutines(obj, prop);
];

[ RunRoutines obj prop;
   if (obj == thedark && prop ~= initial or short_name or description)
       obj = actor.location;
   if (obj.&prop == 0) rfalse;
   return obj.prop();
];

#ifndef TARGET_GLULX;

[ ChangeDefault prop val     a b;
   ! Use assembly-language here because -S compilation won't allow this:
   @loadw 0 5 -> a;
   b = prop-1;
   @storew a b val;
];

#endif;
#ifdef TARGET_GLULX;

[ ChangeDefault prop val;
   ! Use assembly-language here because -S compilation won't allow this:
   ! #cpv__start-->prop = val;
   @astore #cpv__start prop val;
];

#endif; ! TARGET_GLULX


! ----------------------------------------------------------------------------

[ StartTimer obj time;

    if (~~(obj provides time_left)) RunTimeError(5, obj);
    give obj activetimer;
    obj.time_left = time;
];

[ StopTimer obj; give obj ~activetimer; ];

[ StartDaemon obj; give obj activedaemon; ];

[ StopDaemon obj; give obj ~activedaemon; ];

! ----------------------------------------------------------------------------

[ DisplayStatus;
   if (the_time==NULL)
   {   sline1=score; sline2=turns; }
   else
   {   sline1=the_time/60; sline2=the_time%60; }
];

[ SetTime t s;
   the_time=t; time_rate=s; time_step=0;
   if (s<0) time_step=0-s;
];

[ NotifyTheScore     x fl;

    objectloop(x in AchievedTasks)
        if (x has general)
        {   if (fl) fl = -1;
            else fl = x;
            give x ~general;
        }

    x = actor; actor = player;

    if (fl == 0)
        L__M(##Miscellany, 524);
    else
        L__M(##Miscellany, 523, fl);

    L__M(##Miscellany, 525, score - last_score);

    actor = x;
];    

! ----------------------------------------------------------------------------

[ AdjustLight flag     olf;

   olf = lightflag;

   lightflag = (~~(InDark(player)));

   if (olf == 0 && lightflag == 1 && flag == 0) player.perform(##Look);

   if (olf == 1 && lightflag == 0 && flag == 0)
   {   NoteArrival(); return L__M(##Miscellany, 9); }
 ];

[ InDark obj     p x pos;

    if (metaclass(obj) ~= Object) rtrue;
    if (obj has light) rfalse;
    p = parent(obj);
    if (metaclass(p) ~= Object) rtrue;

    if (parent(p) == 0 or Map)
    {   if (p has light) rfalse;
        objectloop (x in p) if (HasLightSource(x)) rfalse;
        objectloop (x in FloatingHome)
            if (HasLightSource(x) && IsFoundIn(x, p)) rfalse;
        rtrue;
    }
    pos = positionof(obj);
    if (pos == upon or under) return Indark(p);
    if (pos == inside)
    {   if (p has light) rfalse;
        if (p has transparent or open) return InDark(p);
        objectloop(x in p)
            if (x has inside && HasLightSource(x)) rfalse;
        rtrue;
    }
    if (p has animate
        && (obj has worn || (PositionOf(obj) == 0 && p has transparent)))
        return InDark(p);
];

[ HasLightSource obj     x pos ad j;

    if (metaclass(obj) ~= Object) rfalse;
    if (obj has light) rtrue;

    objectloop(x in obj)
    {   pos = positionof(x);
        if ((pos == upon or under or worn
             || (pos == inside && obj has open or transparent)
             || (pos == 0 && obj has transparent))
            && HasLightSource(x)) rtrue;
    }
    
   ad = obj.&add_to_scope;
   if (ad && parent(obj))
   {   if (metaclass(ad-->0) == Routine)
       {   ats_hls = 0; ats_flag = 1;
           RunRoutines(obj, add_to_scope);
           ats_flag = 0; if (ats_hls == 1) rtrue;
       }
       else
       {   for (j=0:(WORDSIZE*j)<obj.#add_to_scope:j++)
               if (HasLightSource(ad-->j)) rtrue;
       }
   }
   rfalse;
];

        ! ChangePlayer (to object, as something flag)

[ ChangePlayer obj flag;

    if (player == obj) rfalse;
    if (actor == player) actor = obj;
    give player ~transparent ~concealed;

    player = obj;

    give player transparent concealed proper known;
    player.location = rootof(player);
    AdjustLight(1);
    print_player_flag = flag;
];

! ----------------------------------------------------------------------------

#IFDEF DEBUG;
#ifndef TARGET_GLULX;
[ DebugParameter w x n l;
  x=0-->4; x=x+(x->0)+1; l=x->0; n=(x+1)-->0; x=w-(x+3);
  print w;
  if (w>=1 && w<=top_object) print " (", (name) w, ")";
  if (x%l==0 && (x/l)<n) print " ('", (address) w, "')";
];
[ DebugAction a anames;
  if (a>=4096) { print "<fake action ", a-4096, ">"; return; }
  anames = #identifiers_table + (2 * (#identifiers_table-->0)) + 96;
  print (string) anames-->a;
];
[ DebugAttribute a anames;
  if (a<0 || a>=48) print "<invalid attribute ", a, ">";
  else
  {   anames = #identifiers_table + (2 * (#identifiers_table-->0));
      print (string) anames-->a;
  }
];
#endif;
#ifdef TARGET_GLULX;
[ DebugParameter w endmem;
  print w;
  @getmemsize endmem;
  if (w >= 1 && w < endmem) {
    if (w->0 >= $70 && w->0 < $7F) print " (", (name) w, ")";
    if (w->0 >= $60 && w->0 < $6F) print " ('", (address) w, "')";
  }
];
[ DebugAction a str;
  if (a>=4096) { print "<fake action ", a-4096, ">"; return; }
  if (a<0 || a>=#identifiers_table-->7) print "<invalid action ", a, ">";
  else {
    str = #identifiers_table-->6;
    str = str-->a;
    if (str) print (string) str;
    else print "<unnamed action ", a, ">";
  }
];
[ DebugAttribute a str;
  if (a<0 || a>=NUM_ATTR_BYTES*8) print "<invalid attribute ", a, ">";
  else {
    str = #identifiers_table-->4;
    str = str-->a;
    if (str) print (string) str;
    else print "<unnamed attribute ", a, ">";
  }
];
#endif; ! TARGET_

[ TraceAction source ar;
  if (source<2) print "[ Action ", (DebugAction) action;
  else
  {   if (ar==##Order)
          print "[ Order to ", (name) actor, ": ", (DebugAction) action;
      else
          print "[ Life rule ", (DebugAction) ar;
  }
  if (noun)   print " with noun ", (DebugParameter) noun;
  if (second) print " and second ", (DebugParameter) second;
  if (source==0) print " ";
  if (source==1) print " (from < > statement) ";
  print "]^";
];

[ DebugToken token;
  AnalyseToken(token);
  switch(found_ttype)
  {   ILLEGAL_TT: print "<illegal token number ", token, ">";
      ELEMENTARY_TT:
      switch(found_tdata)
      {   NOUN_TOKEN:        print "noun";
          HELD_TOKEN:        print "held";
          MULTI_TOKEN:       print "multi";
          MULTIHELD_TOKEN:   print "multiheld";
          MULTIEXCEPT_TOKEN: print "multiexcept";
          MULTIINSIDE_TOKEN: print "multiinside";
          CREATURE_TOKEN:    print "creature";
          SPECIAL_TOKEN:     print "special";
          NUMBER_TOKEN:      print "number";
          TOPIC_TOKEN:       print "topic";
          ENDIT_TOKEN:       print "END";
      }
      PREPOSITION_TT:
          print "'", (address) found_tdata, "'";
      ROUTINE_FILTER_TT:
      #ifdef INFIX; print "noun=", (InfixPrintPA) found_tdata;
      #ifnot; print "noun=Routine(", found_tdata, ")"; #endif;
      ATTR_FILTER_TT:
          print (DebugAttribute) found_tdata;
      SCOPE_TT:
      #ifdef INFIX; print "scope=", (InfixPrintPA) found_tdata;
      #ifnot; print "scope=Routine(", found_tdata, ")"; #endif;
      GPR_TT:
      #ifdef INFIX; print (InfixPrintPA) found_tdata;
      #ifnot; print "Routine(", found_tdata, ")"; #endif;
  }
];

[ DebugGrammarLine pcount;
  print " * ";
  for (:line_token-->pcount ~= ENDIT_TOKEN:pcount++)
  {   if ((line_token-->pcount)->0 & $10) print "/ ";
      print (DebugToken) line_token-->pcount, " ";
  }
  print "-> ", (DebugAction) action_to_be;
  if (action_reversed) print " reverse";
];

#ifndef TARGET_GLULX;
[ ShowVerbSub address lines da meta i j;
    if (((noun->#dict_par1) & 1) == 0)
      "Try typing ~showverb~ and then the name of a verb.";
    meta=((noun->#dict_par1) & 2)/2;
    i = $ff-(noun->#dict_par2);
    address = (0-->7)-->i;
    lines = address->0;
    address++;
    print "Verb ";
    if (meta) print "meta ";
    da = 0-->4;
    for (j=0:j < (da+5)-->0:j++)
        if (da->(j*9 + 14) == $ff-i)
            print "'", (address) (da + 9*j + 7), "' ";
    new_line;
    if (lines == 0) "has no grammar lines.";
    for (:lines > 0:lines--)
    {   address = UnpackGrammarLine(address);
        print "    "; DebugGrammarLine(); new_line;
    }
];
#endif;
#ifdef TARGET_GLULX;
[ ShowVerbSub address lines i j meta wd dictlen entrylen;
  if (noun == 0 || ((noun->#dict_par1) & 1) == 0)
    "Try typing ~showverb~ and then the name of a verb.";
  meta=((noun->#dict_par1) & 2)/2;
  i = $ff-(noun->#dict_par2);
  address = (#grammar_table)-->(i+1);
  lines = address->0;
  address++;
  print "Verb ";
  if (meta) print "meta ";
  dictlen = #dictionary_table-->0;
  entrylen = DICT_WORD_SIZE + 7;
  for (j=0:j<dictlen:j++) {
    wd = #dictionary_table + WORDSIZE + entrylen*j;
    if (wd->#dict_par2 == $ff-i)
      print "'", (address) wd, "' ";
  }
  new_line;
  if (lines == 0) "has no grammar lines.";
  for (:lines > 0:lines--) {
    address = UnpackGrammarLine(address);
    print "    "; DebugGrammarLine(); new_line;
  }
];
#endif; ! TARGET_

        ! ShowobjSub
        ! Modified to support ShowobjCogs.

[ ShowobjSub     c f l a n x pl usepl numattr;

    if (noun == 0) noun = player.location;

    objectloop (c ofclass Class)
        if (noun ofclass c) { f++;  l = c; }

    new_line;
    if (f == 1) print (name) l, " ~";
    else        print "Object ~";

    print (name) noun, "~ (", noun, ")";

    if (parent(noun))
        print " in ~", (name) parent(noun), "~";

    new_line;
    if (f > 1)
    {
        print "  class ";
        objectloop (c ofclass Class) if (noun ofclass c) print (name) c, " ";
        new_line;
    }
#ifndef TARGET_GLULX;
   numattr = 48;
#endif;
#ifdef TARGET_GLULX;
   numattr = NUM_ATTR_BYTES * 8;
#endif; ! TARGET_

    for (a = 0,f = 0:a < 48 && f==0:a++) if (noun has a) f = 1;
    if (f)
    {   print "  has ";
        for (a = 0:a < 48:a++) if (noun has a) print (DebugAttribute) a, " ";
        new_line;
    }
    if (noun ofclass Class) return;

   f = 0;
#ifndef TARGET_GLULX;
   l = #identifiers_table-->0;
#endif;
#ifdef TARGET_GLULX;
   l = INDIV_PROP_START + #identifiers_table-->3;
#endif; ! TARGET_
   for (a = 1:a <= l:a++)
   {   if (a ~= 2 or 3 && noun provides a)
       {   if (f == 0) { print "  with "; f = 1; }
           print (property) a;

            usepl = 0;

            objectloop (pl in ShowobjGizmo)
                if (pl.knows_property(a)) { usepl = pl; break; }

           n = noun.#a / WORDSIZE;
           for (c = 0:c < n:c++)
           {   print " ";
               x = (noun.&a)-->c;
               if (usepl)
               {   if (pl.print_property(a, x)) break; }
                else
                switch(x)
                {   NULL: print "NULL";
                    0: print "0";
                    1: print "1";
                    default: switch(metaclass(x))
                    {   Class, Object: print (name) x;
                        String: print "~", (string) x, "~";
                        Routine: print "[...]";
                    }
                    print " (", x, ")";
                }
           }
           print ",^       ";
       }
   }
];
#ENDIF;

! ----------------------------------------------------------------------------

#ifndef TARGET_GLULX;

[ DrawStatusLine width posa posb     l;
   @split_window 1; @set_window 1; @set_cursor 1 1; style reverse;
   width = 0->33; posa = width-26; posb = width-13;
   spaces width;
   @set_cursor 1 2;
   l = ScopeCeiling(player);
   if (l ~= player.location) print (The) l; else print (name) l;
   if ((0->1)&2 == 0)
   {   if (width > 76)
       {   @set_cursor 1 posa; print (string) SCORE__TX, sline1;
           @set_cursor 1 posb; print (string) MOVES__TX, sline2;
       }
       if (width > 63 && width <= 76)
       {   @set_cursor 1 posb; print sline1, "/", sline2;
       }
   }
   else
   {   @set_cursor 1 posa;
       print (string) TIME__TX;
       LanguageTimeOfDay(sline1, sline2);
   }
   @set_cursor 1 1; style roman; @set_window 0;
];

#endif;
#ifdef TARGET_GLULX;

[ StatusLineHeight hgt parwin;
  if (gg_statuswin == 0)
    return;
  if (hgt == gg_statuswin_cursize)
    return;
  parwin = glk($0029, gg_statuswin); ! window_get_parent
  glk($0026, parwin, $12, hgt, 0); ! window_set_arrangement
  gg_statuswin_cursize = hgt;
];

[ DrawStatusLine     width height posa posb l;
    ! If we have no status window, we must not try to redraw it.
    if (gg_statuswin == 0)
        return;

    ! If there is no player location, we shouldn't try either.
    if (player.location == nothing || parent(player) == nothing)
        return;

    glk($002F, gg_statuswin); ! set_window
    StatusLineHeight(GG_STATUSWIN_SIZE);

    glk($0025, gg_statuswin, gg_arguments, gg_arguments+4); ! window_get_size
    width = gg_arguments-->0;
    height = gg_arguments-->1;
    posa = width-26; posb = width-13;

    glk($002A, gg_statuswin); ! window_clear

    glk($002B, gg_statuswin, 1, 0); ! window_move_cursor
   l = ScopeCeiling(player);
   if (l ~= player.location) print (The) l; else print (name) l;

    if (width > 66) {
        glk($002B, gg_statuswin, posa-1, 0); ! window_move_cursor
        print (string) SCORE__TX, sline1;
        glk($002B, gg_statuswin, posb-1, 0); ! window_move_cursor
        print (string) MOVES__TX, sline2;
    }
    if (width > 53 && width <= 66) {
        glk($002B, gg_statuswin, posb-1, 0); ! window_move_cursor
        print sline1, "/", sline2;
    }

    glk($002F, gg_mainwin); ! set_window
];

[ Box__Routine maxwid arr ix lines lastnl parwin;
    maxwid = 0; ! squash compiler warning
    lines = arr-->0;

    if (gg_quotewin == 0) {
        gg_arguments-->0 = lines;
        ix = InitGlkWindow(GG_QUOTEWIN_ROCK);
        if (ix == 0) 
            gg_quotewin = glk($0023, gg_mainwin, $12, lines, 3, 
                GG_QUOTEWIN_ROCK); ! window_open
    }
    else {
        parwin = glk($0029, gg_quotewin); ! window_get_parent
        glk($0026, parwin, $12, lines, 0); ! window_set_arrangement
    }

    lastnl = true;
    if (gg_quotewin) {
        glk($002A, gg_quotewin); ! window_clear
        glk($002F, gg_quotewin); ! set_window
        lastnl = false;
    }

    ! If gg_quotewin is zero here, the quote just appears in the story window.

    glk($0086, 7); ! set blockquote style
    for (ix=0 : ix<lines : ix++) {
        print (string) arr-->(ix+1);
        if (ix < lines-1 || lastnl) new_line;
    }
    glk($0086, 0); ! set normal style

    if (gg_quotewin) {
        glk($002F, gg_mainwin); ! set_window
    }
];

#endif; ! TARGET_GLULX

! ----------------------------------------------------------------------------
#ifdef TARGET_GLULX;

[ GGInitialise res;
    @gestalt 4 2 res; ! Test if this interpreter has Glk.
    if (res == 0) {
      ! Without Glk, we're entirely screwed.
      quit;
    }
    ! Set the VM's I/O system to be Glk.
    @setiosys 2 0;

    ! First, we must go through all the Glk objects that exist, and see
    ! if we created any of them. One might think this strange, since the
    ! program has just started running, but remember that the player might 
    ! have just typed "restart".
    GGRecoverObjects();

    res = InitGlkWindow(0);
    if (res ~= 0)
        return;

    ! Now, gg_mainwin and gg_storywin might already be set. If not, set them.

    if (gg_mainwin == 0) {
        ! Open the story window.
        res = InitGlkWindow(GG_MAINWIN_ROCK);
        if (res == 0)
            gg_mainwin = glk($0023, 0, 0, 0, 3, GG_MAINWIN_ROCK); ! window_open
        if (gg_mainwin == 0) {
            ! If we can't even open one window, there's no point in going on.
            quit;
        }
    }
    else {
        ! There was already a story window. We should erase it.
        glk($002A, gg_mainwin); ! window_clear
    }

    if (gg_statuswin == 0) {
        res = InitGlkWindow(GG_STATUSWIN_ROCK);
        if (res == 0) {
            gg_statuswin_cursize = gg_statuswin_size;
            gg_statuswin = glk($0023, gg_mainwin, $12, gg_statuswin_cursize, 
                4, GG_STATUSWIN_ROCK); ! window_open
        }
    }
    ! It's possible that the status window couldn't be opened, in which case
    ! gg_statuswin is now zero. We must allow for that later on.

    glk($002F, gg_mainwin); ! set_window

    InitGlkWindow(1);
];

[ GGRecoverObjects id;
    ! If GGRecoverObjects() has been called, all these stored IDs are
    ! invalid, so we start by clearing them all out. 
    ! (In fact, after a restoreundo, some of them may still be good.
    ! For simplicity, though, we assume the general case.)
    gg_mainwin = 0;
    gg_statuswin = 0;
    gg_quotewin = 0;
    gg_scriptfref = 0;
    gg_scriptstr = 0;
    gg_savestr = 0;
    gg_statuswin_cursize = 0;
#IFDEF DEBUG;
    gg_commandstr = 0;
    gg_command_reading = false;
#ENDIF;
    ! Also tell the game to clear its object references.
    IdentifyGlkObject(0);

    id = glk($0040, 0, gg_arguments); ! stream_iterate
    while (id) {
        switch (gg_arguments-->0) {
            GG_SAVESTR_ROCK: gg_savestr = id;
            GG_SCRIPTSTR_ROCK: gg_scriptstr = id;
#IFDEF DEBUG;
            GG_COMMANDWSTR_ROCK: gg_commandstr = id;
                                 gg_command_reading = false;
            GG_COMMANDRSTR_ROCK: gg_commandstr = id;
                                 gg_command_reading = true;
#ENDIF;
            default: IdentifyGlkObject(1, 1, id, gg_arguments-->0); 
        }
        id = glk($0040, id, gg_arguments); ! stream_iterate
    }

    id = glk($0020, 0, gg_arguments); ! window_iterate
    while (id) {
        switch (gg_arguments-->0) {
            GG_MAINWIN_ROCK: gg_mainwin = id;
            GG_STATUSWIN_ROCK: gg_statuswin = id;
            GG_QUOTEWIN_ROCK: gg_quotewin = id;
            default: IdentifyGlkObject(1, 0, id, gg_arguments-->0); 
        }
        id = glk($0020, id, gg_arguments); ! window_iterate
    }

    id = glk($0064, 0, gg_arguments); ! fileref_iterate
    while (id) {
        switch (gg_arguments-->0) {
            GG_SCRIPTFREF_ROCK: gg_scriptfref = id;
            default: IdentifyGlkObject(1, 2, id, gg_arguments-->0); 
        }
        id = glk($0064, id, gg_arguments); ! fileref_iterate
    }

    ! Tell the game to tie up any loose ends.
    IdentifyGlkObject(2);
];

! This is a trivial function which just prints a number, in decimal
! digits. It may be useful as a stub to pass to PrintAnything.
[ DecimalNumber num;
    print num;
];

! This somewhat obfuscated function will print anything.
! It handles strings, functions (with optional arguments), objects,
! object properties (with optional arguments), and dictionary words.
! It does *not* handle plain integers, but you can use
! DecimalNumber or EnglishNumber to handle that case.
!
! Calling:                           Is equivalent to:
! -------                            ----------------
! PrintAnything()                    <nothing printed>
! PrintAnything(0)                   <nothing printed>
! PrintAnything("string");           print (string) "string";
! PrintAnything('word')              print (address) 'word';
! PrintAnything(obj)                 print (name) obj;
! PrintAnything(obj, prop)           obj.prop();
! PrintAnything(obj, prop, args...)  obj.prop(args...);
! PrintAnything(func)                func();
! PrintAnything(func, args...)       func(args...);
! 
[ PrintAnything _vararg_count obj mclass;
    if (_vararg_count == 0)
        return;
    @copy sp obj;
    _vararg_count--;
    if (obj == 0)
        return;

    if (obj->0 == $60) {
        ! Dictionary word. Metaclass() can't catch this case, so we do
        ! it manually.
        print (address) obj;
        return;
    }

    mclass = metaclass(obj);
    switch (mclass) {
        nothing:
            return;
        String:
            print (string) obj;
            return;
        Routine:
            ! Call the function with all the arguments which are already
            ! on the stack.
            @call obj _vararg_count 0;
            return;
        Object:
            if (_vararg_count == 0) {
                print (name) obj;
            }
            else {
                ! Push the object back onto the stack, and call the
                ! veneer routine that handles obj.prop() calls.
                @copy obj sp;
                _vararg_count++;
                @call CA__Pr _vararg_count 0;
            }
            return;
    }
];

! This does the same as PrintAnything, but the output is sent to a
! byte array in memory. The first two arguments must be the array
! address and length; the following arguments are interpreted as 
! for PrintAnything. The return value is the number of characters
! output.
! If the output is longer than the array length given, the extra 
! characters are discarded, so the array does not overflow. 
! (However, the return value is the total length of the output, 
! including discarded characters.)

[ PrintAnyToArray _vararg_count arr arrlen str oldstr len;

   if (buffers_open) @setiosys 2 0;

   @copy sp arr;
   @copy sp arrlen;
   _vararg_count = _vararg_count - 2;

   oldstr = glk($0048); ! stream_get_current
   str = glk($0043, arr, arrlen, 1, 0); ! stream_open_memory

   if (str == 0)
   {    if (buffers_open) @setiosys 1 FilterOutput;
        return 0;
   }

   glk($0047, str); ! stream_set_current

   @call PrintAnything _vararg_count 0;

   if (buffers_open) @setiosys 1 FilterOutput;

   glk($0047, oldstr); ! stream_set_current
   @copy $ffffffff sp;
   @copy str sp;
   @glk $0044 2 0; ! stream_close
   @copy sp len;
   @copy sp 0;

   return len;
];

#endif; ! TARGET_GLULX

Array StorageForShortName --> 161;

[ PrefaceByArticle o acode pluralise     i artform findout;

   if (o provides articles)
   {  i = 1; 
      if (metaclass(o.&articles-->0) == Routine)
           i = o.articles(acode+short_name_case*LanguageCases);
        else print (string) (o.&articles)-->
            (acode+short_name_case*LanguageCases)," ";
       if (i)
       {    if (pluralise) return;
           print (PSN__) o; return;
       }
   }

   i = GetGNAOfObject(o);
   if (pluralise)
   {   if (i<3 || (i>=6 && i<9)) i = i + 3;
   }
   i = LanguageGNAsToArticles-->i;

   artform = LanguageArticles
             + 3*WORDSIZE*LanguageContractionForms
             *(short_name_case + i*LanguageCases);

#iftrue LanguageContractionForms == 2;
   if (artform-->acode ~= artform-->(acode+3)) findout = true;
#endif;
#iftrue LanguageContractionForms == 3;
   if (artform-->acode ~= artform-->(acode+3)) findout = true;
   if (artform-->(acode+3) ~= artform-->(acode+6)) findout = true;
#endif;
#iftrue LanguageContractionForms == 4;
   if (artform-->acode ~= artform-->(acode+3)) findout = true;
   if (artform-->(acode+3) ~= artform-->(acode+6)) findout = true;
   if (artform-->(acode+6) ~= artform-->(acode+9)) findout = true;
#endif;
#iftrue LanguageContractionForms > 4;
   findout = true;
#endif;
#ifndef TARGET_GLULX;
   if (findout)
   {   StorageForShortName-->0 = 160;
       OpenBuffer(StorageForShortName);
       if (pluralise) print (languagenumber) pluralise; else print (PSN__) o;
       CloseBuffer();
       acode = acode + 3*LanguageContraction(StorageForShortName + 2);
   }
#endif;
#ifdef TARGET_GLULX;
   if (findout)
   {   if (pluralise)
           PrintAnyToArray(StorageForShortName, 160, LanguageNumber, pluralise);
       else
           PrintAnyToArray(StorageForShortName, 160, PSN__, o);
       acode = acode + 3*LanguageContraction(StorageForShortName);
   }
#endif;
   print (string) artform-->acode;
   if (pluralise) return;
   print (PSN__) o;
];

Global known_giving_flag;

[ PSN__ o;
   if (o==0) { print (string) NOTHING__TX; rtrue; }
   switch(metaclass(o))
   {   Routine: print "<routine ", o, ">"; rtrue;
       String:  print "<string ~", (string) o, "~>"; rtrue;
       nothing: print "<illegal object number ", o, ">"; rtrue;
   }
   if (o==player && player_perspective ~= 3)
   {    if (actor == player) 
            switch(pron(player))
            {   1: print (string) YOURSELF__TX;
                6: print (string) MYSELF__TX;
                7: print (string) OURSELVES__TX;
                8: print (string) YOURSELVES__TX;
            }
        else switch(pron(player))
        {   1: print (string) YOU__TX;
            6: print (string) ME__TX;
            7: print (string) US__TX;
            8: print (string) YOUPL__TX;
        }
        rtrue;
   }
    if (meta == 0 && known_giving_flag == 0
        && o ofclass Object && o hasnt known or secret)
    {   known_giving_flag = 1;
        give o known;
        known_giving_flag = 0;
    }
    #ifdef LanguagePrintShortName;
        if (LanguagePrintShortName(o)) rtrue;
    #endif;
    if (indef_mode && o.&short_name_indef
        && PrintOrRun(o, short_name_indef, 1)) rtrue;
    if (o.&short_name && PrintOrRun(o,short_name,1)) rtrue;
    print (object) o;
];

[ Indefart o i;
   i = indef_mode; indef_mode = true;
   if (o has proper) { indef_mode = NULL; print (PSN__) o; return; }
   if (o provides article)
   {   PrintOrRun(o,article,1); print " ", (PSN__) o; indef_mode = i; return;
   }
   PrefaceByArticle(o, 2); indef_mode = i;
];
[ Defart o i;
   i = indef_mode; indef_mode = false;
   if (o has proper)
   { indef_mode = NULL; print (PSN__) o; indef_mode = i; return; }
   PrefaceByArticle(o, 1); indef_mode = i;
];
[ CDefart o i;
   i = indef_mode; indef_mode = false;
   if (o has proper)
   { indef_mode = NULL; print (PSN__) o; indef_mode = i; return; }
   PrefaceByArticle(o, 0); indef_mode = i;
];

[ PrintShortName o i;
   i = indef_mode; indef_mode = NULL;
   PSN__(o); indef_mode = i;
];

[ NumberWord n     idx;

    idx = FindInTable(n, LanguageNumbers, 2);
    if (idx ~= -1) return LanguageNumbers-->(idx + 1);
    rfalse;
];

[ RandomEntry tab;
  if (tab-->0==0) return RunTimeError(8);
  return tab-->(random(tab-->0));
];

#ifndef TARGET_GLULX;

[ LTI_Insert i ch  b y;

  !   Protect us from strict mode, as this isn't an array in quite the
  !   sense it expects
      b = buffer;

  !   Insert character ch into buffer at point i.

  !   Being careful not to let the buffer possibly overflow:

      y = b->1;
      if (y > b->0) y = b->0;

  !   Move the subsequent text along one character:

      for (y=y+2: y>i : y--) b->y = b->(y-1);
      b->i = ch;

  !   And the text is now one character longer:
      if (b->1 < b->0) (b->1)++;
];

#endif;
#ifdef TARGET_GLULX;

[ LTI_Insert i ch  b y;

  !   Protect us from strict mode, as this isn't an array in quite the
  !   sense it expects
      b = buffer;

  !   Insert character ch into buffer at point i.

  !   Being careful not to let the buffer possibly overflow:

      y = b-->0;
      if (y > INPUT_BUFFER_LEN) y = INPUT_BUFFER_LEN;

  !   Move the subsequent text along one character:

      for (y=y+WORDSIZE: y>i : y--) b->y = b->(y-1);

      b->i = ch;

  !   And the text is now one character longer:
      if (b-->0 < INPUT_BUFFER_LEN)
          (b-->0)++;
];

#endif; ! TARGET_

! ----------------------------------------------------------------------------
!  Useful routine: unsigned comparison (for addresses in Z-machine)
!    Returns 1 if x>y, 0 if x=y, -1 if x<y
! ----------------------------------------------------------------------------

[ UnsignedCompare x y     u v;

  if (x == y) rfalse;
  if (x < 0 && y >= 0) rtrue;
  if (x >= 0 && y < 0) return -1;
  u = x&$7fff; v= y&$7fff;
  if (u > v) rtrue;
  return -1;
];

! ----------------------------------------------------------------------------

#ifdef TARGET_GLULX;
[ Banner     i y;
#endif;
#ifndef TARGET_GLULX;
[ Banner     y;
#endif;
   if (Story ~= 0)
   {
#ifndef TARGET_GLULX;
   style bold;
   print (string) Story;
   style roman;
#endif;
#ifdef TARGET_GLULX;
   glk($0086, 3); ! set header style
   print (string) Story;
   glk($0086, 0); ! set normal style
#endif; ! TARGET_
   }
   if (Headline ~= 0)
       print (string) Headline;
#ifndef TARGET_GLULX;
!   print "Release ", (0-->1) & $03ff, " / Serial number ";
!   for (i=18:i<24:i++) print (char) 0->i;
    print "Release ",(0-->1) & $03ff," (";
    y = GetDigitValue(0->18) * 10 + GetDigitValue(0->19);
    if (y > 70) y = y + 1900; else y = y + 2000;
    print y,"-",(char) 0->20,(char) 0->21,"-",(char) 0->22,(char) 0->23, ")";
#endif;
#ifdef TARGET_GLULX;
   print "Release ";
   @aloads 52 0 i;
   print i;
!   print " / Serial number ";
!   for (i=0:i<6:i++) print (char) 54->i;
    print " (";
    y = GetDigitValue(54->0) * 10 + GetDigitValue(54->1);
    if (y > 70) y = y + 1900; else y = y + 2000;
    print y,"-",(char) 54->2,(char) 54->3,"-",(char) 54->4,(char) 54->5, ")";
#endif; ! TARGET_
   print "^Inform v"; inversion;
   print " / Platypus ", (string) platypus_version, " ";
#ifdef STRICT_MODE;
   print "-S";
#endif;
#ifdef INFIX;
#ifndef STRICT_MODE; print "-"; #endif;
   print "X";
#ifnot;
#ifdef DEBUG;
#ifndef STRICT_MODE; #ifndef INFIX; print "-"; #endif; #endif;
   print "D";
#endif;
#endif;
   new_line;
];

[ VersionSub ix;
  Banner();
#ifndef TARGET_GLULX;
  if (standard_interpreter > 0)
      print "Standard interpreter ",
          standard_interpreter/256, ".", standard_interpreter%256,
          " (", 0->$1e, (char) 0->$1f, ")";
  else print "Interpreter ", 0->$1e, " Version ", (char) 0->$1f;
  ix = 1;
#endif;
#ifdef TARGET_GLULX;
  @gestalt 1 0 ix;
  print "Interpreter version ", ix / $10000, ".", (ix & $FF00) / $100,
    ".", ix & $FF, " / ";
  @gestalt 0 0 ix;
  print "VM ", ix / $10000, ".", (ix & $FF00) / $100,
    ".", ix & $FF;
#endif; ! TARGET_;

#IFDEF LanguageVersion;
  print " / ",(string) LanguageVersion, "^";
#ENDIF;
#ifndef LanguageVersion;
    new_line;
#endif;
];

[ RunTimeError n p1 p2;
#IFDEF DEBUG;
  print "** Library error ", n, " (", p1, ",", p2, ") **^** ";
  switch(n)
  {   1: print "preposition not found (this should not occur)";
      2: print "Property value not routine or string: ~",
               (property) p2, "~ of ~", (name) p1, "~ (", p1, ")";
      3: print "Entry in property list not routine or string: ~",
               (property) p2, "~ list of ~", (name) p1, "~ (", p1, ")";
      5: print "Object ~", (name) p1, "~ has no ~time_left~ property";
      6: print "Object ~", (name) p1, "~ has no ~time_out~ property";
      8: print "Attempt to take random entry from an empty table array";
      9: print p1, " is not a valid direction property number";
      10: print "The player-object is outside the object tree";
      11: print "The room ~", (name) p1, "~ has no ~description~ property";
      12: print "Tried to set a non-existent pronoun using SetPronoun";
      13: print "A 'topic' token can only be followed by a preposition";
      default: print "(unexplained)";
  }
  " **";
#IFNOT;
  "** Library error ", n, " (", p1, ",", p2, ") **";
#ENDIF;
];

! ----------------------------------------------------------------------------

! ----------------------------------------------------------------------------
!  Descriptors
! ----------------------------------------------------------------------------

[ ResetDescriptors;
   indef_mode=0; indef_type=0; indef_wanted=0; indef_guess_p=0;
   indef_cases = $$111111111111;
];

    ! fl == 1 means actually parsing, not just testing descriptors
[ ParseEarlyDescriptor obj wd fl     n;

    n = NumberWord(wd);
    if (n > 0)
    {   if (allow_plurals || n == 1)
        {   if (fl)
            {   numspec = n;
                indef_mode_spec = true;
                if (n > 1) indef_guess_p = true;
            }
            rtrue;
        }
        rfalse;
    }

    switch(wd) {
        'the': rtrue;
        'a//', 'an':
            if (obj has pluralname) rfalse;
            if (fl)
            {   indef_mode_spec = true;
                numspec = 1;
            }
            rtrue;
        'any':
            if (fl) indef_mode_spec = true;
            rtrue;
        'all', 'each', 'every', 'everything', 'both':
            if (fl)
            {   numspec = 100;
                if (take_all_rule == 1) take_all_rule = 2;
                indef_mode_spec = true;
            }
            rtrue;
        'another', 'other':
            if (MatchesAPronoun(obj) == 0) rtrue;
        'some':
            if (fl) indef_mode_spec = true;
            rtrue;
    }
    rfalse;
];

        ! ParseStandardDescriptor(object, word, flag)
        ! Returns: 1 if matches, 0 if doesn't, -1 if not a known descriptor

[ ParseStandardDescriptor obj wd fl     rv;

    rv = ParseDescriptor(obj, wd, fl);  ! Check entry point routine
    if (rv ~= -1) return rv;            ! and return if descriptor handled

    switch(wd) {
        'open', 'opened':
            if (obj has open) rtrue;
        'closed':
            if (obj has openable && obj hasnt open) rtrue;
        'worn':
            if (obj has worn) rtrue;
        'unworn':
            if (obj has clothing && obj hasnt worn) rtrue;
        'empty':
            if ((obj has supporter || (obj has container && obj has open))
                && HasVisibleContents(obj) == false) rtrue;
        'my', 'mine', 'this', 'these':
            if (IndirectlyContains(player, obj)) rtrue;
        'your':
            if (IndirectlyContains(actor, obj)) rtrue;
        'that', 'those':
            if (obj notin player) rtrue;
        'his': if (obj in PronounValue('him')) rtrue;
        'her': if (obj in PronounValue('her')) rtrue;
        'its': if (obj in PronounValue('it')) rtrue;
        'their': if (obj in PronounValue('them')) rtrue;
        default:
            return -1;
    }
    rfalse;
];

[ StartupRoutines     x;

    Init();

    objectloop(x ofclass Object)
        if (x provides startup) x.startup();

    print "^^^^^";

    return Initialise();
];

