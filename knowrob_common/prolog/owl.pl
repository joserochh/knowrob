/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2002, University of Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(t20_owl,
	  [ owl_restriction_on/2,	% ?Class, ?Restriction
	    owl_restriction_implied_class/2,
	    owl_merged_restriction/3,	% ?Class, ?Property, ?Restriction
	    owl_restriction/2,		% +Resource, -Restriction,
	    owl_restriction_assert/2,		% +Restriction, -Resource,
	    owl_unsatisfied_restriction/2,	% +Resource, ?Restriction
	    owl_description/2,		% +Resource, -Description
	    owl_description_assert/2,		% +Restriction, -Resource,
	    owl_property_range_on_resource/3,	% +Resource, +Pred, -Range
	    owl_property_range_on_subject/3,	% +Subject, +Pred, -Range
	    owl_property_range_on_class/3,		% +Class, +Pred, -Range
	    owl_cardinality_on_resource/4,
	    owl_cardinality_on_subject/4, % +Subject, +Predicate, +Description, -Card
	    owl_cardinality_on_class/4,	% idem BJW
	    owl_cardinality/3,
	    owl_cardinality/4,
	    owl_satisfies/2,		% +Spec, +Resource
	    owl_individual_of/2,	% ?Resource, +Description
	    owl_individual_of_description/2,
	    owl_individual_from_range/2,
	    owl_inverse_property/2,
	    owl_most_specific_predicate/2,
	    owl_most_specific/2,
	    owl_direct_subclass_of/2,	% ?Resource, ?Class
	    owl_subclass_of/2,		% ?Class, ?Super
	    owl_has/3,			% ?Subject, ?Predicate, ?Object
	    owl_has_direct/3,		% ?Subject, ?Predicate, ?Object
	    owl_same_as/2,		% ?X, ?Y
	    owl_disjoint_with/2,        % ?Class1, ?Class2
	    owl_find/5,			% +For, +Dom, ?Props, +Method, -Subj
	    non_negative_integer/4,
	    non_negative_int/2,
	    rdf_assert_literal(r,r,+)
	  ]).
:- use_module(library(lists)).
:- use_module(library('semweb/rdf_db')).
:- use_module(library('semweb/rdfs')).


		 /*******************************
		 *	    EXPANSION		*
		 *******************************/

%	user:goal_expansion(+NSGoal, -Goal)
%
%	This predicate allows for writing down rdf queries in a friendly
%	name-space fashion.

:- multifile
	user:goal_expansion/2.

:- rdf_meta
	owl_restriction_on(r, t),
	owl_restriction_implied_class(r, r),
	owl_merged_restriction(r, r, t),
	owl_restriction(r, t),
	owl_restriction_assert(t, r),
	owl_unsatisfied_restriction(r, r),
	owl_description(r, -),
	owl_description_assert(t, t),
	owl_property_range_on_resource(r, r, -),
	owl_property_range_on_subject(r, r, -),
	owl_property_range_on_class(r, r, -),
	owl_cardinality_on_resource(r, r, r, -),
	owl_cardinality_on_subject(r, r, r, -),
	owl_cardinality_on_class(r, r, r, -),
	owl_cardinality(r,r,?),
	owl_cardinality(r,r,r,?),
	owl_satisfies(r, t),
	owl_individual_of(r, t),
	owl_individual_of_description(r, t),
	owl_individual_from_range(r, t),
	owl_direct_subclass_of(r, r),
	owl_subclass_of(r, r),
	owl_has(r, r, o),
	owl_most_specific_predicate(t,t),
	owl_most_specific(t,t),
	owl_has_direct(r, r, o),
	owl_inverse_property(r, r),
	owl_same_as(r, r),
	owl_disjoint_with(r, r),
	owl_find(+, t, t, +, -).


		 /*******************************
		 *	       FACTS		*
		 *******************************/

%	owl_individual(?IndividualID, ?Type)
%	owl_property(?IndividualID, ?PropertyID, ?PropertyValue)
%	owl_same_individual(?IndividualID1, ?IndividualID2)
%	owl_different_individual(?IndividualID1, ?IndividualID2)


		 /*******************************
		 *	      AXIOMS		*
		 *******************************/

%	owl_class(?ClassID, ?Super)
%	owl_class_modality(?ClassID, ?Modality)
%	owl_same_class(?ClassID1, ?ClassID2)


		 /*******************************
		 *	   RESTRICTIONS		*
		 *******************************/

%%	owl_restriction_on(+ClassID,
%%			   -Restriction:restriction(?PropertyID, ?Restriction)) is nondet.
%
%	Enumerate the restrictions that apply to PropertyID for Class.
%	Restriction is one of
%
%		* all_values_from(Class)
%		* some_values_from(Class)
%		* has_value(Value)
%		* cardinality(Min, Max, Class)

:- rdf_meta
	rdf_phas(r,r,o).

owl_restriction_on(Class, Restriction) :-
	owl_subclass_of(Class, Super),
	(   rdfs_individual_of(Super, owl:'Restriction'),
	    owl_restriction(Super, Restriction)
	;   Restriction = restriction(Property,
				      all_values_from(Range)),
	    rdf_phas(Property, rdfs:domain, Super),
	    (	rdf_phas(Property, rdfs:range, Range)
	    *-> true
	    ;	rdf_equal(Range, rdfs:'Resource')
	    )
	).

owl_restriction_implied_class(RestrictionID, Class) :-
	rdf_has(RestrictionID, owl:allValuesFrom, Class), !.
owl_restriction_implied_class(RestrictionID, Class) :-
	rdf_has(RestrictionID, owl:someValuesFrom, Class), !.
owl_restriction_implied_class(RestrictionID, Class) :-
	restriction_facet(RestrictionID, cardinality(Min, _, Class)),
	Min > 0, !.

rdf_phas(Property, P, O) :-
	rdfs_subproperty_of(Property, Super),
	rdf_has(Super, P, O2), !,
	O = O2.

%%	owl_restriction(+Resource, -Prolog) is det.
%
%	Translate Resource, an individual of owl:restriction into a Prolog term.
%
%	@see owl_restriction_on/2 for the Prolog representation.

owl_restriction(RestrictionID, restriction(Property, Restriction)) :-
	rdf_has(RestrictionID, owl:onProperty, Property),
	restriction_facet(RestrictionID, Restriction).

restriction_facet(RestrictionID, R) :-
	(   rdf_has(RestrictionID, owl:allValuesFrom, Class)
	->  R = all_values_from(Class)
	;   rdf_has(RestrictionID, owl:someValuesFrom, Class)
	->  R = some_values_from(Class)
	).
restriction_facet(RestrictionID, has_value(Value)) :-
	rdf_has(RestrictionID, owl:hasValue, Value).
restriction_facet(R, cardinality(Min, Max, Class)) :-
	once(( rdf_has(R, owl:onClass, Class) ;
	       Class='http://www.w3.org/2002/07/owl#Thing' )),
	(   once(( rdf_has(R, owl:cardinality, literal(Atom)) ;
	           rdf_has(R, owl:qualifiedCardinality, literal(Atom)) ))
	->  non_negative_integer(Atom, Min, R, owl:qualifiedCardinality),
	    Max = Min
	;   rdf_has(R, owl:minCardinality, literal(MinAtom))
	->  non_negative_integer(MinAtom, Min, R, owl:minCardinality),
	    (   rdf_has(R, owl:maxCardinality, literal(MaxAtom))
	    ->  non_negative_integer(MaxAtom, Max, R, owl:maxCardinality)
	    ;	Max = inf
	    )
	;   rdf_has(R, owl:maxCardinality, literal(MaxAtom))
	->  non_negative_integer(MaxAtom, Max, R, owl:maxCardinality),
	    Min = 0
	).

