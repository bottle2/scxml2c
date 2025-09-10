divert(-1)

# NOTE: Data constructors embed a dnl, so each item MUST each be on a
#       line of their own.
#
# TODO
# - Maybe we should inject all data that is needed as parameters
# - We can kind of emulate named arguments
# - For ELEMENT_XS, we want some elements to have no struct:
#   - <initial>
#   - Heterogeneous X macros
#   - I think this is precipitate
# - We should define structs inside E()
# - We should leverage thid argument of E() to:
#   - Side effects of children
#   - How to collect children 
#   - How to copy children
# - Remove that cringe P parameter of X Macros, just man up
# - Defining E(), AR(), AO(), CE(), CN(), CO() still feels very repetitive
# - That counting thing is also very duplicate

define(`RESETER',`define(`$1',`')ifelse($#,1,,`RESETER(shift($@))')')

define(`nl',`
')

define(`upper',`translit($1,a-z,A-Z)')
define(`peel',`$*')

define(`max',dnl
`$1 `$1'`_widest' `$1_widest' FUCK'
`ifdef(`$1_widest',,`define($1_widest,0)')dnl
ifelse(eval(len($2) > $1_widest),1,`define(`$1_widest',len($2))')')

define(`adv',`substr(`                                              ',
0,ifelse($#,1,len($1),`eval($1_widest-len($2))'))')

define(`advi',`substr(`                                             ',
0,$1)')

define(`RESET',`define(`$1'I)define(`$1'S)')

define(`RESET_ALL',`RESETER(
`EI',   dnl Element Item
`ES',   dnl Element Separator
`EINA', dnl Element Item      with No Attribute
`EIA',  dnl Element Item      with some Attribute
`ESA',  dnl Element Separator with some Attribute
`EIAR', dnl Element Item      with some Attribute Required
`ESAR', dnl Element Separator with some Attribute Required
`EIAO', dnl Element Item      with some Attribute non-required (Optional)
`AI',   dnl Attribute Item
`AS',   dnl Attribute Separator
`AAF',  dnl Attribute After First
`AOI',  dnl Attribute non-required (Optional) Item
`ARI',  dnl Attribute Required Item
`ARS',  dnl Attribute Required Separator
`CI',   dnl Child Item
`CS',   dnl Child Separator
`CNI',  dnl Child zero or more (N) Item
`CNS',  dnl Child zero or more (N) Separator
`COI',  dnl Child zero or One (optional) Item
`COS',  dnl Child zero or One (optional) Separator
`CEI',  dnl Child Exactly (occurs) once Item
`CES',  dnl Child Exactly (occurs) once Separator
)')

define(`E',
  `E_SEP`'dnl
`'ifelse($1_A_cnt,0,,`EA_SEP')`'dnl
`'define(`E_SEP',`ES')dnl
`'RESETER(`A_SEP', `AR_SEP', `C_SEP')dnl
`'define(`E_LAST',`$1')dnl
`'define(`A_AFTER_FIRST',`AAF')dnl
`'EI($@)`'dnl
`'ifelse($1_A_cnt,0,`'EINA($@),
    $1_A_cnt_req,0,`define(`EA_SEP',`ESA')'EIA($@)`'EIAO($@),
    `define(`EA_SEP',`ESA`'ESAR')'EIA($@)`'EIAR($@)`'dnl
`')`'dnl
`'dnl'dnl
)
define(`AO',
  `A_SEP`'dnl
`'define(`A_SEP',`AS')dnl
`'define(`Q_SEP',`')dnl
`'define(`A_LAST',`$1')dnl
`'AOI($@)`'dnl
`'AI( $@)`'dnl
`'A_AFTER_FIRST`'dnl
`'define(`A_AFTER_FIRST',`')dnl
`'dnl'dnl
)
define(`AR',
  `A_SEP`'AR_SEP`'dnl
`'define( `A_SEP',`AS')dnl
`'define(`AR_SEP',`ARS')dnl
`'define(`Q_SEP',`')dnl
`'define(`A_LAST',`$1')dnl
`'ARI($@)`'dnl
`'AI( $@)`'dnl
`'A_AFTER_FIRST`'dnl
`'define(`A_AFTER_FIRST',`')dnl
`'dnl'dnl
)
define(`CN',
  `C_SEP`'dnl
`'define(`C_SEP',`CNS`'CS')dnl
`'CNI($@)`'dnl
`'CI( $@)`'dnl
`'dnl'dnl
)
define(`CO',
  `C_SEP`'dnl
`'define(`C_SEP',`COS`'CS')dnl
`'COI($@)`'dnl
`'CI( $@)`'dnl
`'dnl'dnl
)
define(`CE',
  `C_SEP`'dnl
`'define(`C_SEP',`CES`'CS')dnl
`'CEI($@)`'dnl
`'CI( $@)`'dnl
`'dnl'dnl
)
define(`Q',
  `Q_SEP`'dnl
