! "Middle.h"
! Part of Platypus release 4.
! Copyright 2001 Anson Turner and Graham Nelson
! (not necessarily in that order).
! Comments to: anson@pobox.com

System_file;

!                           #############################
!                                OBJECTS AND CLASSES
!                           #############################

Default MAX_CARRIED = 100;

#ifdef DEBUG;

! Formats the printing of certain object messages when
! message listing is on.
[ PrintParams p y a b c d e     ;

    if (y == 0) rfalse;
    
    if (p == begin_action or perform)
    {   print (debugaction) a;
        if (y > 1) print ",",(name) b;
        if (y > 2) print ",",(name) c;
        jump ppl3;
    }
    if (p == dirs or join_scope or door_to or allow_push or with_key or moveYN)
    {   print (name) a;
        jump ppl1;
    }
    if (p == guide_path)
    {   print (name) a;
        if (y > 1) print ",",(name) b;
        jump ppl2;
    }
    rfalse;
    .ppl1;  if (y > 1) print ",",b;
    .ppl2;  if (y > 2) print ",",c;
    .ppl3;  if (y > 3) print ",",d;
    .ppl4;  if (y > 4) print ",",e;
];
#endif;

Object blank "blank"
  has proper,
  with number,
  private
    allow_entry, allow_push, allow_take, disambiguate, door_to,
    invent_late, join_scope, moveYN, startup, guide_path, with_key;

Object OM__SysObj;

#ifdef ATTRIBUTE_CLASSES;
Class Animates, has animate;
Class Containers, has container;
Class Edibles, has edible;
Class Hiders, has hider;
Class Openables, has openable;
Class Supporters, has supporter;
Class Switchables, has switchable;
Class Talkables, has talkable;
Class Wearables, has clothing;
#endif;

Class Gizmos,
  has proper,
  with cog_class 0;

Class ScopeCogs has proper;

Gizmos ScopeGizmo "(Scope Gizmo)",
  with cog_class ScopeCogs;

Object FloatingHome "(Floating Home)" has proper;
Object Map "(Map)" has proper;
Object Storage "(Storage)" has proper;

Object AchievedTasks "(Achieved Tasks)"
  has proper;

Class MessageCogs has proper;

Gizmos MessageGizmo "(Message Gizmo)",
  with cog_class MessageCogs;

#IFDEF DEBUG;
Class ShowobjCogs
  has proper;

Gizmos ShowobjGizmo "(Showobj Gizmo)" with cog_class ShowobjCogs;

ShowobjCogs
  with
    knows_property [ p;
        if (p == inside_capacity or upon_capacity or under_capacity or carrying_capacity
            or number or time_left or fpsa or name or adjective or location
            or shared or points or words or possessive)
                 rtrue;
    ],
    print_property [ p v;
        switch(p)
        {   name, adjective, possessive: print "'", (address) v,"'";
            location, shared: print (name) v;
            words: print "[...]";
            default: print v;
        }
    ];

#ENDIF;


        ! Directions

Object Compass "(Compass)" has concealed;

Object ndir "north" compass     
  has static concealed,
  with name 'n//' 'north' 'northward', article THE__TX, number 0;
Object sdir "south" compass      
  has static concealed,
  with name 's//' 'south' 'southward', article THE__TX, number 0;
Object edir "east" compass      
  has static concealed,
  with name 'e//' 'east' 'eastward', article THE__TX, number 0;
Object wdir "west" compass       
  has static concealed,
  with name 'w//' 'west' 'westward', article THE__TX, number 0;
Object nedir "northeast" compass 
  has static concealed,
  with name 'ne' 'northeast', article THE__TX, number 0;
Object sedir "southeast" compass
  has static concealed,
  with name 'se' 'southeast', article THE__TX, number 0;
Object nwdir "northwest" compass
  has static concealed,
  with name 'nw' 'northwest', article THE__TX, number 0;
Object swdir "southwest" compass
  has static concealed,
  with name 'sw' 'southwest', article THE__TX, number 0;
Object udir "up" compass, has proper,
  has static concealed,
  with name 'u//' 'up' 'upward' 'upwards', number 0;
Object ddir "down" compass, has proper,
  has static concealed,
  with name 'd//' 'down' 'dn' 'downward' 'downwards', number 0;

Object -> outdir "out"
  has static concealed proper,
  with number 0;
Object -> indir "in"
  has static concealed proper,
  with number 0;

        ! Rooms

Class Rooms
  has proper static concealed,
  with
    fpsa,
    respond [;
        Examine: <<Look>>;
        Listen: <<Listen>>;
        Smell: <<Smell>>;
    ];