%%	owl_restriction_assert(+Prolog, -Resource) is det.
%
owl_restriction_assert(restriction(P,all_values_from(Cls)), Id) :-
  owl_description_assert(Cls, ClsId),
  rdf_instance_from_class(owl:'Restriction', Id),
  rdf_assert(Id, owl:onProperty, P),
  rdf_assert(Id, owl:allValuesFrom, ClsId), !.
owl_restriction_assert(restriction(P,some_values_from(Cls)), Id) :-
  owl_description_assert(Cls, ClsId),
  rdf_instance_from_class(owl:'Restriction', Id),
  rdf_assert(Id, owl:onProperty, P),
  rdf_assert(Id, owl:someValuesFrom, ClsId), !.
owl_restriction_assert(restriction(P,cardinality(Card,Card,Cls)), Id) :- !,
  owl_description_assert(Cls, ClsId),
  rdf_instance_from_class(owl:'Restriction', Id),
  rdf_assert(Id, owl:onProperty, P),
  rdf_assert(Id, owl:onClass, ClsId),
  rdf_assert_literal(Id, owl:cardinality, Card), !.
owl_restriction_assert(restriction(P,cardinality(Min,Max,Cls)), Id) :-
  owl_description_assert(Cls, ClsId),
  rdf_instance_from_class(owl:'Restriction', Id),
  rdf_assert(Id, owl:onProperty, P),
  rdf_assert(Id, owl:onClass, ClsId),
  once(( Min is 0 ;  rdf_assert_literal(Id, owl:minCardinality, Min) )),
  once(( Max = inf ; rdf_assert_literal(Id, owl:maxCardinality, Max) )), !.
owl_restriction_assert(restriction(P,has_value(V)), Id) :-
  rdf_instance_from_class(owl:'Restriction', Id),
  rdf_assert(Id, owl:onProperty, P),
  rdf_assert(Id, owl:hasValue, V), !.

%	non_negative_integer(+Atom, -Integer, +Subject, +Predicate)
%
%	Deduce integer value from rdf(Subject, Predicate, literal(Atom))
%	and if a conversion error occurs warn compatible to the rdfs_validate
%	library.
%
%	TBD: If argument is typed we should check the type is compatible
%	to xsd:nonNegativeInteger.

non_negative_integer(type(_Type, Atom), Int, S, P) :-
	nonvar(Atom), !,
	non_negative_integer(Atom, Int, S, P).
non_negative_integer(Atom, Int, _, _) :-
	catch(atom_number(Atom, Int), _, fail), !,
	integer(Int),
	Int >= 0.
non_negative_integer(Atom, _, S, P) :-
	rdf_equal(xsd:nonNegativeInteger, Range),
	rdf_global_id(P, Pred),
	print_message(error,
		      rdf_illegal_object(S,Pred,literal(Atom),Range)),
	fail.

%%	owl_merged_restriction(+Class, ?Property, ?Restriction) is nondet.
%
%	As owl_restriction_on/2, but combines multiple restrictions into
%	the   least   strict   restriction   satisfying   the   declared
%	restrictions.

owl_merged_restriction(Class, Property, Restriction) :-
	setof(Decl,
	      owl_restriction_on(Class, restriction(Property, Decl)),
	      Decls),
	join_decls(Decls, Minimal),
	member(Restriction, Minimal).

%	input is sorted, thus the following holds:
%
%		cardinality < has_value < values_from

join_decls([], []).
join_decls([cardinality(Min1, Max1), cardinality(Min2, Max2)|T], Set) :- !,
	Min is max(Min1, Min2),
	max_cardinality(Max1, Max2, Max),
	join_decls([cardinality(Min, Max)|T], Set).
join_decls([has_value(Value)|T], [has_value(Value)]) :- !,
	satisfies_restrictions(T, Value).
join_decls([values_from(AS1, C1), values_from(AS2, C2)|T], Set) :-
	merge_values_from(AS1, C1, AS2, C2, AS, C), !,
	join_decls([values_from(AS, C)|T], Set).
join_decls([H|T0], [H|T]) :-
	join_decls(T0, T).

max_cardinality(infinite, Min, Min) :- !.
max_cardinality(Min, infinite, Min) :- !.
max_cardinality(Min1, Min2, Min) :-
	Min is min(Min1, Min2).

%	satisfies_restrictions(+Restrictions, +Value)
%
%	See whether Value satisfies all restrictions, so we can indeed
%	use it as a value.

satisfies_restrictions([], _).
satisfies_restrictions([H|T], Value) :-
	satisfies_restriction(H, Value),
	satisfies_restrictions(T, Value).

satisfies_restriction(has_value(Value), Value).
satisfies_restriction(values_from(some, _), _).
satisfies_restriction(values_from(all, Class), Value) :-
	rdfs_individual_of(Value, Class).

%	merge_values_from(+AllSome2, +C1, +AllSome2, +C2, -AllSome, -C)
%
%	Merge multiple allValuesFrom and someValuesFrom restrictions.
%	This needs some thought, but as we don't need it for the MIA
%	tool right now we'll leave it.

merge_values_from(all, C1, all, C2, all, C) :-
	rdfs_subclass_of(C, C1),
	rdfs_subclass_of(C, C2).

%%	owl_property_range_on_resource(+Resource, +Pred, -Range) is semidet.
%
owl_property_range_on_resource(Resource, Predicate, Range) :-
	rdfs_individual_of(Resource, owl:'Class'), !,
	owl_property_range_on_class(Resource, Predicate, Range).
owl_property_range_on_resource(Resource, Predicate, Range) :-
	owl_property_range_on_subject(Resource, Predicate, Range).

%%	owl_property_range_on_subject(+Subject, +Pred, -Range) is semidet.
%
owl_property_range_on_subject(Subject, Predicate, Range) :-
	findall(R, range_on_subject(Subject, Predicate, R), Ranges),
	(  Ranges=[]
	-> Range='http://www.w3.org/2002/07/owl#Thing'
	;  member(Range, Ranges) ).

range_on_subject(Subject, Predicate, Range) :-
	% infer range based on value type of functional property
	owl_inverse_property(Predicate, Predicate_inv),
	once(( rdfs_individual_of(Predicate, owl:'FunctionalProperty') ;
	       rdfs_individual_of(Predicate_inv, owl:'InverseFunctionalProperty') )),
	once(( rdf_has(Subject, Predicate, O) ;
	       rdf_has(O, Predicate_inv, Subject) )),
	rdf_has(O, rdf:type, Range),
	Range \= 'http://www.w3.org/2002/07/owl#Thing',
	Range \= 'http://www.w3.org/2002/07/owl#NamedIndividual'.

range_on_subject(Subject, Predicate, Range) :-
	rdf_has(Subject, rdf:type, Class),
	range_on_class(Class, Predicate, Range).


%%	owl_property_range_on_class(+Subject, +Pred, -Range) is semidet.
%
owl_property_range_on_class(Class, Predicate, Range) :-
	findall(R, (
		range_on_class(Class, Predicate, R) ;
		rdf_phas(Predicate, rdfs:range, R)
	), Ranges),
	owl_most_specific(Ranges, Ranges_specific),
	findall(R, (
		member(X, Ranges_specific),
		once(( range_on_cardinality(Class, Predicate, X, R) ; R=X ))
	), Ranges_cardinality),
	(  Ranges_cardinality=[]
	-> Range='http://www.w3.org/2002/07/owl#Thing'
	;  member(Range, Ranges_cardinality) ).

