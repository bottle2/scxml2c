#include <assert.h>
#include <errno.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rax.h"

#define NIL
#define COMMA ,

#define AS_ENUM(P, U, L) P##U
#define AS_PTR( P, U, L) struct L *L
#define AS_MEMB(P, U, L) struct L L
/* TODO Do away with this P parameter. */

/* TODO We want children that occur N times to remain on nodes stack,
 * but children that only occur once, just process them at once.
 * This thing mixing code generation gets ugly real fast,
 * but maybe there is more power to untap. */

/* TODO Code would be simpler if there was always a parent, always a virtual root kind of */

#include "element.h"

#define PROG_NAME "token"

/* I'm positive _someone_ MUST have created some kind of XML schema to
   C generator, this is pointless... whatever. */

/* TODO See about UCS, ISO 10646 and 8859 something something... */

/* XXX I should ensure that UTF-16 has BOM, but who cares? Fuck it. */

/* List of acronyms etc.
 * bmp basic
 * sp  supplementary plane
 * le  little-endian
 * be  big-endian
 * fr  full range
 */

static enum enc {
    ENC_NONE, ENC_UTF8, ENC_UTF16BE, ENC_UTF16LE = 4, ENC_UTF16 = 6
} enc = 0;

/* Gerenciar a memória dessas listas encadeadas vai ser gostoso */

#define ID_XS(X, S, P)    \
X(P, STATE   , state   )S \
X(P, PARALLEL, parallel)S \
X(P, FINAL   , final   )S \
X(P, HISTORY , history )

struct id
{
    enum  { ID_XS(AS_ENUM, COMMA, ID_)  } type;
    union { ID_XS(AS_PTR , ;    , NIL); } penis;
};

struct state
{
    struct state *states;
    int n_state;
    struct parallel *parallels;
    int n_parallel;

    struct id initial;
    struct history *history;
    int n_history;

    /* TODO Transitions */
};

struct parallel
{
    struct state *states;
    int n_state;
    struct parallel *parallel;
    int n_parallel;

    struct history *history;
    int n_history;
};

struct final
{
    int dummy;
};

struct history
{
    enum depth { DEPTH_SHALLOW, DEPTH_DEEP } depth;
    struct id _default;
};

static struct scxml
{
    struct state *states;
    int n_state;
    struct parallel *parallels;
    int n_parallel;
    struct final *finals;
    int n_final;

    struct id initial;
} scxml;

struct transition { int fuck; };
struct initial { int fuck; };
struct onentry { int fuck; };
struct onexit { int fuck; };
struct raise { int fuck; };
struct datamodel { int fuck; };
struct donedata { int fuck; };
struct content { int fuck; };
struct invoke { int fuck; };
struct script { int fuck; };

static char * element_string(enum element e)
{
    switch (e)
    {
        #define AS_STR(P, U, L) case P##U: return #L
        ELEMENT_XS(ELEMENT_, AS_STR, ;);
        #undef AS_STR
        default: assert(!"Invalid element"); break;
    }

    return NULL;
}

static void print_state(int level, struct state *s)
{
    printf("%*.0ssome state\n", level, "");
    for (int i = 0; i < s->n_state; i++)
        print_state(level + 1, s->states + i);
}

static void print_tree(struct scxml *it)
{
    puts("root:");
    for (int i = 0; i < it->n_state; i++)
        print_state(1, it->states + i);
}

static struct builder
{
    enum element element;
    union {
        ELEMENT_XS(NIL, AS_MEMB, ;);
    } e;
    unsigned mask;
} nodes[1000];
static int n_node = 0;

static unsigned mask;

static enum element element;

static int parents[1000];
static int n_parent = 0;

#define DECL_MAX(ARR, NAME) enum { NAME##_MAX = sizeof (ARR) / sizeof (*ARR) }
DECL_MAX(nodes, NODE);
DECL_MAX(parents, PARENT);

#define UNICODE_REPLACEMENT_CHARACTER 0xFFFD

/* Copyright (c) 2025 Chris Wellons
 * This is free and unencumbered software released into the public domain.
 * https://github.com/skeeto/scratch/blob/613e68416be98af1a24c8674cd03884652805f73/misc/utf8_branchless.c
 * Always writes four bytes, but returns the length to be kept (1-4).
 */
int utf8encode(unsigned char *s, long cp)
{
    int utfmask[] = { 0xffffffff, 0x3fffffff, 0x3fffffff, 0x3fffffff };
    int lencode[] = { 0x00000000, 0x80c00000, 0x8080e000, 0x808080f0 };

    int len = 1 + (cp>0x7f) + (cp>0x7ff) + (cp>0xffff);
    int out = (((unsigned)cp << 24) & 0xff000000) |
              (((unsigned)cp << 10) & 0x003f0000) |
              (((unsigned)cp >>  4) & 0x00003f00) |
              (((unsigned)cp >> 18) & 0x0000003f);
    out &= utfmask[len-1];  // mask some of low byte if non-ASCII
    out |= lencode[len-1];  // inject length code

    out >>= (4 - len) * 8;
    s[0] = out >>  0;  // NOTE: optimized for little endian
    s[1] = out >>  8;
    s[2] = out >> 16;
    s[3] = out >> 24;
    return len;
}

