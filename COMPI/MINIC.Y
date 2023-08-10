%{
// Se incluyen las librer�as necesarias
#include<stdio.h>
#include<ctype.h>
#include<string.h>
// Declaraci�n de variables y estructuras
int yylex();
typedef union { int entero; float real; } tipovalor;
void IS(int , int);
char lexema[80];
typedef struct {
    char nombre[30];
    int a1, a2; // a1: FUN/VAR a2: INT/FLOAT
    tipovalor a3; // guarda valor
} tipoTablaSimbolo;

tipoTablaSimbolo TS[100], *pTS;
int nTS = 0;
int insertaSimbolo(char *, int);
int localizaSimbolo(char *);
void muestraSimbolo();
int tipoVar;

// Definici�n de la tabla de c�digo
typedef struct {
    int op, a1, a2, a3;
} tipoCodigo;
tipoCodigo TABCOD[100];
int cx = -1; // �ndice de c�digo actual
int indicevartemp = 0; // n�mero de variables temporales
void genCodigo(int, int, int, int);
int genvartemp();
void muestraCodigo();

void interprete();

// Definici�n de las operaciones de lenguaje intermedio
#define MOVER 1
#define SUMAR 2
#define SALTAR 3
#define SALTARV 4
#define SALTARF 5
#define MENOR 6
%}
%token INT FLOAT FORMATO ID IF ELSE NUM REAL WHILE DO FOR FUNCION
%token LEENUM IMPRINUM
%token CENTERO %token CFLOAT %token ID VAR
%right '='
%left '?'
%left OR %left AND %right NOT
%left IGUAL NOIGUAL MENORIGUAL MAYORIGUAL '<' '>'
%left '+' '-'
%left '*' '/'
%%
// Reglas de la gram�tica del lenguaje MINIC
programaC : listaDeclC ;
listaDeclC : listaDeclC declC | ;
declC : Tipo listaVar ';';
declC : Tipo ID '(' { IS($1, FUNCION); } listaPar ')' bloque;
Tipo : INT | FLOAT ;
listaVar : ID ',' { IS(tipoVar, VAR); } listaVar | ID { IS(tipoVar, VAR); };
listaPar : Tipo ID { IS($1, VAR); } ',' listaPar | Tipo ID { IS($1, VAR); };
bloque : '{' listaVarLoc listaProp '}';
listaVarLoc : /* Nada */ | Tipo listaVar ';' listaVarLoc ;
listaProp : listaProp prop | ;
prop : ';';
prop : bloque;
prop : IF '(' expr ')' prop;
prop : IF '(' expr ')' prop ELSE prop;
prop : WHILE '(' { $$ = cx + 1; } expr ')' { genCodigo(SALTARF, $4, 0, -1);
$$ = cx; };
prop : FOR '(' expr ';' expr ';' expr ')' prop;
prop : IMPRINUM '(' expr ')' { genCodigo(IMPRINUM, $3, 0, 0); };
prop : expr ;
expr : expr OR expr ;
expr : expr AND expr ;
expr : NOT expr ;
expr : expr IGUAL expr ;
expr : expr NOIGUAL expr ;
expr : expr '<' expr { int n = genvartemp(); genCodigo(MENOR, n, $1, $3); $$
= n; };
expr : expr '>' expr ;
expr : expr MENORIGUAL expr ;
expr : expr MAYORIGUAL expr ;
expr : expr '+' expr { int n = genvartemp(); genCodigo(SUMAR, n, $1, $3); $$
= n; };
expr : expr '-' expr ;
expr : expr '*' expr ;
expr : expr '/' expr ;
expr : expr '?' expr ':' expr ;
expr : ID { $$ = localizaSimbolo(lexema); };
expr : NUM { IS($1, NUM); $$ = localizaSimbolo(lexema); TS[$$].a3.entero =
atoi(lexema); };
expr : REAL { float v; IS($1, REAL); $$ = localizaSimbolo(lexema);
sscanf(lexema, "%f", &v); TS[$$].a3.real = v; };
expr : ID '=' { $$ = localizaSimbolo(lexema); } expr { genCodigo(MOVER, $3,
$4, 0); };
expr : ID '[' expr ']' ;
expr : ID '[' expr ']' '=' expr;
%%
// Funci�n para generar c�digo intermedio
void genCodigo(int op, int a1, int a2, int a3)
{
    tipoCodigo *p;
    cx++;
    p = &TABCOD[cx];
    p->op = op;
    p->a1 = a1;
    p->a2 = a2;
    p->a3 = a3;
}
// Funci�n para generar nombres de variables temporales
int genvartemp()
{
    char t[30];
    sprintf(t, "_T%-2d", indicevartemp++);
    strcpy(TS[nTS].nombre, t);
    TS[nTS].a1 = VAR;
    return nTS++;
}
// Funci�n para mostrar el c�digo intermedio generado
void muestraCodigo()
{
    int i, op, a1, a2, a3;
    for (i = 0; i <= cx; i++)
    {
        op = TABCOD[i].op;
        a1 = TABCOD[i].a1;
        a2 = TABCOD[i].a2;
        a3 = TABCOD[i].a3;
        printf("%2d) ", i);
        switch (op)
        {
            case SUMAR:
                printf("SUMAR %s = %s + %s\n", TS[a1].nombre, TS[a2].nombre,TS[a3].nombre);
                break;
            case MENOR:
                printf("MENOR %s = %s < %s\n", TS[a1].nombre, TS[a2].nombre,TS[a3].nombre);
                break;
            case SALTAR:
                printf("SALTAR %d \n", a3);
                break;
            case SALTARV:
                printf("SALTARV %s %d \n", TS[a1].nombre, a3);
                break;
            case SALTARF:
                printf("SALTARF %s %d \n", TS[a1].nombre, a3);
                break;
            case MOVER:
                printf("MOVER %s %s \n", TS[a1].nombre, TS[a2].nombre);
                break;
            case IMPRINUM:
                printf("IMPRINUM %s \n", TS[a1].nombre);
                break;
            // Los dem�s casos
        }
    }
    return;
}
// Funci�n para localizar un s�mbolo en la tabla de s�mbolos
int localizaSimbolo(char *n)
{
    int i;
    for (i = 0; i < nTS; i++)
    {
        if (strcmp(n, TS[i].nombre) == 0)
        return i;
    }   
    return -1;
}
// Funci�n para insertar un s�mbolo en la tabla de s�mbolos
int insertaSimbolo(char *n, int t)
{
    if (localizaSimbolo(n) >= 0)
        return -1;
    strcpy(TS[nTS].nombre, n);
    TS[nTS].a1 = t;
    TS[nTS].a2 = TS[nTS].a3.real = 0;
    return nTS++;
}
// Funci�n para insertar un s�mbolo en la tabla de s�mbolos y asignarle un tipo y clase
void IS(int tipo, int clase)
{
    int i;
    i = insertaSimbolo(lexema, tipo);
    TS[i].a2 = clase;
}
// Funci�n para mostrar la tabla de s�mbolos
void muestraSimbolo()
{
    int i;
    for (i = 0, pTS = TS; i < nTS; i++, pTS++)
        printf("%20s %d %d %g\n", pTS->nombre, pTS->a1, pTS->a2, pTS->a3.real);
}
// Funci�n para el an�lisis l�xico
int yylex()
{
int c;
char *p;
do
c = getchar();
while (isspace(c));
;
if (isalpha(c))
{
p = lexema;
do
{
*p++ = c;
c = getchar();
} while (isalpha(c));
ungetc(c, stdin);
*p = 0;
// Comprobar si es una palabra reservada y devolver el token correspondiente
if (strcmp(lexema, "if") == 0)
return IF;
if (strcmp(lexema, "else") == 0)
return ELSE;
if (strcmp(lexema, "int") == 0)
return tipoVar = yylval = INT;
if (strcmp(lexema, "float") == 0)
return tipoVar = yylval = FLOAT;
if (strcmp(lexema, "while") == 0)
return WHILE;
if (strcmp(lexema, "for") == 0)
return FOR;
if (strcmp(lexema, "do") == 0)
return DO;
if (strcmp(lexema, "print") == 0)
return IMPRINUM;
if (strcmp(lexema, "chao") == 0)
return EOF;
// Devolver el token correspondiente a un identificador
return yylval = ID;
}
// Resto de caracteres y n�meros
// ... (c�digo del an�lisis l�xico para caracteres y n�meros)
}
// Funci�n para mostrar errores de sintaxis
void yyerror(char *m)
{
    fprintf(stderr, "error de sintaxis %s\n", m);
    getchar();
    exit(0);
}
// Funci�n principal del programa
int main()
{
// Inicia el proceso de compilaci�n llamando a "yyparse()"
    yyparse();
    // Muestra la tabla de s�mbolos y el c�digo intermedio generado
    muestraSimbolo();
    muestraCodigo();
    // Ejecuta el programa mediante la funci�n "interprete()"
    interprete();
    return 0;
}