range_on_cardinality(_, _, 'http://www.w3.org/2002/07/owl#Thing',
                           'http://www.w3.org/2002/07/owl#Thing') :- !.
range_on_cardinality(Class, Predicate, RangeIn, RangeOut) :-
	% for each range, find terminal classes that are subclass of range
	% FIXME: this is potentially very slow when there is a large nuber of terminal subclasses
	findall(X, owl_terminal_subclass_of(RangeIn, X), Terminals),
	length(Terminals, NumTerminals), NumTerminals > 1,
	once(((
		% if class restriction, use infered inverse predicate range for cardinality computation
		rdfs_individual_of(Class, owl:'Restriction'),
		rdf_has(Class, owl:onProperty, P_restr),
		owl_restriction_implied_class(Class, Restr_cls),
		owl_inverse_property(P_restr, P_inv),
		owl_property_range_on_class(Restr_cls, P_inv, CardCls)
	);(
		CardCls = Class
	))),
	% infer cardinality for each terminal class [AxleSnapInFBack:1,AxleSnapInFFront:0,AxleSnapInM:1]
	findall(X, (
		member(X,Terminals),
		( owl_cardinality_on_class(CardCls, Predicate, X, cardinality(Min,_))
		-> Min > 0 ; true )
	), RangesOut),
	% if a terminal class was eliminated with cardinality=0 then create union class of remaining
	length(RangesOut, NumCandidates), NumCandidates < NumTerminals,
	(  RangesOut=[X]
	-> RangeOut=X
	;  owl_description_assert(union_of(RangesOut), RangeOut)
	).

range_on_class(Class, Predicate, Range) :-
	rdf_has(Class, owl:unionOf, Set),
	rdfs_list_to_prolog_list(Set, Members),
	findall(R, (
		member(Descr, Members),
		range_on_class(Descr, Predicate, R)
	), Ranges),
	% if each union member restricts the range
	length(Ranges, N), length(Members, N),
	owl_common_ancestor(Ranges, Range),
	\+ rdf_equal(Range, owl:'Thing').

range_on_class(Class, Predicate, Range) :-
	rdf_has(Class, owl:intersectionOf, Set),
	rdfs_list_to_prolog_list(Set, Members),
	member(Descr, Members),
	range_on_class(Descr, Predicate, Range).

range_on_class(Class, Predicate, Range) :-
	rdfs_subclass_of(Class, RestrictionID),
	once((
		rdfs_individual_of(RestrictionID, owl:'Restriction'),
		owl_restriction(RestrictionID, Restr),
		range_on_restriction(Restr, Predicate, Range)
	)).

range_on_restriction(restriction(Predicate, has_value(Range)),       Predicate, Range) :- !.
range_on_restriction(restriction(Predicate, all_values_from(Range)), Predicate, Range) :- !.
range_on_restriction(restriction(P,         Facet),                  Predicate, Range) :-
	% infer range from inverse restrictions
	P \= Predicate,
	once(( Facet=all_values_from(Cls) ;
		   Facet=some_values_from(Cls) ;
		 ( Facet=cardinality(Min,_,Cls), Min > 0 ) )),
	Cls \= 'http://www.w3.org/2001/XMLSchema#anyURI',
	owl_inverse_property(P, P_inv),
	range_on_class(Cls, P_inv, Cls_P_inv_range), % FIXME: may causes infinite loops
	once((
		range_on_class(Cls_P_inv_range, Predicate, Range_inv) ;
		Range_inv = 'http://www.w3.org/2002/07/owl#Thing'
	)),
	(  Range_inv \= 'http://www.w3.org/2002/07/owl#Thing'
	-> Range=Range_inv ; (
	   owl_inverse_property(Predicate, Predicate_inv),
	   owl_description_assert(restriction(Predicate_inv,
	                          some_values_from(Cls_P_inv_range)), Range)
	)).

		 /*******************************
		 *	    CARDINALITY		*
		 *******************************/

cardinality_on_property(Predicate, cardinality(0,1)) :-
	rdfs_individual_of(Predicate, owl:'FunctionalProperty').


owl_cardinality_on_resource(Resource, Predicate, Range, Cardinality) :-
	rdfs_individual_of(Resource, owl:'Class'), !,
	owl_cardinality_on_class(Resource, Predicate, Range, Cardinality).
owl_cardinality_on_resource(Resource, Predicate, Range, Cardinality) :-
	owl_cardinality_on_subject(Resource, Predicate, Range, Cardinality).

%%	owl_cardinality_on_subject(+Subject, +Pred, +Descr, -Card:cardinality(Min, Max)) is semidet.
%
%	Deduces the minimum and maximum cardinality for a property of a
%	resource.  This predicate may fail if no information is available.
%
% TODO(DB): infer min cardinality by counting (S,P,O) triples?

owl_cardinality_on_subject(Subject, Predicate, Range, Cardinality) :-
	findall(C, (
		cardinality_on_property(Predicate, C) ;
		cardinality_on_subject(Subject, Predicate, Range, C)
	), L),
	join_decls(L, [Cardinality]).

cardinality_on_subject(Subject, Predicate, Range, C) :-
	rdf_has(Subject, rdf:type, Class),
	once( rdf_has(Class, rdfs:subClassOf, _) ),
	( cardinality_on_class(Class, Predicate, Range, C)
	; cardinality_from_sibling_range(Class, Predicate, Range, C) ).

%%	owl_cardinality_on_class(+Class, ?Predicate, ?Range, -Card:cardinality(Min, Max)) is semidet.
%
% TODO(DB): could also infer min cardinality based on restrictions on parent and siblings
%		--> accumulate max values and take difference to superclass min value (only if all direct subclasses restricted)
%
owl_cardinality_on_class(Class, Predicate, Range, Cardinality) :-
	ground(Range),
	findall(C, (
		  cardinality_on_property(Predicate, C)
		; cardinality_on_class(Class, Predicate, Range, C)
		; cardinality_from_sibling_range(Class, Predicate, Range, C)
	), L),
	join_decls(L, [Cardinality]).

cardinality_on_class(Class, Predicate, Range, cardinality(Min, Max)) :-
	once( rdf_has(Class, rdfs:subClassOf, _) ),
	rdfs_subclass_of(Class, RestrictionID),
	rdfs_individual_of(RestrictionID, owl:'Restriction'),
	rdf_has(RestrictionID, owl:onProperty, P),
	once( rdfs_subproperty_of(P,Predicate) ),
	restriction_facet(RestrictionID, cardinality(Min_restr, Max_restr, Descr)),
	(  Descr = Range
	-> ( Min is Min_restr, Max is Max_restr )
	;  ( rdfs_individual_of(Range, Descr), Min is 0, Max is Max_restr )
	).

cardinality_from_sibling_range(Class, Predicate, Range, cardinality(0, Max)) :-
	% infer cardinality of parent
	rdf_has(Range, rdfs:subClassOf, SR),
	once(rdf_has(SR, rdfs:subClassOf, _)),
	cardinality_on_class(Class, Predicate, SR, cardinality(_, Max_sr)),
	% infer cardinality of siblings
	findall(Min_other, (
		rdf_has(Range_other, rdfs:subClassOf, SR),
		Range_other \= Range,
		cardinality_on_class(Class, Predicate, Range_other, cardinality(Min_other, _))
	),	Min_others),
	Min_others \= [],
	% compute maximum cardinality from accumulated min cardinality of siblings
	sumlist(Min_others, Card_reserved),
	Allowed is Max_sr - Card_reserved,
	( Allowed < 0 -> Max is 0 ; Max is Allowed ).

%%	owl_unsatisfied_restriction(?Resource, +Restriction)
%	
%	True if Resource does not satisfy the class description Restriction.
%	