static int lineno = 0;
static int colno = 0;

/* Error rationale:
 * - A message is not needed, because:
 *   - The label should be concise and spell out the problem
 *   - Knowing location of error is more useful to debug
 *     - This also makes printing data unnecessary
 * - Integer code is not printed, because:
 *   - It will change from version to version
 *   - It is not searchable (the label is, however) 
 * TODO
 * - Actually write useful labels
 * - Fuck.
 * - Error reporting is that one thing that everyone has their own ideas,
 *   everyone does their own way.
 * - Honestly. I don't know.
 * - Fuck. I'm not happy. I feel like I'm consfusing things.
 */

#define ERROR_XS(X) \
X(OOM                 ), \
X(ONLY_ONE_ROOT       ), \
X(ROOT_MUST_BE_SCXML  ), \
X(WRONG_CHILD         ), \
X(CHILD_AT_MOST_ONCE  ), \
X(MISSING_CHILD       ), \
X(TAG_MISMATCH        ), \
X(EXTERNAL_UNSUPPORTED), \
X(OTHER_ERROR         ), \
X(ENCODING_MISMATCH   )

#define AS_ENUM2(C) ERROR_##C
enum { ERROR_XS(AS_ENUM2) };
#undef AS_ENUM2

#define DIE(CODE, COND) if (COND) { \
    fprintf(stderr, "-:%d:%d: Error " #CODE ": %s (" PROG_NAME ":%s:%d)\n", \
        lineno, colno, #COND, __FILE__, __LINE__ \
    ); exit(EXIT_FAILURE); } else (void)ERROR_##CODE

struct lbuffer
{
    long it[1000];
    int len;
};

#define ADJ(IT) (unsigned char *)(IT).it, (IT).len * sizeof (*(IT).it)

struct lbuffer lbuf1;
struct lbuffer lbuf2;
struct lbuffer *lbuf;

struct entities { rax *em; raxIterator iter; };

struct entities pes; /* Parameter % entities */
struct entities ges; /* (General) & entities */
struct entities *ces; /* Current entities */

static void entities_init(struct entities *es)
{
    DIE(OOM, !(es->em = raxNew()));
    raxStart(&es->iter, es->em);
}

static void entities_deinit(struct entities *es)
{
    raxStop(&es->iter);
    raxFree(es->em);
}

static void push_element(void)
{
    DIE(ONLY_ONE_ROOT, 1 == n_node && 0 == n_parent);

    struct builder *parent = n_parent ? nodes + parents[n_parent - 1] : NULL;

    printf("Pushing %s\n", element_string(element));

    assert(n_node < NODE_MAX);

    if (0 == n_parent)
    {
        DIE(ROOT_MUST_BE_SCXML, element != ELEMENT_SCXML);
    }
    else
    {
        unsigned allowed;
        unsigned max;

        switch (parent->element)
        {
            #define AS_ALLOWED(P, U, L) case P##U: allowed = CHILDREN_##U; max = CHILDREN_ONE_MAX_##U; break
            ELEMENT_XS(ELEMENT_, AS_ALLOWED, ;);
            #undef AS_ALLOWED
            default: assert(!"Invalid ele"); break;
        }

        DIE(WRONG_CHILD, !(allowed & (1 << element)));

        DIE(CHILD_AT_MOST_ONCE, max & nodes[parents[n_parent - 1]].mask & (1 << element));

        parent->mask |= 1 << element;

        switch (parent->element)
        {
            case ELEMENT_SCXML:
            switch (element)
            {
                case ELEMENT_STATE:
                    parent->e.scxml.n_state++;
                break;

                default: /* Others unhandled. */ break;
            }
            break;

            case ELEMENT_STATE:
            switch (element)
            {
                case ELEMENT_STATE:
                    parent->e.state.n_state++;
                break;

                default: /* Others unhandled. */ break;
            }
            break;

            default: /* Nothing for now. */ break;
        }
    }

    /* TODO Automate this. */
    switch (element)
    {
        case ELEMENT_SCXML:
            nodes[n_node].e.scxml.n_state = 0;
        break;
        case ELEMENT_STATE:
            nodes[n_node].e.state.n_state = 0;
        break;
        default: /* Do nothing. */ break;
    }

    parents[n_parent++] = n_node;
    nodes[n_node++].element = element;
}

