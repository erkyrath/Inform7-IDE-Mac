//
//  IFError.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#ifndef __IFError_h
#define __IFError_h

typedef enum {
    IFLexBase = 1,

    IFLexCompilerVersion,
    IFLexCompilerMessage,
    IFLexCompilerWarning,
    IFLexCompilerError,
    IFLexCompilerFatalError,

    IFLexAssembly,
    IFLexHexDump,
    IFLexStatistics,
} IFLex;

extern int  IFErrorScanString(const char* string);
extern void IFErrorAddError  (const char* file,
                              int line,
                              IFLex type, // Limited to Message, Warning or Error
                              const char* message);

#endif
