! "Last.h"
! Part of Platypus preview release 2.
! Copyright 2001 Anson Turner and Graham Nelson
! (not necessarily in that order).
! Comments to: anson@pobox.com


System_file;

Verb meta 'brief' 'normal'
                *                                -> LMode1;
Verb meta 'fullscore' 'full'
                *                                -> FullScore
                * 'score'                        -> FullScore;
Verb meta 'noscript' 'unscript'
                *                                -> ScriptOff;
Verb meta 'notify'
                * 'on'                           -> NotifyOn
                * 'off'                          -> NotifyOff;
Verb meta 'pronouns' 'nouns'
                *                                -> Pronouns;
Verb meta 'q//' 'quit' 'die'
                *                                -> Quit;
Verb meta 'restore'
                *                                -> Restore;
Verb meta 'restart'
                *                                -> Restart;
Verb meta 'save'
                *                                -> Save;
Verb meta 'score'
                *                                -> Score;
Verb meta 'script' 'transcript'
                *                                -> ScriptOn
                * 'off'                          -> ScriptOff
                * 'on'                           -> ScriptOn;
Verb meta 'superbrief' 'short'
                *                                -> LMode3;
Verb meta 'verbose' 'long'
                *                                -> LMode2;
Verb meta 'verify'
                *                                -> Verify;
Verb meta 'version'
                *                                -> Version;
Verb meta 'note' 'footnote'
                *                                -> Notes
                * number                         -> Footnote;
Verb meta 'notes' 'footnotes'
                *                                -> Notes;
#IFNDEF NO_PLACES;
Verb meta 'places'
                *                                -> Places;
#ENDIF;

! ----------------------------------------------------------------------------
!  Debugging grammar
! ----------------------------------------------------------------------------

#ifdef DEBUG;
Verb meta 'changes'
                *                                -> ChangesOn
                * 'on'                           -> ChangesOn
                * 'off'                          -> ChangesOff;
Verb meta 'trace'
                *                                -> TraceOn
                * number                         -> TraceLevel
                * 'on'                           -> TraceOn
                * 'off'                          -> TraceOff;
Verb meta 'actions'
                *                                -> ActionsOn
                * 'on'                           -> ActionsOn
                * 'off'                          -> ActionsOff;
Verb meta 'routines' 'messages'
                *                                -> RoutinesOn
                * 'on'                           -> RoutinesOn
                * 'off'                          -> RoutinesOff;
Verb meta 'timers' 'daemons'
                *                                -> TimersOn
                * 'on'                           -> TimersOn
                * 'off'                          -> TimersOff;
Verb meta 'recording'
                *                                -> CommandsOn
                * 'on'                           -> CommandsOn
                * 'off'                          -> CommandsOff;
Verb meta 'replay'
                *                                -> CommandsRead;
Verb meta 'random'
                *                                -> Predictable;
Verb meta 'purloin'
                * multi                          -> XPurloin;
Verb meta 'abstract'
                * noun 'to' noun                 -> XAbstract;
Verb meta 'tree'
                *                                -> XTree
                * noun                           -> XTree;
Verb meta 'goto'
                * number                         -> Goto;
Verb meta 'gonear'
                * noun                           -> Gonear;
Verb meta 'scope'
                *                                -> Scope
                * noun                           -> Scope;
Verb meta 'showverb'
                * special                        -> Showverb;
Verb meta 'showobj'
                *                                -> Showobj
                * multi                          -> Showobj;