static void pop_element(void)
{
    assert(n_node > 0);

    printf("Popping %s\n", element_string(element));

    n_parent--;

    struct state *states;

    switch (element)
    {
        case ELEMENT_SCXML:
            states = nodes[parents[n_parent]].e.scxml.states = malloc(sizeof (struct state) * nodes[parents[n_parent]].e.scxml.n_state);
            DIE(OOM, !states);
             
        break;

        case ELEMENT_STATE:
            states = nodes[parents[n_parent]].e.state.states = malloc(sizeof (struct state) * nodes[parents[n_parent]].e.state.n_state);
            DIE(OOM, !states);
        break;

        default:
            /* FUCK */
        break;
    }

    int state_i = 0;

    /* Pointer smartassness here. */

    /* Collect children. */
    for (int i = parents[n_parent] + 1; i < n_node; i++)
    {
        switch (nodes[i].element)
        {
            case ELEMENT_STATE:
                states[state_i++] = nodes[i].e.state;
            break;

            default: /* Nothing for now */ break;
        }
    }

    if (n_parent > 0)
    {
        unsigned min;
        switch (nodes[parents[n_parent]].element)
        {
            #define AS_CASE(P, U, L) case P##U: min = CHILDREN_ONE_MIN_##U; break
            ELEMENT_XS(ELEMENT_, AS_CASE, ;);
            #undef AS_CASE
            default: assert(!"Invalid element"); break;
        }
        DIE(MISSING_CHILD, min != (min & nodes[parents[n_parent]].mask));
    }

    printf("Had %d children\n", n_node - parents[n_parent] - 1);
    n_node = parents[n_parent] + 1;

    if (ELEMENT_SCXML == element)
    {
        assert(0 == n_parent);
        assert(1 == n_node);

        scxml = nodes[0].e.scxml;
    }

    DIE(TAG_MISMATCH, nodes[n_node - 1].element != element);
}