owl_unsatisfied_restriction(Resource, Restriction) :-
	ground(Restriction), ground(Resource), !,
	\+ owl_satisfies_restriction(Resource, Restriction).
owl_unsatisfied_restriction(Resource, Restriction) :-
	ground(Resource),
	bagof(Cls, (
		rdfs_individual_of(Resource, Cls),
		rdfs_individual_of(Cls, owl:'Restriction')
	), Restrictions),
	member(Restriction, Restrictions),
	\+ owl_satisfies_restriction(Resource, Restriction).

%%	owl_satisfies_restriction(?Resource, +Restriction)
%
%	True if Resource satisfies the restriction imposed by Restriction.
%	The current implementation makes the following assumptions:
%
%		* Only one of owl:hasValue, owl:allValuesFrom or owl:someValuesFrom
%		  is present.

owl_satisfies_restriction(Resource, Restriction) :-
	rdf_has(Restriction, owl:onProperty, Property),
	once( owl_satisfies_restriction_internal(Resource, Property, Restriction) ),
	once( owl_satisfies_cardinality(Resource, Restriction) ), !.
owl_satisfies_restriction_internal(Resource, Property, Restriction) :-
	rdf_has(Restriction, owl:hasValue, Value), !,
	owl_has(Resource, Property, Value).
owl_satisfies_restriction_internal(Resource, Property, Restriction) :-
	rdf_has(Restriction, owl:allValuesFrom, Class), !,
	once(( bagof(V, owl_has(Resource, Property, V), Vs) ; Vs=[] )),
	all_individual_of(Vs, Class).
owl_satisfies_restriction_internal(Resource, Property, Restriction) :-
	rdf_has(Restriction, owl:someValuesFrom, Class), !,
	owl_has(Resource, Property, Value),
	owl_individual_of(Value, Class).
owl_satisfies_restriction_internal(Resource, Property, Restriction) :-
	rdf_has(Restriction, owl:onClass, Class), !,
	owl_has(Resource, Property, Value),
	owl_individual_of(Value, Class).
owl_satisfies_restriction_internal(Resource, _, _) :-
	rdf_subject(Resource).

all_individual_of([], _).
all_individual_of([H|T], Class) :-
	owl_individual_of(H, Class), !,
	all_individual_of(T, Class).

%	owl_satisfies_cardinality(?Resource[, +Property], +Restriction)
%
%	True if Resource satisfies the cardinality restrictions on
%	Property imposed by Restriction.

owl_satisfies_cardinality(Resource, Restriction) :-
	rdf_has(Restriction, owl:onProperty, Property),
	owl_satisfies_cardinality(Resource, Property, Restriction).

owl_satisfies_cardinality(Resource, Property, Restriction) :-
	once(( rdf_has(Restriction, owl:cardinality, literal(Atom)) ;
	       rdf_has(Restriction, owl:qualifiedCardinality, literal(Atom)) )), !,
	non_negative_int(Atom, Card),
	once(( rdf_has(Restriction, owl:onClass, Cls) ;
	       Cls='http://www.w3.org/2002/07/owl#Thing' )),
	owl_cardinality(Resource, Property, Cls, Card).
owl_satisfies_cardinality(Resource, Property, Restriction) :-
	rdf_has(Restriction, owl:minCardinality, literal(MinAtom)),
	non_negative_int(MinAtom, Min), !,
	once(( rdf_has(Restriction, owl:onClass, Cls) ;
	       Cls='http://www.w3.org/2002/07/owl#Thing' )),
	owl_cardinality(Resource, Property, Cls, Count),
	Count >= Min,
	(   rdf_has(Restriction, owl:maxCardinality, literal(MaxAtom)),
	    atom_number(MaxAtom, Max)
	->  Count =< Max
	;   true
	).
owl_satisfies_cardinality(Resource, Property, Restriction) :-
	rdf_has(Restriction, owl:maxCardinality, literal(MaxAtom)),
	non_negative_int(MaxAtom, Max), !,
	once(( rdf_has(Restriction, owl:onClass, Cls) ;
	       Cls='http://www.w3.org/2002/07/owl#Thing' )),
	owl_cardinality(Resource, Property, Cls, Count),
	Count =< Max.
owl_satisfies_cardinality(Resource, _, _) :-
	rdf_subject(Resource).

non_negative_int(type(Type, Atom), Number) :-
	rdf_equal(xsd:nonNegativeInteger, Type),
	catch(atom_number(Atom, Number), _, fail).
non_negative_int(Atom, Number) :-
	atom(Atom),
	catch(atom_number(Atom, Number), _, fail).

%%	owl_cardinality(+Resource, +Property, +Cls, -Card) is det.
owl_cardinality(Resource, Property, Cls, Card) :-
	once((bagof(V, (
		owl_has(Resource, Property, V), % need to use owl_has here for property chains
		once(owl_individual_of(V,Cls))
	), Vs) ; Vs=[])),
	length(Vs, Card).
%%	owl_cardinality(+Resource, +Property, -Card) is det.
owl_cardinality(Resource, Property, Card) :-
	once((bagof(V, owl_has(Resource, Property, V), Vs) ; Vs=[])),
	length(Vs, Card).


		 /*******************************
		 *	    DESCRIPTION		*
		 *******************************/

%%	owl_description(+DescriptionID, -Prolog) is det.
%
%	Convert an owl description into a Prolog representation.  This
%	representation is:
%
%		* class(Class)
%		* restriction(Property, Restriction)
%		* union_of(ListOfDescriptions)
%		* intersection_of(ListOfDescriptions)
%		* complement_of(Description)
%		* one_of(Individuals)
%		* thing
%		* nothing
%
%	where Restriction is defined by owl_restriction_on/2.
%	For example, the union-of can be the result of
%
%	==
%	<rdfs:Class rdf:ID="myclass">
%	  <owl:unionOf parseType=Collection>
%	    <rdf:Description rdf:about="gnu"/>
%	    <rdf:Description rdf:about="gnat"/>
%	  </owl:unionOf>
%	</rdfs:Class>
%	==

owl_description(Restriction, Restriction) :- compound(Restriction), !.

owl_description(ID, Restriction) :-
	(   rdf_equal(owl:'Thing', ID)
	->  Restriction = thing
	;   rdf_equal(owl:'Nothing', ID)
	->  Restriction = nothing
	;   rdf_has(ID, rdf:type, owl:'Restriction')
	->  owl_restriction(ID, Restriction)
	;   rdf_has(ID, rdf:type, owl:'Class')
	->  (   (   rdf_has(ID, owl:unionOf, Set)
		->  Restriction = union_of(SubDescriptions)
		;   rdf_has(ID, owl:intersectionOf, Set)
		->  Restriction = intersection_of(SubDescriptions)
		)
	    ->	rdfs_list_to_prolog_list(Set, Members),
		maplist(owl_description, Members, SubDescriptions)
	    ;	rdf_has(ID, owl:complementOf, Arg)
	    ->	Restriction = complement_of(SubDescription),
		owl_description(Arg, SubDescription)
	    ;	rdf_has(ID, owl:oneOf, Arg)
	    ->	Restriction = one_of(Individuals),
		rdfs_list_to_prolog_list(Arg, Individuals)
	    ;	Restriction = class(ID)
	    )
	).

%%	owl_description_assert(+Prolog, -Resource) is det.
%
owl_description_assert(Cls, Cls) :- atom(Cls), !.
owl_description_assert(class(Cls), Cls) :- !.
owl_description_assert(thing, 'http://www.w3.org/2002/07/owl#Thing') :- !.
owl_description_assert(nothing, 'http://www.w3.org/2002/07/owl#Nothing') :- !.
owl_description_assert(restriction(P,Facet), Id) :-
  owl_restriction_assert(restriction(P,Facet), Id), !.
