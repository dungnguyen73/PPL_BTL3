grammar ZCode;

@lexer::header {
from lexererr import *
}

options {
	language=Python3;
}


/* KEYWORD */
TRUE : 'true';
FALSE: 'false';
    //types
NUMBER: 'number';
BOOL: 'bool';
STRING: 'string';

RETURN: 'return';
VAR: 'var';
DYNAMIC: 'dynamic';
FUNC: 'func';
FOR: 'for';
UNTIL: 'until';
BY: 'by';
BREAK: 'break';
CONTINUE: 'continue';
IF: 'if';
ELSE: 'else';
ELIF: 'elif';
BEGIN: 'begin';
END: 'end';

/* LOGIC OPERATORS */
NOT: 'not';
AND: 'and';
OR: 'or';

/* ARITHMETIC OPERATORS */
// NEV: '-'; //overlap with SUB
ADD: '+';
SUB: '-';
MUL: '*';
DIV: '/';
MOD: '%';

/* STRING OPERATORS */
CONCAT : '...';

/* RELATIONAL OPERATORS */
EQ: '=';
NOT_EQ: '!=';
LT: '<';
GT: '>';
LTE: '<=';
GTE: '>=';
STRINGCMP: '=='; // Compare two same strings, STRING operand's type

ASSIGN: '<-';

/* SEPERATORS */
R_OPEN: '('; //ROUND 
R_CLOSE: ')';
SQ_OPEN: '['; //SQUARE
SQ_CLOSE: ']';
C_OPEN: '{';  //CURLY
C_CLOSE: '}';
COMMA: ',';
SEMI: ';';

/* Build in function */
READNUMBER: 'readNumber';
READBOOL: 'readBool';
READSTRING: 'readString';
WRITE: 'write';
WRITESTRING: 'writeNumber';
WRITENUMBER: 'writeString';