%%{
    machine token;
    access xml_;
    alphtype long;

    Char = 0x9 | 0xA | 0xD | 0x20..0xD7FF | 0xE000..0xFFFD | 0x10000..0x10FFFF;
    # 2 https://www.w3.org/TR/xml/#NT-Char

    S = (0x20 | 0x9 | 0xD | 0xA)+;
    # 3 https://www.w3.org/TR/xml/#NT-S

    #NameStartChar = 'a';
    NameStartChar = [:A-Z_a-z]
                  |   0xC0..0xD6   |   0xD8..0xF6   |    0xF8..0x2FF
                  |  0x370..0x37D  |  0x37F..0x1FFF |  0x200C..0x200D
                  | 0x2070..0x218F | 0x2C00..0x2FEF |  0x3001..0xD7FF
                  | 0xF900..0xFDCF | 0xFDF0..0xFFFD | 0x10000..0xEFFFF
                  ;
    # 4 https://www.w3.org/TR/xml/#NT-Name
    #NameChar = NameStartChar 'b';
    NameChar = NameStartChar | [\-.0-9] | 0xB7 | 0x0300..0x036F | 0x203F..0x2040;
    # 4a https://www.w3.org/TR/xml/#NT-NameChar
    Name = NameStartChar (NameChar)*;
    # 5 https://www.w3.org/TR/xml/#NT-Name
    Names = Name (0x20 Name)*;
    # 6 https://www.w3.org/TR/xml/#NT-Names
    Nmtoken = NameChar+;
    # 7 https://www.w3.org/TR/xml/#NT-Nmtoken
    Nmtokens = Nmtoken (0x20 Nmtoken)*;
    # 8 https://www.w3.org/TR/xml/#NT-Nmtokens

    CharRef = "&#" [0-9]+ ';'
            | "&#x" [0-9a-fA-F]+ ';';
    # 66 https://www.w3.org/TR/xml/#NT-CharRef

    EntityRef = '&' Name ';';
    # 68 https://www.w3.org/TR/xml/#NT-EntityRef
    Reference = EntityRef | CharRef;
    # 67 https://www.w3.org/TR/xml/#NT-Reference
    PEReference = '%' Name ';';
    # 69 https://www.w3.org/TR/xml/#NT-PEReference

    action buf_1 { lbuf = &lbuf1; }
    action buf_2 { lbuf = &lbuf2; }
    action buf_reset { lbuf->len = 0; }
    action buf { lbuf->it[lbuf->len++] = fc; }

    action entities_store
    {
        long *copy = malloc((lbuf2.len + 1) * sizeof (long)); 
        DIE(OOM, !copy);
        *copy = lbuf2.len;
        memcpy(copy + 1, lbuf2.it, (ADJ(lbuf2)));

        if (!raxTryInsert(ces->em, ADJ(lbuf1), copy, NULL))
        {
            free(copy);

            DIE(OOM, ENOMEM == errno);

            fprintf(stderr, "%d:%d: Repeated entity declaration ignored.\n", lineno, colno);
        }
    }

    EntityValue = ('"' ([^%&"] | PEReference | Reference)* >buf_2 >buf_reset $buf '"'
                |  "'" ([^%&'] | PEReference | Reference)* >buf_2 >buf_reset $buf "'"
                  ) %entities_store;
    # 9 https://www.w3.org/TR/xml/#NT-EntityValue
    AttValue = '"' ([^<&"] | Reference)* '"'
             | "'" ([^<&'] | Reference)* "'";
    # 10 https://www.w3.org/TR/xml/#NT-AttValue
    SystemLiteral = '"' [^"]* '"' | "'" [^']* "'";
    # 11 https://www.w3.org/TR/xml/#NT-SystemLiteral
    PubidChar = 0x20 | 0xD | 0xA | [a-zA-Z0-9'()+,./:=?;!*#@$_%\-];
    # 13 https://www.w3.org/TR/xml/#NT-PubidChar
    PubidLiteral = '"' PubidChar* '"' | "'" (PubidChar - "'")* "'";
    # 12 https://www.w3.org/TR/xml/#NT-PubidLiteral

    CharData = [^<&]* - ([^<&]* "]]>" [^<&]*);
    # 14 https://www.w3.org/TR/xml/#NT-CharData

    Comment = "<!--" ((Char - '-') | ('-' (Char - '-')))* "-->";
    # 15 https://www.w3.org/TR/xml/#NT-Comment

    PITarget = Name - "xml"i;
    # 17 https://www.w3.org/TR/xml/#NT-PITarget
    PI = "<?" PITarget (S (Char* - (Char* "?>" Char*)))? "?>";
    # 16 https://www.w3.org/TR/xml/#NT-PI

    CDStart = "<![CDATA[";
    # 19 https://www.w3.org/TR/xml/#NT-CDStart
    CDData = (Char* - (Char* "]]>" Char*));
    # 20 https://www.w3.org/TR/xml/#NT-CDData
    CDEnd = "]]>";
    # 21 https://www.w3.org/TR/xml/#NT-CDEnd
    CDSect = CDStart CDData CDEnd;
    # 18 https://www.w3.org/TR/xml/#NT-CDSect

    action external_unsupported { DIE(EXTERNAL_UNSUPPORTED, 1); }

    ExternalID = ("SYSTEM" S SystemLiteral
               | "PUBLIC" S PubidLiteral S SystemLiteral) >external_unsupported;
    # 75 https://www.w3.org/TR/xml/#NT-ExternalID

    #cp = (Name | choice | seq) [?*+]?;
    ## 48 https://www.w3.org/TR/xml/#NT-cp
    #choice = '(' S? cp (S? '|' S? cp)+ S? ')';
    ## 49 https://www.w3.org/TR/xml/#NT-choice
    #seq = '(' S? cp (S? ',' S? cp)* S? ')';
    ## 50 https://www.w3.org/TR/xml/#NT-seq
    #children = (choice | seq) [?*+]?;
    ## 47 https://www.w3.org/TR/xml/#NT-children
    # TODO Stackify (?)

    children = Name [?*+]?;
    # XXX provisionary. See above

    Mixed = '(' S? "#PCDATA" (S? '|' S? Name)* S? ')*'
          | '(' S? "#PCDATA" S? ')';
    # 51 https://www.w3.org/TR/xml/#NT-Mixed
    
    contentspec = "EMPTY" | "ANY" | Mixed | children;
    # 46 https://www.w3.org/TR/xml/#NT-contentspec
    elementdecl = "<!ELEMENT" S Name S contentspec S? ">";
    # 45 https://www.w3.org/TR/xml/#NT-elementdecl

    StringType = "CDATA";
    # 55 https://www.w3.org/TR/xml/#NT-StringType
    TokenizedType = "ID" | "IDREF" | "IDREFS"
                  | "ENTITY" | "ENTITIES"
                  | "NMTOKEN" | "NMTOKENS";
    # 56 https://www.w3.org/TR/xml/#NT-TokenizedType
    NotationType = "NOTATION" S '(' S? Name (S? '|' S? Name)* S? ')';
    # 58 https://www.w3.org/TR/xml/#NT-NotationType
    Enumeration = '(' S? Nmtoken (S? '|' S? Nmtoken)* S? ')';
    # 59 https://www.w3.org/TR/xml/#NT-Enumeration
    EnumeratedType = NotationType | Enumeration;
    # 57 https://www.w3.org/TR/xml/#NT-EnumeratedType
    AttType = StringType | TokenizedType | EnumeratedType;
    # 54 https://www.w3.org/TR/xml/#NT-AttType

    DefaultDecl = "#REQUIRED" | "#IMPLIED" | (("#FIXED" S)? AttValue);
    # 60 https://www.w3.org/TR/xml/#NT-DefaultDecl

    AttDef = S Name S AttType S DefaultDecl;
    # 53 https://www.w3.org/TR/xml/#NT-AttDef
    AttlistDecl = "<!ATTLIST" S Name AttDef* S? ">";
    # 52 https://www.w3.org/TR/xml/#NT-AttlistDecl

    NDataDecl = S "NDATA" S Name;
    # 76 https://www.w3.org/TR/xml/#NT-NDataDecl

    action entities_use_pes { ces = &pes; }
    action entities_use_ges { ces = &ges; }

    EntityDef = EntityValue | (ExternalID NDataDecl?);
    # 73 https://www.w3.org/TR/xml/#NT-EntityDef
    GEDecl = "<!ENTITY" S Name >entities_use_ges >buf_1 >buf_reset $buf S EntityDef S? '>';
    # 71 https://www.w3.org/TR/xml/#NT-GEDecl
    PEDef = EntityValue | ExternalID;
    # 74 https://www.w3.org/TR/xml/#NT-PEDef
    PEDecl = "<!ENTITY" S '%' %entities_use_pes S Name >buf_1 >buf_reset $buf S PEDef S? '>';
    # 72 https://www.w3.org/TR/xml/#NT-PEDecl
    EntityDecl = GEDecl | PEDecl;
    # 70 https://www.w3.org/TR/xml/#NT-EntityDecl

    PublicID = "PUBLIC" S PubidLiteral;
    # 83 https://www.w3.org/TR/xml/#NT-PublicID
    NotationDecl = "<!NOTATION" S Name S (ExternalID | PublicID) S? '>';
    # 82 https://www.w3.org/TR/xml/#NT-NotationDecl

    DeclSep = PEReference | S;
    # 28a https://www.w3.org/TR/xml/#NT-DeclSep
    markupdecl = elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment;
    # 29 https://www.w3.org/TR/xml/#NT-markupdecl
    intSubset = (markupdecl | DeclSep)*;
    # 28b https://www.w3.org/TR/xml/#NT-intSubset

    doctypedecl = "<!DOCTYPE" S Name (S ExternalID)? S? ('[' intSubset ']' S?)? '>';
    # 28 https://www.w3.org/TR/xml/#NT-doctypedecl

    Eq = S? '=' S?;
    # 25 https://www.w3.org/TR/xml/#NT-Eq
    VersionNum = "1." [0-9]+;
    # 26 https://www.w3.org/TR/xml/#NT-VersionNum
    VersionInfo = S 'version' Eq ("'" VersionNum "'" | '"' VersionNum '"');
    # 24 https://www.w3.org/TR/xml/#NT-VersionInfo

    action check_utf8    { DIE(ENCODING_MISMATCH, enc != ENC_UTF8);    }
    action check_utf16   { DIE(ENCODING_MISMATCH, !(ENC_UTF16 & enc)); }
    action check_utf16be { DIE(ENCODING_MISMATCH, enc != ENC_UTF16BE); }
    action check_utf16le { DIE(ENCODING_MISMATCH, enc != ENC_UTF16LE); }

    # https://www.iana.org/assignments/character-sets/character-sets.xhtml
    # Disabled names contain some character illegal in a XML EncName
    EncNameActual =    "ASCII"i         %check_utf8
                  | "US-ASCII"i         %check_utf8
                  | "iso-ir-6"i         %check_utf8
                  | "ANSI_X3.4-1968"i   %check_utf8
                  | "ANSI_X3.4-1986"i   %check_utf8
                  #| "ISO_646.irv:1991"i %check_utf8
                  | "ISO646-US"i        %check_utf8 
                  | "us"i               %check_utf8
                  | "IBM367"i           %check_utf8
                  |  "cp367"i           %check_utf8
                  | "csASCII"i          %check_utf8
                  | "UTF-8"i            %check_utf8
                  | "csUTF8"i           %check_utf8
                  | "UTF-16"i    %check_utf16
                  | "csUTF16i"i  %check_utf16
                  | "UTF-16BE"i  %check_utf16be
                  | "csUTF16BE"i %check_utf16be
                  | "UTF-16LE"i  %check_utf16le
                  | "csUTF16LE"i %check_utf16le
                  ;

    EncName = [A-Za-z] [A-Za-z0-9._\-]*;
    # 81 https://www.w3.org/TR/xml/#NT-EncName
    EncodingDecl = S "encoding" Eq ('\"' EncNameActual '\"' | '\'' EncNameActual '\'');
    # 80 https://www.w3.org/TR/xml/#NT-EncodingDecl

    SDDecl = S "standalone" Eq ("'" ("yes" | "no") "'" | '"' ("yes" | "no") '"');
    # 32 https://www.w3.org/TR/xml/#NT-SDDecl

    XMLDecl = "<?xml" VersionInfo EncodingDecl? SDDecl? S? "?>";
    # 23 https://www.w3.org/TR/xml/#NT-XMLDecl
    Misc = Comment | PI | S;
    # 27 https://www.w3.org/TR/xml/#NT-Misc
    prolog = XMLDecl? Misc* (doctypedecl Misc*)?;
    # 22 https://www.w3.org/TR/xml/#NT-prolog

    #element = EmptyElemTag | STag content ETag;
    ## 39 https://www.w3.org/TR/xml/#NT-element
    # XXX Unused because recursion.

    GenericIdentifier = Name - ("xml"i any*);
    # https://www.w3.org/TR/xml/#dt-element

    Attribute = Name Eq AttValue;
    # 41 https://www.w3.org/TR/xml/#NT-Attribute

    #STag = '<' GenericIdentifier (S Attribute)* S? '>';
    ## 40 https://www.w3.org/TR/xml/#NT-STag
    #ETag = '</' GenericIdentifier S? '>';
    ## 42 https://www.w3.org/TR/xml/#NT-ETag
    #EmptyElemTag = '<' GenericIdentifier (S Attribute)* S? "/>";
    ## 44 https://www.w3.org/TR/xml/#NT-EmptyElemTag

    #content = CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*;
    ## 43 https://www.w3.org/TR/xml/#NT-content
    # XXX Unused because recursion

    # TODO We need to turn those actions into functions, because -G2 copies a lot

    action push_element { push_element(); }
    action pop_element { pop_element(); }

    action set_a_initial { puts("attr initial"); }
    action set_a_name { puts("attr name"); }
    action reset_mask { }
    action set_a_event { puts("attr event"); }
    action set_a_id { puts("attr id"); }
    action set_a_target { puts("attr target"); }
    action set_a_early { puts("attr early"); }
    action set_a_late { puts("attr late"); }
    action set_a_deep { puts("attr deep"); }
    action set_a_shallow { puts("attr shallow"); }
    action set_a_external { puts("attr external"); }
    action set_a_internal { puts("attr internal"); }

    IDREFS = Names;
    NMTOKEN = Nmtokens;
    ID = Name;
    Boolean_expression = "true" | "false" | "In(" ID ')';

    EventToken = (NameStartChar | [0-9\-])+;
    EventDescriptor = EventToken ('.' EventToken)* ('.' '*'?)?;

    EventsTypes_datatype = '.'? '*'
                         | EventDescriptor (S EventDescriptor)*;
    # <xsd:simpleType name="EventTypes.datatype">

    #    \.? \*
    # |     (\i | \d | \-)+ ( \. (\i | \d | \-)+ )* (\. \*)?
    #   (\s (\i | \d | \-)+ ( \. (\i | \d | \-)+ )* (\. \*)? )*

    include "element.rl";

    elementActual2 = EmptyElemTagOrSTag | ETag;
    content = CharData?
            ((elementActual2 | Reference | CDSect | PI | Comment)
             CharData?
            )*;
    elementActual1 = EmptyElemTagOrSTag :> content;
    document = prolog elementActual1 <: Misc*;
    # This is the hack to handle element recursion

    #document = prolog element Misc*;
    # 1 https://www.w3.org/TR/xml/#NT-document

    TextDecl = "<?xml" VersionInfo? EncodingDecl S? "?>";
    # 77 https://www.w3.org/TR/xml/#NT-TextDecl

    extSubsetDecl = (markupdecl
#| conditionalSect
| DeclSep)*;
# TODO Resolve recursion
    # 31 https://www.w3.org/TR/xml/#NT-extSubsetDecl
    extSubset = TextDecl? extSubsetDecl;
    # 30 https://www.w3.org/TR/xml/#NT-extSubset

    includeSect = "<![" S? "INCLUDE" S? '[' extSubsetDecl "]]>";
    # 62 https://www.w3.org/TR/xml/#NT-includeSect
    Ignore = Char* - (Char* ("<![" | "]]>") Char*);
    # 65 https://www.w3.org/TR/xml/#NT-Ignore
    ignoreSectContents = Ignore ("<!["
#ignoreSectContents
"]]>" Ignore)*;
    # 64 https://www.w3.org/TR/xml/#NT-ignoreSectContents
    # TODO Resolve recursion
    ignoreSect = "<![" S? "IGNORE" S? '[' ignoreSectContents* "]]>";
    # 63 https://www.w3.org/TR/xml/#NT-ignoreSect
    conditionalSect = includeSect | ignoreSect;
    # 61 https://www.w3.org/TR/xml/#NT-conditionalSect

    extParsedEnt = TextDecl? content;
    # 78 https://www.w3.org/TR/xml/#NT-extParsedEnt

    action some_fucking_error { DIE(OTHER_ERROR, 1); }

    main := document $!some_fucking_error;

    write data noerror nofinal noentry;
}%%

int xml_cs;

void init(void)
{
    %% write init;
}

static void parse2(long usv /* Unicode scalar value. */ /*, int last TODO */)
{
    long *p = &usv, *pe = p+1, *eof = 0 ? pe : NULL;

#if 0
    unsigned char buceta[4];
    int len = utf8encode(buceta, usv);
    printf("%lx %.*s\n", usv, len, buceta);
#endif

    %% write exec;
}

static void parse(long usv)
{
    static int has_rc = 0; /* Carriage return 0xD */
    
    if (0 == lineno)
        lineno = 1;

    if (!has_rc)
    {
        if (0xD == usv)
            has_rc = 1;
        else
        {
            if (usv != 0xA)
                colno++;
            else
            {
                colno = 0;
                lineno++;
            }

            parse2(usv);
        }
    }
    else
    {
        if (0xA == usv)
        {
            has_rc = 0;
            colno = 0;
            lineno++;
            parse2(0xA);
        }
        else
        {
            colno = 0;
            lineno++;
            parse2(0xA);

            if (usv != 0xD)
            {
                colno++;
                parse2(usv);
            }
        }
    }
}

static void entities_debug(struct entities *es, char *name, char *prefix)
{
    printf("List of %s entities:\n", name);
    raxSeek(&es->iter, "^", NULL, -1);
    while (raxNext(&es->iter))
    {
        long *val = (long *)es->iter.key;
        int len = es->iter.key_len / sizeof (long);
        printf("  %s\"", prefix);
        for (int i = 0; i < len; i++)
        {
            unsigned char lala[4];
            int how = utf8encode(lala, val[i]);
            printf("%.*s", how, lala);
        }
        printf("\" ");

        val = (long *)es->iter.data;
        assert(val != NULL);
        len = *val;
        assert(len >= 0);
        val++;
        for (int i = 0; i < len; i++)
        {
            unsigned char lala[4];
            int how = utf8encode(lala, val[i]);
            printf("%.*s", how, lala);
        }
        putchar('\n');
    }
}

int main(void)
{
    {
        int i;
        char *locales[] = {
              ".UTF8"
            , ".UTF-8"
            , ".utf8"
            , ".utf-8"
        };
        DECL_MAX(locales, LOCALE);
        for (i = 0; i < LOCALE_MAX && !setlocale(LC_ALL, locales[i]); i++)
            ;
        if (LOCALE_MAX == i)
            fprintf(stderr, "UTF-8 output not setup, might be garbled.\n");
    }

    int prev = getchar();

    if (EOF == prev)
    {
        fprintf(stderr, "no input.\n");
        return 1;
    }

    long usv; // Unicode Scalar Value
    long postpone[3];
    DECL_MAX(postpone, POSTPONE);
    int n_postpone = 0;
    int cs;

    %% machine unicode;
    %% write data noerror nofinal noentry;
    %% write init;

    init();

    entities_init(&pes);
    entities_init(&ges);

    for (int curr = getchar(); prev != EOF; prev = curr, curr = getchar())
    {
        assert(prev >= 0 && prev < 256);
        unsigned char ch = prev;
        unsigned char *p = &ch, *pe = p+1, *eof = EOF == curr ? pe : NULL;

        %%{
            machine unicode;
            alphtype unsigned char;

            action err32 {
                fprintf(stderr, "Some 32-bit encoding, all of which are unsupported.\n");
                return 1;
            }

            action ebcdic {
                fprintf(stderr, "Encoding is some EBCDIC, which is unsupported.\n");
                return 1;
            }

            action ill_formed {
                // TODO Since which edition? Be more specific than "input".
                fprintf(stderr, "Ill-formed input is a fatal error.\n");
                return 1;
            }

            action set_utf8    { enc = ENC_UTF8;    }
            action set_utf16le { enc = ENC_UTF16LE; }
            action set_utf16be { enc = ENC_UTF16BE; }

            action postpone {
                assert(n_postpone < POSTPONE_MAX);
                postpone[n_postpone++] = usv;
            }

            action push_ltint { parse('<'); parse('?'); }
            action push_xm    { parse('x'); parse('m'); }
            action push       { parse(usv); }
            action push_postponed {
                for (int i = 0; i < n_postpone; i++) parse(postpone[i]);
            }

            action utf16_ini { usv = 0; }
            action utf16_diff { usv += 0x10000; }
            action utf16_bmp_high { usv = usv | (fc << 8); }
            action utf16_bmp_low  { usv = usv |  fc; }
            action utf16_leading_surrogate_high  { usv = usv | ((fc & 3) << 18); }
            action utf16_leading_surrogate_low   { usv = usv |  (fc      << 10); }
            action utf16_trailing_surrogate_high { usv = usv | ((fc & 3) <<  8); }
            action utf16_trailing_surrogate_low  { usv = usv |   fc; }
            action utf16_le_trim { usv = usv & 0x00FF; }

            utf16_bmp_high = (0..0xD7 | 0xE0..0xFF) @utf16_bmp_high;
            utf16_bmp_low = 0..0xFF @utf16_bmp_low;
            utf16_leading_surrogate_high  = 0xD8..0xDB @utf16_leading_surrogate_high;
            utf16_leading_surrogate_low   =    0..0xFF @utf16_leading_surrogate_low;
            utf16_trailing_surrogate_high = 0xDC..0xDF @utf16_trailing_surrogate_high;
            utf16_trailing_surrogate_low  =    0..0xFF @utf16_trailing_surrogate_low;

            # Big-endian is more visually intuitive.
            utf16be_bmp = utf16_bmp_high utf16_bmp_low;
            utf16be_sp = utf16_leading_surrogate_high
                         utf16_leading_surrogate_low
                         utf16_trailing_surrogate_high
                         utf16_trailing_surrogate_low;

            # Little-endian is the one visually backwards.
            utf16le_bmp = utf16_bmp_low utf16_bmp_high >utf16_le_trim;
            utf16le_sp = utf16_leading_surrogate_low
                         utf16_leading_surrogate_high
                         utf16_trailing_surrogate_low
                         utf16_trailing_surrogate_high;

            utf16be = (utf16be_bmp | utf16be_sp @utf16_diff)* @push >utf16_ini @utf16_ini;
            utf16le = (utf16le_bmp | utf16le_sp @utf16_diff)* @push >utf16_ini @utf16_ini;

            action utf8_1_ini { assert(   0 == (fc & 0x80)); usv = fc; }
            action utf8_2_ini { assert(0xC0 == (fc & 0xE0)); usv = fc & 0x1F; }
            action utf8_3_ini { assert(0xE0 == (fc & 0xF0)); usv = fc & 0xF; }
            action utf8_4_ini { assert(0xF0 == (fc & 0xF8)); usv = fc & 7; }
            action utf8_a {
                assert(0xC0 == (fc & 0xC0));
                usv = (usv << 6) + (0x3F & fc);
            }

            # But... we could simplify! NO. We don't simplify. Ragel does. And the compiler.

            utf8_fr = 0x80..0xBF;
            utf8_1 =    0..0x7f >utf8_1_ini;
            utf8_2 = 0xC2..0xDF >utf8_2_ini utf8_fr @utf8_a;
            utf8_3 = 0xE0       >utf8_3_ini (0xA0..0xFB utf8_fr) $utf8_a
                   | 0xE1..0xEC >utf8_3_ini (utf8_fr    utf8_fr) $utf8_a
                   | 0xED       >utf8_3_ini (0x80..0x9F utf8_fr) $utf8_a
                   | 0xEE..0xEF >utf8_3_ini (utf8_fr    utf8_fr) $utf8_a
                   ;
            utf8_4 = 0xF0       >utf8_4_ini (0x90..0xBF utf8_fr utf8_fr) $utf8_a
                   | 0xF1..0xF3 >utf8_4_ini (utf8_fr    utf8_fr utf8_fr) $utf8_a
                   | 0xF4       >utf8_4_ini (0x80..0x8F utf8_fr utf8_fr) $utf8_a
                   ;

            #Visualization kludge
            #utf8_1 = 'a' >utf8_1_ini;
            #utf8_2 = 'b' >utf8_2_ini 'r' $utf8_a;
            #utf8_3 = 'c' >utf8_3_ini 'rr' $utf8_a;
            #utf8_4 = 'd' >utf8_4_ini 'rrr' $utf8_a;

            utf8 = (utf8_1 | utf8_2 | utf8_3 | utf8_4)* @push;

            #Visualization kludge
            #utf16be = 'a'*;
            #utf16le = 'b'*;
            #utf8 = 'c'*;
            # Reference: https://www.w3.org/TR/xml/#sec-guessing

            guess =  0    0    0xFE 0xFF >(fuck, 1) @err32
                  |  0xFF 0xFE >(fuck, 1) 0    0    @err32
                  |  0    0    0xFF 0xFE >(fuck, 1) @err32
                  |  0xFE 0xFF >(fuck, 1) 0    0    @err32
                  |  0xFE 0xFF >(fuck, 1) @set_utf16be (utf16be - (0 0 any*))
                  |  0xFF 0xFE >(fuck, 1) @set_utf16le (utf16le - (0 0 any*))
                  |  0xEF 0xBB 0xbf      >(fuck, 1) @set_utf8 utf8
                  |  0    0    0    0x3C >(fuck, 1) @err32
                  |  0x3C 0    0    0    >(fuck, 1) @err32
                  |  0    0    0x3C 0    >(fuck, 1) @err32
                  |  0    0x3C 0    0    >(fuck, 1) @err32
                  |  0    0x3C 0    0x3F >(fuck, 1) @set_utf16be @push_ltint          utf16be
                  |  0x3C 0    0x3F 0    >(fuck, 1) @set_utf16le @push_ltint          utf16le
                  |  0x3C 0x3F 0x78 0x6D >(fuck, 1) @set_utf8    @push_ltint @push_xm utf8
                  |  0x4C 0x6F 0xA7 0x94 >(fuck, 1) @ebcdic
                  ;

            # Setting BOM for UTF-8 doesn't matter unless it's an
            # empty external entity.

            utf8_default = ( utf8_3 @postpone
                           | utf8_2 @postpone utf8_1? @postpone
                           | utf8_1 @postpone utf8_2? @postpone
                           | utf8_1 @postpone utf8_1? @postpone utf8_1? @postpone
                           )? <: utf8 >push_postponed;

            main := (guess | (utf8_default $(fuck, 0))) $!ill_formed;

            # TODO Handle presence of External Encoding Information
            #      perhaps using the `when` keyword
            #      in the case of command line argument.

            write exec;
        }%%
    }

    entities_debug(&ges, "general entities", "  ");
    entities_debug(&pes, "parameter entities", "% ");

    print_tree(&scxml);

    puts("Events\tOccurrences");

    puts("Unused events");
    
    entities_deinit(&pes);
    entities_deinit(&ges);

    return 0;
}
