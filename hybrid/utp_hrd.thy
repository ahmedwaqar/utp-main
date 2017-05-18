section {* Hybrid Reactive Designs *}

theory utp_hrd
  imports
    utp_rea_designs
    utp_differential
begin

definition hrdODE ::
  "('a::ordered_euclidean_space \<Longrightarrow> 'c::t2_space) \<Rightarrow>
   ('a ODE, 'c) uexpr \<Rightarrow> ('d, 'c) hyrel" where
[urel_defs]: "hrdODE x \<F>' = \<^bold>R\<^sub>s(true \<turnstile> \<langle>x \<bullet> \<F>'\<rangle>\<^sub>h \<diamondop> false)"


definition hrdPreempt ::
    "('d, 'c::t2_space) hyrel \<Rightarrow> 'c upred \<Rightarrow>
    ('d,'c) hyrel \<Rightarrow> ('d,'c) hyrel" ("_ [_]\<^sub>H _" [64,0,65] 64) where
"hrdPreempt P b Q =
  Q \<triangleleft> \<lceil>b\<rceil>\<^sub>C\<^sub>< \<triangleright>
    \<^bold>R\<^sub>s((pre\<^sub>R(P) \<and> (post\<^sub>R(P) \<and> $\<^bold>c\<acute> =\<^sub>u lim\<^sub>u(x\<rightarrow>\<^bold>l\<^sup>-)(\<^bold>t\<lparr>\<guillemotleft>x\<guillemotright>\<rparr>\<^sub>u) \<and> \<lceil>b\<rceil>\<^sub>C\<^sub>>) wp\<^sub>R pre\<^sub>R(Q))
       \<turnstile> (peri\<^sub>R(P) \<or> (peri\<^sub>R(P) \<and> $\<^bold>c\<acute> =\<^sub>u lim\<^sub>u(x\<rightarrow>\<^bold>l\<^sup>-)(\<^bold>t\<lparr>\<guillemotleft>x\<guillemotright>\<rparr>\<^sub>u) \<and> \<lceil>b\<rceil>\<^sub>C\<^sub>>) ;; peri\<^sub>R(P))
       \<diamondop> (post\<^sub>R(P) \<or> (peri\<^sub>R(P) \<and> $\<^bold>c\<acute> =\<^sub>u lim\<^sub>u(x\<rightarrow>\<^bold>l\<^sup>-)(\<^bold>t\<lparr>\<guillemotleft>x\<guillemotright>\<rparr>\<^sub>u) \<and> \<lceil>b\<rceil>\<^sub>C\<^sub>>) ;; peri\<^sub>R(P)))"

lemma hrdPreempt_true:
  "P is SRD \<Longrightarrow> P [true]\<^sub>H Q = Q"
  by (simp add: hrdPreempt_def alpha)

lemma hrdPreempt_false:
  "P is SRD \<Longrightarrow> P [false]\<^sub>H Q = P"
  by (simp add: hrdPreempt_def alpha wp SRD_reactive_tri_design)

lemma hrdPreempt_term:
  "II\<^sub>R [b]\<^sub>H P = P \<triangleleft> \<lceil>b\<rceil>\<^sub>C\<^sub>< \<triangleright> II\<^sub>R"
  apply (simp add: hrdPreempt_def rdes, rel_auto) using minus_zero_eq by auto


end