/* LITERAL */
// Fragment
fragment SingQ : '\'';
fragment DoubleQ : '"';
fragment Backslash : '\\';
fragment DoubleQinString : SingQ DoubleQ ;// for double quote inside a string;
fragment EscapeSeq : '\\'  [btnfr'\\] | '\'"' ;
fragment Character : ~["\\\r\n] ;
fragment Unterminated: [\n] | EOF;
fragment StringCharacters: (Character | EscapeSeq | DoubleQinString) ;

fragment DIGIT : [0-9];
fragment DECIMALPART : DIGIT* ('.' DIGIT | DIGIT '.') DIGIT*;
fragment INTEGER : DIGIT DIGIT*;
fragment EXPONENTPART : [eE] ([-+])? INTEGER;

NUMBER_LITERAL :  INTEGER EXPONENTPART? | DECIMALPART EXPONENTPART? ; 
BOOLEAN_LITERAL : TRUE | FALSE;
STRING_LITERAL : '"' StringCharacters* '"' {
    self.text = self.text[1:-1]
};

/* IDENTIFIER */
ID: [A-Za-z_][A-Za-z0-9_]*;
// INT: [0-9]+;


program: NEWLINE* declare (NEWLINE+ declare)* NEWLINE*  EOF;


declare: (var_decl | func_decl);
// All declarations and statements in this programming language
// must end with a newline character.
// Types
prim_type: NUMBER | BOOL | STRING;
//variable declaration
var_decl: ((prim_type | DYNAMIC) ID (ASSIGN expr)?)
                | (VAR ID ASSIGN expr)
                | (prim_type ID SQ_OPEN num_list SQ_CLOSE (ASSIGN expr)?); // for array declaration

num_list: NUMBER_LITERAL COMMA num_list | NUMBER_LITERAL;

// arraydecl : prim_type ID (SQ_OPEN index_operators SQ_CLOSE) (ASSIGN expr)?;


// arrayliteral // [1,2,3]
//  : SQ_OPEN index_operators? SQ_CLOSE;
// index_operators  
//  : arraysizeliteral | arraysizeliteral COMMA  index_operators
//  ;
// arraysizeliteral: arrayliteral | ID | literal | funcallData | expr ;  
// arrayElement:( ID|funcallData ) (SQ_OPEN index_operators SQ_CLOSE);   // element Expression or func that return arraytype such as: foo()

// function declaration
func_decl: FUNC ID R_OPEN paralist? R_CLOSE NEWLINE* (return_stmt | block_stmt)?;

paralist: para COMMA paralist | para ; // ID or array element 
para: (prim_type ID )
    | (prim_type ID SQ_OPEN num_list SQ_CLOSE ); 
//statement
stmt: return_stmt
    | block_stmt
    | assignment_stmt
    | if_stmt
    | for_stmt
    | break_stmt
    | continue_stmt
    | func_call_stmt
    | var_decl; // Allow variable declarations in block
// stmtlist: stmt NEWLINE+ stmtlist | ;

return_stmt: RETURN expr?;
block_stmt: BEGIN NEWLINE+ (stmt* NEWLINE+)* END;

assignment_stmt: (ID | elem_array) (ASSIGN (expr)); // assign variable in func body
elem_array: ID SQ_OPEN exprlist SQ_CLOSE;
if_stmt: IF  R_OPEN expr R_CLOSE NEWLINE* stmt 
         (NEWLINE ELIF  R_OPEN expr R_CLOSE  NEWLINE* stmt)*
         (NEWLINE ELSE NEWLINE* stmt)?   ;

         
for_stmt: FOR ID UNTIL expr BY expr NEWLINE* stmt; 
break_stmt: BREAK ;
continue_stmt: CONTINUE ;
func_call_stmt: (ID R_OPEN exprlist? R_CLOSE) | io_func;

// arguments_list: argument COMMA arguments_list | argument;
// argument: ID | literal | arrayElement | expr;
// IO operations - built-in func
io_func: readNumber | readBool | readString | write | writeNumber | writeString ;
readNumber: READNUMBER R_OPEN R_CLOSE;
writeNumber: WRITENUMBER R_OPEN expr R_CLOSE;
readBool: READBOOL R_OPEN expr R_CLOSE;
write: WRITE R_OPEN expr R_CLOSE;
readString: READSTRING R_OPEN  R_CLOSE;
writeString: WRITESTRING R_OPEN expr R_CLOSE;



/*Expression */
exprlist: expr COMMA exprlist | expr;
expr: expr1 CONCAT expr1 | expr1;  // none association
expr1: expr2 (EQ | NOT_EQ | LT | LTE | GT | GTE | STRINGCMP) expr2 | expr2; //none
expr2: expr2 (AND | OR) expr3 | expr3; //left 
expr3: expr3 (ADD | SUB) expr4 | expr4;
expr4: expr4 (MUL | DIV | MOD) expr5 | expr5;
expr5: NOT expr5 | expr6;
expr6: (ADD | SUB )expr6 | expr7;
expr7: array_cell 
        | operand 
        // | func_call_stmt
        ;
array_cell: (ID | funcallData) SQ_OPEN exprlist SQ_CLOSE;

operand: ID | funcallData | R_OPEN expr R_CLOSE | literal  ; //--------------------
funcallData: ID R_OPEN exprlist? R_CLOSE ;

literal: NUMBER_LITERAL | TRUE | FALSE | STRING_LITERAL | arrayliteral ;
arrayliteral: SQ_OPEN exprlist SQ_CLOSE;


// newline character
NEWLINE: '\r'?'\n' {self.text = '\n'};
/* COMMENT */
LINECMT : '##' ~[\n\r\f]* -> skip;

WS : [ \t\f\b]+ -> skip ; // skip spaces, tabs, newlines
ERROR_CHAR: . {raise ErrorToken(self.text)};
UNCLOSE_STRING: '"' StringCharacters* (Unterminated | [\b\f\r\n\t\\] ) {
    esc = ['\b', '\t', '\n', '\f', '\r', '\\']
    temp = str(self.text)
    quote_count = temp.count('"')  # Count the number of double quotes in the text
    if quote_count % 2 != 0: 
        raise UncloseString(temp[1:])  
    if (temp[-1] in esc):
        raise UncloseString(temp[1:-1])
    else:
        raise UncloseString(temp[1:])
};
ILLEGAL_ESCAPE: '"' StringCharacters* ('\\' ~[bnfrt'\\] | ~'\\') {
    temp = self.text
    raise IllegalEscape(temp[1:])
};