Object UnknownRoom
  has proper,
  with short_name [; return L__M(##Exits, 5); ];

Class Sacks
  has open container openable;

[ IsASack x;
    if (x ofclass Sacks) rtrue;
    rfalse;
];

Class Actors
  has animate,
  with
    carrying_capacity MAX_CARRIED,
    location,
    path_moves 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0,
    path_rooms 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0,
    path_length,
    perform [ act x y     ;

#ifndef TARGET_GLULX;
        @push actor; @push action; @push noun; @push second;
#endif;
#ifdef TARGET_GLULX;
        @copy actor sp; @copy action sp; @copy noun sp; @copy second sp;
#endif;
        actor = self;
        action = act; noun = x; second = y;
        
        if (self == player && multiflag && narrative_mode == false)
        {
            if (inp1 == 0) {   L__M(##Miscellany, 510, noun); SetNamePrinted(noun); }
            else {   L__M(##Miscellany, 510, second); SetNamePrinted(second); }
        }
        if (act >= 0 && act <= 256)
        {
        if (ActionIgnoresDarkness()) ignore_darkness = true;
#ifndef TARGET_GLULX;
        if (BeforeRoutines() == 0) (#actions_table-->act)();
#endif;
#ifdef TARGET_GLULX;
        if (BeforeRoutines() == 0) (#actions_table-->(act+1))();
#endif;
        }
        RunProperties(MEDDLE_LATE_LATE_REASON);
        ignore_darkness = false;
#ifndef TARGET_GLULX;
        @pull second; @pull noun; @pull action; @pull actor;
#endif;
#ifdef TARGET_GLULX;
        @copy sp second; @copy sp noun; @copy sp action; @copy sp actor;
#endif;
    ],
    messages [;
        if (self == player) rfalse;
        Answer, Ask, Tell, Sorry: "#A# mumble#s# something.";
        Attack: "#A# look#s# perturbed.";
        Blow: "#A# blow#s# on #o#.";
        Burn, Buy, Kiss: return ActionMessage(##Miscellany, 1000);
        Climb, ClimbDown: "#A# attempt#s# to climb on #o#.";
        Close: switch(lm_n) {
            1: rfalse;
            default: return ActionMessage(##Miscellany, 1000);
        }
        Consult, Empty, Enter, LookOn: return ActionMessage(##Miscellany, 1000);
        Cut: "#A# attempt#s# to cut #o# with #d#.";
        Dig, Fill, Leave, Swim, Swing, Think: return ActionMessage(##Miscellany, 1002);
        Disrobe: switch(lm_n) {
            2: return ActionMessage(##Miscellany, 1000);
        }
        Drink: return ActionMessage(##Miscellany, 1000);
        Drop: switch(lm_n) {
            1: "#A# drop#s# #o#.";
            default: return ActionMessage(##Miscellany, 1000);
        }
        Eat: switch(lm_n) {
            1: "#A# eat#s# #o#.";
            2: return ActionMessage(##Miscellany, 1000);
        }
        Enter: return ActionMessage(##Miscellany, 1000);
        EnterIn: switch(lm_n) {
            2: return ActionMessage(##Miscellany, 1002);
            3: "#A# attempt#s# to get into #o#.";
        }
        EnterOn: switch(lm_n) {
            2: return ActionMessage(##Miscellany, 1002);
            3: "#A# attempt#s# to get on top of #o#.";
        }
        EnterUnder: switch(lm_n) {
            1: if (lm_o hasnt transparent
                   && IndirectlyContains(lm_o, player) ~= under)
                   "#A# disappear#s# beneath #o#.";
               "#A# get#s# under #o#.";
            2: return ActionMessage(##Miscellany, 1002);
            3: "#A# attempt#s# to get under #o#.";
        }
        Examine: switch(lm_n) {
            1: return ActionMessage(##Miscellany, 1002);
            2: if (lm_o in Compass)
               {
                   print "#A# look#s# ";
                   if (lm_o ~= udir or ddir) print "to ";
                   "#o#.";
               }
               return ActionMessage(##Miscellany, 1000);
            3: return ActionMessage(##Miscellany, 1000);
        }
        Exit, GetOff: return ActionMessage(##Miscellany, 1002);
        Exits: "#A# look#s# for a way out.";
        ExitFromUnder: switch(lm_n) {
            1: if (IndirectlyContains(lm_o, player) == under)
                   "#A# exit#s# from under #o#.";
               if (lm_o hasnt transparent)
                   "#A# appear#s# from under #o#.";
               rfalse;
        }
        Give: switch(lm_n) {
            1: "#A# juggle#s# #o#.";
            3: "#A# offer#s# #n# to #o#.";
        }
        Go: switch(lm_n) {
            3,4: "#A# attempt#s# to climb on #o#.";
            5001: "^#A# depart#s# to #o#.";
            5002: "^#A# enter#s#.";
            5003: "^#A# go#es# through #o#.";
            5004: "^#A# enter#s# through #o#.";
            default: return ActionMessage(##Miscellany, 1002);
        }
        Insert: switch(lm_n) {
            2 to 6: return ActionMessage(##Miscellany, 1000);
            7: if (multiphase == 3 or 4) "#o# won't fit.";
               "#A# attempt#s# to stuff #o# into #d# and fail#s-a#.";
        }
        JumpOver, Pull, Push, Turn,
                    Set, SetTo, Tie: return ActionMessage(##Miscellany, 1001);
        Listen: "#A# look#s# alert.";
        Lock: switch(lm_n) {
            2 to 5: return ActionMessage(##Miscellany, 1001);
            5001: "#A# lock#s# #o# with #d#.";
        }
        LookUnder: switch(lm_n) {
            1: "#A# peek#s# under #o#.";
            2: return ActionMessage(##Miscellany, 1000);
        }
        Mild,Pray,Strong: "#A# mumble#s# something under #his# breath.";
        Miscellany: switch(lm_n) {
            1000: print "#A# contemplate#s# #o#";
                if (second && second ~= lm_o or actor.location)
                    print " and #d#";
                ".";
            1001: print "#A# fiddle#s# with #o#";
                if (second && second ~= lm_o or actor.location)
                    print " and #d#";
                ".";
            1002: "#A# appear#s# momentarily confused.";
        }
        No: "#A# shake#s# #his# head.";
        Open: switch(lm_n) {
            2, 3: return ActionMessage(##Miscellany, 1001);
            4,6: return ActionMessage(##Miscellany, 1000);
        }
        PushDir: "#A# attempt#s# to push #o#.";
        PutOn: switch(lm_n) {
            1: rfalse;
            5: return ActionMessage(##Miscellany, 1000);
            6: if (multiphase == 3 or 4) "#o# won't fit.";
               "#A# attempt#s# to put #o# on top of #d#,
                but there is no room.";
            default: if (lm_n > 6) rfalse;
                     return ActionMessage(##Miscellany, 1001);
        }
        PutUnder: switch(lm_n) {
            1: rfalse;
            4: if (multiphase == 3 or 4) "#o# won't fit.";
               "#A# attempt#s# to stuff #o# under #d#, but there is no room.";
            5: return ActionMessage(##Miscellany, 1000);
            default: if (lm_n > 6) rfalse;
                     return ActionMessage(##Miscellany, 1001);
        }
        Rub: "#A# rub#s# #o#.";
        Scream: "#A# scream#s#.";
        Search: switch(lm_n) {
            1: return ActionMessage(##Miscellany, 1002);
            4,6: "#A# look#s# inside #o#.";
            5: return ActionMessage(##Miscellany, 1000);
        }
        Show: switch(lm_n) {
            1: "#A# show#s# #o# to #d#.";
        }
        Sing: "#A# sing#s#.";
        Sleep, Wake: "#A# yawn#s#.";
        Smell: print "#A# sniff#s# ";
            if (lm_o) "#o#.";
            "the air.";
        Squeeze: switch(lm_n) {
            1: return ActionMessage(##Miscellany, 1000);
            2: "#A# squeeze#s# #o#.";
        }
        SwitchOff: switch(lm_n) {
            1: rfalse;
            2, 3: return ActionMessage(##Miscellany, 1001);
        }
        SwitchOn: switch(lm_n) {
            1: rfalse;
            2, 3: return ActionMessage(##Miscellany, 1001);
        }
        Take: switch(lm_n) {
            1: "#A# take#s# #o#.";
            10, 11: if (multiphase == 3 or 4) "#a-s# #is# unable to lift #o#.";
                    "#A# attempt#s# to pick up #o#, but fail#s-a#.";
            12: "#A# attempt#s# to take #o# despite #his# load.";
            21: return ActionMessage(##Miscellany, 1002);
            default: if (lm_n > 21) rfalse;
                     return ActionMessage(##Miscellany, 1000);
        }
        Taste: "#A# taste#s# #o#.";
        ThrowAt: "#A# heft#s# #n#.";
        Touch: switch(lm_n) {
            1: return ActionMessage(##Miscellany, 1000);
            2: "#A# feel#s# #o#.";
            3: "#A# touch#es# #a#.";
        }
        Unlock: switch(lm_n) {
            2 to 5: return ActionMessage(##Miscellany, 1001);
        }
        Yes: "#A# nod#s#.";
        Wait: "#A# look#s# bored.";
        WakeOther: "#A# jostle#s# #o#.";
        Wave: "#A# wave#s# #o# around.";
        WaveHands: "#A# wave#s#.";
        Wear: switch(lm_n) {
            2: "#A# attempt#s# to wear #o#.";
            4: return ActionMessage(##Miscellany, 1001);
        }
    ];
        

#IFNDEF PLAYER_OBJECT;
Actors newselfobj "your former self"
  has transparent proper concealed,
  with
    description "As good-looking as ever.",
    orders,
    short_name [;
        if (self == player && player_perspective == 3)
        {   if (self has proper) print "Player";
            else print "player";
            rtrue;
        }
    ],
    guide_path [     x;
        
        if (self ~= player) rfalse;
        objectloop(x in Map)
            if (x hasnt known) x.fpsa = 0;
    ];

Constant PLAYER_OBJECT = newSelfObj;
#ENDIF;

!                          #############################
!                                GENERAL ROUTINES
!                          #############################

[ Init     x y cc;

    #ifdef RuntimeDictionary;
#ifndef TARGET_GLULX;
        RuntimeDictionary -> 0 = 3;
        RuntimeDictionary -> 1 = '.';
        RuntimeDictionary -> 2 = ',';
        RuntimeDictionary -> 3 = '"';
        RuntimeDictionary -> 4 = 9;
#endif;
    #endif;
    
    #ifdef MAX_SCORE;
        maximum_score = MAX_SCORE;
    #ifnot;
       objectloop(x)
        {   if (x provides points && x.points > 0)
                maximum_score = maximum_score + x.points;
        }
    #endif;
    
    objectloop(x)
    {   if (x ofclass Gizmos)
            if (x.cog_class)
            {   cc = x.cog_class;
                objectloop(y)
                    if (y ofclass cc && y notin Storage)
                        move y to x;
            }

        if (x notin Storage && (x provides found_in
            || (x provides door_to && x.#door_to > WORDSIZE)))
                move x to FloatingHome;

        if (x ofclass Rooms)
        {   if (x provides shared)
                for (y = 0:y < x.#shared/WORDSIZE:y++)
                    if (x.&shared-->y notin Storage)
                        move x.&shared-->y to FloatingHome;
            move x to Map;
        }
    }
    
    if (player && player hasnt secret)
        give player known;
];

[ SetDefaultObjectPositions     x;

    objectloop(x ofclass Object) SetDefaultPosition(x);
];

[ SetDefaultPosition obj     p;

    if (PositionOf(obj)) rfalse;
    p = parent(obj); if (p == 0) rtrue;
    if (p ofclass Gizmos or Class || p in Map) rtrue;
    if (p has supporter) give obj upon;
    else if (p has container) give obj inside;
    else if (p has hider) give obj under;
    else rfalse;
];

[ Transmogrify x y flag     bitm c;

    if (parent(x))
    {   MoveTo(y, parent(x), PositionOf(x));
        remove x;
    }
    else remove y;
    
    if (noun == x) noun = y;
    if (second == x) second = y;
    if (actor == x) actor = y;

    for (c = 1:c < 64:c++)
        if (multiple_object-->c == x) multiple_object-->c = y; 

    bitm = PowersOfTwo_TB-->(GetGNAOfObject(y));

    for (c = 0 : c < NUMBER_OF_PRONOUNS : c++)
        if (PronounReferents-->c == x)
        {   if (bitm & (PronounGNAs-->c))
                PronounReferents-->c = y;
            else
                PronounReferents-->c = 0;
        }
    
    if (x == player) return ChangePlayer(y, flag);
];


        ! implements print (spaces)

[ spaces n; if (n) spaces n; ];

[ RoutFalse; rfalse; ];
[ RoutTrue; rtrue; ];


#ifndef TARGET_GLULX;
        ! DrawCompass(horizontal position)
        ! Draws an onscreen compass showing available exits.

#IFDEF DEBUG;
[ DrawCompass x     a loc df;
#IFNOT;
[ DrawCompass x     a loc;
#ENDIF;

    #ifdef DEBUG; df = debug_flag; debug_flag = 0; #endif;
    if (InDark(player))
    {
        @set_cursor 2 x; print "      *";
    }
    else
    {
        loc = player.location;
        @set_cursor 1 x; finding_path = ExitsSub;
        if (GetDestination(loc,udir)) print "UP "; else print "   ";
        if (GetDestination(loc,nwdir)) print "NW "; else print "   ";
        if (GetDestination(loc,ndir)) print "N "; else print "  ";
        if (GetDestination(loc,nedir)) print "NE";
        a = x + 4; @set_cursor 2 a;
        if (GetDestination(loc,wdir)) print "W * "; else print "  * ";
        if (GetDestination(loc,edir)) print "E";
        @set_cursor 3 x;
        if (GetDestination(loc,ddir)) print "DN "; else print "   ";
        if (GetDestination(loc,swdir)) print "SW "; else print "   ";
        if (GetDestination(loc,sdir)) print "S "; else print "  ";
        if (GetDestination(loc,sedir)) print "SE";
        finding_path = 0;
    }
     #ifdef DEBUG; debug_flag = df; #endif;
];
#endif;
#ifdef TARGET_GLULX;
#IFDEF DEBUG;
[ DrawCompass x     a loc df;
#IFNOT;
[ DrawCompass x     a loc;
#ENDIF;

    #ifdef DEBUG; df = debug_flag; debug_flag = 0; #endif;
    if (InDark(player))
    {
        glk($002B, gg_statuswin, x, 1);
        print "      *";
    }
    else
    {
        loc = player.location;
        glk($002B, gg_statuswin, x, 0);
        finding_path = ExitsSub;
        if (GetDestination(loc,udir)) print "UP "; else print "   ";
        if (GetDestination(loc,nwdir)) print "NW "; else print "   ";
        if (GetDestination(loc,ndir)) print "N "; else print "  ";
        if (GetDestination(loc,nedir)) print "NE";
        a = x + 4; 
        glk($002B, gg_statuswin, a, 1);
        if (GetDestination(loc,wdir)) print "W * "; else print "  * ";
        if (GetDestination(loc,edir)) print "E";
        glk($002B, gg_statuswin, x, 2);
        if (GetDestination(loc,ddir)) print "DN "; else print "   ";
        if (GetDestination(loc,swdir)) print "SW "; else print "   ";
        if (GetDestination(loc,sdir)) print "S "; else print "  ";
        if (GetDestination(loc,sedir)) print "SE";
        finding_path = 0;
    }
     #ifdef DEBUG; debug_flag = df; #endif;
];

#endif;

        ! FindByByte (value, address, bytes[, form])
        ! Scans the given number of bytes starting from the given address,
        ! and returns the index of the first occurance of the given value,
        ! or -1 if it is not found.
        !
        ! Thus, if the Values array contains: 4 0 3 9 12,
        ! a call to FindByByte(9, Values, 5) will return 3, because
        ! Values->3 == 9.

#ifndef TARGET_GLULX;
[ FindByByte v arr bytes fln     idx;

    if (fln == 0) fln = 1; else bytes = bytes / fln;
    @scan_table v arr bytes fln idx ? fbbmatch;
    return -1;
    .fbbmatch;
    return idx - arr;
];


        ! FindByWord (value, address, words[, item length])
        ! Similar to FindByByte, but scans for a word, and returns a
        ! word index.

[ FindByWord v arr words fln     form idx;

    if (fln == 0) fln = 1; else words = words / fln;
    form = $80 + fln * 2;
    @scan_table v arr words form idx ? fbwmatch;
    return -1;
    .fbwmatch;
    return (idx - arr) / 2;
];
#endif;
#ifdef TARGET_GLULX;

[ FindByByte v arr bytes fln     idx;

    if (fln == 0) fln = 1; else bytes = bytes / fln;
    @linearsearch v 1 arr fln bytes 0 4 idx;
    return idx;
];

[ FindByWord v arr words fln    idx;

    if (fln == 0) fln = 1; else words = words / fln;
    fln = fln * WORDSIZE;
    @linearsearch v WORDSIZE arr fln words 0 4 idx;
    return idx;
];
#endif;

        ! FindInTable (value, table[, item length])
        ! Similar to FindByWord, but uses the table's own length
        ! entry to determine how far to scan.

[ FindInTable v arr fln     r;

    r = FindByWord(v, arr + WORDSIZE, arr-->0, fln);
    if (r ~= -1) r++;
    return r;
];
        ! GetDestination (room,direction object[,go flag])
        ! Returns the object that a given direction (object) leads to
        ! from the given room.

[ GetDestination x y fl     idx xy;

    if (x.#dirs > WORDSIZE)
    {   idx = FindByWord(y, x.&dirs, x.#dirs / WORDSIZE);
        if (idx == -1) rfalse;
        .getdestinationlab01;
        idx++;
        xy = x.&dirs-->idx;
        if (xy ofclass Object && xy in Compass)
            jump getdestinationlab01;
    }
    else xy = x.dirs(y);

    if (fl) return xy;
    
    if (metaclass(xy) ~= Object) rfalse;

    if (xy provides door_to)
    {   y = xy.&door_to;
        if (xy.#door_to > WORDSIZE)
        {   if (y-->0 == x) return y-->1;
            if (y-->1 == x) return y-->0;
            rfalse;
        }
        xy = y-->0;
        y = metaclass(xy);

        if (y == String) rfalse;
        if (y == Routine)
            xy = xy(x);
    }
    return xy;
];

[ TestExit x y     a rv;

    a = finding_path;
    finding_path = ExitsSub;
    rv = GetDestination(x, y, 1);
    finding_path = a;
    return rv;
];

        ! GetDigitValue (character)
        ! Returns the value of a digit character, or -1 if not a digit.
        ! E.g. GetDigitValue('4') returns 4.

[ GetDigitValue ch;
    if (ch < '0' || ch > '9') return -1;
    return ch - '0';
];


        ! LesserOf (value 1, value 2)
        ! Returns the lower of the two values (signed).

[ LesserOf a b;
    if (a < b)
        return a;
    return b;
];


        ! GreaterOf (value 1, value 2)
        ! Returns the greater of the two values (signed).

[ GreaterOf a b;
    if (a > b)
        return a;
    return b;
];

        ! GetTableValue (word, index table, result table)
        ! Looks up |word| in |index table| and returns the value in the
        ! corresponding position in |result table| (or -1 if not found).

[ GetTableValue wd table result     v;

    v = FindInTable(wd,table);
    if (v == -1)  return -1;

    return result-->v;
];


        ! GetUppercase (character)
        ! Returns the given character, converted to uppercase if it
        ! was a lowercase letter.

[ GetUppercase ch;
  if (ch >= 'a' && ch <= 'z')
     return ch + LOWER_TO_UPPER;
  return ch;
];


        ! GetWordIndex (parse table, word number)
        ! Returns a buffer index for the given word number in
        ! the given parse table.

[ GetWordIndex p wordnum;
  return p->(wordnum * 4 + 1);
];


        ! HasVisibleContents (object[, flag[, attribute]])
        ! flag = CONCEAL_BIT to include concealed objects as visible
        !        ALWAYS_BIT  to include all contents not concealed
        !                    (unless CONCEAL_BIT also set)
        ! Returns a bitmap based on the following possibilities:

Constant ONE_UPON     = 1;
Constant MULTI_UPON   = 2;
Constant ONE_INSIDE   = 4;
Constant MULTI_INSIDE = 8;
Constant ONE_UNDER    = 16;
Constant MULTI_UNDER  = 32;
Constant ONE_HELD     = 64;
Constant MULTI_HELD   = 128;
Constant ONE_WORN     = 256;
Constant MULTI_WORN   = 512;
Constant ANY_UPON     = 1024;   ! The ANY bits are set if either the corresponding
Constant ANY_INSIDE   = 2048;   ! ONE or MULTI bits are set. (Provided for convenience
Constant ANY_UNDER    = 4096;   ! in cases where it doesn't matter which.)
Constant ANY_HELD     = 8192;
Constant ANY_WORN     = 16384;

[ HasVisibleContents x cs att     y rv cflag sc ss sh sp sw ar;
    
    ar = IndirectlyContains(x, actor);

    if (cs & CONCEAL_BIT == 0) cflag = true;
    if (cs & ALWAYS_BIT || actor == x)
    {   sc = true;     ss = true;     sh = true;
        sp = true;     sw = true;
    }
    else
    {   if (x has container
            && (x has transparent
                || ar == inside
                || (x has open && ar ~= under)))
                sc = true;
        if (x has supporter
            && (x has transparent
                || (ar ~= under && (x has open || ar ~= inside))))
                ss = true;
        if (x has hider
            && (x has transparent || ar == under || action == ##LookUnder))
            sh = true;
        if (x in Map) sp = true;
        if (x has animate)
        {   sw = true;
            if (x has transparent) sp = true;
        }
    }

    objectloop(y in x)
    {   if (cflag && y has concealed) continue;
        if (att && y hasnt att) continue;
        switch(PositionOf(y)) {
            upon: if (ss) ss++;
            inside: if (sc) sc++;
            under: if (sh) sh++;
            worn: if (sw) sw++;
            0: if (sp) sp++;
        }
    }

    if (sc == 2) rv = rv | (ONE_INSIDE + ANY_INSIDE);
    if (sc > 2)  rv = rv | (MULTI_INSIDE + ANY_INSIDE);
    if (ss == 2) rv = rv | (ONE_UPON + ANY_UPON);
    if (ss > 2)  rv = rv | (MULTI_UPON + ANY_UPON);
    if (sh == 2) rv = rv | (ONE_UNDER + ANY_UNDER);
    if (sh > 2)  rv = rv | (MULTI_UNDER + ANY_UNDER);
    if (sp == 2) rv = rv | (ONE_HELD + ANY_HELD);
    if (sp > 2)  rv = rv | (MULTI_HELD + ANY_HELD);
    if (sw == 2) rv = rv | (ONE_WORN + ANY_WORN);
    if (sw > 2)  rv = rv | (MULTI_WORN + ANY_WORN);
    
    return rv;
];

        ! abs (value)
        ! Returns the absolute value of the given number.

[ abs a;
    if (a < 0) a = -a;
    return a;
];

#ifndef TARGET_GLULX;
        ! CopyBytes (from address, to address, bytes)
        ! Copies the given number of bytes starting at the intial
        ! address to the destination address, correctly copying even
        ! if the regions overlap.
    
[ CopyBytes fromaddr toaddr bytes;
    if (toaddr && toaddr < fromaddr) bytes = -bytes;
    @copy_table fromaddr toaddr bytes;
];

        ! CopyWords (from address, to address, words)
        ! Like CopyBytes, but accepts a size given in words.

[ CopyWords fromaddr toaddr words;
    CopyBytes(fromaddr, toaddr, words * 2);
];

#endif;
#ifdef TARGET_GLULX;
[ CopyBytes fromaddr toaddr bytes     c;

    if (toaddr > fromaddr)
        for (c = bytes-1:c >= 0:c--)
            toaddr->c = fromaddr->c;
     
    else
        for (c = 0:c < bytes:c++)
            toaddr->c = fromaddr->c;
];
[ CopyWords fromaddr toaddr words     c;

    if (toaddr > fromaddr)
        for (c = words-1:c >= 0:c--)
            toaddr-->c = fromaddr-->c;
    else
        for (c = 0:c < words:c++)
            toaddr-->c = fromaddr-->c;
];
#endif;

[ MatchesAPronoun obj     idx;

    idx = FindByWord(obj, PronounReferents, NUMBER_OF_PRONOUNS);
    if (idx > -1) return PronounWords-->idx;
    rfalse;
];

#IFDEF RuntimeDictionary;
        ! AddWord (address, # of characters)
        ! Adds a word to the Runtime Dictionary and returns its address,
        ! or false if there is no room left in the Dictionary.
        ! (If word already exists in either dictionary, returns existing
        ! address without adding word).

#ifndef TARGET_GLULX;
[ AddWord address length     sz addr2 dl c;

    sz = (RuntimeDictionary + 1) --> 2;         ! Avoid dictionary overflow.
    if (-sz >= RUNTIME_DICTIONARY_MAX_WORDS) rfalse;
    if (length > 9) length = 9;

    CopyBytes(address, Byte1A, length);
    for (c = 0:c < length:c++) Byte1A->c = GetLowercase(Byte1A->c);

    dl = DictionaryLookup(address, length);     ! Avoid duplicate words.
    if (dl) return dl;

    addr2 = RuntimeDictionary + 7 + (-sz * (RuntimeDictionary->4));
    @encode_text Byte1A length 0 addr2;
    (RuntimeDictionary + 1) --> 2 = sz - 1;

    return addr2;
];
#endif;
#ifdef TARGET_GLULX;
[ Addword address length     sz addr2 dl;
    
    sz = RuntimeDictionary-->0;
    if (sz >= RUNTIME_DICTIONARY_MAX_WORDS) rfalse;
    
    dl = DictionaryLookup(address, length);
    if (dl) return dl;

    addr2 = RuntimeDictionary + 4
            + (RuntimeDictionary-->0) * (7+DICT_WORD_SIZE);
    if (length > DICT_WORD_SIZE) length = DICT_WORD_SIZE;
    CopyBytes(address, addr2+1, length);
    addr2->0 = $60;
    (RuntimeDictionary-->0)++;
    
    return addr2;
];
#endif;
#ENDIF;

[ rootof obj;
    if (metaclass(obj) ~= Object) rfalse;
    while (parent(obj) ~= 0 or Map) obj = parent(obj);
    return obj;
];

[ CurrentCarryingCapacity act     x c;

    objectloop(x in act) if (positionof(x) == 0) c++;
    return ValueOrRun(act, carrying_capacity) - c;
];

[ CurrentInsideCapacity obj;
    if (obj hasnt container) rfalse;
    return ValueOrRun(obj, inside_capacity) - CountContentsByAttribute(obj, inside);
];

[ CurrentUponCapacity obj;
    if (obj hasnt supporter) rfalse;
    return ValueOrRun(obj, upon_capacity) - CountContentsByAttribute(obj, upon);
];

[ CurrentUnderCapacity obj;
    if (obj hasnt hider) rfalse;
    return ValueOrRun(obj, under_capacity) - CountContentsByAttribute(obj, under);
];

#ifndef TARGET_GLULX;
! Routine to implement obj.prop(). Modified a bit from standard veneer.

[ CA__Pr obj id a b c d e     x y z s s2 n m pv;

    if (obj < 1 || obj > #largest_object - 255)
    {   switch(Z__Region(obj))
        {   2: if (id ~= call) jump Call__Error;
               s = sender; sender = self; self = obj;
               sw__var = action;
               x = indirect(obj, a, b, c, d, e);
               self = sender; sender = s; return x;
            3: if (id == print) { @print_paddr obj; rtrue; }
               if (id ~= print_to_array) jump Call__Error;
               OpenBuffer(a); @print_paddr obj; CloseBuffer();
               return a-->0;
        }
        jump Call__Error;
    }
    @check_arg_count 3 ?~ A__x; y++;
    @check_arg_count 4 ?~ A__x; y++;
    @check_arg_count 5 ?~ A__x; y++;
    @check_arg_count 6 ?~ A__x; y++;
    @check_arg_count 7 ?~ A__x; y++;
    .A__x;
    #ifdef INFIX; if (obj has infix__watching) n = 1; #endif;
    #ifdef DEBUG;
    if (debug_flag & 1) n = 1;
    if (n == 1)
    {   n = debug_flag & 1; debug_flag = debug_flag - n;
        print "[ ~", (name) obj, "~.", (property) id, "(";
        if (PrintParams(id, y, a, b, c, d, e) == 0)
        {   if (y) print a;
            if (y > 1) print ",",b;
            if (y > 2) print ",",c;
            if (y > 3) print ",",d;
            if (y > 4) print ",",e;
        }
        print ") ]^";
        debug_flag = debug_flag + n;
    }
    #endif;
    if (id >= 0 && id < 64)
    {   x = obj.&id; if (x == 0) { x=$000a-->0 + 2*(id-1); n = 2; }
        else n = obj.#id;
    }
    else
    {   if (id >= 64 && id < 69 && obj in Class) return Cl__Ms(obj,id,y,a,b,c,d);
        x = obj..&id;
        if (x == 0) {
            .Call__Error;
            RT__Err("send message", obj, id); return;
        }
        n = 0->(x - 1);
        if (id & $C000 == $4000)
            switch (n & $C0) { 0:n = 1; $40:n = 2; $80:n = n & $3F; }

    }
    n = n / 2;          ! Convert bytes to words.
    for (:m < n:m++)
    {   pv = x-->m;
        if (pv == $ffff) rfalse;
        switch(Z__Region(pv))
        {   2:  s = sender; sender = self; self = obj; s2 = sw__var;
                sw__var = action;
                switch(y) {
                    0: z = indirect(pv);
                    1: z = indirect(pv, a);
                    2: z = indirect(pv, a, b);
                    3: z = indirect(pv, a, b, c);
                    4: z = indirect(pv, a, b, c, d);
                    5: z = indirect(pv, a, b, c, d, e);
                }
                self = sender; sender = s; sw__var = s2;
                if (z) return z;
            3: print_ret (string) pv;
            default: return pv;
        }
    }
    rfalse;
];

! Routine to implement ofclass. Modified from veneer.

[ OC__Cl obj cla     a;

    if (obj<1 || obj > (#largest_object-255))
    {   if (cla ~= 3 or 4) rfalse;
        if (Z__Region(obj) == cla - 1) rtrue;
        rfalse;
    }
    
    if (cla == 1)
    {   if (obj < 5 || obj in 1) rtrue;
        rfalse;
    }
    if (cla == 2)
    {   if (obj < 5 || obj in 1) rfalse;
        rtrue;
    }
    if (cla == 3 or 4) rfalse;

    if (cla notin 1) { RT__Err("apply 'ofclass' for", cla, -1);rfalse;}
    
    a = obj.&2;
    if (a == 0) rfalse;
    if (FindByWord(cla, a, obj.#2 / 2) ~= -1) rtrue;
    rfalse;
];

#endif;
#ifdef TARGET_GLULX;
[ CA__Pr _vararg_count obj id zr s s2 z addr len m val;

    @copy sp obj;  @copy sp id;
    _vararg_count = _vararg_count - 2;
    zr = Z__Region(obj);
    if (zr == 2) {
        if (id ~= call) jump Call__Error;
        s = sender; sender = self; self = obj;
        sw__var = action;
        @call obj _vararg_count z;
        self = sender; sender = s;
        return z;
    }
    if (zr == 3) {
        if (id == print) { @streamstr obj; rtrue; }
        if (id == print_to_array)
        {   if (_vararg_count >= 2)
            {   @copy sp m;
                @copy sp len;
            }
            else {
                @copy sp m;
                len = $7FFFFFFF;
            }
            s2 = glk($0048);
            s = glk($0043, m+4, len-4, 1, 0);
            if (s) {
                glk($0047, s);
                @streamstr obj;
                glk($0047, s2);
                @copy $ffffffff sp;
                @copy s sp;
                @glk $0044 2 0;
                @copy sp len;
                @copy sp 0;
                m-->0 = len;
                return len;
            }
            rfalse;
        }
        jump Call__Error;
    }
    if (zr ~= 1) jump Call__Error;
    #ifdef DEBUG; #ifdef InformLibrary;
        if (debug_flag & 1)
        {   debug_flag--;
            print "[ ~", (name) obj, "~.", (property) id, "(";
            @stkcopy _vararg_count;
            for (val=0 : val < _vararg_count : val++)
            {   if (val) print ", ";
                @streamnum sp;
            }
            print ") ]^";
            debug_flag++;
        }
    #endif; #endif;
    if (obj in Class) 
    {   switch (id) 
        {   remaining:
                return Cl__Ms(obj, id);
            copy:
                @copy sp m; @copy sp val;
                return Cl__Ms(obj, id, m, val);
            create, destroy, recreate:
                m = _vararg_count+2;
                @copy id sp;
                @copy obj sp;
                @call Cl__Ms m val;
                return val;
        }
    }
    addr = obj.&id;
    if (addr == 0)
    {   if (id > 0 && id < INDIV_PROP_START)
        {   addr = #cpv__start + 4*id;
            len = 4;
        }
        else jump Call__Error;
    }
    else len = obj.#id;
    for (m=0 : 4*m<len : m++)
    {   val = addr-->m;
        if (val == -1) rfalse;
        switch (Z__Region(val)) {
            2: s = sender; sender = self; self = obj; s2 = sw__var;
               sw__var=action;
               @stkcopy _vararg_count;
               @call val _vararg_count z;
               self = sender; sender = s; sw__var = s2;
               if (z) return z;
            3: @streamstr val;
               new_line; rtrue;
            default: return val;
        }
    }
    rfalse;
    .Call__Error;
    RT__Err("send message", obj, id);
    rfalse;
];

#endif;

!                          #############################
!                               OBJECT TREE ROUTINES
!                          #############################

[ GetLastChild obj     x;

    x = child(obj);
    if (x) while (sibling(x)) x = sibling(x);
    return x;
];

        ! GetNthChild (object, n)
        ! Returns the nth descendant of the given object.

[ GetNthChild obj n;

    obj = child(obj);
    for (:n > 1:n--) obj = sibling(obj);
    return obj;
];


        ! GetNthSibling (object, n)
        ! Returns the nth sibling of the given object.

[ GetNthSibling obj n;
  for (:n > 0:n--) obj = sibling(obj);
  return obj;
];


        ! InsertAfter (object,object2)
        ! Makes |object2| the sibling of |object| in the tree.

[ InsertAfter obj obj2     x;

    x = parent(obj);
    if (obj == obj2 || metaclass(x) ~= Object) rfalse;

    remove obj2;
    while (child(x) ~= obj) move child(x) to OM__SysObj;
    move obj to OM__SysObj;
    move obj2 to x;
    while (child(OM__SysObj)) move child(OM__SysObj) to x;
];  


        ! InsertBefore (object,object2)
        ! Makes -object2- the elder of -object- in the tree.

[ InsertBefore obj obj2     x;

    x = parent(obj);
    if (obj == obj2 || metaclass(x) ~= Object) rfalse;

    remove obj2;
    if (child(x) == obj) { move obj2 to x; rtrue; }
    while (child(x) ~= obj) move child(x) to OM__SysObj;
    move obj2 to x;
    while (child(OM__SysObj)) move child(OM__SysObj) to x;
];


        ! InsertLast (object, object2)
        ! Make -object2- the last child of -object-.

[ InsertLast obj obj2;
    if (child(obj) == 0) move obj2 to obj;
    else InsertAfter(GetLastChild(obj), obj2);
];



!                             #############################
!                                      BIT ROUTINES
!                             #############################


Array BitValues -> 128 64 32 16 8 4 2 1;

        ! HasBit (address, bit)
        ! Returns true if the given bit is set, counting from
        ! the given address.

[ HasBit adr b     v bit;

      v = adr->(b / 8);
    bit = BitValues->(b % 8);
    if (v & bit) rtrue;
    rfalse;
];

        ! SetBit (address, bit)
        ! Sets the given bit, counting from the given address.

[ SetBit adr b     bit v i;

    i = b / 8;
    v = adr->i;
    bit = BitValues->(b % 8);
    adr->i = v | bit;
];

        ! ClearBit (address, bit)
        ! Clears the given bit, counting from the given address.

[ ClearBit adr b     bit v i;

    i = b / 8;
    v = adr->i;
    bit = BitValues->(b % 8);
    bit = ~bit;
    adr->i = v & bit;
];

        ! binary(value)  ||  print (binary) value
        ! Prints the given value in binary form.

[ binary v     c;

    Byte1A-->0 = v;
    for (:c < 16:c++)
        print HasBit(Byte1A, c);
];


        ! ParseObj (object, "parsing secondary object" flag)
        ! Matches as many words as possible starting at the current word
        ! to the object supplied.

Global tglobal;

[ ParseObj obj nfl     w c fl own z du early ap uwp r pos;

    if (obj has void) rfalse;

    if (nfl) nfl = 1;
    else
    {   indef_mode_spec = 0;
        numspec = 0;
    }
    desc_used = 0;
    early = true;

    uwp = number;
    if (obj provides parse_name) uwp = parse_name;

    while ((w = NextWord()) ~= 0)
    {
        if (uwp == parse_name or number)
        {   own = wn; wn--;
            parser_action = NULL;
            if (uwp == parse_name) r = obj.parse_name();
            else r = ParseNoun(obj);
            z = 0;
            if (r >= 10000)
            {   if (r >= 20000)
                {   r = r - 20000;
                    z = 2;
                }
                else
                {   r = r - 10000;
                    z = 1;
                }
            }
            if (r)
            {
                if (r == -1)
                {   wn = own - 1;
                    if (uwp == parse_name) uwp = number;
                    else if (obj provides words) uwp = words;
                    else uwp = 0;
                    continue;
                }
                desc_used = desc_used + r / 100;
                c = c + r % 100 + r / 100;
                #ifdef WEAK_ADJECTIVES;
                if (r % 100) fl = true;
                #endif;
                #ifndef WEAK_ADJECTIVES;
                fl = true;
                #endif;
                wn = own + (r % 100) + (r / 100);
                if (z == 2) break;
                w = NextWord(); if (w == 0) break;
                if (z == 1) jump parseobj002;
                jump parseobj001;
            }
            wn = own;
            if (z == 2) break;
            if (z == 1) jump parseobj002;
        }
        if (uwp == words)
        {   r = obj.words(w);
            if (r == name) { fl = true; jump pngotword; }
            if (r == adjective)
            {   desc_used++;
                #ifndef WEAK_ADJECTIVES; fl = true; #endif;
                jump pngotword;
            }
        }
        else
        {   if (WordInProperty(w, obj, name)) { fl = true; jump pngotword; }
            if (WordInProperty(w, obj, adjective))
            {   desc_used++;
                #ifndef WEAK_ADJECTIVES; fl = true; #endif;
                jump pngotword;
            }
        }

        .parseobj001;

        if (obj == actor && IsYouWord(w)) { fl = 1; jump pngotword; }

        if ((inputobjs-->2 == obj || obj == actor) && MatchSelfRef(obj, w))
            { fl = 1; jump pngotword; }

        if (the_owner && WordInProperty(w, the_owner, possessive)) jump pngotword;

        if (early)
            if (c > desc_used) early = false;
            else if (ParseEarlyDescriptor(obj, w, 1 - nfl) == 1)
                {   if (numspec ~= 0 or 100)
                        early = false;
                    desc_used = desc_used + 100;
                    if (numspec == 100) fl = 1;
                    jump pngotword;
                }

        if (ParseStandardDescriptor(obj, w, 1 - nfl) == 1)
        {   early = 0;
            desc_used = desc_used + 100;
            jump pngotword;
        }

        .parseobj002;                       ! Confused yet?

        pos = PositionOf(obj);

        ! Try for something like READ BOOK ON TABLE
        if (fl && ((pos == inside && w == 'in' or 'inside')
                   || (pos == upon && w == 'on' or 'upon')
                   || (pos == under && w == 'under' or 'underneath'
                                        or 'beneath' or 'behind')))
        {   own = wn;
            ! Make sure that PUT (BOOK) ON (TABLE) doesn't become PUT (BOOK ON TABLE):

            if (line_ttype-->pcount == PREPOSITION_TT)
            {   z = pcount;
                if (WordLeft(line_tdata-->z)) jump parseobj004;
                if ((line_token-->z)->0 & $20)
                {   do
                    {   if (WordLeft(line_tdata-->z)) jump parseobj004;
                        z++;
                    } until ((line_token-->z == ENDIT_TOKEN)
                              || (((line_token-->z)->0 & $10) == 0));
                }
                jump parseobj003;
            }
            .parseobj004;            

            z = 1;
            du = desc_used;
            ap = allow_plurals;

            allow_plurals = false;
            tglobal = ParseObj(parent(obj), 1);
            allow_plurals = ap;

            if (tglobal)
            {   desc_used = desc_used + du;
                c = c + z + tglobal;
                fl = 1;
                break;
            }
            desc_used = du;
            wn = own; break;
        }

        break;

    .pngotword;
        if (w->#dict_par1 & 4) parser_action = ##PluralFound;
        c++;
    }

    .parseobj003;
    if (fl == 0) rfalse;
    return c;
];

[ WordLeft w     own cw flag;
    own = wn;
    while ((cw = NextWordStopped()) ~= -1)
    {   if (flag)
        {   if (cw && (cw->#dict_par1) & 1) break;
            flag = 0;
        }
        if (cw == w) { wn = own; rtrue; }
        if (IsALinkWord(w)) flag = 1;
    }
    wn = own;
    rfalse;
];

[ MatchSelfRef obj w     g;

    if (obj hasnt male or female or neuter)
    {   if (obj has animate) g = LanguageAnimateGender;
        else g = LanguageInanimateGender;
    }
    if (obj has pluralname)
    {   if (w == 'themselves') rtrue;
    } else if (obj has male || g == male) { if (w == 'himself') rtrue; }
      else if (obj has female || g == female) { if (w == 'herself') rtrue; }
      else if (w == 'itself') rtrue;
    rfalse;
];

!                             #############################
!                               ALPHABETIZATION ROUTINES
!                             #############################

        ! GetLowercase (character)
        ! Returns the given character, converted to lowercase if it
        ! was an uppercase letter.

[ GetLowercase ch;
  if (ch >= 'A' && ch <= 'Z')
     return ch + UPPER_TO_LOWER;
  return ch;
];

        ! AlphabetizeAll (object, workflag flag)
        ! Sorts the children of the given object alphabetically by name,
        ! recursing downward through its descendants. If the workflag flag
        ! is set, only recurses down through objects with workflag set.

[ AlphabetizeAll obj f     x;

  x = child(obj);
  while (x)
  {  if (child(x) && (f == 0 || x has workflag))
        AlphabetizeAll(x, f);
     x = sibling(x);
  }
  AlphabetizeIn(obj);
];


        ! AlphabetizeIn (object)
        ! Sorts the children of |object| alphabetically by name.

[ AlphabetizeIn obj     x y z d n nc n1 fl a;

    a = action; action = ##Alphabetizing;

    x = child(obj);
    while ((y = sibling(x)) ~= 0)
        if (CompareAlpha(x, y) == y)
            move y to indir;
        else
            x = y;    

    nc = children(obj);
     d = nc;
     n = (nc + 1) / 2;

    while ((x = child(indir)) ~= 0)
    {
        y = GetNthChild(obj, n);
        fl = 0;
        for (::)
        {
            z = CompareAlpha(x, y, fl);
            if (z == 0 || d == 1)
            {
                if (z == x)
                    InsertBefore(y, x);
                else
                    InsertAfter(y, x);
                break;
            }
            else 
            {
                fl = 1;
                d = (d + 1) / 2;
                if (z == x)
                {
                    n = greaterof(n - d, 1);
                    y = GetNthChild(obj, n);
                }
                else
                {
                   n1 = lesserof(n + d, nc);
                    y = GetNthSibling(y, n1 - n);
                    n = n1;
                }
            }
        }
        nc++;
        d = nc;
        n = (nc + 1) / 2;
    }
    action = a;
];

        ! CompareAlpha (obj1, obj2)
        ! Returns the object whose name comes first alphabetically.

[ CompareAlpha a b fl     la lb c ch ln ch2;

    if (fl == 0)
    {   OpenBuffer(Byte1A);  print (name) a;  CloseBuffer(); }

    OpenBuffer(Byte2A);  print (name) b;  CloseBuffer();

    la = Byte1A-->0;
    lb = Byte2A-->0;
    ln = lesserof(la, lb) + WORDSIZE;

    for (c = WORDSIZE:c < ln:c++)
    {
        ch  = GetLowercase(Byte1A->c);
        ch2 = GetLowercase(Byte2A->c);
        if (ch > ch2) return b;
        if (ch < ch2) return a;
    }
    if (la > lb) return b;
    if (lb > la) return a;
    rfalse;
];


!                          #############################
!                                 STACK ROUTINES
!                          #############################


        ! Push (value, table)
        ! Pushes a word onto the front of a table

[ Push value tab     l;

     l = tab-->0 * 2 - 2;

    CopyBytes(tab + 2, tab + 4, l);
    tab-->1 = value;
];

        ! Pull (table)
        ! Pulls a value off the front of a table.

[ Pull tab     l value tl;

       tl = tab-->0;
    value = tab-->1;
        l = tl * 2 - 2;

    CopyBytes(tab + 4, tab + 2, l);
    tab-->tl = 0;
    return value;
];

        ! FindPath (start,finish,object[,maximum length])
        ! Finds the shortest path from |start| to |finish| for |object|,
        ! as allowed by the object's guide_path property, if provided.
        ! Result is stored in the object's path_moves, path_rooms, and
        ! path_length properties.

[ FindPath start finish obj max     x;

#ifdef DEBUG;
    if (metaclass(obj) ~= Object)
    {   print "***Error: FindPath called for a non-object.^";
        rfalse;
    }
    if (~~(obj provides path_moves))
    {   print "***Error: FindPath called for '",(name) obj,
              "', which has no path_moves property.^";
        rfalse;
    }
    if (~~(obj provides path_rooms))
    {   print "***Error: FindPath called for '",(name) obj,
              "', which has no path_rooms property.^";
        rfalse;
    }
    if (~~(obj provides path_length))
    {   print "***Error: FindPath called for '",(name) obj,
              "', which has no path_length property.^";
        rfalse;
    }
#endif;

#ifndef DEBUG;
    if (metaclass(obj) ~= Object
        || 0 == obj.&path_moves or obj.&path_rooms or obj.&path_length)
        rfalse;    
#endif;

    if (max == 0)  max = MAX_PATH_LENGTH;
    if (max > obj.#path_moves / WORDSIZE) max = obj.#path_moves / WORDSIZE;
    if (max > obj.#path_rooms / WORDSIZE) max = obj.#path_rooms / WORDSIZE;

    if (start == finish || max < 0 || max > MAX_PATH_LENGTH)
        rfalse;

    pathLengthG = max;
    give blank ~light;

    objectloop(x provides fpsa)
        x.fpsa = 1000;
    start.fpsa = 0;

    if (GuidePath(obj, start, finish, max))
        rfalse;

    if (obj provides guide_path && obj.guide_path(start, finish, max))
        rfalse;

    finding_path = obj;
    FindPath2(start, finish, 1);
    finding_path = 0;

    if (blank hasnt light)
        pathLengthG = 0;
    else if (obj ofclass Actors)
    {
        CopyWords(PathMovesA, obj.&path_moves, pathLengthG);
        CopyWords(PathRoomsA, obj.&path_rooms, pathLengthG);
        obj.path_length = pathLengthG;
    }
    return pathLengthG;
];


        ! FindPath2
        ! Recursive routine used by FindPath()

[ FindPath2 start finish len     x y;

    if (start == finish) return SetBestPath(len);

    if (len > pathLengthG) return;

    objectloop(x in Compass)
    {   y = GetDestination(start, x);
        if (y && y.fpsa > len)
        {   y.fpsa = len;
            Byte1A-->(len - 1) = x;
            Byte2A-->(len - 1) = y;
            FindPath2(y, finish, len + 1);
        }
    }
];

        ! SetBestPath
        ! Used by FindPath()

[ SetBestPath len;

    pathLengthG = len - 1;
#ifndef TARGET_GLULX;
    len = pathLengthG * 2;
    @copy_table  Byte1A  PathMovesA  len;
    @copy_table  Byte2A  PathRoomsA  len;
#endif;
#ifdef TARGET_GLULX;
    CopyWords(Byte1A, PathMovesA, pathlengthG);
    CopyWords(Byte2A, PathRoomsA, pathlengthG);
#endif;
    give blank light;
];


!                             #############################
!                                 OBJECT LISTING SYSTEM
!                             #############################

! ----------------------------------------------------------------------------
!  WriteListFrom(), a flexible object-lister taking care of plurals,
!  inventory information, various formats and so on.  This is used
!  by (almost) everything in the library which ever wants to list anything.
!
!  If there were no objects to list, it prints nothing and returns false;
!  otherwise it returns true.
!
!  o is the object, and style is a bitmap, whose bits are given by:
! ----------------------------------------------------------------------------

Default INDENT_SIZE = 2;

Constant NEWLINE_BIT       1;   !  New-line after each entry
Constant INDENT_BIT        2;   !  Indent each entry by depth
Constant FULLINV_BIT       4;   !  Full inventory information after entry
Constant ENGLISH_BIT       8;   !  English sentence style, with commas and and
Constant RECURSE_BIT      16;   !  Recurse downwards with usual rules
Constant ALWAYS_BIT       32;   !  Always recurse downwards
Constant TERSE_BIT        64;   !  More terse English style
Constant PARTINV_BIT     128;   !  Only brief inventory information after entry
Constant DEFART_BIT      256;   !  Use the definite article in list
Constant ISARE_BIT      1024;   !  Print " is" or " are" before list
Constant CONCEAL_BIT    2048;   !  Include objects with concealed:
Constant NOARTICLE_BIT  4096;   !  Print no articles, definite or not
Constant SORT_BIT       8192;   !  Alphabetize list
Constant NEWSTYLE_BIT  16384;   !  List with separated contents sentences.

Global invwide_style = (FULLINV_BIT + ENGLISH_BIT + RECURSE_BIT
                        + NEWSTYLE_BIT + SORT_BIT);
Global invtall_style = (FULLINV_BIT + INDENT_BIT + NEWLINE_BIT
                         + RECURSE_BIT + SORT_BIT);

Global locale_style = (ENGLISH_BIT + RECURSE_BIT + PARTINV_BIT
                        + TERSE_BIT + NEWSTYLE_BIT);
Global listatt;
Global pos__att;

[ PositionOf obj    rv p;

    p = parent(obj);

    if (obj has upon) rv = upon;
    if (obj has inside) { if (rv) jump positionoflab2; rv = inside; }
    if (obj has under) { if (rv) jump positionoflab2; rv = under; }
    if (obj has worn)  { if (rv) jump positionoflab2; rv = worn; }

    if (p)
    {
        if ((rv == upon && p hasnt supporter)
            || (rv == inside && p hasnt container)
            || (rv == under && p hasnt hider)
            || (rv == worn && p hasnt animate))
            jump positionoflab2;
    }
    return rv;
    .positionoflab2;
    return -1;
];

[ NextEntry o odepth;

    while ((o = sibling(o)) ~= 0)
        if ((lt_value == 0 or o.list_together)
            && (pos__att == 0 || o has pos__att)
            && (listatt == 0 || o has listatt
                   || (odepth > 0 && listatt == workflag))
            && (o hasnt concealed || c_style & CONCEAL_BIT))
            return o;
    rfalse;
];

[ ListEqual o1 o2;

    if (HasVisibleContents(o1, c_style)
        || HasVisibleContents(o2, c_style))
            rfalse;

    if (c_style & (FULLINV_BIT + PARTINV_BIT))
    {   if ((o1 hasnt worn && o2 has worn)
            || (o2 hasnt worn && o1 has worn)
            || (o1 hasnt light && o2 has light)
            || (o2 hasnt light && o1 has light))
            rfalse;
        if (o1 has container)
        {   if (o2 hasnt container)
                rfalse;
            if ((o1 has open && o2 hasnt open)
                || (o2 has open && o1 hasnt open))
                rfalse;
        }
        else if (o2 has container) rfalse;
    }

    if (PositionOf(o1) ~= PositionOf(o2))
        rfalse;

    return Identical(o1,o2);
];

[ SortTogether obj value     x y;
    x = child(obj);
    while (x)
    {   y = sibling(x);
        if (x.list_together ~= value) move x to outdir;
        x = y;
    }
    while (child(outdir)) move child(outdir) to obj;
];

[ SortOutList obj     i k l;
    .AP_SOL;
    for (i = obj:i:i = sibling(i))
    {   k = i.list_together;
        if (k)
        {   while((i = sibling(i)) ~= 0 && i.list_together == k)
                ;
            if (i == 0) rfalse;

            for (l = sibling(i):l:l = sibling(l))
                if (l.list_together == k)
                {   SortTogether(parent(obj), k);
                    obj = child(parent(obj));
                    jump AP_SOL;
                }
        }
    }
];

[ WriteBeforeEntry o depth sentencepos     flag;

    if (c_style & INDENT_BIT)
        print (spaces) (INDENT_SIZE * (depth + wlf_indent));

    if (c_style & FULLINV_BIT && o.invent)
    {   inventory_stage = 1;
        flag = PrintOrRun(o, invent, 1);
        if (flag == 1)
        {   if (c_style & ENGLISH_BIT)
            {   if (sentencepos < -1) print ", ";
                if (sentencepos == -1) print (string) AND__TX;
            }
            if (c_style & NEWLINE_BIT) new_line;
        }
    }
    return flag;
];

[ WriteAfterEntry o depth stack_p     hvc wtp flag flag2 comb x;

    if (listatt ~= workflag) x = listatt;
    hvc = HasVisibleContents(o, c_style, x);

! *** Indicate position (upon, inside, under) of child in vertical list:
    if (c_style & NEWLINE_BIT && (c_style & (FULLINV_BIT + PARTINV_BIT))
        && c_style & NEWSTYLE_BIT == 0
        && ((parent(o) has supporter) + (parent(o) has container) +
            (parent(o) has hider) + (parent(o) has animate) > 1))
    {   if (o has upon && parent(o) has supporter) L__M(##ListMiscellany, 501);
        if (o has inside && parent(o) has container) L__M(##ListMiscellany, 502);
        if (o has under && parent(o) has hider) L__M(##ListMiscellany, 503);
    }
! *** Add "(providing light)", "open", "closed", "empty", etc:
    if (c_style & PARTINV_BIT)
    {   if (o has light && actor.location hasnt light) comb = 1;
        if (o has container && o hasnt open)           comb = comb + 2;
        if (o has container && o has open or transparent
            && hvc == 0 && actor notin o)              comb = comb + 4;

        if (comb) L__M(##ListMiscellany, comb, o);
    }
    if (c_style & FULLINV_BIT)
    {   if (o.invent)
        {   inventory_stage=2;
            if (RunRoutines(o,invent))
            {   if (c_style & NEWLINE_BIT) new_line;
                rtrue;
            }
        }
        if (o has light && o has worn && c_style & NEWLINE_BIT)
        {    L__M(##ListMiscellany, 8); flag2=1; }
        else
        {   if (o has light) {  L__M(##ListMiscellany, 9, o); flag2=1; }
            if (o has worn && c_style & NEWLINE_BIT)
            {   L__M(##ListMiscellany, 10, o); flag2=1; }
        }
        if (o has container)
        {   if (o has openable)
            {   if (flag2==1) print (string) AND__TX;
                else L__M(##ListMiscellany, 11, o);
                if (o has open)
                {   if (hvc & ANY_INSIDE) L__M(##ListMiscellany, 12, o);
                    else L__M(##ListMiscellany, 13, o);
                }
                else
                {   if (o provides with_key && o has locked)
                        L__M(##ListMiscellany, 15, o);
                    else L__M(##ListMiscellany, 14, o);
                }

                flag2=1;
            }
            else
            if ((hvc & ANY_INSIDE == 0) && o has transparent)
            {   if (flag2 == 1) L__M(##ListMiscellany, 16, o);
                else L__M(##ListMiscellany, 17, o);
            }
        }
        if (flag2 == 1) print ")";
    }

    if (c_style & NEWLINE_BIT) new_line;

    if (c_style & (RECURSE_BIT + ALWAYS_BIT) == 0) return;

    if (hvc && c_style & NEWSTYLE_BIT == 0)
    {   if (c_style & TERSE_BIT) print " (";
        else if (c_style & ENGLISH_BIT) print ", ";

#ifndef TARGET_GLULX;
        @push lt_value; @push listing_together; @push listing_size;
#endif;
#ifdef TARGET_GLULX;
        @copy lt_value sp; @copy listing_together sp; @copy listing_size sp;
#endif;
        lt_value = 0; listing_together = 0; listing_size = 0;
        flag = pos__att;
        if (hvc & ANY_UPON)
        {   if (c_style & ENGLISH_BIT)
            {   if (hvc & MULTI_UPON) wtp = ARE2__TX; else wtp = IS2__TX;
                if (c_style & TERSE_BIT) L__M(##ListMiscellany, 19);
                else L__M(##ListMiscellany, 20);
                if (o has animate) print (string) WHOM__TX;
                else print (string) WHICH__TX;
                print (string) wtp;
            }
            pos__att = upon;
            WriteListR(child(o), depth + 1, stack_p);
        }
        if (hvc & ANY_INSIDE)
        {   if (c_style & ENGLISH_BIT)
            {   if (hvc & ANY_UPON) print (string) AND__TX;
                if (hvc & MULTI_INSIDE) wtp = ARE2__TX; else wtp = IS2__TX;
                if (c_style & TERSE_BIT) L__M(##ListMiscellany, 21);
                else L__M(##ListMiscellany, 22);
                if (o has animate) print (string) WHOM__TX;
                else print (string) WHICH__TX;
                print (string) wtp;
            }
            pos__att = inside;
            WriteListR(child(o), depth + 1, stack_p);
        }
        if (hvc & ANY_UNDER)
        {   if (c_style & ENGLISH_BIT)
            {   if (hvc & (ANY_INSIDE + ANY_UPON)) print (string) AND__TX;
                if (hvc & MULTI_UNDER) wtp = ARE2__TX; else wtp = IS2__TX;
                if (c_style & TERSE_BIT) L__M(##ListMiscellany, 50);
                else L__M(##ListMiscellany, 51);
                if (o has animate) print (string) WHOM__TX;
                else print (string) WHICH__TX;
                print (string) wtp;
            }
            pos__att = under;
            WriteListR(child(o), depth + 1, stack_p);
        }
        if (hvc & ANY_WORN)
        {   if (c_style & ENGLISH_BIT)
            {   if (hvc & (ANY_INSIDE + ANY_UPON + ANY_UNDER))
                    print (string) AND__TX;
                L__M(##ListMiscellany, 52);
            }
            pos__att = worn;
            WriteListR(child(o), depth + 1, stack_p);
        }
        if (hvc & ANY_HELD)
        {   if (c_style & ENGLISH_BIT)
            {   if (hvc & (ANY_INSIDE + ANY_UPON + ANY_UNDER + ANY_WORN))
                    print (string) AND__TX;
                L__M(##ListMiscellany, 54);
            }
            objectloop(x in o)
                if (positionof(x) == 0 
                    && (x hasnt concealed || c_style & CONCEAL_BIT))
                    give x workflag2;
                else
                    give x ~workflag2;
            pos__att = workflag2;
            WriteListR(child(o), depth + 1, stack_p);
        }

        if (c_style & TERSE_BIT) print ")";
#ifndef TARGET_GLULX;
        @pull listing_size; @pull listing_together; @pull lt_value;
#endif;
#ifdef TARGET_GLULX;
        @copy sp listing_size; @copy sp listing_together;
        @copy sp lt_value;
#endif;
    pos__att = flag;
    }
];

[ ListContents obj str att style depth     z hvc opatt fl;

    opatt = pos__att;
    if (style == 0) style = locale_style;
    hvc = HasVisibleContents(obj, style, att);
    if (hvc) { if (str) print (string) str; }
    else rfalse;
    if (style & NEWLINE_BIT && style & NEWSTYLE_BIT == 0)
        return WriteListFrom(child(obj), style, depth, att);
    if (hvc & ANY_WORN)
    {   L__M(##ListMiscellany, 504, obj);
        pos__att = worn;
        WriteNewStyleList(child(obj), style & ~ISARE_BIT, depth + 1, att);
        fl = 1;
    }
    if (hvc & ANY_HELD)
    {   if (hvc & ANY_WORN) L__M(##ListMiscellany, 505);
        else L__M(##ListMiscellany, 506, obj);
        pos__att = workflag2;
        objectloop(z in obj)
            if (PositionOf(z) == 0
                && (att == 0 or workflag || z has att))
                give z workflag2;
            else give z ~workflag2;
        WriteNewStyleList(child(obj), style & ~ISARE_BIT, depth + 1, att);
        fl = 1;
    }
    if (hvc & ANY_UPON)
    {   if (fl && style & NEWLINE_BIT == 0) print (string) PS__STR;
        L__M(##ListMiscellany, 507, obj);
        pos__att = upon;
        WriteNewStyleList(child(obj), style | ISARE_BIT, depth + 1, att);
        fl = 1;
    }
    if (hvc & ANY_INSIDE)
    {   if (fl && style & NEWLINE_BIT == 0) print (string) PS__STR;
        L__M(##ListMiscellany, 508, obj);
        pos__att = inside;
        WriteNewStyleList(child(obj), style | ISARE_BIT, depth + 1, att);
        fl = 1;
    }
    if (hvc & ANY_UNDER)
    {   if (fl && style & NEWLINE_BIT == 0) print (string) PS__STR;
        L__M(##ListMiscellany, 509, obj);
        pos__att = under;
        WriteNewStyleList(child(obj), style | ISARE_BIT, depth + 1, att);
    }
    pos__att = opatt;
];

[ WriteNewStyleList obj style depth att     y vatt str;

    ClearNamesPrinted();
    WriteTradList(obj, style, depth, att);
    if (blank has secret) { LMRaw(##Look, 501); give blank ~secret; }
    if (att ~= workflag) vatt = att;
    if (style & NEWLINE_BIT == 0) str = ". ";
    while (obj)
    {   y = sibling(obj);
        if ((style & CONCEAL_BIT || obj hasnt concealed)
            && (pos__att == 0 || obj has pos__att)
            && (att == 0 || obj has att || (depth && att == workflag)))
            {   ClearNamesPrinted();
                ListContents(obj, str, vatt, style, depth);
            }
        obj = y;
    }
];

[ WriteListFrom o style depth att;

    if (o == 0) rfalse;
    if (depth < 0) { wlf_indent = -depth; depth = 0; }
    else wlf_indent = 0;
    if (style & NEWSTYLE_BIT) return WriteNewStyleList(o, style, depth, att);
    WriteTradList(o, style, depth, att);
];

[ WriteTradList o style depth att     a fl ola;

    ola = listatt; listatt = att;
    a = action;
    action = ##Listing;
    if (o == child(parent(o))) fl = true;
    if (style & SORT_BIT) AlphabetizeAll(parent(o));

    if (fl)
    {   SortOutList(o); o = child(parent(o)); }
    fl = c_style; c_style = style;
    WriteListR(o, depth);
    c_style = fl;
    action = a;
    listatt = ola;
];

[ WriteListR o depth stack_pointer     classes_p sizes_p i j k k2 l m n q senc mr;

    if (depth > 0 && o == child(parent(o)))
    {   SortOutList(o); o = child(parent(o)); }

    if (listatt == workflag && depth > 0) i = 0; else i = listatt;

    for (::)
    {   if (o == 0) rfalse;
        if ((i && o hasnt i)
            || (c_style & CONCEAL_BIT == 0 && o has concealed)
            || (pos__att ~= 0 && o hasnt pos__att))
        {   o = sibling(o); continue; }
        break;
    }

    classes_p = match_classes + stack_pointer;
    sizes_p   = match_list + stack_pointer;

    for (i = o,j = 0:i && (j + stack_pointer) < 128:i=NextEntry(i,depth),j++)
    {   classes_p->j = 0;
        if (i.plural) k++;
    }

    if (c_style & ISARE_BIT)
    {   if (j == 1 && o hasnt pluralname)
            print (string) IS__TX; else print (string) ARE__TX;
        if (c_style & NEWLINE_BIT) print ":^"; else print (char) ' ';
        c_style = c_style - ISARE_BIT;
    }

    stack_pointer = stack_pointer + j + 1;

    if (k < 2) jump EconomyVersion;   ! It takes two to plural

    n = 1;
    for (i = o,k = 0:k < j:i = NextEntry(i, depth),k++)
        if (classes_p->k == 0)
        {
            classes_p->k = n; sizes_p->n = 1;

            l = NextEntry(i, depth);
            m = k + 1;
            while (l && m < j)
            {
                if (classes_p->m == 0 && i.plural && l.plural)
                {   if (ListEqual(i, l) == 1)
                    {   sizes_p->n = sizes_p->n + 1;
                        classes_p->m = n;
                    }
                }
                l = NextEntry(l, depth); m++;
            }
            n++;
        }
    n--;

    for (i=1, j=o, k=0: i<=n: i++, senc++)
    {   while (classes_p->k ~= i or -i) { k++; j = NextEntry(j, depth); }
        m = sizes_p->i;
        if (j == 0) mr = 0;
        else
        {  if (j.list_together == mr && mr ~= 0 or lt_value
                && metaclass(mr) == Routine or String)
                senc--;
            mr=j.list_together;
        }
    }
    senc--;
    for (i=1, j=o, k=0, mr=0: senc>=0: i++, senc--)
    {   while (classes_p->k ~= i or -i) { k++; j = NextEntry(j, depth); }
        if (j.list_together ~= 0 or lt_value)
        {   if (j.list_together==mr) { senc++; jump Omit_FL2; }
            k2 = NextEntry(j, depth);
            if (k2 == 0 || k2.list_together ~= j.list_together) jump Omit_WL2;
            k2 = metaclass(j.list_together);

            if (k2 == Routine or String)
            { 
                q = j; listing_size=1; l=k; m=i;
                while (m<n && q.list_together==j.list_together)
                {   m++;
                    while (classes_p->l ~= m or -m) { l++; q = NextEntry(q, depth); }
                    if (q.list_together==j.list_together) listing_size++;
                }

                if (listing_size==1) jump Omit_WL2;
                if (c_style & INDENT_BIT)
                    print (spaces) (INDENT_SIZE * (depth + wlf_indent));
                if (k2 == String)
                {   q = 0;
                    for (l=0:l<listing_size:l++) q = q + sizes_p->(l + i);
                    print (languagenumber) q," ",(string) j.list_together;
                    if (c_style & ENGLISH_BIT) print " (";
                    if (c_style & INDENT_BIT) print ":";
                    if (c_style & NEWLINE_BIT) new_line;
                }
                q = c_style;
                if (k2 ~= String)
                {   inventory_stage=1;
                    parser_one=j; parser_two=depth+wlf_indent;
                    if (RunRoutines(j,list_together)==1) jump Omit__Sublist2;
                }

#ifndef TARGET_GLULX;                
                @push lt_value; @push listing_together; @push listing_size;
#endif;
#ifdef TARGET_GLULX;
                @copy lt_value sp; @copy listing_together sp;
                @copy listing_size sp;
#endif;
                lt_value = j.list_together; listing_together = j; wlf_indent++;
                WriteListR(j, depth, stack_pointer); wlf_indent--;
#ifndef TARGET_GLULX;
                @pull listing_size; @pull listing_together; @pull lt_value;
#endif;
#ifdef TARGET_GLULX;
                @copy sp listing_size; @copy sp listing_together;
                @copy sp lt_value;
#endif;

                if (k2 == String)
                {   if (q & ENGLISH_BIT) print ")";
                }
                else
                {   inventory_stage=2;
                    parser_one=j; parser_two=depth+wlf_indent;
                    RunRoutines(j, list_together);
                }
                .Omit__Sublist2;
                if (q & NEWLINE_BIT && c_style & NEWLINE_BIT == 0)
                    new_line;
                c_style = q;
                mr = j.list_together;
                jump Omit_EL2;
            }
        }

        .Omit_WL2;
        if (WriteBeforeEntry(j,depth,-senc)==1) jump Omit_FL2;
        if (sizes_p->i == 1)
        {   if (c_style & NOARTICLE_BIT) print (name) j;
            else
            {   if (c_style & DEFART_BIT) print (the) j; else print (a) j;
            }
        }
        else
        {   if (c_style & DEFART_BIT)
                PrefaceByArticle(j, 1, sizes_p->i);
            print (languagenumber) sizes_p->i, " ";
            PrintOrRun(j,plural,1);
        }
        if (sizes_p->i > 1 && j hasnt pluralname)
        {   give j pluralname;
            WriteAfterEntry(j, depth, stack_pointer);
            give j ~pluralname;
        }
        else WriteAfterEntry(j,depth,stack_pointer);

        .Omit_EL2;
        if (c_style & ENGLISH_BIT)
        {   if (senc>1) print ", ";
            if (senc==1) print (string) AND__TX;
        }
        .Omit_FL2;
    }
    rtrue;

    .EconomyVersion;

    n = j;

    for (i=1, j=o: i<=n: j=NextEntry(j, depth), i++, senc++)
    {   if (j.list_together == mr && mr ~= 0 or lt_value    
            && metaclass(mr) == Routine or String)
            senc--;
        mr=j.list_together;
    }

    for (i=1, j=o, mr=0: i<=senc: j=NextEntry(j,depth), i++)
    {   if (j.list_together ~= 0 or lt_value)
        {   if (j.list_together==mr) { i--; jump Omit_FL; }
            k = NextEntry(j,depth);
            if (k == 0 || k.list_together ~= j.list_together) jump Omit_WL;
            k = metaclass(j.list_together);
          if (k == Routine or String)
          {   if (c_style & INDENT_BIT)
                    print (spaces) (INDENT_SIZE * (depth + wlf_indent));
              if (k == String)
              {   q=j; l=0;
                  do
                  {   q=NextEntry(q,depth); l++;
                  } until (q == 0 || q.list_together ~= j.list_together);
                  print (languagenumber) l, " ", (string) j.list_together;
                  if (c_style & ENGLISH_BIT) print " (";
                  if (c_style & INDENT_BIT) print ":";
                  if (c_style & NEWLINE_BIT) new_line;
              }
              q = c_style;
              if (k ~= String)
              {   inventory_stage=1;
                  parser_one=j; parser_two=depth+wlf_indent;
                  if (RunRoutines(j,list_together)==1) jump Omit__Sublist;
              }

#ifndef TARGET_GLULX;                
              @push lt_value; @push listing_together; @push listing_size;
#endif;
#ifdef TARGET_GLULX;
              @copy lt_value sp; @copy listing_together sp;
              @copy listing_size sp;
#endif;
              lt_value = j.list_together; listing_together = j; wlf_indent++;
              WriteListR(j,depth,stack_pointer); wlf_indent--;
#ifndef TARGET_GLULX;
              @pull listing_size; @pull listing_together; @pull lt_value;
#endif;
#ifdef TARGET_GLULX;
              @copy sp listing_size; @copy sp listing_together;
              @copy sp lt_value;
#endif;

              if (k == String)
              {   if (q & ENGLISH_BIT) print ")";
              }
              else
              {   inventory_stage=2;
                  parser_one=j; parser_two=depth+wlf_indent;
                  RunRoutines(j,list_together);
              }
             .Omit__Sublist;
              if (q & NEWLINE_BIT && c_style & NEWLINE_BIT == 0) new_line;
              c_style=q;
              mr=j.list_together;
              jump Omit_EL;
          }
      }
     .Omit_WL;
      if (WriteBeforeEntry(j, depth, i - senc) == 1) jump Omit_FL;
      if (c_style & NOARTICLE_BIT) print (name) j;
      else
      {   if (c_style & DEFART_BIT) print (the) j; else print (a) j;
      }
      WriteAfterEntry(j,depth,stack_pointer);

     .Omit_EL;
      if (c_style & ENGLISH_BIT)
      {   if (i==senc-1) print (string) AND__TX;
          if (i<senc-1) print ", ";
      }
     .Omit_FL;
  }
];

[ RunProperties sr     osr op1 f;

    osr = scope_reason;  scope_reason = sr;
    op1 = parser_one;    parser_one = 0;
    SearchScope(actor);
    if (parser_one) f = 1;
    scope_reason = osr;  parser_one = op1;
    return f;
];

[ ObjectPropertyAction obj prop act     a rv;

    a = action;  action = act;
    rv = RunRoutines(obj, prop);
    action = a;
    return rv;
];

    ! TryToAccess(object, flag)
    ! if flag is set, apply take/remove restrictions

[ TryToAccess x f     ancestor i j os;

    if (x == actor) rfalse;

    if (f && ((x has static && x has concealed) || x in FloatingHome))
        return ActionMessage(##Take, 10, x);

    ancestor = CommonAncestor(actor, x);

    if (ancestor == 0)
    {   if (x in FloatingHome) os = actor.location;
        else os = ObjectScopedBySomething(x);
        if (os)
        {   if (f && x has static) return ActionMessage(##Take, 7, os);
            else ancestor = CommonAncestor(actor, os);
        }
        else return ActionMessage(##Take, 8, x);
    }

    if (ancestor == 0) return ActionMessage(##Take, 8, x);

    if (f && ancestor == x) return ActionMessage(##Take, 4, x);

    i = parent(x);
    if (i hasnt animate && i notin Map && positionof(x) == 0)
        return ActionMessage(##Take, 7, i);

    if (actor ~= ancestor)
    {   i = parent(actor); j = actor;
        while (i ~= ancestor)
        {   if (j has inside && i has container
                && i hasnt open) return ActionMessage(##Open, 6, i);
            j = i;
            i = parent(i);
        }
    }

    if (os == 0 && x ~= ancestor)
    {   i = parent(x); j = x;
        while (i ~= ancestor)
        {   if (i has animate) return ActionMessage(##Take, 6, i);
            if (f && (i hasnt container or supporter or hider))
                return ActionMessage(##Take, 8, x);
             if (j has inside && i has container
                && i hasnt open) return ActionMessage(##Open, 6, i);
            j = i;
            i = parent(i);
        }
    }

    if (f && x has static) return ActionMessage(##Take, 11, x);

    rfalse;
];

[ AttemptAction act x y     ks rv mf af;

    ks = keep_silent;
    mf = multiflag;
    af = action_failed;
    multiflag = 0;
    if (actor == player)
    {
        keep_silent = true;
        ImplicitMessage(act, x, y);
    }
    <(act) x y>;
    keep_silent = ks;
    multiflag = mf;
    rv = action_failed;
    action_failed = af;
    return rv;
];

[ AttemptToHoldObject x;
    if (x in actor && x has worn && AttemptAction(##Disrobe, x))
        rtrue;
    return AttemptToTakeObject(x);
];

[ AttemptToTakeObject x;
    if (x in actor) rfalse;
    return AttemptAction(##Take, x);
];


[ BeforeRoutines      ;

    action_failed = true;
    if (GamePreRoutine() || (actor == player && RunRoutines(player, orders)))
        rtrue;
    if (RunProperties(MEDDLE_EARLY_REASON)
        || (noun && RunRoutines(noun, respond_early))
        || (second && RunRoutines(second, respond_early_indirect)))
        rtrue;

    rfalse;
];

[ OnRoutines     ;

    if (GameOnRoutine()) rtrue;
    if (RunProperties(MEDDLE_REASON)
        || (noun && RunRoutines(noun, respond))
        || (second && RunRoutines(second, respond_indirect)))
        rtrue;
    action_failed = false;
    rfalse;
];

[ AfterRoutines     ;

    if (RunProperties(MEDDLE_LATE_REASON)
        || (noun && RunRoutines(noun, respond_late))
        || (second && RunRoutines(second, respond_late_indirect)))
        rtrue;
    if (GamePostRoutine() || deadflag)
        rtrue;
    rfalse;
];

[ ActionIgnoresDarkness;

    if (action == ##Tell or ##Ask or ##Answer or ##Scream or ##Pray)
        rtrue;
    rfalse;
];

[ CountByOutcome n     c count;

    give blank ~pluralname;
    for (c = 1:c <= multicount:c++)
    {   if (multiple_outcome-->c == n)
        {   count++;
            if (count > 1) break;
            if (multiple_object-->c has pluralname)
                give blank pluralname;
        }
    }
    if (count > 1) give blank pluralname;
    return count;
];

[ ListByOutcome n     c count obj mo;

    count = CountByOutcome(n);
    if (count == 0) return;
    for (c = 1:c <= multicount:c++)
    {   if (multiple_outcome-->c == n)
        {   obj = multiple_object-->c;
            multiple_outcome-->c = parent(obj);
            move obj to OM__SysObj;
        }
    }

    if (multiphase == -2) print "But ";
    WriteListFrom(child(OM__SysObj), ENGLISH_BIT + DEFART_BIT);

    for (c = 1: c <= multicount:c++)
    {   obj = multiple_object-->c;
        if (obj in OM__SysObj)
        {   mo = multiple_outcome-->c;
            if (mo)
                move obj to mo;
            else remove obj;
            multiple_outcome-->c = n;
        }
    }
    last_name_printed = blank;
];

[ ActionMessage act n x     c lr hr oc pc fnr pnr nr mo;

    if (actor ~= player && TestScope(actor) == 0) rtrue;

    if (x == 0) x = noun;

    if (multiflag && narrative_mode)
    {   multiple_outcome --> multicount = n;
        if (multicount < multiple_object-->0) return;

        for (c = 1:c <= multicount:c++)
        {   mo = multiple_outcome-->c;
            if (mo < lr || lr == 0) lr = mo;
            if (mo > hr) { hr = mo; oc++; }
        }

        multiflag = 0; last_name_printed = 0;
        for (c = lr:c <= hr:)
        {   pc++;
            if (c == lr) multiphase = 1;
            else
            {   multiphase = 3;
                print ", ";
                if (pc == 2 && lr == 1) print "but ";
                else if (c == hr) print "and ";
            }
            last_name_printed = actor;
            L__M(action, c, blank);
            if (multiphase < 0) ListByOutcome(c);
            if (c == lr) multiphase = 2; else multiphase = 4;
            L__M(action, c, blank);
            if (c == hr) break;
            nr = hr;
            for (fnr = 1:fnr < multicount:fnr++)
            {   pnr = multiple_outcome-->fnr;
                if (pnr > c && pnr < nr) nr = pnr;
            }
            c = nr;
        }
        multiphase = 0;
        ".";
    }

    L__M(act, n, x);
];

        ! IsFoundIn (floater, room)
        !
        ! Returns true if the given floating object is present in the
        ! given room.

[ IsFoundIn x y     ;

    if (x provides found_in)
    {   if (metaclass(x.&found_in-->0) == Routine)
        {   if (x.found_in(y)) rtrue; }
        else if (WordInproperty(y, x, found_in)) rtrue;
    }
    else if (x provides door_to && x.#door_to > WORDSIZE
             && y == x.&door_to-->0 or x.&door_to-->1) rtrue;

    if (y provides shared && WordInProperty(x, y, shared))
    {   if (x provides moveYN && x.moveYN(y) == false) rfalse;
        rtrue;
    }
    rfalse;
];

        ! MoveTo (object, destination[, position attribute[, look flag])
        !
        ! Moves the object to the destination (object), giving it the
        ! specified attribute or a default. The look flag is used only
        ! when moving the =player=. If 1, no description is printed.
        ! If 2, a description is printed as if the player had walked into the
        ! room (and may be abbreviated). Otherwise, a full ##Look is
        ! performed.

[ MoveTo obj dest position flag     root ol;

    if (obj in dest) rfalse;
    move obj to dest;  give obj ~upon ~inside ~under ~worn;
    if (position) give obj position;
    else SetDefaultPosition(obj);
    root = rootof(dest);
    if (obj ofclass Actors)
        obj.location = root;
    ol = player.location;
    SetActorsLocations(obj, root);
    if (obj == player || player.location ~= ol)
    {   AdjustLight(1);
        switch(flag)
        {   1: NoteArrival(); ScoreArrival();
            2: player.perform(##Look, blank);
            default: player.perform(##Look);
        }
    }
];

[ SetActorsLocations obj loc     x;

    objectloop(x in obj)
    {   if (x ofclass Actors)
            x.location = loc;
        if (child(x)) SetActorsLocations(x, loc);
    }
];

[ YesOrNo i;
  for (::)
  {
#ifndef TARGET_GLULX;
      if (player.location == nothing || parent(player) == nothing) read buffer parse;
      else read buffer parse DrawStatusLine;
#endif;
#ifdef TARGET_GLULX;
      KeyboardPrimitive(buffer, parse);
#endif; ! TARGET_
      i=parse-->1;
      if (i==YES1__WD or YES2__WD or YES3__WD) rtrue;
      if (i==NO1__WD or NO2__WD or NO3__WD) rfalse;
      L__M(##Quit,1); print "> ";
  }
];

#ifndef TARGET_GLULX;

[ QuitSub; L__M(##Quit,2); if (YesOrNo()~=0) quit; ];

[ RestartSub; L__M(##Restart,1);
  if (YesOrNo()~=0) { @restart; L__M(##Restart,2); }
];

[ RestoreSub;
  restore Rmaybe;
  return L__M(##Restore,1);
  .RMaybe; L__M(##Restore,2);
];

[ SaveSub flag;
  #IFV5;
  @save -> flag;
  switch (flag) {
      0: L__M(##Save,1);
      1: L__M(##Save,2);
      2: L__M(##Restore,2);
  }
  #IFNOT;
  save Smaybe;
  return L__M(##Save,1);
  .SMaybe; L__M(##Save,2);
  #ENDIF;
];

[ VerifySub;
  @verify ?Vmaybe;
  jump Vwrong;
  .Vmaybe; return L__M(##Verify,1);
  .Vwrong;
  L__M(##Verify,2);
];

[ ScriptOnSub;
  transcript_mode = ((0-->8) & 1);
  if (transcript_mode) return L__M(##ScriptOn,1);
  @output_stream 2;
  if (((0-->8) & 1) == 0) return L__M(##ScriptOn,3);
  L__M(##ScriptOn,2); VersionSub();
  transcript_mode = true;
];

[ ScriptOffSub;
  transcript_mode = ((0-->8) & 1);
  if (transcript_mode == false) return L__M(##ScriptOff,1);
  L__M(##ScriptOff,2);
  @output_stream -2;
  if ((0-->8) & 1) return L__M(##ScriptOff,3);
  transcript_mode = false;
];

#endif;
#ifdef TARGET_GLULX;

[ QuitSub;
  L__M(##Quit,2);
  if (YesOrNo()~=0) {
    quit;
  }
];

[ RestartSub;
  L__M(##Restart,1);
  if (YesOrNo()~=0) { 
    @restart; 
    L__M(##Restart,2);
  }
];

[ RestoreSub res fref;
  fref = glk($0062, $01, $02, 0); ! fileref_create_by_prompt
  if (fref == 0) 
    jump RFailed;
  gg_savestr = glk($0042, fref, $02, GG_SAVESTR_ROCK); ! stream_open_file
  glk($0063, fref); ! fileref_destroy
  if (gg_savestr == 0) {
    jump RFailed;
  }

  @restore gg_savestr res;

  glk($0044, gg_savestr, 0); ! stream_close
  gg_savestr = 0;

.RFailed;
  L__M(##Restore,1);  
];

[ SaveSub res fref;
  fref = glk($0062, $01, $01, 0); ! fileref_create_by_prompt
  if (fref == 0) 
    jump SFailed;
  gg_savestr = glk($0042, fref, $01, GG_SAVESTR_ROCK); ! stream_open_file
  glk($0063, fref); ! fileref_destroy
  if (gg_savestr == 0) {
    jump SFailed;
  }

  @save gg_savestr res;

  if (res == -1) {
    ! The player actually just typed "restore". We're going to print
    !  L__M(##Restore,2); the Z-Code Inform library does this correctly
    ! now. But first, we have to recover all the Glk objects; the values
    ! in our global variables are all wrong.
    GGRecoverObjects();
    glk($0044, gg_savestr, 0); ! stream_close
    gg_savestr = 0;
    return L__M(##Restore,2);
  }

  glk($0044, gg_savestr, 0); ! stream_close
  gg_savestr = 0;

  if (res == 0)
    return L__M(##Save,2);

.SFailed;
  L__M(##Save,1);
];

[ VerifySub res;
  @verify res;
  if (res == 0)
    return L__M(##Verify,1);
  L__M(##Verify,2);
];

[ ScriptOnSub;
  if (gg_scriptstr ~= 0)
    return L__M(##ScriptOn,1);

  if (gg_scriptfref == 0) {
    ! fileref_create_by_prompt
    gg_scriptfref = glk($0062, $102, $05, GG_SCRIPTFREF_ROCK); 
    if (gg_scriptfref == 0) 
      jump S1Failed;
  }
  ! stream_open_file
  gg_scriptstr = glk($0042, gg_scriptfref, $05, GG_SCRIPTSTR_ROCK); 
  if (gg_scriptstr == 0)
    jump S1Failed;

  glk($002D, gg_mainwin, gg_scriptstr); ! window_set_echo_stream
  L__M(##ScriptOn,2);
  VersionSub();
  return;

.S1Failed;
  L__M(##ScriptOn,3);  
];

[ ScriptOffSub;
  if (gg_scriptstr == 0)
    return L__M(##ScriptOff,1);

  L__M(##ScriptOff,2);
  glk($0044, gg_scriptstr, 0); ! stream_close
  gg_scriptstr = 0;
];

#endif; ! TARGET_;

[ NotifyOnSub; notify_mode = true; L__M(##NotifyOn); ];
[ NotifyOffSub; notify_mode = false; L__M(##NotifyOff); ];

! ----------------------------------------------------------------------------
!   The scoring system
! ----------------------------------------------------------------------------

Object finding_items
  with
    points 0,
    short_name [; return LMRaw(##FullScore, 2); ],
    number 30000;

Object visiting_places
  with
    points 0,
    short_name [; return LMRaw(##FullScore, 3); ],
    number 30001;

[ ScoreSub;
  L__M(##Score);
  PrintRank();
];

[ Achieved obj     x;

    if (obj in AchievedTasks) rfalse;
    score = score + obj.points;
    give obj general proper;

    if (child(AchievedTasks) == 0)
    {   move obj to AchievedTasks;
        rtrue;
    }

    objectloop(x in AchievedTasks)
    {   if (x.number > obj.number)
        {   InsertBefore(x, obj);
            rtrue;
        }
    }

    InsertLast(AchievedTasks, obj);
];

[ PANum m n;
  print "  ";
  n=m;
  if (n<0)    { n=-m; n=n*10; }
  if (n<10)   { print "   "; jump panuml; }
  if (n<100)  { print "  "; jump panuml; }
  if (n<1000) { print " "; }
.panuml;
  print m, " ";
];

[ FullScoreSub     x y;

    ScoreSub();
    if (child(AchievedTasks) == 0) rfalse;

    new_line;
    L__M(##FullScore,1);
    x = child(AchievedTasks);
    while (x)
    {   y = sibling(x);
        PANum(x.points);
        print (name) x;
        new_line;
        x = y;
    }

    new_line;
    PANum(score);
    L__M(##FullScore,4);
];    

!                          #############################
!                                 VERB ROUTINES
!                          #############################

                                                                             !~~~~~~~~~~!
!----------------------------------------------------------------------------! ExitsSub !
! Lists the apparent exits from a room.

[ ExitsSub     loc dest x y tsets c fl;

    if (InDark(actor)) return ActionMessage(##Exits, 1);
    if (actor ~= player) return ActionMessage(##Exits, 7);
    loc = actor.location;
    finding_path = ExitsSub;

    objectloop(x in Compass) give x ~workflag;

    objectloop(x in Compass)
    {   if (x has workflag) continue;
        give x workflag;
        dest = destorunknown(loc, x);
        if (dest)
        {   tsets++;
            if (dest ~= blank)
                objectloop(y in Compass)
                    if (y hasnt workflag && destorunknown(loc, y) == dest)
                    {   give y workflag;
                        fl = 1;
                    }
        }
    }

    if (tsets == 0) return L__M(##Exits, 2);
    if (tsets == 1 && fl == 0) L__M(##Exits, 6);
    else L__M(##Exits, 3);

    objectloop(x in Compass)
    {   if (x hasnt workflag) continue;
        give x ~workflag;
        dest = destorunknown(loc, x);
        if (dest)
        {   print (name) x;
            if (dest ~= blank)
            {   c = 0;
                objectloop(y in Compass)
                    if (y has workflag && destorunknown(loc, y) == dest)
                        c++;
                objectloop(y in Compass)
                    if (y has workflag && destorunknown(loc, y) == dest)
                    {   if (c == 1) print (string) OR__TX;
                        else if (c) print ", ";
                        print (name) y;
                        give y ~workflag;
                        c--;
                    }
                L__M(##Exits, 4, dest);
            }
            tsets--;
            if (tsets == 1) print (string) OR__TX;
            else if (tsets) print ", ";
        }
    }

    finding_path = 0;
    ".";
];

[ destorunknown loc x     dest;
    dest = GetDestination(loc, x);
    if (dest && dest hasnt known) return blank;
    return dest;
];

[ LeaveSub;
    if (noun == actor) return ActionMessage(##Leave, 1, noun);
    if (IndirectlyContains(noun, actor)) <<Exit noun>>;
    if (noun has animate && noun notin actor) <<Go>>;
    <<Drop noun>>;
];


#IFNDEF NO_PLACES;
[ PlacesSub     x fl;

    ActionMessage(##Places, 1);
    WriteListFrom(child(Map), ENGLISH_BIT+DEFART_BIT+SORT_BIT+CONCEAL_BIT,
                  0, visited);
    print ".^";
    objectloop(x in Map)
        if (x has known && x hasnt visited)
        {   give x workflag; fl = 1; }
        else
            give x ~workflag;
    if (fl)
    {   ActionMessage(##Places, 2);
        WriteListFrom(child(Map), ENGLISH_BIT+DEFART_BIT+SORT_BIT+CONCEAL_BIT,
                      0, workflag);
        ".";
    }
];
#ENDIF;


        ! SwitchSub

[ SwitchSub;
    if (noun has on) <<SwitchOff noun>>;
    <<SwitchOn noun>>;
];

[ InvWideSub;
  inventory_style = invwide_style;
  <Inv>;
];

[ InvTallSub;
  inventory_style = invtall_style;
  <Inv>;
];


[ InvSub     x y nwflag is wflag spfl invent_late_flag last_printed;

    if (HasVisibleContents(actor) == 0)
    {   ActionMessage(##Inv, 1);            ! Nothin'
        jump skipinv;
    }

    if (actor ~= player)
    {   if (TestScope(actor) == 0) jump skipinv;
        is = inventory_style;
        inventory_style = FULLINV_BIT + ENGLISH_BIT + RECURSE_BIT;
    }

    if (inventory_style == 0) return InvTallSub();

    x = child(actor);
    while(x)
    {
        y = sibling(x);
        if (x hasnt concealed)
        {   if (x provides invent_late
                && (metaclass(x.invent_late) == String || x.invent_late(1)))
                {   give x concealed workflag2;
                    if (x has worn)
                        invent_late_flag = invent_late_flag | ANY_WORN;
                    else invent_late_flag = invent_late_flag | ANY_HELD;
                }
            else 
            {   give x ~workflag2;
                if (x has worn)
                {   wflag = true;
                    give x ~workflag;
                }
                else
                {   nwflag = true;
                    give x workflag;
                }
            }
        }
        x = y;
    }

    if (nwflag)
    {   L__M(##Inv, 2); ! Preface to held list
        WriteListFrom(child(actor), inventory_style, -1, workflag);
        if (wflag == 0 && invent_late_flag == 0)
        {   L__M(##Inv, 3); jump skipinv; }
        last_printed = 1;
    }

    if (invent_late_flag & ANY_HELD)
    {   if (last_printed)
        {   L__M(##Inv, 4); 
            spfl = true;
        }
        objectloop(x in actor)
            if (x has workflag2 && x hasnt worn)
            {   if (inventory_style & NEWLINE_BIT == 0 && spfl) print " ";
                if (PrintOrRun(x, invent_late, inventory_style & NEWLINE_BIT) == 0)
                spfl = true;
                give x ~concealed;
            }
        if (wflag == 0 && invent_late_flag & ANY_WORN == 0)
        {   L__M(##Inv, 7); jump skipinv; }
        last_printed = 2;
    }

    if (wflag)
    {   if (last_printed == 1) L__M(##Inv, 5);
        else if (last_printed == 2) L__M(##Inv, 8);
        else L__M(##Inv, 10);
        objectloop(x in actor)
            if (x has worn) give x workflag ~worn;
            else give x ~workflag;
        WriteListFrom(child(actor), inventory_style, -1, workflag);
        objectloop(x in actor) if (x has workflag) give x worn;
        if (invent_late_flag & ANY_WORN == 0)
        {   L__M(##Inv, 11); jump skipinv; }
        last_printed = 3;
    }
    
    if (invent_late_flag & ANY_WORN)
    {  spfl = false; 
       switch(last_printed) {
            1: L__M(##Inv, 6);
            2: L__M(##Inv, 9);
            3: L__M(##Inv, 12); spfl = true;
        }
        objectloop(x in actor)
            if (x has workflag2 && x has worn)
            {   if (inventory_style & NEWLINE_BIT == 0 && spfl) print " ";
                if (PrintOrRun(x, invent_late, inventory_style & NEWLINE_BIT) == 0)
                spfl = true;
                give x ~concealed;
            }
        L__M(##Inv, 13);
    }

   .skipinv;
    if (is) inventory_style = is;
    AfterRoutines();
];

! ----------------------------------------------------------------------------
!   The object tree and determining the possibility of moves
! ----------------------------------------------------------------------------

[ CommonAncestor o1 o2     x;
  !  Find the nearest object indirectly containing o1 and o2,
  !  or return 0 if there is no common ancestor.

  while (o1)
  {
      x = o2;
      while (x)
      {   if (x == o1) return o1;
          x = parent(x);
      }
      o1 = parent(o1);
  }
  rfalse;
];

  !  Does o1 indirectly contain o2, and if so, how?

[ IndirectlyContains obj2 obj     x pos;

    if (obj == obj2) return -1;

    x = obj;
    while (x ~= obj2)
    {   obj = x;
        x = parent(x);
        if (x == 0) rfalse;
    }

    pos = PositionOf(obj);
    if (pos) return pos;
    return -1;
];

Global sought_object;

[ OSBS_LOS obj     addr;
    
    if (obj.add_to_scope == 0) rfalse;
    addr = obj.&add_to_scope;
    if (metaclass(addr-->0) == Routine) rfalse;
    if (FindByWord(sought_object, addr, obj.#add_to_scope/WORDSIZE) ~= -1)
        sought_object = obj;

];

[ ObjectScopedBySomething item;

    .objectscopedbysomethinglab01;
    sought_object = item;
    LoopOverScope(OSBS_LOS, actor);
    if (sought_object ~= item) return sought_object;
    item = parent(item);
    if (item) jump objectscopedbysomethinglab01;
    rfalse;
];

! ----------------------------------------------------------------------------
!   Object movement verbs
! ----------------------------------------------------------------------------

[ TakeFromUnderSub;

    if (noun hasnt under)
        return ActionMessage(##Take, 20);

    <<Take noun second>>;
];

[ TakeSub     i k x y os fl ol;

    if (second && noun notin second) return ActionMessage(##Take, 20);
    if (second == 0 && parent(noun))
    {   second = parent(noun);
        if (RunRoutines(second, respond_early_indirect)) rtrue;
    }

    if (noun in actor) return ActionMessage(##Take, 5);
    if (noun == actor) return ActionMessage(##Take, 2);
    if (noun has animate
        && ((~~(noun provides allow_take)) || noun.allow_take() == false))
        return ActionMessage(##Take, 3);
    if (noun in Compass) return ActionMessage(##Take, 21);
    if (TryToAccess(noun, true)) rtrue;

    if (CurrentCarryingCapacity(actor) < 1)
    {   objectloop(i in actor && IsASack(i) && CurrentInsideCapacity(i) > 0)
        {   objectloop(k in actor && k ~= i && k hasnt worn or light)
            {
                if (AttemptAction(##Insert, k, i)) rtrue;
                jump maderoom;
            }
        }
        return ActionMessage(##Take, 12);
    }

    .maderoom;
    if (OnRoutines()) rtrue;

    ol = parent(noun);
    os = PositionOf(noun);
    if (os == worn or -1) os = 0;

    move noun to actor;
    give noun ~concealed ~under ~inside ~upon;
    if (actor == player) NoteObjectAcquisitions();

    if (noun has hider)
    {   x = child(noun);
        while (x)
        {   y = sibling(x);
            if (x has under) { move x to blank; give x ~under; }
            x = y;
        }
        if (children(blank) > ContainsByAttribute(blank, concealed))
        {   if (0 == multiflag or narrative_mode)
            {   ActionMessage(##Take, 22);
                WriteListFrom(child(blank), ENGLISH_BIT + RECURSE_BIT + PARTINV_BIT +
                    TERSE_BIT + NEWSTYLE_BIT);
                print ".^";
                fl = true;
            }
            while((x = child(blank)) ~= 0)
            {   move x to ol;
                if (os) give x os;
            }
        }
    }

    if (AfterRoutines()) rtrue;
    if (keep_silent || fl) rtrue;
    ActionMessage(##Take, 1, noun);
];

[ DropSub     p;

    if (noun == actor) return ActionMessage(##Drop, 4);
    if (noun in parent(actor)
        && PositionOf(noun) == PositionOf(actor))
            return ActionMessage(##Drop, 2);
    if (noun notin actor) return ActionMessage(##Drop, 3);

    if (noun has worn)
    {   if (multiflag || narrative_mode) return ActionMessage(##Drop, 5, noun);
            if (AttemptAction(##Disrobe, noun)) rtrue;
            
    }

    if (OnRoutines()) rtrue;

    p = PositionOf(actor);
    if (p == upon) <<PutOn noun parent(actor)>>;
    if (p == inside) <<Insert noun parent(actor)>>;
    if (p == under) <<PutUnder noun parent(actor)>>;

    MoveTo(noun, parent(actor));

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##Drop, 1, noun);
];

[ PutUnderSub     ancestor;

    if (noun in second && noun has under) return ActionMessage(##Insert, 4);
    if (0 == narrative_mode or multiflag)
    { if (AttemptToHoldObject(noun)) return ActionMessage(##PutUnder, 5);
    }
    else if (noun notin actor || noun has worn) return ActionMessage(##PutUnder, 5);

    ancestor = CommonAncestor(noun, second);
    if (ancestor == noun) return ActionMessage(##PutUnder, 2);
    if (TryToAccess(second)) rtrue;

    if (second hasnt hider) return ActionMessage(##PutUnder, 3);
    if (ancestor == actor) return ActionMessage(##PutUnder, 6);
    if (CurrentUnderCapacity(second) < 1)
        return ActionMessage(##PutUnder, 4);

    if (OnRoutines())
        rtrue;

    move noun to second;
    give noun under ~upon ~inside;

    if (AfterRoutines() || keep_silent)
        rtrue;
    ActionMessage(##PutUnder, 1, noun);
];

[ PutOnSub     ancestor;

    if (noun in second && noun has upon) return ActionMessage(##Insert, 4);
    if (noun == actor) <<Enter second>>;
    if (second == actor) <<Wear noun>>;
    if (0 == narrative_mode or multiflag)
    { if (AttemptToHoldObject(noun)) return ActionMessage(##PutOn, 5);
    }
    else if (noun notin actor || noun has worn) return ActionMessage(##PutOn, 5);

    ancestor = CommonAncestor(noun, second);
    if (ancestor == noun) return ActionMessage(##PutOn, 2);
    if (TryToAccess(second)) rtrue;

    if (second hasnt supporter) return ActionMessage(##PutOn, 3);
    if (ancestor == actor) return ActionMessage(##PutOn, 4);
    if (CurrentuponCapacity(second) < 1) return ActionMessage(##PutOn, 6);

    if (OnRoutines())
        rtrue;

    MoveTo(noun, second, upon);

    if (AfterRoutines() || keep_silent)
        rtrue;
    ActionMessage(##PutOn, 1);
];

[ InsertSub     ancestor;

    if (second == ddir) <<Drop noun>>;
    if (noun in second && noun has inside) return ActionMessage(##Insert, 4);
    if (0 == narrative_mode or multiflag)
    {   if (AttemptToHoldObject(noun)) rtrue;
    }
    else if (noun notin actor || noun has worn) return ActionMessage(##Insert, 3);
    if (noun == actor) <<Enter second>>;

    if (second hasnt container) return ActionMessage(##Insert, 2);

    if (second hasnt open
        && ((narrative_mode && multiflag) || AttemptAction(##Open, second)))
        return ActionMessage(##Insert, 6);

    ancestor = CommonAncestor(noun, second);
    if (ancestor == noun) return ActionMessage(##Insert, 5);
    if (TryToAccess(second)) rtrue;

    if (CurrentInsideCapacity(second) < 1) return ActionMessage(##Insert, 7);

    if (OnRoutines())
        rtrue;
    MoveTo(noun, second, inside);

    if (AfterRoutines() || keep_silent)
        rtrue;
    ActionMessage(##Insert, 1);
];

! ----------------------------------------------------------------------------
!   Empties and transfers are routed through the actions above
! ----------------------------------------------------------------------------

[ TransferSub;

    if (AttemptToHoldObject(noun)) rtrue;
    if (second has supporter) <<PutOn noun second>>;
    if (second has container) <<Insert noun second>>;
    if (second == ddir) <<Drop noun>>;
    <<Insert noun second>>;
];

[ EmptySub     x y;

    if (second == nothing) second = ddir;
    if (noun == second) return ActionMessage(##Empty, 4);

    if (TryToAccess(noun, true)) rtrue;
    if (noun hasnt container or supporter) return ActionMessage(##Empty, 1);
    if (noun has container && noun hasnt open && AttemptAction(##Open, noun))
        rtrue;
    if (second ~= ddir)
    {   if (second hasnt container or supporter)
            return ActionMessage(##Empty, 1, second);
        if (second hasnt supporter or open)
            return ActionMessage(##Empty, 2, second);
    }
    x = child(noun);
    if (x == 0) return ActionMessage(##Empty, 3);

    while (x)
    {   y = sibling(x);
        <Transfer x second>;
        if (action_failed || TestScope(second, actor) == 0) rtrue;
        x = y;
    }
];

! ----------------------------------------------------------------------------
!   Gifts
! ----------------------------------------------------------------------------

[ GiveSub;

    if (AttemptToHoldObject(noun)) rtrue;
    if (second == actor) return ActionMessage(##Give, 1);
    if (TryToAccess(second)) rtrue;
    if (OnRoutines() || AfterRoutines()) rtrue;
    if (noun in second) return ActionMessage(##Take, 1, noun);
    ActionMessage(##Give, 3, second);
];

[ ShowSub;
    if (AttemptToTakeObject(noun)) rtrue;
    if (second == actor) <<Examine noun>>;
    if (OnRoutines() || AfterRoutines()) rtrue;
    ActionMessage(##Show, 1, noun);
];

! ----------------------------------------------------------------------------
!   Travelling around verbs
! ----------------------------------------------------------------------------

[ EnterInSub;
    if (noun provides door_to) <<Go noun>>;
    return EnterSub(inside);
];
[ EnterOnSub; return EnterSub(upon); ];    
[ EnterUnderSub; return EnterSub(under); ];

[ EnterSub p     can_get_on can_get_in can_get_under;

    if (p == 0 or inside)
    {   if (noun provides door_to) <<Go noun>>;
        if (noun in compass) <<Go noun>>;
    }

    if (IndirectlyContains(player, noun)) return ActionMessage(##Enter, 4);
    if (~~(noun provides allow_entry)) return ActionMessage(##Enter, 2);
    if (noun has supporter && noun.allow_entry(upon)) can_get_on = true;
    if (noun has container && noun.allow_entry(inside)) can_get_in = true;
    if (noun has hider && noun.allow_entry(under)) can_get_under = true;
    if (can_get_on + can_get_in + can_get_under == 0)
        return ActionMessage(##Enter, 2);

    if (p == 0)
    {   if (can_get_in)
        {   p = inside; action = ##EnterIn;
            if (BeforeRoutines()) rtrue;
        }
        else if (can_get_on)
        {   p = upon; action = ##EnterOn;
            if (BeforeRoutines()) rtrue;
        }
        else return ActionMessage(##Enter, 2);
    }

    if ((p == upon && can_get_on == false)
        || (p == inside && can_get_in == false)
        || (p == under && can_get_under == false))
        return ActionMessage(action, 3);

    if (actor in noun)
    {   if (actor has p) return ActionMessage(action, 2);
        if (AttemptAction(##Exit, parent(actor))) rtrue;
    }

    if (p == inside && noun hasnt open && AttemptAction(##Open, noun)) rtrue;

    if (noun in Map)
    {   if (actor.location == parent(noun)) return ActionMessage(##Enter, 3);
        return ActionMessage(##Enter, 5);
    }
    if (actor notin parent(noun) || PositionOf(actor) ~= PositionOf(noun))
    {   if (parent(noun) has animate) return ActionMessage(##Enter, 7);
        return ActionMessage(##Enter, 6);
    }

    if (OnRoutines()) rtrue;
    MoveTo(actor, noun, p, 1);

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(action, 1);
    if (actor == player) Locale(noun);
];

[ GetOffSub;

    if (actor notin noun || actor hasnt upon)
        return ActionMessage(##GetOff, 2);
    <<Exit>>;
];

[ ExitFromSub;

    if (IndirectlyContains(noun, actor) == false) return ActionMessage(##Exit, 3);
    if (actor notin noun) return ActionMessage(##Go, 1, parent(actor));
    if (noun == actor.location)
    {   if (TestExit(noun, outdir)) <<Go outdir>>;
        return ActionMessage(##Go, 15);
    }
    <<Exit>>;
];

[ ExitSub     p ppos mes;

    p = parent(actor);
    second = p;
    if (RunRoutines(second, respond_early_indirect)) rtrue;
    if (p == actor.location)
    {   if (TestExit(p, outdir)) <<Go outdir>>;
        return ActionMessage(##Exit, 1);
    }
    if (p has container && p hasnt open && actor has inside)
        return ActionMessage(##Exit, 2, p);

    if (OnRoutines()) rtrue;
    mes = ##ExitFromInside;
    if (actor has upon) mes = ##ExitFromUpon;
    if (actor has under) mes = ##ExitFromUnder;
    move actor to parent(p);
    give actor ~upon ~inside ~under;
    ppos = PositionOf(p);
    if (ppos ~= 0 or -1 or worn) give actor ppos;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(mes, 1, p);
    if (actor == player) player.perform(##Look, blank);
];

[ VagueGoSub; ActionMessage(##VagueGo); ];

[ GoInSub;
    <<Go indir>>;
];

[ GoSub     loc movewith i j k df ol dir x;

    if (noun == 0) return ActionMessage(##Go, 15);

     df = InDark(actor);
    loc = actor.location;
      i = parent(actor);

    if (noun == udir or ddir && i has supporter && actor has upon)
        <<Exit>>;

    if (i ~= loc)
    {   k = RunRoutines(i, respond_early);
        if (k == 0) return ActionMessage(##Go, 1, i);
        if (k == 2 or 3) rfalse;
        movewith = i;
    }

    if (noun provides door_to)
    {   if (metaclass(loc.&dirs-->0) == Object)
        {   i = FindByWord(noun, loc.&dirs,
                           loc.#dirs / WORDSIZE);
            if (i ~= -1)
            {   i = loc.&dirs-->(i-1);
                <<Go i>>;
            }
        }
        else
        {   #ifndef TARGET_GLULX; @push finding_path;
            #ifnot; @copy finding_path sp;
            #endif;
            finding_path = ExitsSub; i = 0;
            objectloop(x in Compass)
                if (loc.dirs(x) == noun) { i = x; break; }
            #ifndef TARGET_GLULX; @pull finding_path;
            #ifnot; @copy sp finding_path;
            #endif;
            if (i) <<Go i>>;
        }
        j = noun;
    }
    else
    {   j = GetDestination(i, noun, 1);  if (j == 1) rtrue;
        k = metaclass(j);
        if (k == String) 
        {   if (actor == player) print_ret (string) j;
            rtrue;
        }
        if (j == 0 || k ~= Object)
        {
            if (actor == player && i provides cant_go
                && PrintOrRun(i, cant_go)) rtrue;
            return ActionMessage(##Go, 2);
        }

    }

    if (j provides door_to)
    {   dir = noun;  df = InDark(actor);
        action = ##EnterIn;  noun = j;
        if (BeforeRoutines()) rtrue;

        if (j hasnt open && AttemptAction(##Open, j)) rtrue;
        if (j.#door_to > WORDSIZE)
        {   if (loc == j.&door_to-->0) j = j.&door_to-->1;
            else if (loc == j.&door_to-->1) j = j.&door_to-->0;
            else return ActionMessage(##Go, 6, j);
        }
        else
        {   if (metaclass(j.door_to) == String) 
            {   if (actor == player) print_ret (string) j.door_to;
                rtrue;
            }
            k = j;
            j = j.door_to(loc);
            if (j == 0) return ActionMessage(##Go, 6, k);
        }
        if (OnRoutines()) rtrue;
        noun = dir; action = ##Go;
    }

    if (noun in compass && OnRoutines()) rtrue;

    if (actor ~= player)
    {   if (noun in compass) ActionMessage(##Go, 5001, noun);
        else ActionMessage(##Go, 5003, noun);
    }

    if (movewith) move movewith to j;
    else move actor to j;

    actor.location = rootof(j);
    ol = player.location;
    SetActorsLocations(actor, rootof(j));

    if (actor == player || player.location ~= ol)
    {   if (InDark(actor)) lightflag = 0;
        else lightflag = 1;
    }
    else
    {   if (noun in compass) ActionMessage(##Go, 5002, noun);
        else ActionMessage(##Go, 5004, noun);
    }

    if (df && InDark(actor))
    {
        DarkToDark(actor);
        if (deadflag) rtrue;
    }
    if (actor == player || player.location ~= ol)
    {   AdjustLight();
        if (AfterRoutines() || keep_silent) rtrue;
        player.perform(##Look, blank);
    }
];

[ PushDirSub;

    if (parent(actor) ~= actor.location)
        return ActionMessage(##Go, 1, parent(actor));
    if (TryToAccess(noun)) rtrue;
    if (second notin compass) return ActionMessage(##PushDir, 2);
    if (~~(noun provides allow_push)) return ActionMessage(##PushDir, 1);
    if (noun.allow_push(second) == 0) return ActionMessage(##PushDir, 3);

    if (OnRoutines()) rtrue;    
    move noun to actor;
    <Go second>;
    MoveTo(noun, actor.location);

    AfterRoutines();
];

! ----------------------------------------------------------------------------

[ SayWhatsOn obj;
    if (ListContents(obj, 0, upon)) ".";
    rfalse;
];

[ SayWhatsUnder obj;
    if (ListContents(obj, 0, under)) ".";
    rfalse;
];

[ SayWhatsIn obj;
    if (ListContents(obj, 0, inside)) ".";
    rfalse;
];

[ ContainsByAttribute obj att fl     x;

    objectloop(x in obj) if (x has att && (x hasnt concealed || fl)) rtrue;
    rfalse;
];

[ CountContentsByAttribute obj att     x c;

    objectloop(x in obj) if (x has att) c++;
    return c;
];

[ HandleDescribe obj     text rv;

    rv = PrintOrRun(obj, describe, 1);
    if (metaclass(obj.&describe-->0) == String)
        rv = 2;
    if (rv == 2 or 3)
    {   if (rv == 2) text = " "; else text = "^";
        SetNamePrinted(obj);
        if (obj hasnt known or secret)
            give obj known;
        if (ListContents(obj, text, 0, 0, 1)) print ".";
        new_line;
    }
    return rv;
];

        ! Locale (describe in,text,also text)

[ Locale descin text1 text2     o k j flag nlf ;

!    print "[ Locale called for ",(name) descin,"]^";

!  Handle describe properties for any floating objects here:

    if (descin ofclass Rooms)
        objectloop(o in FloatingHome)
        {   if (IsFoundIn(o, descin) && o.describe ~= 0 or NULL)
                HandleDescribe(o);
        }

  objectloop (o in descin) give o ~workflag;

  objectloop (o in descin)
        if ((o hasnt concealed || o has static)
            && IndirectlyContains(o, actor) == 0)
        {
            if (o has concealed)
            {   if (o has supporter && SayWhatsOn(o))
                    nlf = 1;
                continue;
            }
            give o workflag; k++;
            if (o.describe ~= 0 or NULL)
            {   j = HandleDescribe(o);
                if (j) { flag = 1; give o ~workflag; k--; }
            }
            else if (o hasnt known or secret) give o known;
        }

  if (k == 0) rfalse;

  if (text1)
  {   new_line;
      if (flag == 1) text1 = text2;
      print (string) text1, " ";
      WriteListFrom(child(descin), locale_style, 0, workflag);
      return k;
  }

    if (descin == actor.location)
    {   ActionMessage(##Look, 500, flag + 1);
        if (locale_style & INDENT_BIT) print ":";
        if (locale_style & NEWLINE_BIT) new_line;
        else { print " "; if (locale_style & NEWSTYLE_BIT) give blank secret; }
        WriteListFrom(child(descin), locale_style, -1, workflag);
        if (locale_style & NEWLINE_BIT == 0) 
        {   if (locale_style & NEWSTYLE_BIT == 0) ActionMessage(##Look, 501);
            print ".";
            nlf = 1;
        }
    }
    else
    {   ClearNamesPrinted();
        if (ListContents(descin,0,workflag,locale_style,-1)
            && locale_style & NEWLINE_BIT == 0) { print "."; nlf = true; }
    }

    if (nlf) new_line;

];

! ----------------------------------------------------------------------------
!   Looking.  If noun is set to blank (by .perform(##Look, blank), then the
!             description is allowed to be abbreviated (unless lookmode == 2)
! ----------------------------------------------------------------------------

[ LMode1Sub; lookmode=1; L__M(##LMode1); ];  ! Brief

[ LMode2Sub; lookmode=2; L__M(##LMode2); player.perform(##Look); ];  ! Verbose

[ LMode3Sub; lookmode=3; L__M(##LMode3); ];  ! Superbrief

[ NoteArrival descin;

  descin = player.location;
  if (descin ~= lastdesc)
  {   descin = player.location;
      NewRoom();
      lastdesc = descin;
  }
];

[ ScoreArrival     pl;

    if (InDark(player)) rfalse;
    pl = player.location;
    if (pl hasnt visited)
    {   give pl visited;
        if (pl provides points)
        {   visiting_places.points = visiting_places.points
                + pl.points;
            if (visiting_places notin AchievedTasks)
                Achieved(visiting_places);
            else
            {   give visiting_places general;
                score = score + pl.points;
            }
        }
    }
];

[ FindVisibilityLimit obj     p pos;

    if (obj == 0) rfalse;
    while (parent(obj) ~= 0 or Map)
    {   p = parent(obj);
        pos = PositionOf(obj);

        if (p has transparent
            || pos == upon or worn
            || (pos == inside && p has open)
            || parent(p) == 0 or Map)
            obj = p;
        else
            break;
    }

    return p;
];


[ LookSub     i j k loc cf vlevs nlf;

    if (parent(actor) == 0) return RunTimeError(10);

    if (OnRoutines()) rtrue;

    .MovedByInitial;
    if (InDark(actor))
    {   visibility_ceiling = 0;
        loc = thedark;
    }
    else
    {   loc = actor.location;
        visibility_ceiling = FindVisibilityLimit(actor);
    }
    if (visibility_ceiling == loc && actor == player)
    {   NoteArrival();
        if (visibility_ceiling ~= loc) jump MovedByInitial;
    }

    if (visibility_ceiling)
    {   i = actor;
        while (i ~= visibility_ceiling)
        {   vlevs++;
            i = parent(i);
        }
    }

  !   Printing the top line: e.g.
  !   Octagonal Room (on the table) (as Frodo)

    new_line;  
#ifndef TARGET_GLULX;
  style bold;
#endif;
#ifdef TARGET_GLULX;
  glk($0086, 4); ! set subheader style
#endif; ! TARGET_
    if (visibility_ceiling == 0) print (name) thedark;
    else
    {   if (visibility_ceiling ~= loc) print (The) visibility_ceiling;
        else { print (name) visibility_ceiling; nlf = 1; }
    }
#ifndef TARGET_GLULX;
  style roman;
#endif;
#ifdef TARGET_GLULX;
  glk($0086, 0); ! set normal style
#endif; ! TARGET_

    if (vlevs > 1)
    {   i = actor; j = parent(i);
        while (j ~= visibility_ceiling)
        {   ClearNamesPrinted();
            if (i has upon) ActionMessage(##Look, 4, j);
            else if (i has inside) ActionMessage(##Look, 5, j);
            else if (i has under) ActionMessage(##Look, 6, j);
            else if (parent(i) has animate)
                 {  if (i has worn) ActionMessage(##Look, 8, j);
                    else ActionMessage(##Look, 7, j);
                 }
            i = parent(i); j = parent(i);
        }
    }

    if (actor == player && print_player_flag==1)
        ActionMessage(##Look,3,player);
    new_line;

  !   The room description (if visible)

    if (lookmode<3 && visibility_ceiling == loc or 0)
    {   if (noun ~= blank || lookmode == 2 || loc hasnt visited)
        {   if (loc.describe ~= NULL) RunRoutines(loc,describe);
            else
            {   if (loc.description == 0) RunTimeError(11,loc);
                else PrintOrRun(loc,description);
            }
        }
    }

    if (actor ~= player) 
    {   give player ~concealed;
        if (actor hasnt concealed)
        {   give actor concealed; cf = true; }
    }

    if (visibility_ceiling == 0) Locale(thedark);
    else
    {   for (i = actor,j = vlevs:j>0:j--,i = parent(i))
            give i workflag;

        for (j = vlevs:j > 0:j--)
        {   i = actor;
            for (k = 0:k < j:k++) i = parent(i);
            if (i.inside_description)
            {   new_line; PrintOrRun(i, inside_description); }
            Locale(i);
        }
    }

    if (actor ~= player)
    {   give player concealed;
        if (cf) give actor ~concealed;
    }

  LookRoutine();
  ScoreArrival();
  AfterRoutines();

];

[ ExamineSub     c;

    if (InDark(actor)) return ActionMessage(##Examine, 1);

    if (OnRoutines()) rtrue;
    if (noun.description == 0)
    {   if (noun has container && noun hasnt open or transparent) c = 1;
        if (noun has switchable) c = c + 2;
        if (c)
        {   ActionMessage(##Examine, 3, noun);
            if (c & 1) ActionMessage(##Examine, 4, noun);
            if (c == 3) print (string) AND__TX;
            if (c & 2) ActionMessage(##Examine, 5, noun);
            print ".";
        }
        if (noun has container && noun has transparent or open)
        {   if (c) print " "; <<Search noun>>; }
        if (c) new_line;
        else ActionMessage(##Examine, 2, noun);
    }
    else
    {   PrintOrRun(noun, description);
        if (noun has switchable) 
        {   ActionMessage(##Examine, 3, noun); ActionMessage(##Examine, 5, noun);
            print ".^";
        }
    }
    AfterRoutines();
];

[ LookUnderSub;
    if (InDark(actor)) return ActionMessage(##LookUnder, 2);

    if (OnRoutines()) rtrue;
!   if (parent(noun) && noun has under) return ActionMessage(##LookUnder, 3, noun);
    if (SayWhatsUnder(noun, 1) == 0) ActionMessage(##LookUnder, 1);
];

[ LookOnSub     cf;

    if (OnRoutines()) rtrue;
    if (actor hasnt concealed) { cf = true; give actor concealed;}
    if (SayWhatsOn(noun, 1) == 0) ActionMessage(##LookOn, 1);
    if (cf) give actor ~concealed;
    AfterRoutines();
];

[ SearchSub     cf;

    if (InDark(actor)) return ActionMessage(##Search, 1);
    if (TryToAccess(noun)) rtrue;

    if (OnRoutines()) rtrue;

    if (noun hasnt container) return ActionMessage(##Search, 4);
    if (noun hasnt transparent or open && AttemptAction(##Open, noun)) rtrue;

    if (actor hasnt concealed) { cf = true; give actor concealed;}
    if (SayWhatsIn(noun, 1) == 0) ActionMessage(##Search, 6);
    if (cf) give actor ~concealed;
    AfterRoutines();
];

! ----------------------------------------------------------------------------
!   Verbs which change the state of objects without moving them
! ----------------------------------------------------------------------------

[ TestKey;
    if (metaclass(noun.with_key) == Routine)
    {   if (noun.with_key(second) == false) rfalse;
        rtrue;
    }
    if (noun.with_key ~= second) rfalse;
];

[ LockSub;

    if (TryToAccess(noun)) rtrue;
    if (~~(noun provides with_key)) return ActionMessage(##Lock, 2);
    if (AttemptToTakeObject(second)) rtrue;
    if (noun has locked) return ActionMessage(##Lock, 3);
    if (noun has open && AttemptAction(##Close, noun)) rtrue;
    if (TestKey() == false) return ActionMessage(##Lock, 5, second);

    if (OnRoutines()) rtrue;
    give noun locked;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##Lock, 5001);
];

[ UnlockSub;

    if (TryToAccess(noun)) rtrue;
    if (~~(noun provides with_key)) return ActionMessage(##Unlock, 2);
    if (AttemptToTakeObject(second)) rtrue;
    if (noun hasnt locked) return ActionMessage(##Unlock, 3);
    if (TestKey() == false)
        return ActionMessage(##Unlock, 4, second);

    if (OnRoutines()) rtrue;
    give noun ~locked;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##Unlock, 5001);
];

[ SwitchOnSub;

    if (TryToAccess(noun)) rtrue;
    if (noun hasnt switchable) return ActionMessage(##SwitchOn, 2);
    if (noun has on) return ActionMessage(##SwitchOn, 3);

    if (OnRoutines()) rtrue;
    give noun on;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##SwitchOn, 1);
];

[ SwitchOffSub;

    if (TryToAccess(noun)) rtrue;
    if (noun hasnt switchable) return ActionMessage(##SwitchOff, 2);
    if (noun hasnt on) return ActionMessage(##SwitchOff, 3);

    if (OnRoutines()) rtrue;
    give noun ~on;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##SwitchOff, 1);
];

[ OpenSub;

    if (TryToAccess(noun)) rtrue;
    if (noun hasnt openable) return ActionMessage(##Open, 2);
    if (noun has locked) return ActionMessage(##Open, 3);
    if (noun has open) return ActionMessage(##Open, 4);

    if (OnRoutines()) rtrue;
    give noun open;

    if (AfterRoutines() || keep_silent) rtrue;

    if (TestScope(actor) == 0)
    {   if (TestScope(noun)) L__M(##Open, 7);
        rtrue;
    }

    if (noun has container && noun hasnt transparent
        && ContainsByAttribute(noun, inside)
        && (IndirectlyContains(noun, actor) == 0 ||
            (actor in noun && actor hasnt inside)))
    {   ActionMessage(##Open, 5);
        WriteListFrom(child(noun), ENGLISH_BIT + RECURSE_BIT +
            PARTINV_BIT, 0, inside);
        ".";
    }
    ActionMessage(##Open, 1);
];

[ CloseSub;

    if (TryToAccess(noun)) rtrue;
    if (noun hasnt openable) return ActionMessage(##Close, 2);
    if (noun hasnt open) return ActionMessage(##Close, 3);

    if (OnRoutines()) rtrue;
    give noun ~open;

    if (AfterRoutines() || keep_silent) rtrue;
    if (TestScope(actor)) ActionMessage(##Close, 1);
    else if (TestScope(noun)) L__M(##Close, 4);
];

[ DisrobeSub;

    if (noun notin actor || noun hasnt worn)
        return ActionMessage(##Disrobe, 2);

    if (OnRoutines()) rtrue;
    give noun ~worn;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##Disrobe, 1);
];

[ WearSub;

    if (noun hasnt clothing) return ActionMessage(##Wear, 2);
    if (AttemptToTakeObject(noun)) rtrue;
    if (noun has worn) return ActionMessage(##Wear, 4);

    if (OnRoutines()) rtrue;
    give noun worn;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##Wear, 1);
];

[ EatSub;

    if (AttemptToHoldObject(noun)) rtrue;
    if (noun hasnt edible) return ActionMessage(##Eat, 2);

    if (OnRoutines()) rtrue;
    remove noun;

    if (AfterRoutines() || keep_silent) rtrue;
    ActionMessage(##Eat, 1);
];

! ----------------------------------------------------------------------------
!   Verbs which are really just stubs (anything which happens for these
!   actions must happen in action response properties)
! ----------------------------------------------------------------------------

[ StandardAction;
    if (OnRoutines() || AfterRoutines()) rtrue;
    ActionMessage(action, 1, noun);
];

[ TouchAction;
    if (noun && TryToAccess(noun)) rtrue;
    if (second && TryToAccess(second)) rtrue;
    return StandardAction();
];

[ PushPullTurnAction;
    if (TryToAccess(noun)) rtrue;
    if (OnRoutines() || AfterRoutines()) rtrue;
    if (noun has static)
    {   if (noun has concealed) return ActionMessage(action, 2, noun);
        return ActionMessage(action, 1, noun);
    }
    if (noun has animate) return ActionMessage(action, 4, noun);
    ActionMessage(action, 3, noun);
];

[ ThrowAtSub;

    if (AttemptToHoldObject(noun)) rtrue;

    if (OnRoutines())
        rtrue;
    if (second hasnt animate) return ActionMessage(##ThrowAt, 1, second);
    if (AfterRoutines())
        rtrue;
    ActionMessage(##ThrowAt, 2, second);        
];

[ CutSub;
    if (AttemptToHoldObject(second)) rfalse;
    if (OnRoutines() || AfterRoutines()) rtrue;
    ActionMessage(##Cut, 1, noun);
];

[ ReadSub;      <<Examine noun>>; ];

[ AnswerSub;    StandardAction(); ];
[ AskSub;       StandardAction(); ];
[ BlowSub;      StandardAction(); ];
[ BurnSub;      StandardAction(); ];
[ BuySub;       StandardAction(); ];
[ ClimbDownSub; StandardAction(); ];
[ ClimbSub;     StandardAction(); ];
[ ConsultSub;   StandardAction(); ];
[ DigSub;       StandardAction(); ];
[ DrinkSub;     StandardAction(); ];
[ FillSub;      StandardAction(); ];
[ JumpSub;      StandardAction(); ];
[ JumpOverSub;  StandardAction(); ];
[ ListenSub;    StandardAction(); ];
[ MildSub;      StandardAction(); ];
[ NoSub;        StandardAction(); ];
[ PraySub;      StandardAction(); ];
[ SetSub;       StandardAction(); ];
[ ScreamSub;    StandardAction(); ];
[ SetToSub;     StandardAction(); ];
[ SingSub;      StandardAction(); ];
[ SleepSub;     StandardAction(); ];
[ SorrySub;     StandardAction(); ];
[ StrongSub;    StandardAction(); ];
[ SwimSub;      StandardAction(); ];
[ TellSub;      StandardAction(); ];
[ ThinkSub;     StandardAction(); ];
[ WaitSub;      StandardAction(); ];
[ WakeSub;      StandardAction(); ];
[ WaveHandsSub; StandardAction(); ];
[ YesSub;       StandardAction(); ];

[ AttackSub;    TouchAction(); ];
[ RubSub;       TouchAction(); ];
[ SmellSub;     TouchAction(); ];
[ TasteSub;     TouchAction(); ];
[ TieSub;       TouchAction(); ];
[ WakeOtherSub; TouchAction(); ];

[ PullSub;      PushPullTurnAction(); ];
[ PushSub;      PushPullTurnAction(); ];
[ TurnSub;      PushPullTurnAction(); ];

[ TouchSub;
    if (TryToAccess(noun)) rtrue;
    if (OnRoutines()) rtrue;
    if (noun == actor) return ActionMessage(##Touch, 3);
    if (noun has animate) return ActionMessage(##Touch, 1);
    ActionMessage(##Touch, 2, noun);
];

[ SwingSub;
    if (AttemptToHoldObject(noun) || OnRoutines()) rtrue;
    ActionMessage(##Swing, 1);
];

[ WaveSub;
    if (AttemptToHoldObject(noun) || OnRoutines()) rtrue;
    ActionMessage(##Wave, 1);
];

[ SqueezeSub;

    if (TryToAccess(noun)) rtrue;
    if (OnRoutines()) rtrue;
    if (noun has animate) return ActionMessage(##Squeeze, 1);
    ActionMessage(##Squeeze, 2);
];

[ KissSub;

    if (TryToAccess(noun)) rtrue;
    if (OnRoutines()) rtrue;
    if (noun == actor) return ActionMessage(##Touch, 3);
    ActionMessage(##Kiss, 1);
];

[ AskForSub;

    if (noun == actor) <<Inv>>;
    if (OnRoutines()) rtrue;
    ActionMessage(##Order,1);
];

        ! GoToRoomSub
        ! Automatically walks the player back to a previously-visited
        ! location, if possible.

[ GoToRoomSub    a x y ppl;

    if (actor ~= player)       return ActionMessage(##GoToRoom, 7);
    if (InDark(player))        return L__M(##GoToRoom,1);
    if (parent(player) ~= player.location)
        return L__M(##Go,1,parent(player));
    if (noun == player.location)   return L__M(##GoToRoom,2);
    if (FindPath(player.location,noun,player) == 0)
        return L__M(##GoToRoom,3);

    moving_player = player;
    ppl = player.path_length;

    for (a = 0:a < ppl:a++)
    {
        x = player.&path_moves-->a;
        y = player.&path_rooms-->a;

        L__M(##GoToRoom, 8, x);
        <Go x>;

        InformLibrary.end_turn_sequence();
        DisplayStatus();
        DrawStatusLine();

        if (InDark(player))
        {   L__M(##GoToRoom,4); break; }
        if (player.location ~= y || moving_player ~= player)
            break;
    }

    if (a == ppl)
        player.path_length = 0;

    moving_player = 0;
    meta = 1;
];

        ! ContinueSub 
        ! Continues a GO TO command that was interrupted.

[ ContinueSub;

    if (player.path_length == 0)
        return L__M(##GoToRoom,6);
    noun = player.&path_rooms-->(player.path_length - 1);
    return GoToRoomSub();
];

! ----------------------------------------------------------------------------
!   Debugging verbs
! ----------------------------------------------------------------------------

#IFDEF DEBUG;
IFDEF VN_1610;
[ ChangesOnSub;  debug_flag=debug_flag | 8; "[Changes listing on.]"; ];
[ ChangesOffSub; debug_flag=debug_flag & 7; "[Changes listing off.]"; ];
IFNOT;
[ ChangesOnSub; "[Changes listing only available under Inform 6.2.]"; ];
[ ChangesOffSub; "[Changes listing only available under Inform 6.2.]"; ];
ENDIF;
[ TraceOnSub; parser_trace=1; "[Trace on.]"; ];
[ TraceLevelSub; parser_trace=noun;
  print "[Parser tracing set to level ", parser_trace, ".]^"; ];
[ TraceOffSub; parser_trace=0; "Trace off."; ];
[ RoutinesOnSub;  debug_flag=debug_flag | 1; "[Message listing on.]"; ];
[ RoutinesOffSub; debug_flag=debug_flag & 14; "[Message listing off.]"; ];
[ ActionsOnSub;  debug_flag=debug_flag | 2; "[Action listing on.]"; ];
[ ActionsOffSub; debug_flag=debug_flag & 13; "[Action listing off.]"; ];
[ TimersOnSub;  debug_flag=debug_flag | 4; "[Timers listing on.]"; ];
[ TimersOffSub; debug_flag=debug_flag & 11; "[Timers listing off.]"; ];

#ifndef TARGET_GLULX;
[ CommandsOnSub;
  @output_stream 4; xcommsdir=1; "[Command recording on.]"; ];
[ CommandsOffSub;
  if (xcommsdir==1) @output_stream -4;
  xcommsdir=0;
  "[Command recording off.]"; ];
[ CommandsReadSub;
  @input_stream 1; xcommsdir=2; "[Replaying commands.]"; ];
[ PredictableSub i; i=random(-100);
  "[Random number generator now predictable.]"; ];
#endif;
#ifdef TARGET_GLULX;
[ CommandsOnSub fref;
  if (gg_commandstr ~= 0) {
    if (gg_command_reading)
      "[Commands are currently replaying.]";
    "[Command recording already on.]";
  }
  ! fileref_create_by_prompt
  fref = glk($0062, $103, $01, 0);
  if (fref == 0)
    "[Command recording failed.]";
  gg_command_reading = false;
  ! stream_open_file
  gg_commandstr = glk($0042, fref, $01, GG_COMMANDWSTR_ROCK);
  glk($0063, fref); ! fileref_destroy
  if (gg_commandstr == 0)
    "[Command recording failed.]";
  "[Command recording on.]";
];
[ CommandsOffSub;
  if (gg_commandstr == 0)
    "[Command recording already off.]";
  if (gg_command_reading)
    "[Commands are currently replaying.]";
  glk($0044, gg_commandstr, 0); ! stream_close
  gg_commandstr = 0;
  gg_command_reading = false;
  "[Command recording off.]";
];
[ CommandsReadSub fref;
  if (gg_commandstr ~= 0) {
    if (gg_command_reading)
      "[Commands are already replaying.]";
    "[Command recording currently on.]";
  }
  ! fileref_create_by_prompt
  fref = glk($0062, $103, $02, 0);
  if (fref == 0)
    "[Command recording failed.]";
  gg_command_reading = true;
  ! stream_open_file
  gg_commandstr = glk($0042, fref, $02, GG_COMMANDRSTR_ROCK);
  glk($0063, fref); ! fileref_destroy
  if (gg_commandstr == 0)
    "[Command recording failed.]";
  "[Command recording on.]";
];
[ PredictableSub;
  @setrandom 100;
  "[Random number generator now predictable.]";
];
#endif; ! TARGET_;

[ XTestMove obj dest;
  if ((obj<=InformLibrary) || (obj in 1))
     "[Can't move ", (name) obj, ": it's a system object.]";
  while (dest)
  {   if (dest == obj)
          "[Can't move ", (name) obj, ": it would contain itself.]";
      dest = parent(dest);
  }
  rfalse;
];
[ XPurloinSub;
  if (XTestMove(noun,player)) return;
  move noun to player; give noun moved ~concealed ~inside ~upon ~under;
  "[Purloined.]"; ];
[ XAbstractSub;
  if (XTestMove(noun,second)) return;
  move noun to second; "[Abstracted.]"; ];

[ XObj obj f;

  if (parent(obj) == 0) print (name) obj;
  else print (a) obj;

  print " (", obj, ") ";

  if (f == 1 && parent(obj))
      print "(in ", (name) parent(obj), " ", parent(obj), ")";

  new_line;

  if (child(obj) == 0) rtrue;

    if (obj == Class)
        WriteListFrom(child(obj), CONCEAL_BIT +
            NOARTICLE_BIT + INDENT_BIT + NEWLINE_BIT + ALWAYS_BIT, 1);
    else
        WriteListFrom(child(obj), CONCEAL_BIT +
            FULLINV_BIT + INDENT_BIT + NEWLINE_BIT + ALWAYS_BIT, 1);
];

[ XTreeSub x;

    if (noun)
        XObj(noun, 1);
    else
        objectloop(x ofclass Object) if (parent(x) == 0) XObj(x);
];

[ GotoSub;
  if ((~~(noun ofclass Object)) || noun notin Map) "[Not a safe place.]";
  MoveTo(player, noun);
];

[ GonearSub; MoveTo(player, rootof(noun)); ];
[ Print_ScL obj; print_ret ++x_scope_count, ": ", (a) obj, " (", obj, ")"; ];
[ ScopeSub; x_scope_count=0; LoopOverScope(Print_ScL, noun);
  if (x_scope_count==0) "Nothing is in scope.";
];

[ DB_DistanceSub;
    print_ret FindPath(player.location,noun,player)," rooms";
];

#ENDIF;

! ----------------------------------------------------------------------------
!   Finally: the mechanism for library text (the text is in the language defn)
! ----------------------------------------------------------------------------

[ LMRaw act n x1     s;
    s = sw__var; sw__var = act;
    if (n == 0) n = 1;
    L___M(n, x1);
    sw__var = s;
];

[ L__M act n x1     s a;
    s = sw__var; sw__var = act; if (n == 0) n = 1;
    a = actor;
  if (act == ##Miscellany && n < 500) actor = player;
  HoldX();
  L___M(n,x1);
  PrintX();
  sw__var = s; actor = a;
];

[ L___M n x1 s;
  s = action;
  lm_n = n; lm_o = x1;
  action = sw__var;
  if ((actor && actor provides messages && actor.messages())
    || CheckMessageCogs()) { action=s; rfalse; }
  action=s;

  LanguageLM(n, x1);
];

[ CheckMessageCogs     x;
    objectloop(x in MessageGizmo)
        if (RunRoutines(x, messages)) rtrue;
    rfalse;
];


! ----------------------------------------------------------------------------

Constant sbold  = 1;
Constant sroman = 2;
Constant sunder = 3;
Constant sfixed = 4;

        ! ts (style constant)
        ! For easier changing of the text style.

#ifndef TARGET_GLULX;
[ ts x;

    switch (x)
    {   sbold: style bold;
        sroman: style roman; font on;
        sunder: style underline;
        sfixed: font off;
    }
];
#endif;
#ifdef TARGET_GLULX;
[ ts x;

    switch (x)
    {   sbold: glk($0086, 5);
        sroman: glk($0086, 0); font on;
        sunder: ;
        sfixed: font off;
    }
];
#endif;

[ FatalError txt;

    print "^*** Fatal Error ***^^",(string) txt,"^^Press a key to exit.";
#ifndef TARGET_GLULX;
    @read_char 1 txt;
#endif;
#ifdef TARGET_GLULX;
    KeyCharPrimitive();
#endif;
    quit;
];

[ WordIsVerb wd     tv;

    if (wd)
    {   tv = wd->#dict_par1;
        if (tv & 1 && wd ~= 'long' or 'short' or 'normal' 
            or 'brief' or 'full' or 'verbose')
            rtrue;
    }
    rfalse;
];

#ifndef TARGET_GLULX;
[ OpenBuffer buff;

    if (buffers_open >= MAXIMUM_OPEN_BUFFERS)
    {   #ifdef DEBUG;
            print "***Error: cannot open buffer at ",buff, " because
                there are already ",buffers_open," open,
                and the maximum is ",MAXIMUM_OPEN_BUFFERS,".^";
        #endif;
        rfalse;
    }

    if (buffers_open) Close__Buffer();
    buffers_open++;
    Open__Buffer(buff, 0, 0);
];

[ CloseBuffer     baddr boffset bdata;

    if (buffers_open == 0) rfalse;
    Close__Buffer();
    buffers_open--;

! Was there another open? If so, reopen it:
    if (buffers_open == 0) rfalse;

    baddr = buffer_addresses-->buffers_open;
    boffset = buffer_offsets-->buffers_open;
    bdata = (baddr + boffset)-->0;
    Open__Buffer(baddr, boffset, bdata);
];

[ Open__Buffer baddr boffset bdata     ;

    buffer_addresses-->buffers_open = baddr;
    buffer_offsets -->buffers_open = boffset;
    buffer_saved_data -->buffers_open = bdata;

    baddr = baddr + boffset;
    @output_stream 3 baddr;
];

[ Close__Buffer      baddr boffset bdata;

    @output_stream -3;
    baddr = buffer_addresses --> buffers_open;
    boffset = buffer_offsets --> buffers_open;
    bdata = buffer_saved_data --> buffers_open;

    if (boffset)
    {   baddr-->0 = baddr-->0 + (baddr + boffset)-->0;
        (baddr + boffset)-->0 = bdata;
    }
    buffer_offsets --> buffers_open = baddr-->0;
];

#endif;
#ifdef TARGET_GLULX;

[ OpenBuffer buff;

    if (buffers_open >= MAXIMUM_OPEN_BUFFERS)
    {   #ifdef DEBUG;
            print "***Error: cannot open buffer at ",buff, " because
                there are already ",buffers_open," open,
                and the maximum is ",MAXIMUM_OPEN_BUFFERS,".^";
        #endif;
        rfalse;
    }
    buff-->0 = 0;
    current_buffer = buff;
    buffers_open++;
    buffer_addresses-->buffers_open = current_buffer;
    if (buffers_open == 1) @setiosys 1 FilterOutput;
];

[ CloseBuffer;

    if (buffers_open == 0) rfalse;
    buffer_addresses-->buffers_open = 0;
    buffers_open--;
    if (buffers_open) current_buffer = buffer_addresses-->buffers_open;
    else @setiosys 2 0;
];

[ FilterOutput char     cbi;

    cbi = current_buffer-->0;
    current_buffer->(cbi + WORDSIZE) = char;
    current_buffer-->0 = cbi + 1;
];

#endif;

#ifdef TARGET_GLULX;
[ GlkListSub id val;
  id = glk($0020, 0, gg_arguments); ! window_iterate
  while (id) {
    print "Window ", id, " (", gg_arguments-->0, "): ";
    val = glk($0028, id); ! window_get_type
    switch (val) {
      1: print "pair";
      2: print "blank";
      3: print "textbuffer";
      4: print "textgrid";
      5: print "graphics";
      default: print "unknown";
    }
    val = glk($0029, id); ! window_get_parent
    if (val) print ", parent is window ", val;
    else print ", no parent (root)";
    val = glk($002C, id); ! window_get_stream
    print ", stream ", val;
    val = glk($002E, id); ! window_get_echo_stream
    if (val) print ", echo stream ", val;
    print "^";
    id = glk($0020, id, gg_arguments); ! window_iterate
  }
  id = glk($0040, 0, gg_arguments); ! stream_iterate
  while (id) {
    print "Stream ", id, " (", gg_arguments-->0, ")^";
    id = glk($0040, id, gg_arguments); ! stream_iterate
  }
  id = glk($0064, 0, gg_arguments); ! fileref_iterate
  while (id) {
    print "Fileref ", id, " (", gg_arguments-->0, ")^";
    id = glk($0064, id, gg_arguments); ! fileref_iterate
  }
  val = glk($0004, 8, 0); ! gestalt, Sound
  if (val) {
    id = glk($00F0, 0, gg_arguments); ! schannel_iterate
    while (id) {
      print "Soundchannel ", id, " (", gg_arguments-->0, ")^";
      id = glk($00F0, id, gg_arguments); ! schannel_iterate
    }
  }
];
#endif; ! TARGET_;