[ AnyRoom      x;

    switch(scope_stage)
    {
        1: rfalse;
        2: objectloop(x provides fpsa) PlaceInScope(x);
        3: return L__M(##Miscellany,505);        
    }
];

Verb meta 'dbdistance'
                * scope=AnyRoom                 -> DB_Distance;

#ifdef TARGET_GLULX;
Verb meta 'glklist'
                *                                -> Glklist;
#endif; ! TARGET_;
#endif;


[ TopicScope     x;
    switch(scope_stage) {
        1: rfalse;
        2: objectloop(x has known) PlaceInScope(x);
        3: "Topic parsing error.";
    }
];


Verb 'affix' 'attach' 'fasten' 'fix' 'tie'
                * noun                           -> Tie
                * noun 'to' noun                 -> Tie;
Verb 'carry' 'hold' 'take'
                * multi                                 -> Take
                * 'off' worn                            -> Disrobe
                * multiinside 'from' noun               -> Take
                * multiinside 'off' noun                -> Take
                * multiinside 'from' 'under' noun       -> TakeFromUnder
                * multiinside 'out' 'from' 'under' noun -> TakeFromUnder
                * 'inventory'                           -> Inv;
Verb 'get'      * multi                                 -> Take
                * 'out'/'off'/'up'                      -> Exit
                * 'in'/'into' noun                      -> EnterIn
                * 'on'/'onto' noun                      -> EnterOn
                * 'under'/'beneath' noun                -> EnterUnder
                * 'off' noun                            -> GetOff
                * multiinside 'out' 'from' 'under' noun -> TakeFromUnder
                * multiinside 'from' 'under' noun       -> TakeFromUnder
                * multiinside 'from' noun               -> Take;
Verb 'pick'
                * 'up' multi                     -> Take
                * multi 'up'                     -> Take;
Verb 'stand'
                *                                -> Exit
                * 'up'                           -> Exit
                * 'on' noun                      -> EnterOn;
Verb 'remove'
                * held                          -> Disrobe
                * multi                         -> Take
                * multiinside 'from' noun   -> Take;
Verb 'shed' 'doff' 'disrobe'
                * noun                           -> Disrobe; 
Verb 'don' 'wear'
                * noun                           -> Wear;
Verb 'put' 'place'
                * multiexcept 'in'/'inside'/'into'/'through' noun
                                                 -> Insert
                * multiexcept 'on'/'onto' noun   -> PutOn
                * multiexcept 'under'/'underneath'/'beneath'/'behind' noun
                                                 -> PutUnder
                * held 'on'                      -> Wear
                * 'on' held                      -> Wear
                * 'down' multiheld               -> Drop
                * multiheld 'down'               -> Drop;
Verb 'hide'
                * 'under'/'beneath'/'behind' noun -> EnterUnder
                * 'in'/'inside' noun              -> EnterIn
                * multiexcept 'in'/'inside' noun  -> Insert
                * multiexcept 'under'/'underneath'/'beneath'/'behind' noun -> PutUnder;
Verb 'insert'
                * multiexcept 'in'/'into' noun   -> Insert;
Verb 'empty' 'clear'
                * noun                           -> Empty
                * 'out' noun                     -> Empty
                * noun 'out'                     -> Empty
                * noun 'to'/'into'/'on'/'onto' noun
                                                 -> Empty;
Verb 'transfer'
                * noun 'to' noun                 -> Transfer;
Verb 'discard' 'drop' 'throw' 'release'
                * multiheld                      -> Drop
                * multiexcept 'in'/'into'/'down' noun
                                                 -> Insert
                * multiexcept 'on'/'onto' noun   -> PutOn
                * held 'at'/'against'/'on'/'onto' noun
                                                 -> ThrowAt;
Verb 'let'
                * 'go' 'of' multiheld           -> Drop
                * multiheld 'go'                -> Drop;
Verb 'give' 'pay' 'offer' 'feed'
                * held 'to' creature             -> Give
                * creature held                  -> Give reverse
                * 'over' held 'to' creature      -> Give;
Verb 'show' 'present' 'display'
                * creature held                  -> Show reverse
                * held 'to' creature             -> Show;
                
[ ADirection; if (noun in compass) rtrue; rfalse; ];

[ KnownRoom     x;

    switch(scope_stage)
    {
        1: rfalse;
        2: objectloop(x in Map) if (x has known) PlaceInScope(x);
        3: if (verb_wordnum == 0) return L__M(##Miscellany, 38); 
           return L__M(##GoToRoom,5);
    }
];

Verb 'go' 'walk' 'run'
                *                                -> Go
                * 'to' noun=ADirection           -> Go
                * 'to' scope=KnownRoom           -> GoToRoom
                * 'back' 'to' scope=KnownRoom    -> GoToRoom
                * noun=ADirection                -> Go
                * scope=KnownRoom                -> GoToRoom
                * 'out' -> Exit
                * 'into'/'in'/'inside'/'through'/'out' noun
                                                 -> EnterIn
                * 'under'/'beneath' noun         -> EnterUnder;
Verb 'continue'
                *                               -> Continue;
Verb 'exits' 't//' 'dirs'
                *                                -> Exits;
Verb 'leave'
                *                                -> Go
                * noun=ADirection                -> Go
                * noun                           -> Leave
                * multiexcept 'on' noun          -> PutOn
                * multiexcept 'in' noun          -> Insert
                * 'into'/'in'/'inside'/'through' noun
                                                 -> EnterIn;
Verb 'inventory' 'inv' 'i//'
                *                                -> Inv
                * 'tall'                         -> InvTall
                * 'wide'                         -> InvWide; 

Verb 'look' 'l//'
                *                                -> Look
                * 'at' noun                      -> Examine
                * 'inside'/'in'/'through'/'out' noun
                                                 -> Search
                * 'on' noun                     -> LookOn
                * 'under'/'beneath'/'underneath'/'behind' noun -> LookUnder
                * noun=ADirection                -> Examine
                * 'up' scope=TopicScope 'in' noun -> Consult
                * 'up' topic 'in' noun           -> Consult
                * 'to' noun=ADirection           -> Examine
                * 'to' noun                      -> Examine
                * 'around'                       -> Look;

Verb 'consult'  
                * noun 'about' scope=TopicScope  -> Consult
                * noun 'about' topic             -> Consult
                * noun 'on' scope=TopicScope     -> Consult
                * noun 'on' topic                -> Consult;
Verb 'open' 'unwrap' 'uncover' 'undo'
                * noun                           -> Open
                * noun 'with' held               -> Unlock;
Verb 'close' 'shut' 'cover'
                * noun                           -> Close
                * 'up' noun                      -> Close
                * 'off' noun                     -> SwitchOff;
Verb 'enter'
                *                                -> GoIn
                * noun                           -> Enter;
Verb 'sit' 'lie'
                * 'on' 'top' 'of' noun           -> EnterOn
                * 'on' noun                         -> EnterOn
                * 'in'/'inside' noun                -> EnterIn;
Verb 'in' 'inside'
                *                                -> GoIn;
Verb 'exit'
                *                               -> Exit
                * noun=ADirection               -> Go
                * 'to' noun=ADirection          -> Go
                * noun                          -> ExitFrom;
Verb 'out' 'outside'
                *                                -> Exit;
Verb 'examine' 'x//' 'watch' 'describe' 'check'
                * noun                           -> Examine;
Verb 'read'
                * noun                               -> Read
                * 'about' scope=TopicScope 'in' noun -> Consult
                * 'about' topic 'in' noun            -> Consult
                * scope=TopicScope 'in' noun         -> Consult
                * topic 'in' noun                    -> Consult;
Verb 'yes' 'y//'
                *                                -> Yes;
Verb 'no'
                *                                -> No;
Verb 'sorry'
                *                                -> Sorry;
Verb 'search'
                * noun                           -> Search;
Verb 'wave'
                *                                -> WaveHands
                * noun                           -> Wave;
Verb 'set' 'adjust'
                * noun                           -> Set
                * noun 'to' special              -> SetTo;
Verb 'pull' 'drag' 'tug' 'yank'
                * noun                           -> Pull;
Verb 'push' 'move' 'shift' 'press'
                * noun                           -> Push
                * noun noun                      -> PushDir
                * noun 'to' ADirection           -> PushDir
                * noun 'to' noun                 -> Transfer;
Verb 'turn' 'rotate' 'twist' 'unscrew' 'screw'
                * noun                           -> Turn
                * noun 'on'                      -> Switchon
                * noun 'off'                     -> Switchoff
                * 'on' noun                      -> Switchon
                * 'off' noun                     -> Switchoff;
Verb 'switch'
                * noun                           -> Switch
                * noun 'on'                      -> Switchon
                * noun 'off'                     -> Switchoff
                * 'on' noun                      -> Switchon
                * 'off' noun                     -> Switchoff;
Verb 'activate'
                * noun                           -> Switchon;
Verb 'lock'
                * noun 'with' held               -> Lock;
Verb 'unlock'
                * noun 'with' held               -> Unlock;
Verb 'attack' 'break' 'smash' 'hit' 'fight' 'wreck' 'crack'
     'destroy' 'murder' 'kill' 'punch' 'thump' 'kick'
                * noun                           -> Attack;
Verb 'wait' 'z//'
                *                               -> Wait;
Verb 'answer' 'say' 'speak' 'mutter' 'whisper' 'reply'
                * scope=TopicScope 'to' creature    -> Answer reverse
                * topic 'to' creature               -> Answer reverse;
Verb 'scream' 'yell' 'holler' 'yodel'
                *                                   -> Scream;
Verb 'shout'
                *                                   -> Scream
                * scope=TopicScope 'to' creature    -> Answer reverse
                * topic 'to' creature               -> Answer reverse;
Verb 'tell'
                * creature 'about' scope=TopicScope -> Tell
                * creature 'about' topic            -> Tell;
Verb 'explain'
                * scope=TopicScope 'to' creature    -> Tell reverse
                * topic 'to' creature               -> Tell reverse;
Verb 'ask'
                * creature 'about' scope=TopicScope -> Ask
                * creature 'about' topic            -> Ask
                * creature 'for' noun               -> AskFor;
Verb 'eat' 'devour' 'consume'
                * noun                           -> Eat;
Verb 'sleep' 'nap' 'doze'
                *                                -> Sleep;
Verb 'peel'
                * 'off' noun                     -> Take;
Verb 'sing'
                *                                -> Sing;
Verb 'climb' 'scale'
                * 'down' noun                   -> ClimbDown
                * 'up'/'over' noun              -> Climb
                * 'in'/'into'/'through'/'inside'/'out' noun -> EnterIn
                * 'onto'/'on'                   -> EnterOn
                * noun                          -> Climb;
Verb 'ascend'
                * noun                          -> Climb
                * 'up' noun                     -> Climb;
Verb 'descend'
                * noun                          -> ClimbDown
                * 'down' noun                   -> ClimbDown;
Verb 'buy' 'purchase'
                * noun                           -> Buy;
Verb 'squeeze' 'squash' 'squish' 'crush'
                * noun                           -> Squeeze;
Verb 'swim' 'dive'
                *                                -> Swim;
Verb 'swing'
                * noun                           -> Swing
                * 'on' noun                      -> Swing;
Verb 'blow'
                * held                           -> Blow
                * 'on'/'out' noun                -> Blow;
Verb 'pray'
                *                                -> Pray;
Verb 'shit' 'fuck' 'damn' 'sod'
                *                                -> Strong
                * topic                          -> Strong;
Verb 'bother' 'curses' 'drat' 'darn'
                *                                -> Mild
                * topic                          -> Mild;
Verb 'wake' 'awake' 'awaken'
                *                                -> Wake
                * 'up'                           -> Wake
                * creature                       -> WakeOther
                * creature 'up'                  -> WakeOther
                * 'up' creature                  -> WakeOther;
Verb 'embrace' 'hug' 'kiss'
                * creature                       -> Kiss;
Verb 'think'
                *                               -> Think
                * topic                         -> Think;
Verb 'smell' 'sniff'
                *                                -> Smell
                * noun                           -> Smell;
Verb 'hear' 'listen'
                *                                -> Listen
                * noun                           -> Listen
                * 'to' noun                      -> Listen;
Verb 'taste'
                * noun                           -> Taste;
Verb 'touch' 'fondle' 'feel' 'grope'
                * noun                           -> Touch;
Verb 'rub' 'shine' 'polish' 'sweep' 'clean' 'dust' 'wipe' 'scrub'
                * noun                           -> Rub;
Verb 'burn' 'light' 'ignite'
                * noun                           -> Burn
                * noun 'with' held               -> Burn;
Verb 'drink' 'imbibe' 'sip' 'swallow'
                * 'up'/'down' noun               -> Drink
                * noun                           -> Drink;
Verb 'fill'
                * noun                           -> Fill;
Verb 'chop' 'cut' 'julienne' 'prune' 'slice'
                * noun 'with' noun               -> Cut;
Verb 'hop' 'jump' 'skip' 'leap'
                *                                -> Jump
                * 'over' noun                    -> JumpOver;
Verb 'dig'
                * noun                          -> Dig
                * 'up' noun                     -> Dig
                * noun 'up'                     -> Dig
                * noun 'with' held              -> Dig
                * noun 'up' 'with' held         -> Dig
                * 'up' noun 'with' held         -> Dig;
Verb 'crawl'
                * 'under'/'beneath'/'behind' noun -> EnterUnder;

! ----------------------------------------------------------------------------
!  Final task: provide trivial routines if the user hasn't already:
! ----------------------------------------------------------------------------

#IFNDEF GuidePath; [ GuidePath; rfalse; ]; #ENDIF;
#IFNDEF FootnoteSub;
[ FootnoteSub; "This game does not have any footnotes."; ];
[ NotesSub; return FootnoteSub(); ];
#ENDIF;
#Stub TimePasses      0;
#Stub Amusing         0;
#Stub DeathMessage    0;
#Stub DarkToDark      0;
#Stub NewRoom         0;
#Stub LookRoutine     0;
#Stub AfterLife       0;
#Stub GamePreRoutine  0;
#Stub GameOnRoutine   0;
#Stub GamePostRoutine 0;
#Stub AfterPrompt     0;
#Stub BeforeParsing   0;
#Stub PrintTaskName   1;
#Stub InScope         1;
#Stub UnknownVerb     1;
#Stub PrintVerb       1;
#Stub ParserError     1;
#Stub ParseNumber     2;
#Stub ChooseObjects   2;

#Stub AlphabetizeAll  2;
#Stub AlphabetizeIn   1;

#IFNDEF PrintRank;
[ PrintRank; "."; ];
#ENDIF;
#Default Story 0;
#Default Headline 0;
#ifndef ParseDescriptor;
[ ParseDescriptor; return -1; ];
#endif;
#ifndef Initialise;
[ Initialise; ];
#endif;
#ifndef ParseNoun;
[ ParseNoun; return -1; ];
#endif;
#ifdef TARGET_GLULX;
#Stub IdentifyGlkObject 4;
#Stub HandleGlkEvent  2;
#Stub InitGlkWindow   1;
#endif; ! TARGET_GLULX

#ifdef INFIX;
Include "infix";
#endif;

#ifndef NO_SPECIAL_WARNINGS;
#ifdef react_before;
Message "^*** Warning: Property 'react_before' should be called 'meddle_early' ***^";
#endif;
#ifdef react_after;
Message "^*** Warning: Property 'react_after' should be called 'meddle_late' ***^";
#endif;
#ifdef before;
Message "^*** Warning: Property 'before' should be called 'respond_early' ***^";
#endif;
#ifdef after;
Message "^*** Warning: Property 'after' should be called 'respond_late' ***^";
#endif;
#ifdef life;
Message "^*** Warning: Property 'life' should be changed to 'respond' ***^";
#endif;
#ifdef door_dir;
Message "^*** Warning: Property 'door_dir' not used in Platypus ***^";
#endif;
#endif;