`'define(`Q_SEP',`QS')dnl
`'QI($@)`'dnl
`''dnl
)

define(`TAGS',`RESET_ALL`'$1`'RESETER(`E_SEP',`EA_SEP',`CU1')define(`CU2',``adv(E_LAST)'')`'dnl
E(scxml,
`'AO(initial,  Q(IDREFS, ` %set_a_initial'))
`'AO(name,     Q(NMTOKEN,` %set_a_name'))
`'AR(xmlns,    Q("http://www.w3.org/2005/07/scxml"))
`'AR(version,  Q("1.0"))
`'AO(datamodel,Q("null"))
`'AO(binding,  Q("early",` %set_a_early')Q("late",` %set_a_late'))
`',
`'CN(state,   )
`'CN(parallel,)
`'CN(final,   )
`'CO(datamodel)
`'CO(script,  )
)
E(state,
`'AO(id,     Q(ID,    ` %set_a_id'))
`'AO(initial,Q(IDREFS,` %set_a_initial'))
`',
`'CN(onentry,  )
`'CN(onexit,   )
`'CN(transition)
`'CO(initial,  )
`'CN(state,    )
`'CN(parallel, )
`'CN(final,    )
`'CN(history,  )
`'CO(datamodel,)
`'CO(invoke,   )
)
E(parallel,
`'AO(id, Q(ID,` %set_a_id'))
`',
`'CN(onentry,  )
`'CN(onexit,   )
`'CN(transition)
`'CN(state,    )
`'CN(parallel, )
`'CN(history,  )
`'CO(datamodel,)
`'CO(invoke,   )
)
define(`CU1',`adv(,E_LAST)')define(`CU2',`adv(transition)')dnl
E(transition,
`'AO(event, Q(EventsTypes_datatype))
`'AO(cond,  Q(Boolean_expression))
`'AO(target,Q(IDREFS,` %set_a_target'))
`'AO(type,  Q("internal",` %set_a_internal')Q("external",` %set_a_external'))
`',
dnl`'CN(TODO)
)
E(initial,,
`'CE(transition)
)
E(final,
`'AO(id, Q(IDREFS,` %set_a_id'))
`',
`'CN(onentry,)
`'CN(onexit, )
`'CN(donedata)
)
E(onentry,,
dnl`'CN(TODO)
)
E(onexit,,
dnl`'CN(TODO)
)
E(history,
`'AO(id,  Q(ID,` %set_a_id'))
`'AO(type,Q("deep",` %set_a_deep')Q("shallow",` %set_a_shallow'))
`',
`'CE(transition)
)
E(raise,
`'AR(event,Q(NMTOKEN,` %set_a_event'))
`',
)
E(datamodel)
E(donedata)
E(content)
E(invoke)
E(script)
')

define(`EVAL_WIDS',`dnl
`'define(`EI',`NOW $'`1 max(,$'`1)$'`2')
`'define(`AI',``FUCK max(E_LAST,'$'`1`)'')
')

define(`EVAL_COUNTS',`dnl
`'define(`EI',`define($''``1_A_cnt, len($'`2))`'define($''``1_C_cnt, len($'`3))')
`'define(`AI',`1')
`'define(`CI',`1')
')

define(`EVAL_COUNTS2',`dnl
`'define(`EI',`define($''``1_A_cnt_req, len($'`2))')
`'define(`ARI',`1')
')

define(`EVAL_COUNTS3',`dnl
`'define(`EI',`define($''``1_CE_cnt, len($'`3))')
`'define(`CEI',`1')
')

define(`EVAL_COUNTS4',`dnl
`'define(`EI',`define($''``1_CM_cnt, len($'`3))')
`'define(`CEI',`1')
`'define(`COI',`1')
')

TAGS(`EVAL_WIDS')
TAGS(`EVAL_COUNTS')
TAGS(`EVAL_COUNTS2')
TAGS(`EVAL_COUNTS3')
TAGS(`EVAL_COUNTS4')

define(`AS_ENUM_ATTRIBUTE',`dnl
`'define(`EIA',`$'`2')dnl
`'define(`ESA',`,nl    ')dnl
`'define(`AAF',` = 0')dnl
`'define(`AI',``ATTRIBUTE_`'upper(E_LAST)_''`upper($'`1)')dnl
`'define(`AS',```,''nl    ')dnl
')

define(`AS_ENUM_REQUIRED',`dnl
`'define(`EIAR',`REQUIRED_`'upper($'`1) = $'`2')dnl
`'define(`ESAR',`,nl    ')dnl
`'define(`ARI',``1 << ATTRIBUTE_`'upper(E_LAST)_''`upper($'`1)')dnl
`'define(`ARS',` | ')dnl
')

define(`AS_ENUM_CHILDREN',`dnl
`'define(`EI',`CHILDREN_`'upper($'`1) CU1= ifelse($'`1_C_cnt,0,0,$'`3)')dnl
`'define(`ES',`,nl    ')dnl
`'define(`CI',`1 << ELEMENT_`'upper($'`1)')dnl
`'define(`CS',`nl              CU2| ')dnl
')

define(`AS_ENUM_CHILDREN_ONE_MIN',`dnl
`'define(`EI',`CHILDREN_ONE_MIN_`'upper($'`1) adv(,E_LAST)= ifelse($'`1_CE_cnt,0,0,$'`3)')dnl
`'define(`ES',`,nl    ')dnl
`'define(`CEI',`1 << ELEMENT_`'upper($'`1)')dnl
`'define(`CES',`nl                       adv(transition)| ')dnl
')

define(`AS_ENUM_CHILDREN_ONE_MAX',`dnl
`'define(`EI',`CHILDREN_ONE_MAX_`'upper($'`1) adv(,E_LAST)= ifelse($'`1_CM_cnt,0,0,$'`3)')dnl
`'define(`ES',`,nl    ')dnl
`'define(`CEI',`1 << ELEMENT_`'upper($'`1)')dnl
`'define(`COI',`1 << ELEMENT_`'upper($'`1)')dnl
`'define(`CES',`nl                      adv(transition)| ')dnl
`'define(`COS',`nl                      adv(transition)| ')dnl
')