owl_description_assert(union_of(List), Id) :-
  rdf_instance_from_class(owl:'Class', Id),
  owl_description_list_assert(List,ListId),
  rdf_assert(Id, owl:unionOf, ListId), !.
owl_description_assert(intersection_of(List), Id) :-
  rdf_instance_from_class(owl:'Class', Id),
  owl_description_list_assert(List,ListId),
  rdf_assert(Id, owl:intersectionOf, ListId), !.
owl_description_assert(complement_of(Cls), Id) :-
  rdf_instance_from_class(owl:'Class', Id),
  owl_description_assert(Cls,ClsId),
  rdf_assert(Id, owl:complementOf, ClsId), !.
owl_description_assert(one_of(List), Id) :-
  rdf_instance_from_class(owl:'Class', Id),
  owl_description_list_assert(List,ListId),
  rdf_assert(Id, owl:oneOf, ListId), !.

owl_description_list_assert([], 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil') :- !.
owl_description_list_assert(List, ListId) :-
  rdf_instance_from_class(rdf:'List', ListId),
  owl_description_list_assert_(ListId, List).

owl_description_list_assert_(Id, [First|Rest]) :-
  owl_description_assert(First, FirstId),
  owl_description_list_assert(Rest, RestId),
  rdf_assert(Id, rdf:'first', FirstId),
  rdf_assert(Id, rdf:'rest', RestId).

rdf_assert_literal(S,P,V) :-
  once(( (atom(V), V_atom=V) ; atom_number(V_atom,V) )),
  rdf_assert(S, P, literal(V_atom)).

		 /*******************************
		 *	   OWL_SATISFIES	*
		 *******************************/

%%	owl_satisfies(+Specification, ?Resource) is nondet.
%
%	Test whether Resource satisfies Specification. All resources are
%	considered to belong  to  rdfs:Resource,   which  is  not really
%	enforced. Domain is one of
%
%	| rdfs:Resource		   | Allow for any resource	  |
%	| class(Class)		   | Allow for a subclass of Class|
%	| union_of(Domains)	   |				  |
%	| intersection_of(Domains) |				  |
%	| complement_of(Domain)	   |				  |
%	| one_of(Resources)	   | One of these values	  |
%	| all_values_from(Class)   | Individual of this class	  |
%	| some_values_from(Class)  | Not used			  |
%	| has_value(Value)	   | Must have this value	  |
%
%	Resource can be a term individual_of(Class),  in which case this
%	predicate succeeds if any individual  of   Class  is accepted by
%	Domain.

					% Short-cut
owl_satisfies(Domain, Resource) :-
	rdf_equal(rdfs:'Resource', Domain), !,
	(   atom(Resource)
	->  true
	;   var(Resource)
	->  rdf_subject(Resource)
	;   Resource = individual_of(_)
	).
					% Descriptions
owl_satisfies(class(Domain), Resource) :- !,
	(   rdf_equal(Domain, rdfs:'Resource')
	->  true
	;   Resource = individual_of(Class),
	    atom(Class)
	->  fail
	;   owl_subclass_of(Resource, Domain)
	).
owl_satisfies(union_of(Domains), Resource) :- !,
	member(Domain, Domains),
	owl_satisfies(Domain, Resource).
owl_satisfies(intersection_of(Domains), Resource) :- !,
	in_all_domains(Domains, Resource).
owl_satisfies(complement_of(Domain), Resource) :- !,
	(   atom(Resource)
	->  true
	;   var(Resource)
	->  rdf_subject(Resource)
	;   fail			% individual_of(Class)
	),
	\+ owl_satisfies(Domain, Resource).
owl_satisfies(one_of(List), Resource) :- !,
	member(Resource, List).
					% Restrictions
owl_satisfies(all_values_from(Domain), Resource) :- !,
	(   Resource = individual_of(Class),
	    atom(Class)
	->  owl_subclass_of(Class, Domain)
	;   owl_individual_of(Resource, Domain)
	).
owl_satisfies(some_values_from(_Domain), _Resource) :- !.
owl_satisfies(has_value(Value), Resource) :-
	rdf_equal(Value, Resource).	% TBD: equality


in_all_domains([], _).
in_all_domains([H|T], Resource) :-
	owl_satisfies(H, Resource),
	in_all_domains(T, Resource).


		 /*******************************
		 *	   INDIVIDUAL OF	*
		 *******************************/

%%	owl_individual_of(?Resource, +Description) is nondet.
%
%	Test  or  generate  the  resources    that  satisfy  Description
%	according the the OWL-Description entailment rules.

owl_individual_of(Resource, Thing) :-
	rdf_equal(Thing, owl:'Thing'), %!, MT 16032011
	(   atom(Resource)
	->  true
	;   rdf_subject(Resource)
	).
owl_individual_of(_Resource, Nothing) :-
	rdf_equal(Nothing, owl:'Nothing'), %!, MT 16032011
	fail.
owl_individual_of(Resource, Description) :-			% RDFS
	rdfs_individual_of(Resource, Description).
owl_individual_of(Resource, Class) :-
	nonvar(Resource),
	setof(C, rdf_has(Resource, rdf:type, C), Cs), %!, MT 16032011
	member(C, Cs),
	owl_subclass_of(C, Class).
owl_individual_of(Resource, Class) :-
        nonvar(Class), % MT 03122014 -- does not allow generic classification of instances any more, but avoids search through all equivalents of all classes whenever Class is unbound
	rdfs_individual_of(Class, owl:'Class'),
	(   rdf_has(Class, owl:equivalentClass, EQ)
	->  owl_individual_of(Resource, EQ)
	;   rdfs_individual_of(Class, owl:'Restriction')
	->  owl_satisfies_restriction(Resource, Class)
	;   owl_individual_of_description(Resource, Class),
	    findall(SC, rdf_has(Class, rdfs:subClassOf, SC), SuperClasses),
	    owl_individual_of_all(SuperClasses, Resource)
	).
owl_individual_of(Resource, Description) :-			% RDFS
	owl_individual_from_range(Resource, Description).


%%	owl_individual_of_description(?Resource, +Description) is nondet.
%
% 	@tbd	Can a description have multiple of these facets?

owl_individual_of_description(Resource, Description) :-
	(   rdf_has(Description, owl:unionOf, Set)
	->  rdfs_member(Sub, Set),
	    owl_individual_of(Resource, Sub)
	;   rdf_has(Description, owl:intersectionOf, Set)
	->  intersection_of(Set, Resource)
	;   rdf_has(Description, owl:complementOf, Arg)
	->  rdf_subject(Resource),
	    \+ owl_individual_of(Resource, Arg)
	;   rdf_has(Description, owl:oneOf, Arg)
	->  rdfs_member(Resource, Arg)
	;   fail			% not an OWL description % MT: changed to 'fail' -> TODO: check if this makes problems if the super-class *is* a restriction
	).


owl_individual_of_all([], _).
owl_individual_of_all([C|T], Resource) :-
	owl_individual_of(Resource, C),
	owl_individual_of_all(T, Resource).


owl_individual_from_range(Resource, Class) :-
	nonvar(Resource), !,
	rdf_has(_, P, Resource), atom(P), % DB: P could be inverse_of(..)
	rdf_has(P, rdfs:range, Class), !.
owl_individual_from_range(Resource, Class) :-
	rdf_has(P, rdfs:range, Class),
	rdf_has(_, P, Resource).	% owl_has?

intersection_of(List, Resource) :-
	rdf_has(List, rdf:first, First),
	owl_individual_of(Resource, First),
	(   rdf_has(List, rdf:rest, Rest)
	->  intersection_of(Rest, Resource)
	;   true
	).
intersection_of(Nil, _) :-
	rdf_equal(rdf:nil, Nil).


		 /*******************************
		 *	  AUX PREDS (CIRC)	*
		 *******************************/

% An element in a property chain is either an object property or a description
% containing an owl:inverseOf some object property.
owl_chain_property(Ch, Pr) :-
        var(Ch),
        nonvar(Pr),
        Ch = Pr.
        
owl_chain_property(Ch, Pr) :-
        nonvar(Ch),
        rdfs_individual_of(Ch, owl:'ObjectProperty'),
        Ch = Pr.
owl_chain_property(Ch, Pr) :-
        nonvar(Ch),
        \+ rdfs_individual_of(Ch, owl:'ObjectProperty'),
        rdf_has(Ch, owl:inverseOf, Pr).

kr_get_props([], Props, Props).

kr_get_props([ChainFirst|RestChain], CrProps, Props) :-
        owl_chain_property(ChainFirst, Property),
        kr_get_props(RestChain, [Property|CrProps], Props).

kr_get_props(PropChain, Props) :-
        kr_get_props(PropChain, [], Props).

kr_circular_chain(ChainProperties, PreviousProperties) :-
        member(P, PreviousProperties),
        member(P, ChainProperties).

kr_circular_chain(ChainProperties, PreviousProperties) :-
        member(P, PreviousProperties),
        rdf_has(P, owl:inverseOf, IP),
        member(IP, ChainProperties).

kr_circular_chain(ChainProperties, PreviousProperties) :-
        member(CP, ChainProperties),
        rdf_has(CP, owl:propertyChainAxiom, RDFList),
        rdfs_list_to_prolog_list(RDFList, CPChain),
        kr_get_props(CPChain, CPProps),
        append(PreviousProperties, ChainProperties, NewPreviousProperties),
        kr_circular_chain(CPProps, NewPreviousProperties).

		 /*******************************
		 *	  OWL PROPERTIES	*
		 *******************************/

%%	owl_has(?Subject, ?Predicate, ?Object)
%
%	True if this relation is specified or can be deduced using OWL
%	inference rules.  It adds transitivity to owl_has_direct/3.

owl_has(S, P, O) :-
	(   var(P)
	->  rdf_current_predicate(P)
	;   true
	),
% 	rdf_reachable(SP, rdfs:subPropertyOf, P),
% 	owl_has_transitive(S, SP, O).
  owl_has_transitive(S, P, O).


%%	owl_has_transitive(?Subject, ?Predicate, ?Object)
%
%	If Predicate is transitive, do a transitive closure on the
%	relation.

owl_has_transitive(S, P, O) :-
	rdfs_individual_of(P, owl:'TransitiveProperty'), !,
	owl_has_transitive(S, P, O, [P]).
owl_has_transitive(S, P, O) :-
	owl_has_equivalent(S, P, O).

owl_has_transitive(S, P, O, Visited) :-
  rdf_reachable(SP, rdfs:subPropertyOf, P),
	owl_has_equivalent(S, SP, O1),          % MT: pulled the rdfs_subprop_of in here to allow transitive sup-property chains
	O1 \= literal(_),                       %     of the form P -> SP1 -> SP2 -> P ->... with SP1, SP2 transitive sub-properties of P
	\+ memberchk(O1, Visited),
	(   O = O1
	;   owl_has_transitive(O1, P, O, [O1|Visited])
	).

%	owl_has_equivalent(?Subject, ?Predicate, ?Object)
%
%	Adds owl:sameAs on Subject and Object to owl_has_direct/3

owl_has_equivalent(S, P, O) :-
	nonvar(S), !,
	owl_same_as(S, S1),
	owl_has_direct(S1, P, O0),
	owl_same_as(O0, O).
owl_has_equivalent(S, P, O) :-
	nonvar(O), !,
	owl_same_as(O1, O),
	owl_has_direct(S0, P, O1),
	owl_same_as(S0, S).
owl_has_equivalent(S, P, O) :-
	owl_has_direct(S0, P, O0),
	owl_same_as(S0, S),
	owl_same_as(O0, O).


%%	owl_same_as(?X, ?Y) is nondet.
%
%	True if X and Y are  identical   or  connected by the owl:sameAs
%	relation. Considers owl:sameAs transitive and symetric.

owl_same_as(literal(X), literal(X)) :- !.
owl_same_as(X, Y) :-
	nonvar(X), !,
	owl_same_as(X, Y, [X]).
owl_same_as(X, Y) :-
	owl_same_as(Y, X, [X]).

owl_same_as(X, X, _).
owl_same_as(X, Y, Visited) :-
	(   rdf_has(X, owl:sameAs, X1)
	;   rdf_has(X1, owl:sameAs, X)
	),
	X1 \= literal(_),
	\+ memberchk(X1, Visited),
	owl_same_as(X1, Y, [X1|Visited]).


%%	owl_has_direct(?Subject, ?Predicate, ?Object)
%
%	Deals  with  `One-step'  OWL  inferencing:  inverse  properties,
%	symmetric properties and being subtype of  a restriction with an
%	owl:hasValue statement on this property.
%
%	@bug	owl_has_direct/3 also uses SWRL rules.  This should be
%		moved elsewhere.

%%      MP 06/2017: also add support for reasoning based on PropertyChain axioms of object properties
%%	TODO: add support for Equivalent properties and mixes of sub properties/Equivalent ones

owl_has_direct(S, P, O) :-
        owl_has_direct_internal(S, P, O).

owl_has_direct(S, P, O) :-
	rdfs_individual_of(P, owl:'SymmetricProperty'),
	owl_has_direct_internal(O, P, S).

owl_has_direct(S, P, O) :-
        (   rdf_has(P, owl:inverseOf, P2)
        ->  true
        ;   rdf_has(P2, owl:inverseOf, P)
        ),
        (   owl_has_direct_internal(O, P2, S)
        ->  true
        ;   rdfs_individual_of(P2, owl:'SymmetricProperty'),
            owl_has_direct_internal(S, P2, O)
        ).

%----------------------------------------------------------
% added by BJW for use of OWL with SWRL rules, highly experimental
% see http://www.daml.org/rules/proposal/rules-all.html for SWRL.
% It implements simple Prolog-like inferencing were order of antecedents
%  may matter and some assumptions about instantiation of variables are
%  made (see comments below).
% Currently is doesnot cater for arbitrary OWL descriptions mixed with
% SWRL.

%owl_has_direct(S, P, O) :-
%	owl_use_rule(S, P, O).

%% Simplest branch: find an explicitly stored rdf triple (S, P, O)
owl_has_direct_internal(S, P, O) :-
	rdf_has(S, P, O).

%% If P is bound to an object property, see if any of its PropertyChain axioms is able to produce explicitly known triples.
%% ASSUMPTION: no circular PropertyChain axioms (example, P defined as A o B and A defined as P o B)
owl_has_direct_internal(S, P, O) :-
        nonvar(P),
        rdfs_individual_of(P, owl:'ObjectProperty'),
        rdf_has(P, owl:propertyChainAxiom, RDFList),
        rdfs_list_to_prolog_list(RDFList, PropChain),
% We need this because the PropChain contains a list of either individuals of type owl:'ObjectProperty', 
% or individuals who are not object properties but have owl:inverseOf some owl:'ObjectProperty',
% and also we need a simple list of the props appearing in a property chain.
        kr_get_props(PropChain, Props),
% Ensure we avoid circular property chains
        \+ kr_circular_chain(Props, [P]),
        owl_has_property_chain(S, PropChain, O).

%% No longer needed. We now attempt direct and inverse properties using the owl_has_direct above, and defined a predicate
%% owl_has_direct_internal that never looks for inverse properties, to avoid infinite backtracking. This fixes the TBD below.
% owl_has_direct(S, P, O) :-
%	(   rdf_has(P, owl:inverseOf, P2)
%	->  true
%	;   rdf_has(P2, owl:inverseOf, P)
%	),
%	rdf_has(O, P2, S).		% TBD: must call owl_has_direct/3

%% Copied above
% owl_has_direct(S, P, O) :-
% 	rdfs_individual_of(P, owl:'SymmetricProperty'),
% 	rdf(O, P, S).

owl_has_direct_internal(S, P, O) :-
	owl_use_has_value(S, P, O).

owl_has_property_chain(S, PropChain, O) :-
        nonvar(S),
        owl_has_property_chain_S2O(S, PropChain, O).

owl_has_property_chain(S, PropChain, O) :-
        var(S),
        nonvar(O),
        reverse(PropChain, PropChainRev),
        owl_has_property_chain_O2S(O, PropChainRev, S).

owl_has_property_chain_S2O(O, [], O).

owl_has_property_chain_S2O(S, [P|RestChain], O) :-
        owl_has(S, P, Oi),
        owl_has_property_chain_S2O(Oi, RestChain, O).

owl_has_property_chain_O2S(S, [], S).

owl_has_property_chain_O2S(O, [P|RestChain], S) :-
        owl_has(Si, P, O),
        owl_has_property_chain_O2S(Si, RestChain, S).

%owl_use_rule(S, P, O):-
	%rdf(Rule, rdf:type, swrl:'Impl'),     % pick a rule
	%rdf(Rule, swrl:head, HeadList),
	%rdfs_member(IPA, HeadList),           % can we use the rule?
	%rdf(IPA, rdf:type, swrl:'IndividualPropertyAtom'),
	%rdf(IPA, swrl:propertyPredicate, P),  % IndividualPropertyAtom
	%rdf(Rule, swrl:body, BodyList),	      % yes
	%rdfs_list_to_prolog_list(BodyList, BL),
	%rdf_has(IPA, swrl:argument1, A1),
	%rdf_has(IPA, swrl:argument2, A2),
	%(   nonvar(S)
	%->  (	nonvar(O) -> SL = [A1/S, A2/O]
	    %;	SL= [A1/S]
	    %)
	%;   nonvar(O)
	%->  SL = [A2/O]
	%;   SL = []
	%),
	%owl_evaluate_body(BL, SL, Subst),
	%ignore(member(A1/S, Subst)), % make sure S and O are instantiated
	%ignore(member(A2/O, Subst)). % could probably be done more elegantly

%owl_evaluate_body([], Subst, Subst).
%owl_evaluate_body([IPA| Rest], SL, Subst):-
	%rdf(IPA, rdf:type, swrl:'IndividualPropertyAtom'),
	%rdf(IPA, swrl:propertyPredicate, P), % IPA = IndividualPropertyAtom
	%rdf_has(IPA, swrl:argument1, A1),    % maybe rdf instead of rdf_has? BJW
	%rdf_has(IPA, swrl:argument2, A2),
	%owl_has_swrl(A1, P, A2, SL, Subst1),
	%owl_evaluate_body(Rest, Subst1, Subst).
%owl_evaluate_body([DF| Rest], SL, Subst):-
	%rdf(DF, rdf:type, swrl:'DifferentIndividualsAtom'),
	%rdf_has(DF, swrl:argument1, A1),
	%instantiated(A1, S, SL),	% assume both arguments are instantiated
	%rdf_has(DF, swrl:argument2, A2),
	%instantiated(A2, O, SL),	% this assumption is to be discussed
	%\+ owl_same_as(S,O),
	%owl_evaluate_body(Rest, SL, Subst).
%owl_evaluate_body([SF| Rest], SL, Subst):-
	%rdf(SF, rdf:type, swrl:'SameIndividualAtom'),
	%rdf_has(SF, swrl:argument1, A1),
	%instantiated(A1, S, SL),	% assume both arguments are instantiated
	%rdf_has(SF, swrl:argument2, A2),
	%instantiated(A2, O, SL),	% this assumption is to be discussed
	%owl_same_as(S,O),		%
	%owl_evaluate_body(Rest, SL, Subst).
%owl_evaluate_body([CA| Rest], SL, Subst):-
	%rdf(CA, rdf:type, swrl:'ClassAtom'),
	%rdf_has(CA, swrl:argument1, A1),
	%(   instantiated(A1, S, SL) -> SL1=SL
	%;   SL1 = [A1/S|SL]),
	%rdf(CA, swrl:classPredicate, Class),
	%owl_individual_of(S, Class),
	%owl_evaluate_body(Rest, SL1, Subst).

%owl_has_swrl(A1, P, A2, Subst, Subst):-	% this can probably be done better BJW
	%instantiated(A1, S, Subst),
	%instantiated(A2, O, Subst),!,	% dont backtrack here, proof complete
	%owl_has(S, P, O).
%owl_has_swrl(A1, P, A2, Subst, [A1/S|Subst]):-
	%is_swrl_variable(A1),
	%instantiated(A2, O, Subst),
	%owl_has(S, P, O).
%owl_has_swrl(A1, P, A2, Subst, [A2/O| Subst] ):-
	%instantiated(A1, S, Subst),
	%is_swrl_variable(A2),
	%owl_has(S, P, O).
%owl_has_swrl(A1, P, A2, Subst, [A1/S, A2/O| Subst]):-  % too general?
	%\+ instantiated(A1, S, Subst),
	%\+ instantiated(A2, O, Subst),
	%owl_has(S, P, O).

%is_swrl_variable(V):-
	%rdf_has(V, rdf:type, swrl:'Variable').

%instantiated(A, A, _Subst):-
	%\+ rdf_has(A, rdf:type, swrl:'Variable').
%instantiated(A, S, Subst):-
	%rdf_has(A, rdf:type, swrl:'Variable'),
	%member(A/S, Subst).

%end additions BJW
%----------------------------------------------------------
owl_use_has_value(S, P, O) :-
	nonvar(P), !,
	rdf_has(Super, owl:onProperty, P),
	rdf_has(Super, owl:hasValue, O),
	owl_direct_subclass_of(Type, Super),
	rdf_has(S, rdf:type, Type).
owl_use_has_value(S, P, O) :-
	rdf_has(S, rdf:type, Type),
	owl_direct_subclass_of(Type, Super),
	rdfs_individual_of(Super, owl:'Restriction'),
	rdf_has(Super, owl:onProperty, P),
	rdf_has(Super, owl:hasValue, O).


		 /*******************************
		 *     OWL CLASS HIERARCHY	*
		 *******************************/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TBD: It is here that we must use a DL classifier!
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

%%	owl_direct_subclass_of(-SubClass, +Class) is nondet.
%%	owl_direct_subclass_of(+SubClass, -Class) is nondet.
%
%	Returns both the RDFS subclasses and  subclass relations implied by
%	owl:intersectionOf and owl:unionOf descriptions.
%
%	@tbd	Should use full DL reasoning

owl_direct_subclass_of(Class, R) :-
	rdf_has(Class, rdfs:subClassOf, R).
owl_direct_subclass_of(Class, R) :-	% added BJW (hack for symetry)
	rdf_has(R, owl:equivalentClass, Class).
owl_direct_subclass_of(Class, R) :-
	(   nonvar(R)
	->  (   rdf_has(R, owl:unionOf, Union),
	        rdfs_member(Class, Union)
	    ;   rdf_has(List, rdf:first, R),
		list_head(List, Head),
		rdf_has(Class, owl:intersectionOf, Head)
	    )
	;   nonvar(Class)
	->  (   rdf_has(Class, owl:intersectionOf, List),
	        rdfs_member(R, List)
	    ;   rdf_has(List, rdf:first, Class),
	        list_head(List, Head),
		rdf_has(R, owl:unionOf, Head)
	    )
	;   throw(error(instantiation_error, _))
	).

list_head(List, Head) :-
	(   rdf_has(H, rdf:rest, List)
	->  list_head(H, Head)
	;   Head = List
	).


%%	owl_subclass_of(+Sub, -Super) is nondet.
%%	owl_subclass_of(-Sub, +Super) is nondet.
%
%	Transitive version of owl_direct_subclass_of/2.

owl_subclass_of(Class, 'http://www.w3.org/2002/07/owl#Thing') :- nonvar(Class), !.
owl_subclass_of(Class, Super) :-
	rdf_equal(rdfs:'Resource', Resource),
	Super == Resource, !,
	(   nonvar(Class)
	->  true
	;   rdfs_individual_of(Class, owl:'Class')
	).
owl_subclass_of(Class, Super) :-
	nonvar(Class), nonvar(Super), !,
	owl_test_subclass(Class, Super).
owl_subclass_of(Class, Super) :-
	nonvar(Class), !,
	owl_gen_supers(Class, [], Super).
owl_subclass_of(Class, Super) :-
	nonvar(Super), !,
	owl_gen_subs(Super, [], Class).
owl_subclass_of(_, _) :-
	throw(error(instantiation_error, _)).

owl_terminal_subclass_of(Terminal, Terminal) :-
	\+ rdf_has(_, rdfs:'subClassOf', Terminal), !.
owl_terminal_subclass_of(Class, Terminal) :-
	rdf_has(SC, rdfs:'subClassOf', Class),
	rdfs_individual_of(SC, owl:'Class'),
	Class \= SC,
	owl_terminal_subclass_of(SC, Terminal).

%%	owl_most_specific(+Types, -List) is semidet.
%
owl_most_specific(Types, List) :-
	bagof(Cls, (
		member(Cls, ['http://www.w3.org/2002/07/owl#Thing'|Types]),
		forall(( % ensure there is no class in Types that is more specific then Cls
			member(Cls_other, Types),
			Cls \= Cls_other
		), \+ owl_subclass_of(Cls_other, Cls))
	), List).

%%	owl_most_specific_predicate(+Predicates, -P) is semidet.
%
owl_most_specific_predicate(Predicates, P) :-
	member(P, Predicates),
	forall(( % ensure there is no class in Types that is more specific then Cls
		member(P_other, Predicates),
		\+ rdf_equal(P, P_other)
	), \+ rdfs_subproperty_of(P_other, P)).

%%	owl_common_ancestor(+Types, Common) is semidet.
%
owl_common_ancestor(Types, Common) :-
	bagof(X, (
		member(Cls_a, Types),
		owl_subclass_of(Cls_a, X),
		forall( member(Cls_b, Types), owl_subclass_of(Cls_b, X) )
	), CommonTypes),
	owl_most_specific(CommonTypes, [Common|_]).

owl_gen_supers(Class, _, Class).
owl_gen_supers(Class, Visited, Super) :-
	(   owl_direct_subclass_of(Class, Super0)
	*-> true
	;   rdf_equal(Super0, rdfs:'Resource')
	),
	\+ memberchk(Super0, Visited),
	owl_gen_supers(Super0, [Super0|Visited], Super).

owl_gen_subs(Class, _, Class).
owl_gen_subs(Class, Visited, Sub) :-
	owl_direct_subclass_of(Sub0, Class),
	\+ memberchk(Sub0, Visited),
	owl_gen_subs(Sub0, [Sub0|Visited], Sub).


%%	owl_test_subclass(+Class, +Super) is semidet.
%
%	Cached check for OWL subclass relation.

:- dynamic
	subclass_cache/3,		% +C1, +C2, -Boolean
	subclass_generation/1.		% RDF generation of last compute

owl_test_subclass(Class, Super) :-
	(   rdf_generation(G),
	    subclass_generation(G2),
	    G \== G2
	->  retractall(subclass_cache(_,_,_))
	;   true
	),
	(   subclass_cache(Class, Super, Bool)
	->  Bool = true
	;   (   owl_gen_supers(Class, [], Super)
	    ->	assert(subclass_cache(Class, Super, true))
	    ;	assert(subclass_cache(Class, Super, false)),
		fail
	    )
	).

%% owl_inverse_property(?P, ?P_inv)
%
owl_inverse_property(P, P_inv) :-
  ( rdf_has(P, owl:inverseOf, P_inv) ;
    rdf_has(P_inv, owl:inverseOf, P) ), !.
owl_inverse_property(P, P_inv) :-
  rdf_instance_from_class('http://www.w3.org/2002/07/owl#Description', P_inv),
  rdf_assert(P_inv, owl:inverseOf, P).


%% owl_disjoint_with(?Class1, ?Class2)
%
%  MT: Tests if Class1 and Class2 are disjoint, taking both individual disjointWith
%      properties and the OWL2 AllDisjointClasses into account
%

owl_disjoint_with(A, A) :-
    fail,!.

% direct assertions (OWL1):
owl_disjoint_with(A, B) :-
    owl_subclass_of(A, Asuper),
    owl_subclass_of(B, Bsuper),
    owl_has(Asuper, owl:disjointWith, Bsuper).

owl_disjoint_with(A, B) :-
    owl_subclass_of(A, Asuper),
    owl_subclass_of(B, Bsuper),
    owl_has(Bsuper, owl:disjointWith, Asuper).

% OWL2 AllDisjointClasses list:
owl_disjoint_with(A, B) :-
    A\=B,
    owl_individual_of(DisjointClasses, owl:'AllDisjointClasses'),
    owl_has(DisjointClasses, owl:members, DisjointClassList),
    rdfs_member(Asuper, DisjointClassList), owl_subclass_of(A, Asuper),
    rdfs_member(Bsuper, DisjointClassList), owl_subclass_of(B, Bsuper).


		 /*******************************
		 *     SEARCH IN HIERARCHY	*
		 *******************************/

%%	owl_find(+String, +Domain, ?Properties, +Method, -Subject) is nondet.
%
%	Search all classes below Domain for a literal property with
%	that matches String.  Method is one of
%
%		* substring
%		* word
%		* prefix
%		* exact
%
%	domain is defined by owl_satisfies/2 from owl.pl
%
%	Note that the rdfs:label field is handled by rdfs_label/2,
%	making the URI-ref fragment name the last resort to determine
%	the label.
%
%	@tbd	Use the RDF literal primitives

owl_find(String, Domain, Fields, Method, Subject) :-
	var(Fields), !,
	For =.. [Method,String],
	rdf_has(Subject, Field, literal(For, _)),
	owl_satisfies(Domain, Subject),
	Fields = [Field].		% report where we found it.
owl_find(String, Domain, Fields, Method, Subject) :-
	globalise_list(Fields, GlobalFields),
	For =.. [Method,String],
	member(Field, GlobalFields),
	(   Field == resource
	->  rdf_subject(Subject),
	    rdf_match_label(Method, String, Subject)
	;   rdf_has(Subject, Field, literal(For, _))
	),
	owl_satisfies(Domain, Subject).

globalise_list([], []) :- !.
globalise_list([H0|T0], [H|T]) :- !,
	globalise_list(H0, H),
	globalise_list(T0, T).
globalise_list(X, G) :-
	rdf_global_id(X, G).
