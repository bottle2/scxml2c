divert(-1)

# NOTE: Data constructors embed a dnl, so each item MUST each be on a
#       line of their own.
#
# TODO
# - Allow internal entities inside element attributes
#   https://github.com/ohler55/ox/issues/122
#   - Probably easier is create third machine between unicode machine and XML machine
# - Q macro becomes a list with special expansion

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
`COI',  dnl Child zero or One Item
`COS',  dnl Child zero or One Separator
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
define(`Q',
  `Q_SEP`'dnl
`'define(`Q_SEP',`QS')dnl
`'QI($@)`'dnl
`''dnl
)

define(`TAGS',`RESET_ALL`'$1`'RESETER(`E_SEP',`EA_SEP',`CU1')define(`CU2',``adv(E_LAST)'')`'dnl
E(scxml,
`'AO(initial,  Q(IDREFS, ` %set_initial'))
`'AO(name,     Q(NMTOKEN,` %set_name'))
`'AR(xmlns,    Q("http://www.w3.org/2005/07/scxml"))
`'AR(version,  Q("1.0"))
`'AO(datamodel,Q("null"))
`'AO(binding,  Q("early",` %set_early')Q("late",` %set_late'))
`',
`'CN(state,   )
`'CN(parallel,)
`'CN(final,   )
`'CO(datamodel)
`'CO(script,  )
)
E(state,
`'AO(id,     Q(ID,    ` %set_id'))
`'AO(initial,Q(IDREFS,` %set_initial'))
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
`'AO(id, Q(ID,` %set_id'))
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
`'AO(target,Q(IDREFS,` %set_target'))
`'AO(type,  Q("internal",` %set_internal')Q("external",` %set_external'))
`',
dnl`'CN(TODO)
)
E(initial,,
`'CN(transition)
)
E(final,
`'AO(id, Q(IDREFS,` %set_id'))
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
`'AO(id,  Q(ID,` %set_id'))
`'AO(type,Q("deep",` %set_deep')Q("shallow",` %set_shallow'))
`',
`'CN(transition)
)
E(raise,
`'AR(event,Q(NMTOKEN,` %set_event'))
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

TAGS(`EVAL_WIDS')
TAGS(`EVAL_COUNTS')
TAGS(`EVAL_COUNTS2')

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

define(`AS_ACTION_SET',`dnl
`'define(`EI',`action set_$'`1 adv(,$'`1){ element = ELEMENT_`'upper($'`1); adv(,$'`1)}')dnl
`'define(`ES',`nl    ')dnl
')

define(`HAVE_MACHINE',`"$1" adv(,$1)@set_$1')

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
`'define(`EIAR',`action check_required_$'`1 { assert(mask == (mask & REQUIRED_`'upper($'`1))); }')dnl
`'define(`ESAR',`nl    ')dnl
')

define(`AS_X',`dnl
`'define(`EI',`X(P, upper($'`1))')dnl
`'define(`ES',`S \nl')dnl
')

divert(2)dnl
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
    TAGS(`AS_ENUM_CHILDREN')
};
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