define(`AS_ACTION_SET',`dnl
`'define(`EI',`action set_e_$'`1 adv(,$'`1){ element = ELEMENT_`'upper($'`1); adv(,$'`1)puts("set $'`1");}')dnl
`'define(`ES',`nl    ')dnl
')

define(`HAVE_MACHINE',`"$1" adv(,$1)@set_e_$1')

define(`AS_MACHINE_ELEM_END',`dnl
`'define(`EI',`HAVE_MACHINE($'`1)')dnl
`'define(`ES',`nl         | ')dnl
')

define(`AS_MACHINE_ELEM_ATTR',`dnl
`'define(`EINA',`HAVE_MACHINE($'`1)')dnl
`'define(`EIAO',`EINA($'`1) adv(,$'`1)(S Attribute_$'`1`'adv(,$'`1))*')dnl
`'define(`EIAR',`EIAO($'`1) %check_required_$'`1')dnl
`'define(`ES',`nl                       | ')dnl
')

define(`INDENT_ATT',`advi(22)``adv(E_LAST)advi(E_LAST`_widest')''')

define(`AS_ATTRIBUTE',`dnl
`'define(`EIA',`Attribute_$'`1 = $'`2')dnl
`'define(`ESA',`;nl    ')dnl
`'define(`AI',`"$'`1" `adv(E_LAST,'$'`1`)'Eq ( $'`2)')dnl
`'define(`QI',`"@aq@" $'`1 "@aq@"$'`2`'nl INDENT_ATT| @aq@"@aq@ $'`1 @aq@"@aq@$'`2')dnl
`'define(`QS',`nl INDENT_ATT| ')dnl
`'define(`AS',`nl`adv(E_LAST)'               | ')dnl
')

define(`AS_ATTRIBUTE_CHECK',`dnl
`'define(`EIAR',`action check_required_$'`1 { assert(mask == (mask & REQUIRED_`'upper($'`1))); puts("checking atts of $'`1");}')dnl
`'define(`ESAR',`nl    ')dnl
')

define(`AS_X',`dnl
`'define(`EI',`X(P, upper($'`1)`'adv(,$'`1), $'`1`'adv(,$'`1))')dnl
`'define(`ES',`S \nl')dnl
')

divert(2)dnl
#ifndef ELEMENT_H
#define ELEMENT_H

#define ELEMENT_XS(P, X, S) \
TAGS(`AS_X')

enum element { ELEMENT_XS(ELEMENT_, AS_ENUM, COMMA) };

enum attribute
{
    TAGS(`AS_ENUM_ATTRIBUTE')
};

enum required
{
    TAGS(`AS_ENUM_REQUIRED')
};

enum children
{
    TAGS(`AS_ENUM_CHILDREN'),
    TAGS(`AS_ENUM_CHILDREN_ONE_MIN'),
    TAGS(`AS_ENUM_CHILDREN_ONE_MAX')
};

#endif
divert(3)dnl
%%{
    machine token;

    TAGS(`AS_ACTION_SET')

    ETag = "</"
         ( TAGS(`AS_MACHINE_ELEM_END')
         ) S? '>' >pop_element
         ;

    TAGS(`AS_ATTRIBUTE');

    TAGS(`AS_ATTRIBUTE_CHECK')

    EmptyElemTagOrSTag = '<'
                       ( TAGS(`AS_MACHINE_ELEM_ATTR')
                       ) >reset_mask S? ('/'? @pop_element '>') >push_element
                       ;
}%%
divert(0)dnl
ifelse(variant,`c',`undivert(2)',`undivert(3)')dnl
m4exit
