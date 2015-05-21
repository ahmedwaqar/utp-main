(******************************************************************************)
(* Project: VDM model for Isabelle/UTP                                        *)
(* File: utp_vdm_commands.thy                                                 *)
(* Authors: Original CML model by Simon Foster, University of York (UK)       *)
(*          Adapted to VDM by Luis Diogo Couto, Aarhus University (DK)        *)
(******************************************************************************)

header {* Commands to construct VDM definitions *}

theory utp_vdm_commands
imports 
  utp_vdm_functions
  utp_vdm_records
  utp_vdm_stmt
keywords "vdmifun" "vdmefun" "vdmeop" "vdmiop" "vdmrec"  :: thy_decl and "inp" "out" "pre" "post" "frame" "invariant"
begin

abbreviation "swap \<equiv> \<lambda> (x,y). (y, x)"                                          

definition mk_ifun_body :: "'a set \<Rightarrow> 'b set \<Rightarrow> ('a \<Rightarrow> bool vdme) \<Rightarrow> (('a * 'b) \<Rightarrow> bool vdme) \<Rightarrow> ('a * 'b) set" where
"mk_ifun_body A B pre post 
  = {(x,y) | x y. x \<in> A \<and> y \<in> B \<and> \<lbrakk>pre(x)\<rbrakk>\<^sub>*\<B> = Some True \<and> \<lbrakk>post(x,y)\<rbrakk>\<^sub>*\<B> = Some True}"

declare mk_ifun_body_def [evalp]

nonterminal acthead

syntax
  "_act_head_id"     :: "idt \<Rightarrow> acthead" ("_")
  "_act_head_pttrn"  :: "idt \<Rightarrow> vpttrns \<Rightarrow> acthead" ("_'(_')")

ML {* @{syntax_const "_act_head_id"} *}

ML {*

signature VDMCOMMANDS =
sig
  val mk_efun: (string * ((string * string) list * string)) * ((string * string) * string) 
              -> Proof.context -> local_theory
  val mk_ifun: (string * ((string * string) list * (string * string))) * (string * string) 
               -> Proof.context -> local_theory
  val mk_eop: (string * ((string * string) list * string)) * ((string * string) * string) 
              -> Proof.context -> local_theory
  val mk_iop: ((string * ((string * string) list * (string * string))) * (string list * (string * string)))
              -> Proof.context -> local_theory
  val mk_rec: (string * ((string * string) list * string)) -> local_theory -> local_theory
  val efun_pr: Token.T list ->
      ((string * ((string * string) list * string)) * ((string * string) * string)) * Token.T list
  val ifun_pr: Token.T list ->
      ((string * ((string * string) list * (string * string))) * (string * string)) * Token.T list
  val eop_pr: Token.T list ->
      ((string * ((string * string) list * string)) * ((string * string) * string)) * Token.T list
  val iop_pr: Token.T list -> 
      ((string * ((string * string) list * (string * string))) * (string list * (string * string))) * Token.T list
  val rec_pr: Token.T list -> (string * ((string * string) list * string)) * Token.T list 
end

structure VdmCommands : VDMCOMMANDS =
struct

open Syntax;
open Local_Theory;
open Typedef;

fun split_dot x = case (String.tokens (fn x => x = #".") x) of
                    [_,y] => y
                  | _ => x;

(* Functions to get grammar categories from the context *)

fun n_upred ctxt = (Config.put root @{nonterminal "n_upred"} ctxt);
fun n_pexpr ctxt = (Config.put root @{nonterminal "n_pexpr"} ctxt);
fun vty ctxt = (Config.put root @{nonterminal "vty"} ctxt);

(* Substitute an expression for a given free name irrespective of the type *)

fun subst_free nm e (u $ t) = subst_free nm e u $ subst_free nm e t
  | subst_free nm e (Free (x, t)) = if (x = nm) then e else Free (x, t)
  | subst_free nm e (Abs (y, ty, tr)) = if (nm = y) then (Abs (y, ty, tr)) else (Abs (y, ty, subst_free nm e tr))
  | subst_free _ _ t = t;

(* Insert a lambda abstraction for a given free name, irrespective of the type *)
local
  fun absnm' x n (u $ t) = (absnm' x n u) $ (absnm' x n t)
    | absnm' x n (Const (y, t)) = if (x = split_dot y) then Bound n else Const (y, t) 
    (* FIXME: Slightly dangerous case: if we encounter a constant with the same local
       name part as the variable we're abstracting, treat it as a variable. Could we
       accidentally capture? *)
    | absnm' x n (Free (y, t)) = if (x = y) then Bound n else Free (y, t)
    | absnm' x n (Abs (y, ty, tr)) = if (x = y) then (Abs (y, ty, tr)) else (Abs (y, ty, absnm' x (n+1) tr))
    | absnm' _ _ e = e;
in fun absnm (x, ty) n tr = Abs (x, ty, absnm' x n tr) end;

(* Given a VDM type, get the HOL "maximimal" type *)

fun get_vdm_holty ty ctxt = 
  let val tctxt = vty ctxt in
  case (type_of (read_term tctxt ty)) of
    Type (_, [ty]) => ty
  | x => error (@{make_string} x)
 end;

(* Create a product-based lambda term from a list of names and types *)

fun mk_lambda [(id, ty)] term ctxt =
      absnm (id, get_vdm_holty ty ctxt) 0 term
  | mk_lambda ((id, ty) :: xs) term ctxt =
      const @{const_name "case_prod"} 
        $ absnm (id, get_vdm_holty ty ctxt) 0 (mk_lambda xs term ctxt)
  | mk_lambda [] term _ = term;

fun mk_n_of_m n m =
  if (m = 0) then const @{const_name id}
  else if (n = 0) then const @{const_name afst}
  else const @{const_name comp} $ mk_n_of_m (n - 1) (m - 1) $ const @{const_name asnd}

(* Attribute to add a theorem to the evalp theorem set *)

val add_evalp = Attrib.internal (K (Thm.declaration_attribute evalp.add_thm));

(* Make a product type from a list of type terms *)

fun mk_prod_ty ctxt [] = @{term UnitD}
  | mk_prod_ty ctxt ts = foldr1 (fn (x,y) => 
                           (check_term ctxt (const @{const_abbrev "vty_prod"} $ x $ y)))
                                            (map (read_term (vty ctxt) o snd) ts)

fun mk_defn id prefix t =
  ((Binding.name (prefix ^ id), NoSyn), ((Binding.name (prefix ^ id ^ "_def"), [add_evalp]), t))

fun mk_eop ((id, (inp, out)), ((pre, post), body)) ctxt =
  let val pre_term  = check_term (n_pexpr ctxt) (mk_lambda inp (parse_term (n_pexpr ctxt) pre) ctxt)
      val post_term = check_term (n_pexpr ctxt)
                          (const @{const_name "comp"} 
                            $ (mk_lambda (("RESULT", out) :: inp) (parse_term (n_pexpr ctxt) post) ctxt)
                            $ const @{const_abbrev "swap"})
      val body_term = absnm ("RESULT", Type (@{type_abbrev "vdmvar"}, [get_vdm_holty out ctxt])) (length inp - 1) (mk_lambda inp (parse_term (n_upred ctxt) body) ctxt)
      val op_term = check_term ctxt (
                        const @{const_name VDMOpR} 
                        $ mk_prod_ty ctxt inp 
                        $ read_term (vty ctxt) out
                        $ pre_term
                        $ post_term
                        $ body_term)
      val ((_,(_,thm1)), ctxt1) = define (mk_defn id "pre_" pre_term) ctxt
      val ((_,(_,thm2)), ctxt2) = define (mk_defn id "post_" post_term) ctxt1
      val ((_,(_,thm3)), ctxt3) = define (mk_defn id "" op_term) ctxt2
  in 
      ctxt3
  end;

fun mk_iop ((id, (inp, (outn, outt))), (frame, (pre, post))) ctxt =
let val pre_term  = check_term (n_pexpr ctxt) (mk_lambda inp (parse_term (n_pexpr ctxt) pre) ctxt)
    val post_term = check_term (n_pexpr ctxt)
                        (const @{const_name "comp"} 
                          $ (mk_lambda ((outn, outt) :: inp) (parse_term (n_pexpr ctxt) post) ctxt)
                          $ const @{const_abbrev "swap"})
    val frame_set = List.foldr (fn (x, xs) => const @{const_name "bset_insert"} $ (const @{const_name erase} $ x) $ xs) (const @{const_name "bset_empty"})
                               (map (parse_term ctxt) frame)
    val op_term = check_term ctxt (
                      const @{const_name VDMIOpR} 
                      $ mk_prod_ty ctxt inp 
                      $ read_term (vty ctxt) outt
                      $ pre_term
                      $ post_term
                      $ frame_set)
      val ((_,(_,thm1)), ctxt1) = define (mk_defn id "pre_" pre_term) ctxt
      val ((_,(_,thm2)), ctxt2) = define (mk_defn id "post_" post_term) ctxt1
      val ((_,(_,thm3)), ctxt3) = define (mk_defn id "" op_term) ctxt2
  in 
      ctxt3
  end;
  
fun mk_efun ((id, (inp, out)), ((pre, post), body)) ctxt =
  let val pre_term = check_term (n_pexpr ctxt) (mk_lambda inp (parse_term (n_pexpr ctxt) pre) ctxt)
      val body_type = parse_term (vty ctxt) out
      val body_inner = const @{const_name "CoerceD"} 
                       $ parse_term (n_pexpr ctxt) body (* FIXME: Do something with the postcondition *)
                       $ body_type
      val body_term = check_term (n_pexpr ctxt) (
                         mk_lambda inp (
                           (if (pre = "true") then body_inner
                                              else const @{const_name IfThenElseD}
                                                 $ parse_term (n_pexpr ctxt) pre
                                                 $ body_inner 
                                                 $ const @{const_name BotDE})) ctxt)
      val ((_,(_,thm1)), ctxt1) = define (mk_defn id "pre_" pre_term) ctxt
      val ((_,(_,thm2)), ctxt2) = define (mk_defn id "" body_term) ctxt1
  in 
      ctxt2
  end;

fun mk_ifun ((id, (inp, out)), (pre, post)) ctxt = 
  let val pctxt = (Config.put Syntax.root @{nonterminal "n_pexpr"} ctxt)
      val tctxt = (Config.put Syntax.root @{nonterminal "vty"} ctxt)
      val preb = (Binding.name ("pre_" ^ id), NoSyn)
      val preb_term = Syntax.check_term pctxt (mk_lambda inp (Syntax.parse_term pctxt pre) ctxt)
      val preb_type = type_of preb_term
      val preb_def = ( (Binding.name ("pre_" ^ id ^ "_def"), [add_evalp]), preb_term)
      val postb = (Binding.name ("post_" ^ id), NoSyn)
      val postb_term = (Syntax.check_term pctxt 
                          (Const (@{const_name "comp"}, dummyT) 
                            $ (mk_lambda (out :: inp) (Syntax.parse_term pctxt post) ctxt)
                            $ Const (@{const_abbrev "swap"}, dummyT)))
      val postb_def = ( (Binding.name ("post_" ^ id ^ "_def"), [add_evalp]), postb_term) 
      val inpt = mk_prod_ty ctxt inp
      val outt = read_term tctxt (snd out)
      val bodyb = (Binding.name id, NoSyn)
      val bodyb_def = ( (Binding.name (id ^ "_def"), [add_evalp]) 
                      ,  Syntax.check_term ctxt (Const (@{const_name mk_ifun_body}, dummyT)
                           $ inpt $ outt $ preb_term $ postb_term))
      val ((_,(_,thm1)), ctxt1) = Local_Theory.define (preb, preb_def) ctxt
      val ((_,(_,thm2)), ctxt2) = Local_Theory.define (postb, postb_def) ctxt1
      val ((_,(_,thm3)), ctxt3) = Local_Theory.define (bodyb, bodyb_def) ctxt2
  in 
     ctxt3
  end;

fun mk_rec_inst typ_name thm1 thm2 thy0 =
let
    val lthy = Named_Target.theory_init thy0
    val typ = Syntax.parse_typ lthy typ_name
    val typ_lname = (#1 o dest_Type) typ
    fun inst_tac ctxt = stac (thm1 RSN (1, @{thm sym})) 1 THEN 
                   asm_simp_tac (ctxt addsimps [simplify ctxt thm2]) 1
in
Local_Theory.exit_global lthy
      |> Class.instantiation ([typ_lname], [], @{sort tag})
      |> (snd o Local_Theory.define (mk_defn ("tagName_" ^ typ_name) "" (Abs ("x", typ, (HOLogic.mk_string typ_name)))))
      |> (fn lthy => Class.prove_instantiation_exit (fn ctxt => Class.intro_classes_tac [] THEN inst_tac ctxt) lthy) 
end

fun prod_sel n = 
  if (n = 1) then (Const (@{const_name plast}, dummyT))
  else if (n > 1) then (Const (@{const_name Fun.comp}, dummyT) 
                          $ prod_sel (n - 1) 
                          $ Const (@{const_name pnext}, dummyT))
  else raise Match;


fun mk_rec (id, (flds, inv)) ctxt =
let
  val ((n, (r, info)), ctxt1) = (Typedef.add_typedef (Binding.name (id ^ "_tag"), [], NoSyn) 
                                   @{term "{True}"}
                                   NONE 
                                   (rtac @{thm exI[of _ "True"]} 1 THEN rtac @{thm insertI1} 1)
                                   ctxt)
  (* Create the tag type and instance *)
  val ctxt2 = background_theory (mk_rec_inst (id ^ "_tag") (#Rep_inject info) (#Rep info)) ctxt1
  val maxty = mk_prod_ty ctxt flds
  val maxty_term = check_term ctxt2 ( const @{const_name "RecMaximalType"} 
                                    $ maxty 
                                    $ Const ("TYPE", Term.itselfT (#abs_type r)))
  val ((mtr,(_,thm2)), ctxt3) = define (mk_defn id "maxty_" maxty_term) ctxt2                                   
  fun mk_flds ((id, ty) :: fs) n =   
    let val fld = const @{const_name MkField} $ maxty_term $ prod_sel n $ read_term (vty ctxt3) ty
    in
    mk_flds fs (n + 1) o
      snd o abbrev Syntax.mode_default ((Binding.name (id ^ "_fld"), NoSyn), check_term ctxt3 fld)
    o snd o abbrev Syntax.mode_default ((Binding.name id, NoSyn), check_term ctxt3 (const @{const_name SelectRec} $ fld))
    end
    | mk_flds [] _ = (fn x => x)
  val ctxt4 = mk_flds flds 1 ctxt3
  (* Define the record type with possible invariant *) 
  val ((ttr, _), ctxt5) = define (mk_defn id "" (check_term ctxt4 (const @{const_name InvS} $ mtr $ parse_term (n_pexpr ctxt4) inv))) ctxt4
  val (_, ctxt6) = define (mk_defn id "mk_" (check_term ctxt5 (const @{const_name MkRec} $ ttr))) ctxt5
in
  ctxt6
end



val inps1_pr = Parse.enum1 "and" (Parse.short_ident -- (@{keyword "::"} |-- Parse.term));
val outs_pr = Parse.short_ident -- (@{keyword "::"} |-- Parse.term)

val ifun_pr = Parse.short_ident 
                  -- ((@{keyword "inp"} |-- inps1_pr) -- (@{keyword "out"} |-- outs_pr))
                  -- (Scan.optional (@{keyword "pre"} |-- Parse.term) "true"
                      -- (@{keyword "post"} |-- Parse.term));

val efun_pr = Parse.short_ident 
                  -- ((@{keyword "inp"} |-- inps1_pr) -- (@{keyword "out"} |-- Parse.term))
                  -- ((Scan.optional (@{keyword "pre"} |-- Parse.term) "true"
                  --  (Scan.optional (@{keyword "post"} |-- Parse.term) "true"))
                  --  (@{keyword "is"} |-- Parse.term));

val eop_pr = Parse.short_ident 
                  -- ((Scan.optional (@{keyword "inp"} |-- inps1_pr) [("null_input", "()")])
                      -- (Scan.optional (@{keyword "out"} |-- Parse.term) "()"))
                  -- ((Scan.optional (@{keyword "pre"} |-- Parse.term) "true"
                  --  (Scan.optional (@{keyword "post"} |-- Parse.term) "true"))
                  --  (@{keyword "is"} |-- Parse.term));

val iop_pr = Parse.short_ident 
                  -- ((Scan.optional (@{keyword "inp"} |-- inps1_pr) [("null_input", "()")])
                      -- (Scan.optional (@{keyword "out"} |-- outs_pr) ("RESULT", "()")))
                  -- ((Scan.optional (@{keyword "frame"} |-- Scan.repeat1 Parse.short_ident) []) 
                  -- (Scan.optional (@{keyword "pre"} |-- Parse.term) "true"
                      -- (@{keyword "post"} |-- Parse.term)));

val rec_pr = Parse.short_ident 
                  -- (inps1_pr -- (Scan.optional (@{keyword "invariant"} |-- Parse.term)) "lambda x @ true") ;

end;

Outer_Syntax.local_theory  @{command_spec "vdmefun"} 
"Explicit VDM function" 
(VdmCommands.efun_pr >> VdmCommands.mk_efun);

Outer_Syntax.local_theory  @{command_spec "vdmifun"} 
"Implicit VDM function" 
(VdmCommands.ifun_pr >> VdmCommands.mk_ifun);

Outer_Syntax.local_theory  @{command_spec "vdmiop"} 
"Implicit VDM operation" 
(VdmCommands.iop_pr >> VdmCommands.mk_iop);

Outer_Syntax.local_theory  @{command_spec "vdmeop"} 
"Explicit VDM operation" 
(VdmCommands.eop_pr >> VdmCommands.mk_eop);

Outer_Syntax.local_theory @{command_spec "vdmrec"}
"VDM Record"
(VdmCommands.rec_pr >> VdmCommands.mk_rec);

*}

no_syntax
  "_n_upred_index"   :: "('b \<Rightarrow> 'a upred) \<Rightarrow> 'b \<Rightarrow> n_upred" ("_<_>" 50)
  "_n_upred_var"      :: "idt \<Rightarrow> n_upred" ("_")

syntax
  "_n_vdm_var"   :: "idt \<Rightarrow> n_upred" ("_")


translations
  "_n_vdm_var p" => "p :: vdmp"


(*term "`i:@int,j:@nat @ P<&i>`"*)

(*
lemma vif_cong [fundef_cong]:
  assumes "b = c"
      and "TautDE c \<Longrightarrow> |@x| = |@u|"
      and "|not(@c)| \<Longrightarrow> |@y| = |@v|"
  shows "|if @b then @x else @y| = |if @c then @u else @v|"
  using assms 
  apply (auto simp add:evalp)
  apply (case_tac "\<lbrakk>b\<rbrakk>\<^sub>* ba")
  apply (auto)
  sledgehammer
 sorry
*)

(* To make recursive functions work in the VDM setting, we'd need some congruence rules
   like those below. I don't really know what these should be though so I've given up
   for now. *)

(*
lemma vif_cong [fundef_cong]:
  assumes "\<lbrakk>b\<rbrakk>\<^sub>*\<B> = \<lbrakk>c\<rbrakk>\<^sub>*\<B>"
      and "[\<lbrakk>c\<rbrakk>\<^sub>*\<B>]\<^sub>3 \<Longrightarrow> \<lbrakk>x\<rbrakk>\<^sub>*\<B> = \<lbrakk>u\<rbrakk>\<^sub>*\<B>"
      and "\<not> [\<lbrakk>c\<rbrakk>\<^sub>*\<B>]\<^sub>3 \<Longrightarrow> \<lbrakk>y\<rbrakk>\<^sub>*\<B> = \<lbrakk>v\<rbrakk>\<^sub>*\<B>"
  shows "\<lbrakk>|if @b then @x else @y|\<rbrakk>\<^sub>*\<B> = \<lbrakk>|if @c then @u else @v|\<rbrakk>\<^sub>*\<B>"
  using assms apply (auto simp add:evalp)
  apply (case_tac "\<lbrakk>c\<rbrakk>\<^sub>*\<B>")
  apply (auto)
done
*)

end
