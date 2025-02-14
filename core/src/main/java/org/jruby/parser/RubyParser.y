%{
/*
 **** BEGIN LICENSE BLOCK *****
 * Version: EPL 2.0/GPL 2.0/LGPL 2.1
  * The contents of this file are subject to the Eclipse Public
 * License Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.eclipse.org/legal/epl-v20.html
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * Copyright (C) 2008-2017 Thomas E Enebo <enebo@acm.org>
 * 
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the EPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the EPL, the GPL or the LGPL.
 ***** END LICENSE BLOCK *****/

package org.jruby.parser;

import java.io.IOException;
import java.util.Set;

import org.jruby.RubySymbol;
import org.jruby.ast.ArgsNode;
import org.jruby.ast.ArgumentNode;
import org.jruby.ast.ArrayNode;
import org.jruby.ast.ArrayPatternNode;
import org.jruby.ast.AssignableNode;
import org.jruby.ast.BackRefNode;
import org.jruby.ast.BeginNode;
import org.jruby.ast.BlockAcceptingNode;
import org.jruby.ast.BlockArgNode;
import org.jruby.ast.BlockNode;
import org.jruby.ast.BlockPassNode;
import org.jruby.ast.BreakNode;
import org.jruby.ast.ClassNode;
import org.jruby.ast.ClassVarNode;
import org.jruby.ast.ClassVarAsgnNode;
import org.jruby.ast.Colon3Node;
import org.jruby.ast.ConstNode;
import org.jruby.ast.ConstDeclNode;
import org.jruby.ast.DefHolder;
import org.jruby.ast.DefinedNode;
import org.jruby.ast.DStrNode;
import org.jruby.ast.DSymbolNode;
import org.jruby.ast.DVarNode;
import org.jruby.ast.DXStrNode;
import org.jruby.ast.DefnNode;
import org.jruby.ast.DefsNode;
import org.jruby.ast.DotNode;
import org.jruby.ast.EncodingNode;
import org.jruby.ast.EnsureNode;
import org.jruby.ast.EvStrNode;
import org.jruby.ast.FalseNode;
import org.jruby.ast.FileNode;
import org.jruby.ast.FindPatternNode;
import org.jruby.ast.FCallNode;
import org.jruby.ast.FixnumNode;
import org.jruby.ast.FloatNode;
import org.jruby.ast.ForNode;
import org.jruby.ast.GlobalAsgnNode;
import org.jruby.ast.GlobalVarNode;
import org.jruby.ast.HashNode;
import org.jruby.ast.HashPatternNode;
import org.jruby.ast.InNode;
import org.jruby.ast.InstAsgnNode;
import org.jruby.ast.InstVarNode;
import org.jruby.ast.IterNode;
import org.jruby.ast.KeywordArgNode;
import org.jruby.ast.LambdaNode;
import org.jruby.ast.ListNode;
import org.jruby.ast.LiteralNode;
import org.jruby.ast.LocalVarNode;
import org.jruby.ast.ModuleNode;
import org.jruby.ast.MultipleAsgnNode;
import org.jruby.ast.NextNode;
import org.jruby.ast.NilImplicitNode;
import org.jruby.ast.NilNode;
import org.jruby.ast.Node;
import org.jruby.ast.NonLocalControlFlowNode;
import org.jruby.ast.NumericNode;
import org.jruby.ast.OptArgNode;
import org.jruby.ast.PostExeNode;
import org.jruby.ast.PreExe19Node;
import org.jruby.ast.RationalNode;
import org.jruby.ast.RedoNode;
import org.jruby.ast.RegexpNode;
import org.jruby.ast.RequiredKeywordArgumentValueNode;
import org.jruby.ast.RescueBodyNode;
import org.jruby.ast.RestArgNode;
import org.jruby.ast.RetryNode;
import org.jruby.ast.ReturnNode;
import org.jruby.ast.SClassNode;
import org.jruby.ast.SelfNode;
import org.jruby.ast.StarNode;
import org.jruby.ast.StrNode;
import org.jruby.ast.TrueNode;
import org.jruby.ast.UnnamedRestArgNode;
import org.jruby.ast.UntilNode;
import org.jruby.ast.VAliasNode;
import org.jruby.ast.WhileNode;
import org.jruby.ast.XStrNode;
import org.jruby.ast.YieldNode;
import org.jruby.ast.ZArrayNode;
import org.jruby.ast.ZSuperNode;
import org.jruby.ast.types.ILiteralNode;
import org.jruby.common.IRubyWarnings;
import org.jruby.common.IRubyWarnings.ID;
import org.jruby.lexer.LexerSource;
import org.jruby.lexer.LexingCommon;
import org.jruby.lexer.yacc.LexContext;
import org.jruby.lexer.yacc.RubyLexer;
import org.jruby.lexer.yacc.StackState;
import org.jruby.lexer.yacc.StrTerm;
import org.jruby.util.ByteList;
import org.jruby.util.CommonByteLists;
import org.jruby.util.KeyValuePair;
import org.jruby.util.StringSupport;
import static org.jruby.lexer.LexingCommon.AMPERSAND;
import static org.jruby.lexer.LexingCommon.BACKTICK;
import static org.jruby.lexer.LexingCommon.BANG;
import static org.jruby.lexer.LexingCommon.CARET;
import static org.jruby.lexer.LexingCommon.DOT;
import static org.jruby.lexer.LexingCommon.GT;
import static org.jruby.lexer.LexingCommon.LCURLY;
import static org.jruby.lexer.LexingCommon.LT;
import static org.jruby.lexer.LexingCommon.MINUS;
import static org.jruby.lexer.LexingCommon.PERCENT;
import static org.jruby.lexer.LexingCommon.OR;
import static org.jruby.lexer.LexingCommon.PLUS;
import static org.jruby.lexer.LexingCommon.RBRACKET;
import static org.jruby.lexer.LexingCommon.RCURLY;
import static org.jruby.lexer.LexingCommon.RPAREN;
import static org.jruby.lexer.LexingCommon.SLASH;
import static org.jruby.lexer.LexingCommon.STAR;
import static org.jruby.lexer.LexingCommon.TILDE;
import static org.jruby.lexer.LexingCommon.EXPR_BEG;
import static org.jruby.lexer.LexingCommon.EXPR_FITEM;
import static org.jruby.lexer.LexingCommon.EXPR_FNAME;
import static org.jruby.lexer.LexingCommon.EXPR_ENDFN;
import static org.jruby.lexer.LexingCommon.EXPR_ENDARG;
import static org.jruby.lexer.LexingCommon.EXPR_END;
import static org.jruby.lexer.LexingCommon.EXPR_LABEL;
import static org.jruby.util.CommonByteLists.FWD_BLOCK;
import static org.jruby.util.CommonByteLists.FWD_KWREST;
import static org.jruby.parser.ParserSupport.arg_blk_pass;
import static org.jruby.parser.ParserSupport.node_assign;

 
public class RubyParser {
    protected ParserSupport support;
    protected RubyLexer lexer;

    public RubyParser(LexerSource source, IRubyWarnings warnings) {
        this.support = new ParserSupport();
        this.lexer = new RubyLexer(support, source, warnings);
        support.setLexer(lexer);
        support.setWarnings(warnings);
    }

    @Deprecated
    public RubyParser(LexerSource source) {
        this(new ParserSupport(), source);
    }

    @Deprecated
    public RubyParser(ParserSupport support, LexerSource source) {
        this.support = support;
        lexer = new RubyLexer(support, source);
        support.setLexer(lexer);
    }

    public void setWarnings(IRubyWarnings warnings) {
        support.setWarnings(warnings);
        lexer.setWarnings(warnings);
    }
%}

// patch_parser.rb will look for token lines with {{ and }} within it to put
// in reasonable strings we expect during a parsing error.
%token <Integer> keyword_class        /* {{`class''}} */
%token <Integer> keyword_module       /* {{`module'}} */
%token <Integer> keyword_def          /* {{`def'}} */
%token <Integer> keyword_undef        /* {{`undef'}} */
%token <Integer> keyword_begin        /* {{`begin'}} */
%token <Integer> keyword_rescue       /* {{`rescue'}} */
%token <Integer> keyword_ensure       /* {{`ensure'}} */
%token <Integer> keyword_end          /* {{`end'}} */
%token <Integer> keyword_if           /* {{`if'}} */
%token <Integer> keyword_unless       /* {{`unless'}} */
%token <Integer> keyword_then         /* {{`then'}} */
%token <Integer> keyword_elsif        /* {{`elsif'}} */
%token <Integer> keyword_else         /* {{`else'}} */
%token <Integer> keyword_case         /* {{`case'}} */
%token <Integer> keyword_when         /* {{`when'}} */
%token <Integer> keyword_while        /* {{`while'}} */
%token <Integer> keyword_until        /* {{`until'}} */
%token <Integer> keyword_for          /* {{`for'}} */
%token <Integer> keyword_break        /* {{`break'}} */
%token <Integer> keyword_next         /* {{`next'}} */
%token <Integer> keyword_redo         /* {{`redo'}} */
%token <Integer> keyword_retry        /* {{`retry'}} */
%token <Object> keyword_in           /* {{`in'}} */
%token <Integer> keyword_do           /* {{`do'}} */
%token <Integer> keyword_do_cond      /* {{`do' for condition}} */
%token <Integer> keyword_do_block     /* {{`do' for block}} */
%token <Integer> keyword_do_LAMBDA    /* {{`do' for lambda}} */
%token <Integer> keyword_return       /* {{`return'}} */
%token <Integer> keyword_yield        /* {{`yield'}} */
%token <Integer> keyword_super        /* {{`super'}} */
%token <Integer> keyword_self         /* {{`self'}} */
%token <Integer> keyword_nil          /* {{`nil'}} */
%token <Integer> keyword_true         /* {{`true'}} */
%token <Integer> keyword_false        /* {{`false'}} */
%token <Integer> keyword_and          /* {{`and'}} */
%token <Integer> keyword_or           /* {{`or'}} */
%token <Integer> keyword_not          /* {{`not'}} */
%token <Integer> modifier_if          /* {{`if' modifier}} */
%token <Integer> modifier_unless      /* {{`unless' modifier}} */
%token <Integer> modifier_while       /* {{`while' modifier}} */
%token <Integer> modifier_until       /* {{`until' modifier}} */
%token <Integer> modifier_rescue      /* {{`rescue' modifier}} */
%token <Integer> keyword_alias        /* {{`alias'}} */
%token <Integer> keyword_defined      /* {{`defined'}} */
%token <Integer> keyword_BEGIN        /* {{`BEGIN'}} */
%token <Integer> keyword_END          /* {{`END'}} */
%token <Integer> keyword__LINE__      /* {{`__LINE__'}} */
%token <Integer> keyword__FILE__      /* {{`__FILE__'}} */
%token <Integer> keyword__ENCODING__  /* {{`__ENCODING__'}} */
  
%token <ByteList> tIDENTIFIER         /* {{local variable or method}} */
%token <ByteList> tFID                /* {{method}} */
%token <ByteList> tGVAR               /* {{global variable}} */
%token <ByteList> tIVAR               /* {{instance variable}} */
%token <ByteList> tCONSTANT           /* {{constant}} */
%token <ByteList> tCVAR               /* {{class variable}} */
%token <ByteList> tLABEL              /* {{label}} */
%token <Node> tINTEGER                /* {{integer literal}} */
%token <FloatNode> tFLOAT             /* {{float literal}} */
%token <RationalNode> tRATIONAL       /* {{rational literal}} */
%token <Node> tIMAGINARY              /* {{imaginary literal}} */
%token <StrNode> tCHAR                /* {{char literal}} */
%token <Node> tNTH_REF                /* {{numbered reference}} */
%token <Node> tBACK_REF               /* {{back reference}} */
%token <Node> tSTRING_CONTENT         /* {{literal content}} */
%token <RegexpNode>  tREGEXP_END

%type <Node> singleton strings string string1 xstring regexp
%type <Node> string_contents xstring_contents regexp_contents
%type <Object> string_content
%type <ListNode> words symbols symbol_list qwords qsymbols
%type <ListNode> word_list qword_list qsym_list  
%type <Node> word 
%type <Node> literal
%type <NumericNode> numeric simple_numeric
%type <Node> ssym dsym symbol cpath
%type <DefHolder> def_name defn_head defs_head
%type <Node> top_compstmt top_stmts top_stmt begin_block
%type <Node> bodystmt compstmt stmts stmt_or_begin stmt expr arg primary command command_call method_call
%type <Node> expr_value expr_value_do arg_value primary_value 
%type <FCallNode> fcall
%type <Node> rel_expr
%type <Node> if_tail opt_else case_body case_args cases 
%type <RescueBodyNode> opt_rescue
%type <Node> exc_list exc_var opt_ensure
%type <Node> args call_args opt_call_args 
%type <Node> paren_args opt_paren_args
%type <ArgsTailHolder> args_tail opt_args_tail block_args_tail opt_block_args_tail 
%type <Node> command_args aref_args
%type <BlockPassNode> opt_block_arg block_arg
%type <Node> var_ref
%type <AssignableNode> var_lhs
%type <Node> command_rhs arg_rhs
%type <Node> command_asgn mrhs mrhs_arg superclass block_call block_command
%type <ListNode> f_block_optarg
%type <Node> f_block_opt
%type <ArgsNode> f_arglist f_opt_paren_args f_paren_args f_args
%type <ListNode> f_arg
%type <Node> f_arg_item
%type <ListNode> f_optarg
%type <Node> f_marg
%type <ListNode> f_marg_list 
%type <Node> f_margs f_rest_marg
%type <HashNode> assoc_list assocs
%type <KeyValuePair> assoc
%type <Node> undef_list backref string_dvar for_var
%type <ArgsNode> block_param opt_block_param block_param_def
%type <Node> f_opt
%type <ListNode> f_kwarg
%type <KeywordArgNode> f_kw
%type <ListNode> f_block_kwarg
%type <Node> f_block_kw
%type <Node> bv_decls opt_bv_decl 
%type <ByteList> bvar
%type <LambdaNode> lambda
%type <ArgsNode> f_larglist
%type <Node> lambda_body
%type <IterNode> brace_body do_body
%type <IterNode> brace_block cmd_brace_block do_block
%type <Node> lhs none fitem
%type <MultipleAsgnNode> mlhs
%type <ListNode> mlhs_head
%type <MultipleAsgnNode> mlhs_basic   
%type <Node> mlhs_item mlhs_node
%type <ListNode> mlhs_post
%type <Node> mlhs_inner
%type <InNode> p_case_body
%type <Node> p_cases p_top_expr p_top_expr_body
%type <Node> p_expr p_as p_alt p_expr_basic
%type <FindPatternNode> p_find
%type <ArrayPatternNode> p_args 
%type <ListNode> p_args_head
%type <ArrayPatternNode> p_args_tail
%type <ListNode> p_args_post p_arg
%type <Node> p_value p_primitive p_variable p_var_ref p_expr_ref p_const
%type <HashPatternNode> p_kwargs
%type <HashNode> p_kwarg
%type <KeyValuePair> p_kw
  /* keyword_variable + user_variable are inlined into the grammar */
%type <ByteList> sym operation operation2 operation3
%type <ByteList> cname op fname 
%type <RestArgNode> f_rest_arg
%type <BlockArgNode> f_block_arg opt_f_block_arg
%type <ByteList> f_norm_arg f_bad_arg
%type <ByteList> f_kwrest f_label 
%type <ArgumentNode> f_arg_asgn
%type <ByteList> call_op call_op2 reswords relop dot_or_colon
%type <ByteList> p_rest p_kwrest p_kwnorest p_any_kwrest p_kw_label
%type <ByteList> f_no_kwarg f_any_kwrest args_forward excessed_comma nonlocal_var
%type <LexContext> lex_ctxt
// Things not declared in MRI - start
%type <ByteList> blkarg_mark restarg_mark kwrest_mark rparen rbracket
%type <BlockPassNode> none_block_pass
%type <Integer> k_return
%type <LexContext> k_class k_module
%type <Integer> k_else k_when k_begin k_if k_do
%type <Integer> k_do_block k_rescue k_ensure k_elsif
%token <ByteList> tUMINUS_NUM
%type <Integer> rbrace
%type <Integer> k_def k_end k_while k_until k_for k_case k_unless
%type <Node> p_lparen p_lbracket
// Things not declared in MRI - end  


%token <Integer> '\\'                   /* {{backslash}} */
%token <Integer> tSP                    /* {{escaped space}} */
%token <Integer> '\t'                   /* {{escaped horizontal tab}} */
%token <Integer> '\f'                   /* {{escaped form feed}} */
%token <Integer> '\r'                   /* {{escaped carriage return}} */
%token <Integer> '\v'                   /* {{escaped vertical tab}} */
%token <ByteList> tUPLUS               /* {{unary+}} */
%token <ByteList> tUMINUS              /* {{unary-}} */
%token <ByteList> tPOW                 /* {{**}} */
%token <ByteList> tCMP                 /* {{<=>}} */
%token <ByteList> tEQ                  /* {{==}} */
%token <ByteList> tEQQ                 /* {{===}} */
%token <ByteList> tNEQ                 /* {{!=}} */
%token <ByteList> tGEQ                 /* {{>=}} */
%token <ByteList> tLEQ                 /* {{<=}} */
%token <ByteList> tANDOP               /* {{&&}}*/
%token <ByteList> tOROP                /* {{||}} */
%token <ByteList> tMATCH               /* {{=~}} */
%token <ByteList> tNMATCH              /* {{!~}} */
%token <ByteList> tDOT2                /* {{..}} */
%token <ByteList> tDOT3                /* {{...}} */
%token <ByteList> tBDOT2               /* {{(..}} */
%token <ByteList> tBDOT3               /* {{(...}} */
%token <ByteList> tAREF                /* {{[]}} */
%token <ByteList> tASET                /* {{[]=}} */
%token <ByteList> tLSHFT               /* {{<<}} */
%token <ByteList> tRSHFT               /* {{>>}} */
%token <ByteList> tANDDOT              /* {{&.}} */
%token <ByteList> tCOLON2              /* {{::}} */
%token <ByteList> tCOLON3              /* {{:: at EXPR_BEG}} */
%token <ByteList> tOP_ASGN             /* {{operator assignment}} +=, etc. */
%token <ByteList> tASSOC               /* {{=>}} */
%token <Integer> tLPAREN               /* {{(}} */
%token <Integer> tLPAREN_ARG           /* {{( arg}} */
%token <ByteList> tLBRACK              /* {{[}} */
%token <Object> tLBRACE               /* {{{}} */
%token <Integer> tLBRACE_ARG           /* {{{ arg}} */
%token <ByteList> tSTAR                /* {{*}} */
%token <ByteList> tDSTAR                /* {{**arg}} */
%token <ByteList> tAMPER               /* {{&}} */
%token <ByteList> tLAMBDA              /* {{->}} */
%token <ByteList> tSYMBEG              /* {{symbol literal}} */
%token <ByteList> tSTRING_BEG          /* {{string literal}} */
%token <ByteList> tXSTRING_BEG         /* {{backtick literal}} */
%token <ByteList> tREGEXP_BEG          /* {{regexp literal}} */
%token <ByteList> tWORDS_BEG           /* {{word list}} */
%token <ByteList> tQWORDS_BEG          /* {{verbatim work list}} */
%token <ByteList> tSTRING_END          /* {{terminator}} */
%token <ByteList> tSYMBOLS_BEG          /* {{symbol list}} */
%token <ByteList> tQSYMBOLS_BEG         /* {{verbatim symbol list}} */
%token <ByteList> tSTRING_DEND          /* {{'}'}} */
%token <ByteList> tSTRING_DBEG tSTRING_DVAR tLAMBEG tLABEL_END


/*
 *    precedence table
 */

%nonassoc tLOWEST
%nonassoc tLBRACE_ARG

%nonassoc  modifier_if modifier_unless modifier_while modifier_until keyword_in
%left  keyword_or keyword_and
%right keyword_not
%nonassoc keyword_defined
%right '=' tOP_ASGN
%left modifier_rescue
%right '?' ':'
%nonassoc tDOT2 tDOT3 tBDOT2 tBDOT3
%left  tOROP
%left  tANDOP
%nonassoc  tCMP tEQ tEQQ tNEQ tMATCH tNMATCH
%left  '>' tGEQ '<' tLEQ
%left  '|' '^'
%left  '&'
%left  tLSHFT tRSHFT
%left  '+' '-'
%left  '*' '/' '%'
%right tUMINUS_NUM tUMINUS
%right tPOW
%right '!' '~' tUPLUS

   //%token <Integer> tLAST_TOKEN

%%
program       : {
                  lexer.setState(EXPR_BEG);
                  support.initTopLocalVariables();
              } top_compstmt {
                  Node expr = $2;
                  if (expr != null && !support.getConfiguration().isEvalParse()) {
                      /* last expression should not be void */
                      if ($2 instanceof BlockNode) {
                        expr = $<BlockNode>2.getLast();
                      } else {
                        expr = $2;
                      }
                      expr = support.remove_begin(expr);
                      support.void_expr(expr);
                  }
                  support.getResult().setAST(support.addRootNode($2));
              }

top_compstmt  : top_stmts opt_terms {
                  $$ = support.void_stmts($1);
              }

top_stmts     : none 
              | top_stmt {
                  $$ = support.newline_node($1, support.getPosition($1));
              }
              | top_stmts terms top_stmt {
                  $$ = support.appendToBlock($1, support.newline_node($3, support.getPosition($3)));
              }
              | error top_stmt {
                  $$ = support.remove_begin($2);
              }

top_stmt      : stmt
              | keyword_BEGIN begin_block {
                  $$ = null;
              }

begin_block   : '{' top_compstmt '}' {
                  support.getResult().addBeginNode(new PreExe19Node(@1.start(), support.getCurrentScope(), $2, lexer.getRubySourceline()));
                  //                  $$ = new BeginNode(@1.start(), support.makeNullNil($2));
                  $$ = null;
              }

bodystmt      : compstmt opt_rescue k_else {
                   if ($2 == null) support.yyerror("else without rescue is useless"); 
              } compstmt opt_ensure {
                   $$ = support.new_bodystmt($1, $2, $5, $6);
              }
              | compstmt opt_rescue opt_ensure {
                   $$ = support.new_bodystmt($1, $2, null, $3);
              }

compstmt        : stmts opt_terms {
                    $$ = support.void_stmts($1);
                }

stmts           : none
                | stmt_or_begin {
                    $$ = support.newline_node($1, support.getPosition($1));
                }
                | stmts terms stmt_or_begin {
                    $$ = support.appendToBlock($1, support.newline_node($3, support.getPosition($3)));
                }
                | error stmt {
                    $$ = $2;
                }

stmt_or_begin   : stmt {
                    $$ = $1;
                }
                | keyword_BEGIN {
                   support.yyerror("BEGIN is permitted only at toplevel");
                } begin_block {
                   $$ = $3;
                }

stmt            : keyword_alias fitem {
                    lexer.setState(EXPR_FNAME|EXPR_FITEM);
                } fitem {
                    $$ = ParserSupport.newAlias($1, $2, $4);
                }
                | keyword_alias tGVAR tGVAR {
                    $$ = new VAliasNode($1, support.symbolID($2), support.symbolID($3));
                }
                | keyword_alias tGVAR tBACK_REF {
                    $$ = new VAliasNode($1, support.symbolID($2), support.symbolID($<BackRefNode>3.getByteName()));
                }
                | keyword_alias tGVAR tNTH_REF {
                    support.yyerror("can't make alias for the number variables");
                }
                | keyword_undef undef_list {
                    $$ = $2;
                }
                | stmt modifier_if expr_value {
                    $$ = support.new_if(support.getPosition($1), support.cond($3), support.remove_begin($1), null);
                    support.fixpos($<Node>$, $3);
                }
                | stmt modifier_unless expr_value {
                    $$ = support.new_if(support.getPosition($1), support.cond($3), null, support.remove_begin($1));
                    support.fixpos($<Node>$, $3);
                }
                | stmt modifier_while expr_value {
                    if ($1 != null && $1 instanceof BeginNode) {
                        $$ = new WhileNode(support.getPosition($1), support.cond($3), $<BeginNode>1.getBodyNode(), false);
                    } else {
                        $$ = new WhileNode(support.getPosition($1), support.cond($3), $1, true);
                    }
                }
                | stmt modifier_until expr_value {
                    if ($1 != null && $1 instanceof BeginNode) {
                        $$ = new UntilNode(support.getPosition($1), support.cond($3), $<BeginNode>1.getBodyNode(), false);
                    } else {
                        $$ = new UntilNode(support.getPosition($1), support.cond($3), $1, true);
                    }
                }
                | stmt modifier_rescue stmt {
                    $$ = support.newRescueModNode($1, $3);
                }
                | keyword_END '{' compstmt '}' {
                   if (lexer.getLexContext().in_def) {
                       support.warn(ID.END_IN_METHOD, $1, "END in method; use at_exit");
                    }
                    $$ = new PostExeNode($1, $3, lexer.getRubySourceline());
                }
                | command_asgn
                | mlhs '=' lex_ctxt command_call {
                    $$ = node_assign($1, $4);
                }
                | lhs '=' lex_ctxt mrhs {
                    support.value_expr(lexer, $4);
                    $$ = node_assign($1, $4);
                }
                | mlhs '=' lex_ctxt mrhs_arg modifier_rescue stmt {
                    $$ = node_assign($1, support.newRescueModNode($4, $6));
                }
                | mlhs '=' lex_ctxt mrhs_arg {
                    $$ = node_assign($1, $4);
                }
                | expr

command_asgn    : lhs '=' lex_ctxt command_rhs {
                    support.value_expr(lexer, $4);
                    $$ = node_assign($1, $4);
                }
                | var_lhs tOP_ASGN lex_ctxt command_rhs {
                    support.value_expr(lexer, $4);
                    $$ = support.new_op_assign($1, $2, $4);
                }
                | primary_value '[' opt_call_args rbracket tOP_ASGN lex_ctxt command_rhs {
                    support.value_expr(lexer, $7);
                    $$ = support.new_ary_op_assign($1, $5, $3, $7);
                }
                | primary_value call_op tIDENTIFIER tOP_ASGN lex_ctxt command_rhs {
                    support.value_expr(lexer, $6);
                    $$ = support.new_attr_op_assign($1, $2, $6, $3, $4);
                }
                | primary_value call_op tCONSTANT tOP_ASGN lex_ctxt command_rhs {
                    support.value_expr(lexer, $6);
                    $$ = support.new_attr_op_assign($1, $2, $6, $3, $4);
                }
                | primary_value tCOLON2 tCONSTANT tOP_ASGN lex_ctxt command_rhs {
                    int line = $1.getLine();
                    $$ = support.new_const_op_assign(line, support.new_colon2(line, $1, $3), $4, $6);
                }

                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN lex_ctxt command_rhs {
                    support.value_expr(lexer, $6);
                    $$ = support.new_attr_op_assign($1, $2, $6, $3, $4);
                }
 		| defn_head f_opt_paren_args '=' command {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    $$ = new DefnNode($1.line, $1.name, $2, support.getCurrentScope(), support.reduce_nodes(support.remove_begin($4)), @4.end());
                    support.popCurrentScope();
                }
                | defn_head f_opt_paren_args '=' command modifier_rescue arg {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    Node body = support.reduce_nodes(support.remove_begin(support.rescued_expr(@1.start(), $4, $6)));
                    $$ = new DefnNode($1.line, $1.name, $2, support.getCurrentScope(), body, @6.end());
                    support.popCurrentScope();
                }
                | defs_head f_opt_paren_args '=' command {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    $$ = new DefsNode($1.line, $1.singleton, $1.name, $2, support.getCurrentScope(), support.reduce_nodes(support.remove_begin($4)), @4.end());
                    support.popCurrentScope();
                }
                | defs_head f_opt_paren_args '=' command modifier_rescue arg {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    Node body = support.reduce_nodes(support.remove_begin(support.rescued_expr(@1.start(), $4, $6)));
                    $$ = new DefsNode($1.line, $1.singleton, $1.name, $2, support.getCurrentScope(), body, @6.end());
                    support.popCurrentScope();
                }
                | backref tOP_ASGN lex_ctxt command_rhs {
                    support.backrefAssignError($1);
                }

command_rhs     : command_call %prec tOP_ASGN {
                    support.value_expr(lexer, $1);
                    $$ = $1;
                }
		| command_call modifier_rescue stmt {
                    support.value_expr(lexer, $1);
                    $$ = support.newRescueModNode($1, $3);
                }
		| command_asgn
 

// Node:expr *CURRENT* all but arg so far
expr            : command_call
                | expr keyword_and expr {
                    $$ = support.newAndNode($1, $3);
                }
                | expr keyword_or expr {
                    $$ = support.newOrNode($1, $3);
                }
                | keyword_not opt_nl expr {
                    $$ = support.getOperatorCallNode(support.method_cond($3), lexer.BANG);
                }
                | '!' command_call {
                    $$ = support.getOperatorCallNode(support.method_cond($2), BANG);
                }
                | arg tASSOC {
                    support.value_expr(lexer, $1);
                    lexer.setState(EXPR_BEG|EXPR_LABEL);
                    lexer.commandStart = false;
                    // MRI 3.1 uses $2 but we want tASSOC typed?
                    LexContext ctxt = lexer.getLexContext();
                    $$ = ctxt.in_kwarg;
                    ctxt.in_kwarg = true;
                } {
                    $$ = support.push_pvtbl();
                } p_top_expr_body {
                    support.pop_pvtbl($<Set>4);
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_kwarg = $<Boolean>3;
                    $$ = support.newPatternCaseNode($1.getLine(), $1, support.newIn(@1.start(), $5, null, null));
                }
                | arg keyword_in {
                    support.value_expr(lexer, $1);
                    lexer.setState(EXPR_BEG|EXPR_LABEL);
                    lexer.commandStart = false;
                    LexContext ctxt = lexer.getLexContext();
                    $$ = ctxt.in_kwarg;
                    ctxt.in_kwarg = true;
                } {
                    $$ = support.push_pvtbl();
                } p_top_expr_body {
                    support.pop_pvtbl($<Set>4);
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_kwarg = $<Boolean>3;
                    $$ = support.newPatternCaseNode($1.getLine(), $1, support.newIn(@1.start(), $5, new TrueNode(lexer.tokline), new FalseNode(lexer.tokline)));
                }
		| arg %prec tLBRACE_ARG

// FIXME:  If we ever want to match MRI's AST mode we may need to make a node
// [!null] - RubySymbol
def_name        : fname {
                    support.pushLocalScope();
                    LexContext ctxt = lexer.getLexContext();
                    RubySymbol name = support.symbolID($1);
                    support.numparam_name(name);
                    $$ = new DefHolder(support.symbolID($1), lexer.getCurrentArg(), (LexContext) ctxt.clone());
                    ctxt.in_def = true;
                    lexer.setCurrentArg(null);
                }

// [!null] - DefnNode
defn_head       : k_def def_name {
                    $2.line = $1;
                    $$ = $2;
                }

// [!null] - DefsNode
defs_head       : k_def singleton dot_or_colon {
                    lexer.setState(EXPR_FNAME); 
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_argdef = true;
                } def_name {
                    lexer.setState(EXPR_ENDFN|EXPR_LABEL);
                    $5.line = $1;
                    $5.setSingleton($2);
                    $$ = $5;
                }

expr_value      : expr {
                    support.value_expr(lexer, $1);
                }

expr_value_do   : {
                    lexer.getConditionState().push1();
                } expr_value do {
                    lexer.getConditionState().pop();
                    $$ = $2;
                }

// Node:command - call with or with block on end [!null]
command_call    : command
                | block_command

// Node:block_command - A call with a block (foo.bar {...}, foo::bar {...}, bar {...}) [!null]
block_command   : block_call
                | block_call call_op2 operation2 command_args {
                    $$ = support.new_call($1, $2, $3, $4, null, @3.start());
                }

// :brace_block - [!null]
cmd_brace_block : tLBRACE_ARG brace_body '}' {
                    $$ = $2;
                }

fcall           : operation {
                    $$ = support.new_fcall($1);
                }

// Node:command - fcall/call/yield/super [!null]
command        : fcall command_args %prec tLOWEST {
                    support.frobnicate_fcall_args($1, $2, null);
                    $$ = $1;
                }
                | fcall command_args cmd_brace_block {
                    support.frobnicate_fcall_args($1, $2, $3);
                    $$ = $1;
                }
                | primary_value call_op operation2 command_args %prec tLOWEST {
                    $$ = support.new_call($1, $2, $3, $4, null, @3.start());
                }
                | primary_value call_op operation2 command_args cmd_brace_block {
                    $$ = support.new_call($1, $2, $3, $4, $5, @3.start());
                }
                | primary_value tCOLON2 operation2 command_args %prec tLOWEST {
                    $$ = support.new_call($1, $3, $4, null);
                }
                | primary_value tCOLON2 operation2 command_args cmd_brace_block {
                    $$ = support.new_call($1, $3, $4, $5);
                }
                | keyword_super command_args {
                    $$ = support.new_super($1, $2);
                }
                | keyword_yield command_args {
                    $$ = support.new_yield($1, $2);
                }
                | k_return call_args {
                    $$ = new ReturnNode($1, support.ret_args($2, $1));
                }
                | keyword_break call_args {
                    $$ = new BreakNode($1, support.ret_args($2, $1));
                }
                | keyword_next call_args {
                    $$ = new NextNode($1, support.ret_args($2, $1));
                }

// MultipleAssigNode:mlhs - [!null]
mlhs            : mlhs_basic
                | tLPAREN mlhs_inner rparen {
                    $$ = $2;
                }

// MultipleAssignNode:mlhs_entry - mlhs w or w/o parens [!null]
mlhs_inner      : mlhs_basic {
                    $$ = $1;
                }
                | tLPAREN mlhs_inner rparen {
                    $$ = new MultipleAsgnNode($1, support.newArrayNode($1, $2), null, null);
                }

// MultipleAssignNode:mlhs_basic - multiple left hand side (basic because used in multiple context) [!null]
mlhs_basic      : mlhs_head {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, null, null);
                }
                | mlhs_head mlhs_item {
                    $$ = new MultipleAsgnNode($1.getLine(), $1.add($2), null, null);
                }
                | mlhs_head tSTAR mlhs_node {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, $3, (ListNode) null);
                }
                | mlhs_head tSTAR mlhs_node ',' mlhs_post {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, $3, $5);
                }
                | mlhs_head tSTAR {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, new StarNode(lexer.getRubySourceline()), null);
                }
                | mlhs_head tSTAR ',' mlhs_post {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, new StarNode(lexer.getRubySourceline()), $4);
                }
                | tSTAR mlhs_node {
                    $$ = new MultipleAsgnNode($2.getLine(), null, $2, null);
                }
                | tSTAR mlhs_node ',' mlhs_post {
                    $$ = new MultipleAsgnNode($2.getLine(), null, $2, $4);
                }
                | tSTAR {
                      $$ = new MultipleAsgnNode(lexer.getRubySourceline(), null, new StarNode(lexer.getRubySourceline()), null);
                }
                | tSTAR ',' mlhs_post {
                      $$ = new MultipleAsgnNode(lexer.getRubySourceline(), null, new StarNode(lexer.getRubySourceline()), $3);
                }

mlhs_item       : mlhs_node
                | tLPAREN mlhs_inner rparen {
                    $$ = $2;
                }

// Set of mlhs terms at front of mlhs (a, *b, d, e = arr  # a is head)
mlhs_head       : mlhs_item ',' {
                    $$ = support.newArrayNode($1.getLine(), $1);
                }
                | mlhs_head mlhs_item ',' {
                    $$ = $1.add($2);
                }

// Set of mlhs terms at end of mlhs (a, *b, d, e = arr  # d,e is post)
mlhs_post       : mlhs_item {
                    $$ = support.newArrayNode($1.getLine(), $1);
                }
                | mlhs_post ',' mlhs_item {
                    $$ = $1.add($3);
                }

mlhs_node       : /*mri:user_variable*/ tIDENTIFIER {
                   $$ = support.assignableLabelOrIdentifier($1, null);
                }
                | tIVAR {
                   $$ = new InstAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                }
                | tGVAR {
                   $$ = new GlobalAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                }
                | tCONSTANT {
                    if (lexer.getLexContext().in_def) support.compile_error("dynamic constant assignment");
                    $$ = new ConstDeclNode(lexer.tokline, support.symbolID($1), null, NilImplicitNode.NIL);
                }
                | tCVAR {
                    $$ = new ClassVarAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                } /*mri:user_variable*/
                | /*mri:keyword_variable*/ keyword_nil {
                    support.compile_error("Can't assign to nil");
                    $$ = null;
                }
                | keyword_self {
                    support.compile_error("Can't change the value of self");
                    $$ = null;
                }
                | keyword_true {
                    support.compile_error("Can't assign to true");
                    $$ = null;
                }
                | keyword_false {
                    support.compile_error("Can't assign to false");
                    $$ = null;
                }
                | keyword__FILE__ {
                    support.compile_error("Can't assign to __FILE__");
                    $$ = null;
                }
                | keyword__LINE__ {
                    support.compile_error("Can't assign to __LINE__");
                    $$ = null;
                }
                | keyword__ENCODING__ {
                    support.compile_error("Can't assign to __ENCODING__");
                    $$ = null;
                } /*mri:keyword_variable*/
                | primary_value '[' opt_call_args rbracket {
                    $$ = support.aryset($1, $3);
                }
                | primary_value call_op tIDENTIFIER {
                    $$ = support.attrset($1, $2, $3);
                }
                | primary_value tCOLON2 tIDENTIFIER {
                    $$ = support.attrset($1, $3);
                }
                | primary_value call_op tCONSTANT {
                    $$ = support.attrset($1, $2, $3);
                }
                | primary_value tCOLON2 tCONSTANT {
                    if (lexer.getLexContext().in_def) support.yyerror("dynamic constant assignment");

                    Integer position = support.getPosition($1);

                    $$ = new ConstDeclNode(position, (RubySymbol) null, support.new_colon2(position, $1, $3), NilImplicitNode.NIL);
                }
                | tCOLON3 tCONSTANT {
                    if (lexer.getLexContext().in_def) {
                        support.yyerror("dynamic constant assignment");
                    }

                    Integer position = lexer.tokline;

                    $$ = new ConstDeclNode(position, (RubySymbol) null, support.new_colon3(position, $2), NilImplicitNode.NIL);
                }
                | backref {
                    support.backrefAssignError($1);
                }

// [!null or throws]
lhs             : /*mri:user_variable*/ tIDENTIFIER {
                    $$ = support.assignableLabelOrIdentifier($1, null);
                }
                | tIVAR {
                    $$ = new InstAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                }
                | tGVAR {
                    $$ = new GlobalAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                }
                | tCONSTANT {
                    if (lexer.getLexContext().in_def) support.compile_error("dynamic constant assignment");

                    $$ = new ConstDeclNode(lexer.tokline, support.symbolID($1), null, NilImplicitNode.NIL);
                }
                | tCVAR {
                    $$ = new ClassVarAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                } /*mri:user_variable*/
                | /*mri:keyword_variable*/ keyword_nil {
                    support.compile_error("Can't assign to nil");
                    $$ = null;
                }
                | keyword_self {
                    support.compile_error("Can't change the value of self");
                    $$ = null;
                }
                | keyword_true {
                    support.compile_error("Can't assign to true");
                    $$ = null;
                }
                | keyword_false {
                    support.compile_error("Can't assign to false");
                    $$ = null;
                }
                | keyword__FILE__ {
                    support.compile_error("Can't assign to __FILE__");
                    $$ = null;
                }
                | keyword__LINE__ {
                    support.compile_error("Can't assign to __LINE__");
                    $$ = null;
                }
                | keyword__ENCODING__ {
                    support.compile_error("Can't assign to __ENCODING__");
                    $$ = null;
                } /*mri:keyword_variable*/
                | primary_value '[' opt_call_args rbracket {
                    $$ = support.aryset($1, $3);
                }
                | primary_value call_op tIDENTIFIER {
                    $$ = support.attrset($1, $2, $3);
                }
                | primary_value tCOLON2 tIDENTIFIER {
                    $$ = support.attrset($1, $3);
                }
                | primary_value call_op tCONSTANT {
                    $$ = support.attrset($1, $2, $3);
                }
                | primary_value tCOLON2 tCONSTANT {
                    if (lexer.getLexContext().in_def) {
                        support.yyerror("dynamic constant assignment");
                    }

                    Integer position = support.getPosition($1);

                    $$ = new ConstDeclNode(position, (RubySymbol) null, support.new_colon2(position, $1, $3), NilImplicitNode.NIL);
                }
                | tCOLON3 tCONSTANT {
                    if (lexer.getLexContext().in_def) {
                        support.yyerror("dynamic constant assignment");
                    }

                    Integer position = lexer.tokline;

                    $$ = new ConstDeclNode(position, (RubySymbol) null, support.new_colon3(position, $2), NilImplicitNode.NIL);
                }
                | backref {
                    support.backrefAssignError($1);
                }

cname           : tIDENTIFIER {
                    support.yyerror("class/module name must be CONSTANT", @1);
                }
                | tCONSTANT {
                   $$ = $1;
                }

cpath           : tCOLON3 cname {
                    $$ = support.new_colon3(lexer.tokline, $2);
                }
                | cname {
                    $$ = support.new_colon2(lexer.tokline, null, $1);
                }
                | primary_value tCOLON2 cname {
                    $$ = support.new_colon2(support.getPosition($1), $1, $3);
                }

// ByteList:fname - A function name [!null]
fname          : tIDENTIFIER {
                   $$ = $1;
               }
               | tCONSTANT {
                   $$ = $1;
               }
               | tFID  {
                   $$ = $1;
               }
               | op {
                   lexer.setState(EXPR_ENDFN);
                   $$ = $1;
               }
               | reswords {
                   $$ = $1;
               }

// Node:fitem
fitem           : fname {  // LiteralNode
                    $$ =  new LiteralNode(lexer.getRubySourceline(), support.symbolID($1));
                }
                | symbol {  // SymbolNode/DSymbolNode
                    $$ = $1;
                }

undef_list      : fitem {
                    $$ = ParserSupport.newUndef($1.getLine(), $1);
                }
                | undef_list ',' {
                    lexer.setState(EXPR_FNAME|EXPR_FITEM);
                } fitem {
                    $$ = support.appendToBlock($1, ParserSupport.newUndef($1.getLine(), $4));
                }

// ByteList:op
op               : '|' {
                     $$ = OR;
                 }
                 | '^' {
                     $$ = CARET;
                 }
                 | '&' {
                     $$ = AMPERSAND;
                 }
                 | tCMP {
                     $$ = $1;
                 }
                 | tEQ {
                     $$ = $1;
                 }
                 | tEQQ {
                     $$ = $1;
                 }
                 | tMATCH {
                     $$ = $1;
                 }
                 | tNMATCH {
                     $$ = $1;
                 }
                 | '>' {
                     $$ = GT;
                 }
                 | tGEQ {
                     $$ = $1;
                 }
                 | '<' {
                     $$ = LT;
                 }
                 | tLEQ {
                     $$ = $1;
                 }
                 | tNEQ {
                     $$ = $1;
                 }
                 | tLSHFT {
                     $$ = $1;
                 }
                 | tRSHFT{
                     $$ = $1;
                 }
                 | '+' {
                     $$ = PLUS;
                 }
                 | '-' {
                     $$ = MINUS;
                 }
                 | '*' {
                     $$ = STAR;
                 }
                 | tSTAR {
                     $$ = $1;
                 }
                 | '/' {
                     $$ = SLASH;
                 }
                 | '%' {
                     $$ = PERCENT;
                 }
                 | tPOW {
                     $$ = $1;
                 }
                 | tDSTAR {
                     $$ = $1;
                 }
                 | '!' {
                     $$ = BANG;
                 }
                 | '~' {
                     $$ = TILDE;
                 }
                 | tUPLUS {
                     $$ = $1;
                 }
                 | tUMINUS {
                     $$ = $1;
                 }
                 | tAREF {
                     $$ = $1;
                 }
                 | tASET {
                     $$ = $1;
                 }
                 | '`' {
                     $$ = BACKTICK;
                 }
 
// String:op
reswords        : keyword__LINE__ {
                    $$ = RubyLexer.Keyword.__LINE__.bytes;
                }
                | keyword__FILE__ {
                    $$ = RubyLexer.Keyword.__FILE__.bytes;
                }
                | keyword__ENCODING__ {
                    $$ = RubyLexer.Keyword.__ENCODING__.bytes;
                }
                | keyword_BEGIN {
                    $$ = RubyLexer.Keyword.LBEGIN.bytes;
                }
                | keyword_END {
                    $$ = RubyLexer.Keyword.LEND.bytes;
                }
                | keyword_alias {
                    $$ = RubyLexer.Keyword.ALIAS.bytes;
                }
                | keyword_and {
                    $$ = RubyLexer.Keyword.AND.bytes;
                }
                | keyword_begin {
                    $$ = RubyLexer.Keyword.BEGIN.bytes;
                }
                | keyword_break {
                    $$ = RubyLexer.Keyword.BREAK.bytes;
                }
                | keyword_case {
                    $$ = RubyLexer.Keyword.CASE.bytes;
                }
                | keyword_class {
                    $$ = RubyLexer.Keyword.CLASS.bytes;
                }
                | keyword_def {
                    $$ = RubyLexer.Keyword.DEF.bytes;
                }
                | keyword_defined {
                    $$ = RubyLexer.Keyword.DEFINED_P.bytes;
                }
                | keyword_do {
                    $$ = RubyLexer.Keyword.DO.bytes;
                }
                | keyword_else {
                    $$ = RubyLexer.Keyword.ELSE.bytes;
                }
                | keyword_elsif {
                    $$ = RubyLexer.Keyword.ELSIF.bytes;
                }
                | keyword_end {
                    $$ = RubyLexer.Keyword.END.bytes;
                }
                | keyword_ensure {
                    $$ = RubyLexer.Keyword.ENSURE.bytes;
                }
                | keyword_false {
                    $$ = RubyLexer.Keyword.FALSE.bytes;
                }
                | keyword_for {
                    $$ = RubyLexer.Keyword.FOR.bytes;
                }
                | keyword_in {
                    $$ = RubyLexer.Keyword.IN.bytes;
                }
                | keyword_module {
                    $$ = RubyLexer.Keyword.MODULE.bytes;
                }
                | keyword_next {
                    $$ = RubyLexer.Keyword.NEXT.bytes;
                }
                | keyword_nil {
                    $$ = RubyLexer.Keyword.NIL.bytes;
                }
                | keyword_not {
                    $$ = RubyLexer.Keyword.NOT.bytes;
                }
                | keyword_or {
                    $$ = RubyLexer.Keyword.OR.bytes;
                }
                | keyword_redo {
                    $$ = RubyLexer.Keyword.REDO.bytes;
                }
                | keyword_rescue {
                    $$ = RubyLexer.Keyword.RESCUE.bytes;
                }
                | keyword_retry {
                    $$ = RubyLexer.Keyword.RETRY.bytes;
                }
                | keyword_return {
                    $$ = RubyLexer.Keyword.RETURN.bytes;
                }
                | keyword_self {
                    $$ = RubyLexer.Keyword.SELF.bytes;
                }
                | keyword_super {
                    $$ = RubyLexer.Keyword.SUPER.bytes;
                }
                | keyword_then {
                    $$ = RubyLexer.Keyword.THEN.bytes;
                }
                | keyword_true {
                    $$ = RubyLexer.Keyword.TRUE.bytes;
                }
                | keyword_undef {
                    $$ = RubyLexer.Keyword.UNDEF.bytes;
                }
                | keyword_when {
                    $$ = RubyLexer.Keyword.WHEN.bytes;
                }
                | keyword_yield {
                    $$ = RubyLexer.Keyword.YIELD.bytes;
                }
                | keyword_if {
                    $$ = RubyLexer.Keyword.IF.bytes;
                }
                | keyword_unless {
                    $$ = RubyLexer.Keyword.UNLESS.bytes;
                }
                | keyword_while {
                    $$ = RubyLexer.Keyword.WHILE.bytes;
                }
                | keyword_until {
                    $$ = RubyLexer.Keyword.UNTIL.bytes;
                }

arg             : lhs '=' lex_ctxt arg_rhs {
                    $$ = node_assign($1, $4);
                }
                | var_lhs tOP_ASGN lex_ctxt arg_rhs {
                    $$ = support.new_op_assign($1, $2, $4);
                }
                | primary_value '[' opt_call_args rbracket tOP_ASGN lex_ctxt arg_rhs {
                    support.value_expr(lexer, $7);
                    $$ = support.new_ary_op_assign($1, $5, $3, $7);
                }
                | primary_value call_op tIDENTIFIER tOP_ASGN lex_ctxt arg_rhs {
                    support.value_expr(lexer, $6);
                    $$ = support.new_attr_op_assign($1, $2, $6, $3, $4);
                }
                | primary_value call_op tCONSTANT tOP_ASGN lex_ctxt arg_rhs {
                    support.value_expr(lexer, $6);
                    $$ = support.new_attr_op_assign($1, $2, $6, $3, $4);
                }
                | primary_value tCOLON2 tIDENTIFIER tOP_ASGN lex_ctxt arg_rhs {
                    support.value_expr(lexer, $6);
                    $$ = support.new_attr_op_assign($1, $2, $6, $3, $4);
                }
                | primary_value tCOLON2 tCONSTANT tOP_ASGN lex_ctxt arg_rhs {
                    Integer pos = support.getPosition($1);
                    $$ = support.new_const_op_assign(pos, support.new_colon2(pos, $1, $3), $4, $6);
                }
                | tCOLON3 tCONSTANT tOP_ASGN lex_ctxt arg_rhs {
                    Integer pos = lexer.getRubySourceline();
                    $$ = support.new_const_op_assign(pos, new Colon3Node(pos, support.symbolID($2)), $3, $5);
                }
                | backref tOP_ASGN lex_ctxt arg_rhs {
                    support.backrefAssignError($1);
                }
                | arg tDOT2 arg {
                    support.value_expr(lexer, $1);
                    support.value_expr(lexer, $3);
    
                    boolean isLiteral = $1 instanceof FixnumNode && $3 instanceof FixnumNode;
                    $$ = new DotNode(support.getPosition($1), support.makeNullNil($1), support.makeNullNil($3), false, isLiteral);
                }
                | arg tDOT3 arg {
                    support.value_expr(lexer, $1);
                    support.value_expr(lexer, $3);

                    boolean isLiteral = $1 instanceof FixnumNode && $3 instanceof FixnumNode;
                    $$ = new DotNode(support.getPosition($1), support.makeNullNil($1), support.makeNullNil($3), true, isLiteral);
                }
                | arg tDOT2 {
                    support.value_expr(lexer, $1);

                    boolean isLiteral = $1 instanceof FixnumNode;
                    $$ = new DotNode(support.getPosition($1), support.makeNullNil($1), NilImplicitNode.NIL, false, isLiteral);
                }
                | arg tDOT3 {
                    support.value_expr(lexer, $1);

                    boolean isLiteral = $1 instanceof FixnumNode;
                    $$ = new DotNode(support.getPosition($1), support.makeNullNil($1), NilImplicitNode.NIL, true, isLiteral);
                }
                | tBDOT2 arg {
                    support.value_expr(lexer, $2);
                    boolean isLiteral = $2 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), NilImplicitNode.NIL, support.makeNullNil($2), false, isLiteral);
                }
                | tBDOT3 arg {
                    support.value_expr(lexer, $2);
                    boolean isLiteral = $2 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), NilImplicitNode.NIL, support.makeNullNil($2), true, isLiteral);
                }
                | arg '+' arg {
                    $$ = support.getOperatorCallNode($1, PLUS, $3, lexer.getRubySourceline());
                }
                | arg '-' arg {
                    $$ = support.getOperatorCallNode($1, MINUS, $3, lexer.getRubySourceline());
                }
                | arg '*' arg {
                    $$ = support.getOperatorCallNode($1, STAR, $3, lexer.getRubySourceline());
                }
                | arg '/' arg {
                    $$ = support.getOperatorCallNode($1, SLASH, $3, lexer.getRubySourceline());
                }
                | arg '%' arg {
                    $$ = support.getOperatorCallNode($1, PERCENT, $3, lexer.getRubySourceline());
                }
                | arg tPOW arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | tUMINUS_NUM simple_numeric tPOW arg {
                    $$ = support.getOperatorCallNode(support.getOperatorCallNode($2, $3, $4, lexer.getRubySourceline()), $1);
                }
                | tUPLUS arg {
                    $$ = support.getOperatorCallNode($2, $1);
                }
                | tUMINUS arg {
                    $$ = support.getOperatorCallNode($2, $1);
                }
                | arg '|' arg {
                    $$ = support.getOperatorCallNode($1, OR, $3, lexer.getRubySourceline());
                }
                | arg '^' arg {
                    $$ = support.getOperatorCallNode($1, CARET, $3, lexer.getRubySourceline());
                }
                | arg '&' arg {
                    $$ = support.getOperatorCallNode($1, AMPERSAND, $3, lexer.getRubySourceline());
                }
                | arg tCMP arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | rel_expr   %prec tCMP {
                    $$ = $1;
                }
                | arg tEQ arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | arg tEQQ arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | arg tNEQ arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | arg tMATCH arg {
                    $$ = support.getMatchNode($1, $3);
                }
                | arg tNMATCH arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | '!' arg {
                    $$ = support.getOperatorCallNode(support.method_cond($2), BANG);
                }
                | '~' arg {
                    $$ = support.getOperatorCallNode($2, TILDE);
                }
                | arg tLSHFT arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | arg tRSHFT arg {
                    $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
                | arg tANDOP arg {
                    $$ = support.newAndNode($1, $3);
                }
                | arg tOROP arg {
                    $$ = support.newOrNode($1, $3);
                }
                | keyword_defined opt_nl {
                    lexer.getLexContext().in_defined = true;
                } arg {
                    lexer.getLexContext().in_defined = false;                    
                    $$ = new DefinedNode($1, $4);
                }
                | arg '?' arg opt_nl ':' arg {
                    support.value_expr(lexer, $1);
                    $$ = support.new_if(support.getPosition($1), support.cond($1), $3, $6);
                }
                | defn_head f_opt_paren_args '=' arg {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    $$ = new DefnNode($1.line, $1.name, $2, support.getCurrentScope(), support.reduce_nodes(support.remove_begin($4)), @4.end());
                    if (support.isNextBreak) $<DefnNode>$.setContainsNextBreak();
                    support.popCurrentScope();
		}
                | defn_head f_opt_paren_args '=' arg modifier_rescue arg {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    Node body = support.reduce_nodes(support.remove_begin(support.rescued_expr(@1.start(), $4, $6)));
                    $$ = new DefnNode($1.line, $1.name, $2, support.getCurrentScope(), body, @6.end());
                    if (support.isNextBreak) $<DefnNode>$.setContainsNextBreak();
                    support.popCurrentScope();
		}
                | defs_head f_opt_paren_args '=' arg {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    $$ = new DefsNode($1.line, $1.singleton, $1.name, $2, support.getCurrentScope(), support.reduce_nodes(support.remove_begin($4)), @4.end());
                    if (support.isNextBreak) $<DefsNode>$.setContainsNextBreak();
                    support.popCurrentScope();
		}
                | defs_head f_opt_paren_args '=' arg modifier_rescue arg {
                    support.endless_method_name($1);
                    support.restore_defun($1);
                    Node body = support.reduce_nodes(support.remove_begin(support.rescued_expr(@1.start(), $4, $6)));
                    $$ = new DefsNode($1.line, $1.singleton, $1.name, $2, support.getCurrentScope(), body, @6.end());
                    if (support.isNextBreak) $<DefsNode>$.setContainsNextBreak();                    support.popCurrentScope();
                }
                | primary {
                    $$ = $1;
                }
 
relop           : '>' {
                    $$ = GT;
                }
                | '<' {
                    $$ = LT;
                }
                | tGEQ {
                     $$ = $1;
                }
                | tLEQ {
                     $$ = $1;
                }

rel_expr        : arg relop arg   %prec '>' {
                     $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }
		| rel_expr relop arg   %prec '>' {
                     support.warning(ID.MISCELLANEOUS, lexer.getRubySourceline(), "comparison '" + $2 + "' after comparison");
                     $$ = support.getOperatorCallNode($1, $2, $3, lexer.getRubySourceline());
                }

lex_ctxt        : tSP {
                   $$ = (LexContext) lexer.getLexContext().clone();
                }
                | none {
                   $$ = (LexContext) lexer.getLexContext().clone();
                }
 
arg_value       : arg {
                    support.value_expr(lexer, $1);
                    $$ = support.makeNullNil($1);
                }

aref_args       : none
                | args trailer {
                    $$ = $1;
                }
                | args ',' assocs trailer {
                    $$ = support.arg_append($1, support.remove_duplicate_keys($3));
                }
                | assocs trailer {
                    $$ = support.newArrayNode($1.getLine(), support.remove_duplicate_keys($1));
                }

arg_rhs         : arg %prec tOP_ASGN {
                    support.value_expr(lexer, $1);
                    $$ = $1;
                }
                | arg modifier_rescue arg {
                    support.value_expr(lexer, $1);
                    $$ = support.newRescueModNode($1, $3);
                }

paren_args      : '(' opt_call_args rparen {
                    $$ = $2;
                }
                | '(' args ',' args_forward rparen {
                    if (!support.check_forwarding_args()) {
                        $$ = null;
                    } else {
                        $$ = support.new_args_forward_call(@1.start(), $2);
                    }
               }
               | '(' args_forward rparen {
                    if (!support.check_forwarding_args()) {
                        $$ = null;
                    } else {
                        $$ = support.new_args_forward_call(@1.start(), null);
                    }
               }
 
opt_paren_args  : none | paren_args

opt_call_args   : none
                | call_args
                | args ',' {
                    $$ = $1;
                }
                | args ',' assocs ',' {
                    $$ = support.arg_append($1, support.remove_duplicate_keys($3));
                }
                | assocs ',' {
                    $$ = support.newArrayNode($1.getLine(), support.remove_duplicate_keys($1));
                }
   

// [!null] - ArgsCatNode, SplatNode, ArrayNode, HashNode, BlockPassNode
call_args       : command {
                    support.value_expr(lexer, $1);
                    $$ = support.newArrayNode(support.getPosition($1), $1);
                }
                | args opt_block_arg {
                    $$ = arg_blk_pass($1, $2);
                }
                | assocs opt_block_arg {
                    $$ = support.newArrayNode($1.getLine(), support.remove_duplicate_keys($1));
                    $$ = arg_blk_pass($<Node>$, $2);
                }
                | args ',' assocs opt_block_arg {
                    $$ = support.arg_append($1, support.remove_duplicate_keys($3));
                    $$ = arg_blk_pass($<Node>$, $4);
                }
                | block_arg {
                }

// [!null] - ArgsCatNode, SplatNode, ArrayNode, HashNode, BlockPassNode
command_args    : /* none */ {
                    boolean lookahead = false;
                    switch (yychar) {
                    case '(': case tLPAREN: case tLPAREN_ARG: case '[': case tLBRACK:
                       lookahead = true;
                    }
                    StackState cmdarg = lexer.getCmdArgumentState();
                    if (lookahead) cmdarg.pop();
                    cmdarg.push1();
                    if (lookahead) cmdarg.push0();
                } call_args {
                    StackState cmdarg = lexer.getCmdArgumentState();
                    boolean lookahead = false;
                    switch (yychar) {
                    case tLBRACE_ARG:
                       lookahead = true;
                    }
                      
                    if (lookahead) cmdarg.pop();
                    cmdarg.pop();
                    if (lookahead) cmdarg.push0();
                    $$ = $2;
                }

block_arg       : tAMPER arg_value {
                    $$ = new BlockPassNode(support.getPosition($2), $2);
                }
                | tAMPER {
                    if (!support.local_id(FWD_BLOCK)) support.compile_error("no anonymous block parameter");
                    $$ = new BlockPassNode(lexer.tokline, support.arg_var(FWD_BLOCK));
                }
 

opt_block_arg   : ',' block_arg {
                    $$ = $2;
                }
                | none_block_pass

// [!null]
args            : arg_value { // ArrayNode
                    int line = $1 instanceof NilImplicitNode ? lexer.getRubySourceline() : $1.getLine();
                    $$ = support.newArrayNode(line, $1);
                }
                | tSTAR arg_value { // SplatNode
                    $$ = support.newSplatNode($2);
                }
                | args ',' arg_value { // ArgsCatNode, SplatNode, ArrayNode
                    Node node = support.splat_array($1);

                    if (node != null) {
                        $$ = support.list_append(node, $3);
                    } else {
                        $$ = support.arg_append($1, $3);
                    }
                }
                | args ',' tSTAR arg_value { // ArgsCatNode, SplatNode, ArrayNode
                    Node node = null;

                    // FIXME: lose syntactical elements here (and others like this)
                    if ($4 instanceof ArrayNode &&
                        (node = support.splat_array($1)) != null) {
                        $$ = support.list_concat(node, $4);
                    } else {
                        $$ = ParserSupport.arg_concat($1, $4);
                    }
                }

mrhs_arg	: mrhs {
                    $$ = $1;
                }
		| arg_value {
                    $$ = $1;
                }


mrhs            : args ',' arg_value {
                    Node node = support.splat_array($1);

                    if (node != null) {
                        $$ = support.list_append(node, $3);
                    } else {
                        $$ = support.arg_append($1, $3);
                    }
                }
                | args ',' tSTAR arg_value {
                    Node node = null;

                    if ($4 instanceof ArrayNode &&
                        (node = support.splat_array($1)) != null) {
                        $$ = support.list_concat(node, $4);
                    } else {
                        $$ = ParserSupport.arg_concat($1, $4);
                    }
                }
                | tSTAR arg_value {
                     $$ = support.newSplatNode($2);
                }

primary         : literal
                | strings
                | xstring
                | regexp
                | words { 
                     $$ = $1; // FIXME: Why complaining without $$ = $1;
                }
                | qwords { 
                     $$ = $1; // FIXME: Why complaining without $$ = $1;
                }
                | symbols { 
                     $$ = $1; // FIXME: Why complaining without $$ = $1;
                }
                | qsymbols {
                     $$ = $1; // FIXME: Why complaining without $$ = $1;
                }
                | var_ref 
                | backref
                | tFID {
                     $$ = support.new_fcall($1);
                }
                | k_begin {
                    lexer.getCmdArgumentState().push0();
                } bodystmt k_end {
                    lexer.getCmdArgumentState().pop();
                    $$ = new BeginNode($1, support.makeNullNil($3));
                }
                | tLPAREN_ARG {
                    lexer.setState(EXPR_ENDARG);
                } rparen {
                    $$ = null; //FIXME: Should be implicit nil?
                }
                | tLPAREN_ARG stmt {
                    lexer.setState(EXPR_ENDARG); 
                } rparen {
                    $$ = $2;
                }
                | tLPAREN compstmt ')' {
                    if ($2 != null) {
                        // compstmt position includes both parens around it
                        $<Node>2.setLine($1);
                        $$ = $2;
                    } else {
                        $$ = new NilNode($1);
                    }
                }
                | primary_value tCOLON2 tCONSTANT {
                    $$ = support.new_colon2(support.getPosition($1), $1, $3);
                }
                | tCOLON3 tCONSTANT {
                    $$ = support.new_colon3(lexer.tokline, $2);
                }
                | tLBRACK aref_args ']' {
                    Integer position = support.getPosition($2);
                    if ($2 == null) {
                        $$ = new ZArrayNode(position); /* zero length array */
                    } else {
                        $$ = $2;
                    }
                }
                | tLBRACE assoc_list '}' {
                    $$ = $2;
                    $<HashNode>$.setIsLiteral();
                }
                | k_return {
                    $$ = new ReturnNode($1, NilImplicitNode.NIL);
                }
                | keyword_yield '(' call_args rparen {
                    $$ = support.new_yield($1, $3);
                }
                | keyword_yield '(' rparen {
                    $$ = new YieldNode($1, null);
                }
                | keyword_yield {
                    $$ = new YieldNode($1, null);
                }
                | keyword_defined opt_nl '(' {
                    lexer.getLexContext().in_defined = true;
                } expr rparen {
                    lexer.getLexContext().in_defined = false;
                    $$ = new DefinedNode($1, $5);
                }
                | keyword_not '(' expr rparen {
                    $$ = support.getOperatorCallNode(support.method_cond($3), lexer.BANG);
                }
                | keyword_not '(' rparen {
                    $$ = support.getOperatorCallNode(support.method_cond(NilImplicitNode.NIL), lexer.BANG);
                }
                | fcall brace_block {
                    support.frobnicate_fcall_args($1, null, $2);
                    $$ = $1;                    
                }
                | method_call
                | method_call brace_block {
                    if ($1 != null && 
                          $<BlockAcceptingNode>1.getIterNode() instanceof BlockPassNode) {
                          lexer.compile_error("Both block arg and actual block given.");
                    }
                    $$ = $<BlockAcceptingNode>1.setIterNode($2);
                    $<Node>$.setLine($1.getLine());
                }
                | lambda {
                    $$ = $1;
                }
                | k_if expr_value then compstmt if_tail k_end {
                    $$ = support.new_if($1, support.cond($2), $4, $5);
                }
                | k_unless expr_value then compstmt opt_else k_end {
                    $$ = support.new_if($1, support.cond($2), $5, $4);
                }
                | k_while expr_value_do compstmt k_end {
                    $$ = new WhileNode($1, support.cond($2), support.makeNullNil($3));
                }
                | k_until expr_value_do compstmt k_end {
                    $$ = new UntilNode($1, support.cond($2), support.makeNullNil($3));
                }
                | k_case expr_value opt_terms {
                    $$ = support.case_labels;
                    support.case_labels = support.getConfiguration().getRuntime().getNil();
                } case_body k_end {
                    $$ = support.newCaseNode($1, $2, $5);
                    support.fixpos($<Node>$, $2);
                }
                | k_case opt_terms {
                    $$ = support.case_labels;
                    support.case_labels = null;
                } case_body k_end {
                    $$ = support.newCaseNode($1, null, $4);
                }
		| k_case expr_value opt_terms p_case_body k_end {
                    $$ = support.newPatternCaseNode($1, $2, $4);
                }
                | k_for for_var keyword_in expr_value_do compstmt k_end {
                    $$ = new ForNode($1, $2, $5, $4, support.getCurrentScope(), 111);
                }
                | k_class cpath superclass {
                    LexContext ctxt = lexer.getLexContext();
                    if (ctxt.in_def) {
                        support.yyerror("class definition in method body");
                    }
                    ctxt.in_class = true;
                    support.pushLocalScope();
                } bodystmt k_end {
                    Node body = support.makeNullNil($5);

                    $$ = new ClassNode(@1.start(), $<Colon3Node>2, support.getCurrentScope(), body, $3, lexer.getRubySourceline());
                    LexContext ctxt = lexer.getLexContext();
                    support.popCurrentScope();
                    ctxt.in_class = $1.in_class;
                    ctxt.shareable_constant_value = $1.shareable_constant_value;
                }
                | k_class tLSHFT expr {
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_def = false;
                    ctxt.in_class = false;
                    support.pushLocalScope();
                } term bodystmt k_end {
                    Node body = support.makeNullNil($6);

                    $$ = new SClassNode(@1.start(), $3, support.getCurrentScope(), body, lexer.getRubySourceline());
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_def = $1.in_def;
                    ctxt.in_class = $1.in_class;
                    ctxt.shareable_constant_value = $1.shareable_constant_value;
                    support.popCurrentScope();
                }
                | k_module cpath {
                    LexContext ctxt = lexer.getLexContext();
                    if (ctxt.in_def) { 
                        support.yyerror("module definition in method body");
                    }
                    ctxt.in_class = true;
                    support.pushLocalScope();
                } bodystmt k_end {
                    Node body = support.makeNullNil($4);

                    $$ = new ModuleNode(@1.start(), $<Colon3Node>2, support.getCurrentScope(), body, lexer.getRubySourceline());
                    support.popCurrentScope();
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_class = $1.in_class;
                    ctxt.shareable_constant_value = $1.shareable_constant_value;
                }
                | defn_head f_arglist bodystmt k_end {
                    support.restore_defun($1);
                    Node body = support.reduce_nodes(support.remove_begin(support.makeNullNil($3)));
                    $$ = new DefnNode($1.line, $1.name, $2, support.getCurrentScope(), body, @4.end());
                    if (support.isNextBreak) $<DefnNode>$.setContainsNextBreak();                    support.popCurrentScope();
                }
                | defs_head f_arglist bodystmt k_end {
                    support.restore_defun($1);
                    Node body = support.reduce_nodes(support.remove_begin(support.makeNullNil($3)));
                    $$ = new DefsNode($1.line, $1.singleton, $1.name, $2, support.getCurrentScope(), body, @4.end());
                    if (support.isNextBreak) $<DefsNode>$.setContainsNextBreak();
                    support.popCurrentScope();
                }
                | keyword_break {
                    support.isNextBreak = true;
                    $$ = new BreakNode($1, NilImplicitNode.NIL);
                }
                | keyword_next {
                    support.isNextBreak = true;
                    $$ = new NextNode($1, NilImplicitNode.NIL);
                }
                | keyword_redo {
                    $$ = new RedoNode($1);
                }
                | keyword_retry {
                    $$ = new RetryNode($1);
                }

primary_value   : primary {
                    support.value_expr(lexer, $1);
                    $$ = $1;
                    if ($$ == null) $$ = NilImplicitNode.NIL;
                }

k_begin         : keyword_begin {
                    $$ = $1;
                }

k_if            : keyword_if {
                    $$ = $1;
                }

k_unless        : keyword_unless {
                    $$ = $1;
                }
 
k_while         : keyword_while {
                    $$ = $1;
                }
 
k_until         : keyword_until {
                    $$ = $1;
                }
 
k_case          : keyword_case {
                    $$ = $1;
                }
 
k_for           : keyword_for {
                    $$ = $1;
                }
 
k_class         : keyword_class {
                    $$ = (LexContext) lexer.getLexContext().clone();
                }

k_module        : keyword_module {
                    $$ = (LexContext) lexer.getLexContext().clone();  
                }

k_def           : keyword_def {
                    $$ = $1;
                    lexer.getLexContext().in_argdef = true;
                }

k_do            : keyword_do {
                    $$ = $1;
                }

k_do_block      : keyword_do_block {
                    $$ = $1;
                }

k_rescue        : keyword_rescue {
                    $$ = $1;
                }

k_ensure        : keyword_ensure {
                    $$ = $1;
                }
 
k_when          : keyword_when {
                    $$ = $1;
                }

k_else          : keyword_else {
                    $$ = $1;
                }

k_elsif         : keyword_elsif {
                    $$ = $1;
                }
 
k_end           : keyword_end {
                    $$ = $1;
                }

k_return        : keyword_return {
                    LexContext ctxt = lexer.getLexContext();
                    if (ctxt.in_class && !ctxt.in_def && !support.getCurrentScope().isBlockScope()) {
                        lexer.compile_error("Invalid return in class/module body");
                    }
                    $$ = $1;
                }

then            : term
                | keyword_then
                | term keyword_then

do              : term
                | keyword_do_cond

if_tail         : opt_else
                | k_elsif expr_value then compstmt if_tail {
                    $$ = support.new_if($1, support.cond($2), $4, $5);
                }

opt_else        : none
                | k_else compstmt {
                    $$ = $2 == null ? NilImplicitNode.NIL : $2;
                }

// [!null]
for_var         : lhs
                | mlhs {
                }

f_marg          : f_norm_arg {
                    $$ = support.assignableInCurr($1, NilImplicitNode.NIL);
                }
                | tLPAREN f_margs rparen {
                    $$ = $2;
                }

// [!null]
f_marg_list     : f_marg {
                    $$ = support.newArrayNode($1.getLine(), $1);
                }
                | f_marg_list ',' f_marg {
                    $$ = $1.add($3);
                }

f_margs         : f_marg_list {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, null, null);
                }
                | f_marg_list ',' f_rest_marg {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, $3, null);
                }
                | f_marg_list ',' f_rest_marg ',' f_marg_list {
                    $$ = new MultipleAsgnNode($1.getLine(), $1, $3, $5);
                }
                | f_rest_marg {
                    $$ = new MultipleAsgnNode(lexer.getRubySourceline(), null, $1, null);
                }
                | f_rest_marg ',' f_marg_list {
                    $$ = new MultipleAsgnNode(lexer.getRubySourceline(), null, $1, $3);
                }

f_rest_marg     : tSTAR f_norm_arg {
                    $$ = support.assignableInCurr($2, null);
                }
                | tSTAR {
                    $$ = new StarNode(lexer.getRubySourceline());
                }

f_any_kwrest    : f_kwrest
                | f_no_kwarg {
                    $$ = LexingCommon.NIL;
                }

f_eq            : {
                    lexer.getLexContext().in_argdef = false;
                } '='

 
block_args_tail : f_block_kwarg ',' f_kwrest opt_f_block_arg {
                    $$ = support.new_args_tail($1.getLine(), $1, $3, $4);
                }
                | f_block_kwarg opt_f_block_arg {
                    $$ = support.new_args_tail($1.getLine(), $1, (ByteList) null, $2);
                }
                | f_any_kwrest opt_f_block_arg {
                    $$ = support.new_args_tail(lexer.getRubySourceline(), null, $1, $2);
                }
                | f_block_arg {
                    $$ = support.new_args_tail($1.getLine(), null, (ByteList) null, $1);
                }

opt_block_args_tail : ',' block_args_tail {
                    $$ = $2;
                }
                | /* none */ {
                    $$ = support.new_args_tail(lexer.getRubySourceline(), null, (ByteList) null, null);
                }

excessed_comma  : ',' { // no need for this other than to look similar to MRI.
                    $$ = null;
                }

// [!null]
block_param     : f_arg ',' f_block_optarg ',' f_rest_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, $5, null, $6);
                }
                | f_arg ',' f_block_optarg ',' f_rest_arg ',' f_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, $5, $7, $8);
                }
                | f_arg ',' f_block_optarg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, null, null, $4);
                }
                | f_arg ',' f_block_optarg ',' f_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, null, $5, $6);
                }
                | f_arg ',' f_rest_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, null, $3, null, $4);
                }
                | f_arg excessed_comma {
                    RestArgNode rest = new UnnamedRestArgNode($1.getLine(), null, support.getCurrentScope().addVariable("*"));
                    $$ = support.new_args($1.getLine(), $1, null, rest, null, (ArgsTailHolder) null);
                }
                | f_arg ',' f_rest_arg ',' f_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, null, $3, $5, $6);
                }
                | f_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), $1, null, null, null, $2);
                }
                | f_block_optarg ',' f_rest_arg opt_block_args_tail {
                    $$ = support.new_args(support.getPosition($1), null, $1, $3, null, $4);
                }
                | f_block_optarg ',' f_rest_arg ',' f_arg opt_block_args_tail {
                    $$ = support.new_args(support.getPosition($1), null, $1, $3, $5, $6);
                }
                | f_block_optarg opt_block_args_tail {
                    $$ = support.new_args(support.getPosition($1), null, $1, null, null, $2);
                }
                | f_block_optarg ',' f_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), null, $1, null, $3, $4);
                }
                | f_rest_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), null, null, $1, null, $2);
                }
                | f_rest_arg ',' f_arg opt_block_args_tail {
                    $$ = support.new_args($1.getLine(), null, null, $1, $3, $4);
                }
                | block_args_tail {
                    $$ = support.new_args($1.getLine(), null, null, null, null, $1);
                }

opt_block_param : none {
    // was $$ = null;
                    $$ = support.new_args(lexer.getRubySourceline(), null, null, null, null, (ArgsTailHolder) null);
                }
                | block_param_def {
                    lexer.commandStart = true;
                    $$ = $1;
                }

block_param_def : '|' opt_bv_decl '|' {
                    lexer.setCurrentArg(null);
                    support.ordinalMaxNumParam();
                    lexer.getLexContext().in_argdef = false;
                    $$ = support.new_args(lexer.getRubySourceline(), null, null, null, null, (ArgsTailHolder) null);
                }
                | '|' block_param opt_bv_decl '|' {
                    lexer.setCurrentArg(null);
                    support.ordinalMaxNumParam();
                    lexer.getLexContext().in_argdef = false;
                    $$ = $2;
                }

// shadowed block variables....
opt_bv_decl     : opt_nl {
                    $$ = null;
                }
                | opt_nl ';' bv_decls opt_nl {
                    $$ = null;
                }

// ENEBO: This is confusing...
bv_decls        : bvar {
                    $$ = null;
                }
                | bv_decls ',' bvar {
                    $$ = null;
                }

bvar            : tIDENTIFIER {
                    support.new_bv($1);
                }
                | f_bad_arg {
                    $$ = null;
                }

lambda          : tLAMBDA {
                    support.pushBlockScope();
                    $$ = lexer.getLeftParenBegin();
                    lexer.setLeftParenBegin(lexer.getParenNest());
                } {
                    $$ = support.resetMaxNumParam();
                } {
                    $$ = support.numparam_push();
                } f_larglist {
                    lexer.getCmdArgumentState().push0();
                } lambda_body {
                    int max_numparam = support.restoreMaxNumParam($<Integer>3);
                    ArgsNode args = support.args_with_numbered($5, max_numparam);
                    lexer.getCmdArgumentState().pop();
                    $$ = new LambdaNode(@1.start(), args, $7, support.getCurrentScope(), lexer.getRubySourceline());
                    lexer.setLeftParenBegin($<Integer>2);
                    support.numparam_pop($<Node>4);
                    support.popCurrentScope();
                }

f_larglist      : '(' f_args opt_bv_decl ')' {
                    $$ = $2;
                    support.ordinalMaxNumParam();
                    lexer.getLexContext().in_argdef = false;
                }
                | f_args {
                    lexer.getLexContext().in_argdef = false;
                    if (!support.isArgsInfoEmpty($1)) {
                        support.ordinalMaxNumParam();
                    }
                    $$ = $1;
                }

lambda_body     : tLAMBEG compstmt '}' {
                    $$ = $2;
                }
                | keyword_do_LAMBDA bodystmt k_end {
                    $$ = $2;
                }

do_block        : k_do_block do_body k_end {
                    $$ = $2;
                }

  // JRUBY-2326 and GH #305 both end up hitting this production whereas in
  // MRI these do not.  I have never isolated the cause but I can work around
  // the individual reported problems with a few extra conditionals in this
  // first production
block_call      : command do_block {
                    // Workaround for JRUBY-2326 (MRI does not enter this production for some reason)
                    if ($1 instanceof YieldNode) {
                        lexer.compile_error("block given to yield");
                    }
                    if ($1 instanceof BlockAcceptingNode && $<BlockAcceptingNode>1.getIterNode() instanceof BlockPassNode) {
                        lexer.compile_error("Both block arg and actual block given.");
                    }
                    if ($1 instanceof NonLocalControlFlowNode) {
                        ((BlockAcceptingNode) $<NonLocalControlFlowNode>1.getValueNode()).setIterNode($2);
                    } else {
                        $<BlockAcceptingNode>1.setIterNode($2);
                    }
                    $$ = $1;
                    $<Node>$.setLine($1.getLine());
                }
                | block_call call_op2 operation2 opt_paren_args {
                    $$ = support.new_call($1, $2, $3, $4, null, @3.start());
                }
                | block_call call_op2 operation2 opt_paren_args brace_block {
                    $$ = support.new_call($1, $2, $3, $4, $5, @3.start());
                }
                | block_call call_op2 operation2 command_args do_block {
                    $$ = support.new_call($1, $2, $3, $4, $5, @3.start());
                }

// [!null]
method_call     : fcall paren_args {
                    support.frobnicate_fcall_args($1, $2, null);
                    $$ = $1;
                }
                | primary_value call_op operation2 opt_paren_args {
                    $$ = support.new_call($1, $2, $3, $4, null, @3.start());
                }
                | primary_value tCOLON2 operation2 paren_args {
                    $$ = support.new_call($1, $3, $4, null);
                }
                | primary_value tCOLON2 operation3 {
                    $$ = support.new_call($1, $3, null, null);
                }
                | primary_value call_op paren_args {
                    $$ = support.new_call($1, $2, LexingCommon.CALL, $3, null, @3.start());
                }
                | primary_value tCOLON2 paren_args {
                    $$ = support.new_call($1, LexingCommon.CALL, $3, null);
                }
                | keyword_super paren_args {
                    $$ = support.new_super($1, $2);
                }
                | keyword_super {
                    $$ = new ZSuperNode($1);
                }
                | primary_value '[' opt_call_args rbracket {
                    if ($1 instanceof SelfNode) {
                        $$ = support.new_fcall(LexingCommon.LBRACKET_RBRACKET);
                        support.frobnicate_fcall_args($<FCallNode>$, $3, null);
                    } else {
                        $$ = support.new_call($1, lexer.LBRACKET_RBRACKET, $3, null);
                    }
                }

brace_block     : '{' brace_body '}' {
                    $$ = $2;
                }
                | k_do do_body k_end {
                    $$ = $2;
                }

brace_body      : {
                    support.pushBlockScope();
                } {
                    $$ = support.resetMaxNumParam();
                } {
                    $$ = support.numparam_push();
                } opt_block_param compstmt {
                    int max_numparam = support.restoreMaxNumParam($<Integer>2);
                    ArgsNode args = support.args_with_numbered($4, max_numparam);
                    $$ = new IterNode(@1.start(), args, $5, support.getCurrentScope(), lexer.getRubySourceline());
                    support.numparam_pop($<Node>3);
                    support.popCurrentScope();
                }

do_body 	: {
                    support.pushBlockScope();
                } {
                    $$ = support.resetMaxNumParam();
                } {
                    $$ = support.numparam_push();
                    lexer.getCmdArgumentState().push0();
                } opt_block_param bodystmt {
                    int max_numparam = support.restoreMaxNumParam($<Integer>2);
                    ArgsNode args = support.args_with_numbered($4, max_numparam);
                    $$ = new IterNode(@1.start(), args, $5, support.getCurrentScope(), lexer.getRubySourceline());
                    lexer.getCmdArgumentState().pop();
                    support.numparam_pop($<Node>3);
                    support.popCurrentScope();
                }

case_args	: arg_value {
                     support.check_literal_when($1);
                     $$ = support.newArrayNode($1.getLine(), $1);
                }
                | tSTAR arg_value {
                    $$ = support.newSplatNode($2);
                }
                | case_args ',' arg_value {
                    support.check_literal_when($3);
                    $$ = support.last_arg_append($1, $3);
                }
                | case_args ',' tSTAR arg_value {
                    $$ = support.rest_arg_append($1, $4);
                }
 
case_body       : k_when case_args then compstmt cases {
                    $$ = support.newWhenNode($1, $2, $4, $5);
                }

cases           : opt_else
                | case_body

// InNode - [!null]
p_case_body     : keyword_in {
                    lexer.setState(EXPR_BEG|EXPR_LABEL);
                    lexer.commandStart = false;
                    LexContext ctxt = (LexContext) lexer.getLexContext();
                    $1 = ctxt.in_kwarg;
                    ctxt.in_kwarg = true;
                    $$ = support.push_pvtbl();
                } {
                    $$ = support.push_pktbl();
                } p_top_expr then {
                    support.pop_pktbl($<Set>3);
                    support.pop_pvtbl($<Set>2);
                    lexer.getLexContext().in_kwarg = $<Boolean>1;
                } compstmt p_cases {
                    $$ = support.newIn(@1.start(), $4, $7, $8);
                }

p_cases         : opt_else
                | p_case_body {
                    $$ = $1;
                }

p_top_expr      : p_top_expr_body
                | p_top_expr_body modifier_if expr_value {
                    $$ = support.new_if(@1.start(), $3, $1, null);
                    support.fixpos($<Node>$, $3);
                }
                | p_top_expr_body modifier_unless expr_value {
                    $$ = support.new_if(@1.start(), $3, null, $1);
                    support.fixpos($<Node>$, $3);
                }

// FindPatternNode, HashPatternNode, ArrayPatternNode + p_expr(a lot)
p_top_expr_body : p_expr
                | p_expr ',' {
                    $$ = support.new_array_pattern(@1.start(), null, $1,
                                                   support.new_array_pattern_tail(@1.start(), null, true, null, null));
                }
                | p_expr ',' p_args {
                    $$ = support.new_array_pattern(@1.start(), null, $1, $3);
                   support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_find {
                    $$ = support.new_find_pattern(null, $1);
                }
                | p_args_tail {
                    $$ = support.new_array_pattern(@1.start(), null, null, $1);
                }
                | p_kwargs {
                    $$ = support.new_hash_pattern(null, $1);
                }

p_expr          : p_as

p_as            : p_expr tASSOC p_variable {
                    $$ = new HashNode(@1.start(), new KeyValuePair($1, $3));
                }
                | p_alt

p_alt           : p_alt '|' p_expr_basic {
                    $$ = support.newOrNode($1, $3);
                }
                | p_expr_basic

p_lparen        : '(' {
                    $$ = support.push_pktbl();
                }
p_lbracket      : '[' {
                    $$ = support.push_pktbl();
                }

p_expr_basic    : p_value
                | p_variable
                | p_const p_lparen p_args rparen {
                    support.pop_pktbl($<Set>2);
                    $$ = support.new_array_pattern(@1.start(), $1, null, $3);
                    support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_const p_lparen p_find rparen {
                     support.pop_pktbl($<Set>2);
                     $$ = support.new_find_pattern($1, $3);
                     support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_const p_lparen p_kwargs rparen {
                     support.pop_pktbl($<Set>2);
                     $$ = support.new_hash_pattern($1, $3);
                     support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_const '(' rparen {
                     $$ = support.new_array_pattern(@1.start(), $1, null,
                                                    support.new_array_pattern_tail(@1.start(), null, false, null, null));
                }
                | p_const p_lbracket p_args rbracket {
                     support.pop_pktbl($<Set>2);
                     $$ = support.new_array_pattern(@1.start(), $1, null, $3);
                     support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_const p_lbracket p_find rbracket {
                    support.pop_pktbl($<Set>2);
                    $$ = support.new_find_pattern($1, $3);
                    support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_const p_lbracket p_kwargs rbracket {
                    support.pop_pktbl($<Set>2);
                    $$ = support.new_hash_pattern($1, $3);
                    support.nd_set_first_loc($<Node>$, @1.start());
                }
                | p_const '[' rbracket {
                    $$ = support.new_array_pattern(@1.start(), $1, null,
                            support.new_array_pattern_tail(@1.start(), null, false, null, null));
                }
                | tLBRACK p_args rbracket {
                    $$ = support.new_array_pattern(@1.start(), null, null, $2);
                }
                | tLBRACK p_find rbracket {
                    $$ = support.new_find_pattern(null, $2);
                }
                | tLBRACK rbracket {
                    $$ = support.new_array_pattern(@1.start(), null, null,
                            support.new_array_pattern_tail(@1.start(), null, false, null, null));
                }
                | tLBRACE {
                    $$ = support.push_pktbl();
                    LexContext ctxt = lexer.getLexContext();
                    $1 = ctxt.in_kwarg;
                    ctxt.in_kwarg = false;
                } p_kwargs rbrace {
                    support.pop_pktbl($<Set>2);
                    lexer.getLexContext().in_kwarg = $<Boolean>1;
                    $$ = support.new_hash_pattern(null, $3);
                }
                | tLBRACE rbrace {
                    $$ = support.new_hash_pattern(null, support.new_hash_pattern_tail(@1.start(), null, null));
                }
                | tLPAREN {
                    $$ = support.push_pktbl();
                 } p_expr rparen {
                    support.pop_pktbl($<Set>2);
                    $$ = $3;
                }

p_args          : p_expr {
                     ListNode preArgs = support.newArrayNode($1.getLine(), $1);
                     $$ = support.new_array_pattern_tail(@1.start(), preArgs, false, null, null);
                }
                | p_args_head {
                     $$ = support.new_array_pattern_tail(@1.start(), $1, true, null, null);
                }
                | p_args_head p_arg {
                     $$ = support.new_array_pattern_tail(@1.start(), support.list_concat($1, $2), false, null, null);
                }
                | p_args_head tSTAR tIDENTIFIER {
                     $$ = support.new_array_pattern_tail(@1.start(), $1, true, $3, null);
                }
                | p_args_head tSTAR tIDENTIFIER ',' p_args_post {
                     $$ = support.new_array_pattern_tail(@1.start(), $1, true, $3, $5);
                }
                | p_args_head tSTAR {
                     $$ = support.new_array_pattern_tail(@1.start(), $1, true, null, null);
                }
                | p_args_head tSTAR ',' p_args_post {
                     $$ = support.new_array_pattern_tail(@1.start(), $1, true, null, $4);
                }
                | p_args_tail {
                     $$ = $1;
                }

// ListNode - [!null]
p_args_head     : p_arg ',' {
                     $$ = $1;
                }
                | p_args_head p_arg ',' {
                     $$ = support.list_concat($1, $2);
                }

p_args_tail     : p_rest {
                     $$ = support.new_array_pattern_tail(@1.start(), null, true, $1, null);
                }
                | p_rest ',' p_args_post {
                     $$ = support.new_array_pattern_tail(@1.start(), null, true, $1, $3);
                }

// FindPatternNode - [!null]
p_find          : p_rest ',' p_args_post ',' p_rest {
                     $$ = support.new_find_pattern_tail(@1.start(), $1, $3, $5);
                     support.warn_experimental(@1.start(), "Find pattern is experimental, and the behavior may change in future versions of Ruby!");
                }

// ByteList
p_rest          : tSTAR tIDENTIFIER {
                    $$ = $2;
                }
                | tSTAR {
                    $$ = null;
                }

// ListNode - [!null]
p_args_post     : p_arg
                | p_args_post ',' p_arg {
                    $$ = support.list_concat($1, $3);
                }

// ListNode - [!null]
p_arg           : p_expr {
                    $$ = support.newArrayNode($1.getLine(), $1);
                }

// HashPatternNode - [!null]
p_kwargs        : p_kwarg ',' p_any_kwrest {
                    $$ = support.new_hash_pattern_tail(@1.start(), $1, $3);
                }
		| p_kwarg {
                    $$ = support.new_hash_pattern_tail(@1.start(), $1, null);
                }
                | p_kwarg ',' {
                    $$ = support.new_hash_pattern_tail(@1.start(), $1, null);
                }
                | p_any_kwrest {
                    $$ = support.new_hash_pattern_tail(@1.start(), null, $1);
                }

// HashNode - [!null]
p_kwarg         : p_kw {
                    $$ = new HashNode(@1.start(), $1);
                }
                | p_kwarg ',' p_kw {
                    $1.add($3);
                    $$ = $1;
                }

// KeyValuePair - [!null]
p_kw            : p_kw_label p_expr {
                    support.error_duplicate_pattern_key($1);

                    Node label = support.asSymbol(@1.start(), $1);

                    $$ = new KeyValuePair(label, $2);
                }
                | p_kw_label {
                    support.error_duplicate_pattern_key($1);
                    if ($1 != null && !support.is_local_id($1)) {
                        support.yyerror("key must be valid as local variables");
                    }
                    support.error_duplicate_pattern_variable($1);

                    Node label = support.asSymbol(@1.start(), $1);
                    $$ = new KeyValuePair(label, support.assignableLabelOrIdentifier($1, null));
                }

// ByteList
p_kw_label      : tLABEL
                | tSTRING_BEG string_contents tLABEL_END {
                    if ($2 == null || $2 instanceof StrNode) {
                        $$ = $<StrNode>2.getValue();
                    } else {
                        support.yyerror("symbol literal with interpolation is not allowed");
                        $$ = null;
                    }
                }

p_kwrest        : kwrest_mark tIDENTIFIER {
                    $$ = $2;
                }
                | kwrest_mark {
                    $$ = null;
                }

p_kwnorest      : kwrest_mark keyword_nil {
                    $$ = null;
                }

p_any_kwrest    : p_kwrest
                | p_kwnorest {
                    $$ = support.KWNOREST;
                }

p_value         : p_primitive
                | p_primitive tDOT2 p_primitive {
                    support.value_expr(lexer, $1);
                    support.value_expr(lexer, $3);
                    boolean isLiteral = $1 instanceof FixnumNode && $3 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), support.makeNullNil($1), support.makeNullNil($3), false, isLiteral);
                }
                | p_primitive tDOT3 p_primitive {
                    support.value_expr(lexer, $1);
                    support.value_expr(lexer, $3);
                    boolean isLiteral = $1 instanceof FixnumNode && $3 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), support.makeNullNil($1), support.makeNullNil($3), true, isLiteral);
                }
                | p_primitive tDOT2 {
                    support.value_expr(lexer, $1);
                    boolean isLiteral = $1 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), support.makeNullNil($1), NilImplicitNode.NIL, false, isLiteral);
                }
                | p_primitive tDOT3 {
                    support.value_expr(lexer, $1);
                    boolean isLiteral = $1 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), support.makeNullNil($1), NilImplicitNode.NIL, true, isLiteral);
                }
                | p_var_ref
                | p_expr_ref
                | p_const
                | tBDOT2 p_primitive {
                    support.value_expr(lexer, $2);
                    boolean isLiteral = $2 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), NilImplicitNode.NIL, support.makeNullNil($2), false, isLiteral);
                }
                | tBDOT3 p_primitive {
                    support.value_expr(lexer, $2);
                    boolean isLiteral = $2 instanceof FixnumNode;
                    $$ = new DotNode(@1.start(), NilImplicitNode.NIL, support.makeNullNil($2), true, isLiteral);
                }

p_primitive     : literal
                | strings
                | xstring
                | regexp
                | words {
                    $$ = $1;
                }
                | qwords {
                    $$ = $1;
                }
                | symbols {
                    $$ = $1;
                }
                | qsymbols {
                    $$ = $1;
                } 
                | /*mri:keyword_variable*/ keyword_nil {
                    $$ = new NilNode(lexer.tokline);
                }
                | keyword_self {
                    $$ = new SelfNode(lexer.tokline);
                }
                | keyword_true { 
                    $$ = new TrueNode(lexer.tokline);
                }
                | keyword_false {
                    $$ = new FalseNode(lexer.tokline);
                }
                | keyword__FILE__ {
                    $$ = new FileNode(lexer.tokline, new ByteList(lexer.getFile().getBytes(),
                    support.getConfiguration().getRuntime().getEncodingService().getLocaleEncoding()));
                }
                | keyword__LINE__ {
                    $$ = new FixnumNode(lexer.tokline, lexer.tokline+1);
                }
                | keyword__ENCODING__ {
                    $$ = new EncodingNode(lexer.tokline, lexer.getEncoding());
                } /*mri:keyword_variable*/
                | lambda {
                    $$ = $1;
                } 

p_variable      : tIDENTIFIER {
                    support.error_duplicate_pattern_variable($1);
                    $$ = support.assignableInCurr($1, null);
                }

p_var_ref       : '^' tIDENTIFIER {
                    Node n = support.gettable($2);
                    if (!(n instanceof LocalVarNode || n instanceof DVarNode)) {
                        support.compile_error("" + $2 + ": no such local variable");
                    }
                    $$ = n;
                }
                | '^' nonlocal_var {
                    $$ = support.gettable($2);
                    if ($$ == null) $$ = new BeginNode(lexer.tokline, NilImplicitNode.NIL);

                }

p_expr_ref      : '^' tLPAREN expr_value ')' {
                    $$ = new BeginNode(lexer.tokline, $3);
                }

p_const         : tCOLON3 cname {
                    $$ = support.new_colon3(lexer.tokline, $2);
                }
                | p_const tCOLON2 cname {
                    $$ = support.new_colon2(lexer.tokline, $1, $3);
                }
                | tCONSTANT {
                    $$ = new ConstNode(lexer.tokline, support.symbolID($1));
                }

opt_rescue      : k_rescue exc_list exc_var then compstmt opt_rescue {
                    Node node;
                    if ($3 != null) {
                        node = support.appendToBlock(node_assign($3, new GlobalVarNode($1, support.symbolID(lexer.DOLLAR_BANG))), support.makeNullNil($5));
                        if ($5 != null) {
                            node.setLine($1);
                        }
                    } else {
                        node = $5;
                    }
                    Node body = support.makeNullNil(node);
                    $$ = new RescueBodyNode($1, $2, body, $6);
                }
                | none {
                    $$ = null; 
                }

exc_list        : arg_value {
                    $$ = support.newArrayNode($1.getLine(), $1);
                }
                | mrhs {
                    $$ = support.splat_array($1);
                    if ($$ == null) $$ = $1; // ArgsCat or ArgsPush
                }
                | none

exc_var         : tASSOC lhs {
                    $$ = $2;
                }
                | none

opt_ensure      : k_ensure compstmt {
                    $$ = $2;
                }
                | none

literal         : numeric {
                    $$ = $1;
                }
                | symbol {
                    $$ = $1;
                }


strings         : string {
                    $$ = $1 instanceof EvStrNode ? new DStrNode($1.getLine(), lexer.getEncoding()).add($1) : $1;
                    /*
                    NODE *node = $1;
                    if (!node) {
                        node = NEW_STR(STR_NEW0());
                    } else {
                        node = evstr2dstr(node);
                    }
                    $$ = node;
                    */
                }

// [!null]
string          : tCHAR {
                    $$ = $1;
                }
                | string1 {
                    $$ = $1;
                }
                | string string1 {
                    $$ = support.literal_concat($1, $2);
                }

string1         : tSTRING_BEG string_contents tSTRING_END {
                    lexer.heredoc_dedent($2);
		    lexer.setHeredocIndent(0);
                    $$ = $2;
                }

xstring         : tXSTRING_BEG xstring_contents tSTRING_END {
                    int line = support.getPosition($2);

                    lexer.heredoc_dedent($2);
		    lexer.setHeredocIndent(0);

                    if ($2 == null) {
                        $$ = new XStrNode(line, null, StringSupport.CR_7BIT);
                    } else if ($2 instanceof StrNode) {
                        $$ = new XStrNode(line, (ByteList) $<StrNode>2.getValue().clone(), $<StrNode>2.getCodeRange());
                    } else if ($2 instanceof DStrNode) {
                        $$ = new DXStrNode(line, $<DStrNode>2);

                        $<Node>$.setLine(line);
                    } else {
                        $$ = new DXStrNode(line).add($2);
                    }
                }

regexp          : tREGEXP_BEG regexp_contents tREGEXP_END {
                    $$ = support.newRegexpNode(support.getPosition($2), $2, (RegexpNode) $3);
                }

// [!null] - ListNode
words           : tWORDS_BEG ' ' word_list tSTRING_END {
                    $$ = $3;
                }

// [!null] - ListNode
word_list       : /* none */ {
                     $$ = new ArrayNode(lexer.getRubySourceline());
                }
                | word_list word ' ' {
                     $$ = $1.add($2 instanceof EvStrNode ? new DStrNode($1.getLine(), lexer.getEncoding()).add($2) : $2);
                }

// [!null] - StrNode, ListNode (usually D*)
word            : string_content {
                     $$ = $<Node>1;
                }
                | word string_content {
                     $$ = support.literal_concat($1, $<Node>2);
                }

symbols         : tSYMBOLS_BEG ' ' symbol_list tSTRING_END {
                    $$ = $3;
                }

symbol_list     : /* none */ {
                    $$ = new ArrayNode(lexer.getRubySourceline());
                }
                | symbol_list word ' ' {
                    $$ = $1.add($2 instanceof EvStrNode ? new DSymbolNode($1.getLine()).add($2) : support.asSymbol($1.getLine(), $2));
                }

// [!null] - ListNode
qwords          : tQWORDS_BEG ' ' qword_list tSTRING_END {
                    $$ = $3;
                }

// [!null] - ListNode
qsymbols        : tQSYMBOLS_BEG ' ' qsym_list tSTRING_END {
                    $$ = $3;
                }


// [!null] - ListNode
qword_list      : /* none */ {
                    $$ = new ArrayNode(lexer.getRubySourceline());
                }
                | qword_list tSTRING_CONTENT ' ' {
                    $$ = $1.add($2);
                }

// [!null] - ListNode
qsym_list      : /* none */ {
                    $$ = new ArrayNode(lexer.getRubySourceline());
                }
                | qsym_list tSTRING_CONTENT ' ' {
                    $$ = $1.add(support.asSymbol($1.getLine(), $2));
                }

string_contents : /* none */ {
                    ByteList aChar = ByteList.create("");
                    aChar.setEncoding(lexer.getEncoding());
                    $$ = lexer.createStr(aChar, 0);
                }
                | string_contents string_content {
                    $$ = support.literal_concat($1, $<Node>2);
                }

xstring_contents: /* none */ {
                    ByteList aChar = ByteList.create("");
                    aChar.setEncoding(lexer.getEncoding());
                    $$ = lexer.createStr(aChar, 0);
                }
                | xstring_contents string_content {
                    $$ = support.literal_concat($1, $<Node>2);
                }

regexp_contents: /* none */ {
                    $$ = null;
                }
                | regexp_contents string_content {
    // FIXME: mri is different here.
                    $$ = support.literal_concat($1, $<Node>2);
                }

// [!null] - StrNode, EvStrNode
string_content  : tSTRING_CONTENT {
                    $$ = $1;
                }
                | tSTRING_DVAR {
                    $$ = lexer.getStrTerm();
                    lexer.setStrTerm(null);
                    lexer.setState(EXPR_BEG);
                } string_dvar {
                    lexer.setStrTerm($<StrTerm>2);
                    $$ = new EvStrNode(support.getPosition($3), $3);
                }
                | tSTRING_DBEG {
                   $$ = lexer.getStrTerm();
                   lexer.setStrTerm(null);
                   lexer.getConditionState().push0();
                   lexer.getCmdArgumentState().push0();
                } {
                   $$ = lexer.getState();
                   lexer.setState(EXPR_BEG);
                } {
                   $$ = lexer.getBraceNest();
                   lexer.setBraceNest(0);
                } {
                   $$ = lexer.getHeredocIndent();
                   lexer.setHeredocIndent(0);
                } compstmt tSTRING_DEND {
                   lexer.getConditionState().pop();
                   lexer.getCmdArgumentState().pop();
                   lexer.setStrTerm($<StrTerm>2);
                   lexer.setState($<Integer>3);
                   lexer.setBraceNest($<Integer>4);
                   lexer.setHeredocIndent($<Integer>5);
                   lexer.setHeredocLineIndent(-1);

                   if ($6 != null) $6.unsetNewline();
                   $$ = support.newEvStrNode(support.getPosition($6), $6);
                }

string_dvar     : tGVAR {
                     $$ = new GlobalVarNode(lexer.getRubySourceline(), support.symbolID($1));
                }
                | tIVAR {
                     $$ = new InstVarNode(lexer.getRubySourceline(), support.symbolID($1));
                }
                | tCVAR {
                     $$ = new ClassVarNode(lexer.getRubySourceline(), support.symbolID($1));
                }
                | backref

// [!null] - SymbolNode, DSymbolNode
symbol          : ssym
                | dsym

// [!null] - SymbolNode:symbol  
ssym            : tSYMBEG sym {
                     lexer.setState(EXPR_END);
                     $$ = support.asSymbol(lexer.getRubySourceline(), $2);
                }

// [!null] - ByteList:symbol
sym             : fname
                | tIVAR {
                    $$ = $1;
                }
                | tGVAR {
                    $$ = $1;
                }
                | tCVAR {
                    $$ = $1;
                }

// [!null] - SymbolNode, DSymbolNode 
dsym            : tSYMBEG string_contents tSTRING_END {
                     lexer.setState(EXPR_END);

                     // DStrNode: :"some text #{some expression}"
                     // StrNode: :"some text"
                     // EvStrNode :"#{some expression}"
                     // Ruby 1.9 allows empty strings as symbols
                     if ($2 == null) {
                         $$ = support.asSymbol(lexer.getRubySourceline(), new ByteList(new byte[] {}));
                     } else if ($2 instanceof DStrNode) {
                         $$ = new DSymbolNode($2.getLine(), $<DStrNode>2);
                     } else if ($2 instanceof StrNode) {
                         $$ = support.asSymbol($2.getLine(), $2);
                     } else {
                         $$ = new DSymbolNode($2.getLine());
                         $<DSymbolNode>$.add($2);
                     }
                }

numeric         : simple_numeric {
                    $$ = $1;  
                }
                | tUMINUS_NUM simple_numeric %prec tLOWEST {
                     $$ = support.negateNumeric($2);
                }

nonlocal_var    : tIVAR
                | tGVAR
                | tCVAR

simple_numeric  : tINTEGER {
                    $$ = $1;
                }
                | tFLOAT {
                     $$ = $1;
                }
                | tRATIONAL {
                     $$ = $1;
                }
                | tIMAGINARY {
                     $$ = $1;
                } 

// [!null]
var_ref         : /*mri:user_variable*/ tIDENTIFIER {
                    $$ = support.declareIdentifier($1);
                }
                | tIVAR {
                    $$ = new InstVarNode(lexer.tokline, support.symbolID($1));
                }
                | tGVAR {
                    $$ = new GlobalVarNode(lexer.tokline, support.symbolID($1));
                }
                | tCONSTANT {
                    $$ = new ConstNode(lexer.tokline, support.symbolID($1));
                }
                | tCVAR {
                    $$ = new ClassVarNode(lexer.tokline, support.symbolID($1));
                } /*mri:user_variable*/
                | /*mri:keyword_variable*/ keyword_nil { 
                    $$ = new NilNode(lexer.tokline);
                }
                | keyword_self {
                    $$ = new SelfNode(lexer.tokline);
                }
                | keyword_true { 
                    $$ = new TrueNode(lexer.tokline);
                }
                | keyword_false {
                    $$ = new FalseNode(lexer.tokline);
                }
                | keyword__FILE__ {
                    $$ = new FileNode(lexer.tokline, new ByteList(lexer.getFile().getBytes(),
                    support.getConfiguration().getRuntime().getEncodingService().getLocaleEncoding()));
                }
                | keyword__LINE__ {
                    $$ = new FixnumNode(lexer.tokline, lexer.tokline+1);
                }
                | keyword__ENCODING__ {
                    $$ = new EncodingNode(lexer.tokline, lexer.getEncoding());
                } /*mri:keyword_variable*/

// [!null]
var_lhs         : /*mri:user_variable*/ tIDENTIFIER {
                    $$ = support.assignableLabelOrIdentifier($1, null);
                }
                | tIVAR {
                    $$ = new InstAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                }
                | tGVAR {
                    $$ = new GlobalAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                }
                | tCONSTANT {
                    if (lexer.getLexContext().in_def) support.compile_error("dynamic constant assignment");

                    $$ = new ConstDeclNode(lexer.tokline, support.symbolID($1), null, NilImplicitNode.NIL);
                }
                | tCVAR {
                    $$ = new ClassVarAsgnNode(lexer.tokline, support.symbolID($1), NilImplicitNode.NIL);
                } /*mri:user_variable*/
                | /*mri:keyword_variable*/ keyword_nil {
                    support.compile_error("Can't assign to nil");
                    $$ = null;
                }
                | keyword_self {
                    support.compile_error("Can't change the value of self");
                    $$ = null;
                }
                | keyword_true {
                    support.compile_error("Can't assign to true");
                    $$ = null;
                }
                | keyword_false {
                    support.compile_error("Can't assign to false");
                    $$ = null;
                }
                | keyword__FILE__ {
                    support.compile_error("Can't assign to __FILE__");
                    $$ = null;
                }
                | keyword__LINE__ {
                    support.compile_error("Can't assign to __LINE__");
                    $$ = null;
                }
                | keyword__ENCODING__ {
                    support.compile_error("Can't assign to __ENCODING__");
                    $$ = null;
                } /*mri:keyword_variable*/

// [!null]
backref         : tNTH_REF {
                    $$ = $1;
                }
                | tBACK_REF {
                    $$ = $1;
                }

superclass      : '<' {
                   lexer.setState(EXPR_BEG);
                   lexer.commandStart = true;
                } expr_value term {
                    $$ = $3;
                }
                | /* none */ {
                   $$ = null;
                }

f_opt_paren_args: f_paren_args
                | none {
                    lexer.getLexContext().in_argdef = false;
                    $$ = support.new_args(lexer.tokline, null, null, null, null, 
                                          support.new_args_tail(lexer.getRubySourceline(), null, (ByteList) null, null));
                }

f_paren_args    : '(' f_args rparen {
                    $$ = $2;
                    lexer.setState(EXPR_BEG);
                    lexer.getLexContext().in_argdef = false;
                    lexer.commandStart = true;
                }

// [!null]
f_arglist       : f_paren_args {
                   $$ = $1;
                }
                | {
                    LexContext ctxt = lexer.getLexContext();
                    $$ = ctxt.in_kwarg;
                    ctxt.in_kwarg = true;
                    ctxt.in_argdef = true;
                    lexer.setState(lexer.getState() | EXPR_LABEL);
                } f_args term {
                    LexContext ctxt = lexer.getLexContext();
                    ctxt.in_kwarg = $<Boolean>1;
                    ctxt.in_argdef = false;
                    $$ = $2;
                    lexer.setState(EXPR_BEG);
                    lexer.commandStart = true;
                }


args_tail       : f_kwarg ',' f_kwrest opt_f_block_arg {
                    $$ = support.new_args_tail($1.getLine(), $1, $3, $4);
                }
                | f_kwarg opt_f_block_arg {
                    $$ = support.new_args_tail($1.getLine(), $1, (ByteList) null, $2);
                }
                | f_any_kwrest opt_f_block_arg {
                    $$ = support.new_args_tail(lexer.getRubySourceline(), null, $1, $2);
                }
                | f_block_arg {
                    $$ = support.new_args_tail($1.getLine(), null, (ByteList) null, $1);
                }
                | args_forward {
                    support.add_forwarding_args();
                    $$ = support.new_args_tail(lexer.tokline, null, $1, new BlockArgNode(support.arg_var(FWD_BLOCK)));
                }

opt_args_tail   : ',' args_tail {
                    $$ = $2;
                }
                | /* none */ {
                    $$ = support.new_args_tail(lexer.getRubySourceline(), null, (ByteList) null, null);
                }

// [!null]
f_args          : f_arg ',' f_optarg ',' f_rest_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, $5, null, $6);
                }
                | f_arg ',' f_optarg ',' f_rest_arg ',' f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, $5, $7, $8);
                }
                | f_arg ',' f_optarg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, null, null, $4);
                }
                | f_arg ',' f_optarg ',' f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, $3, null, $5, $6);
                }
                | f_arg ',' f_rest_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, null, $3, null, $4);
                }
                | f_arg ',' f_rest_arg ',' f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, null, $3, $5, $6);
                }
                | f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), $1, null, null, null, $2);
                }
                | f_optarg ',' f_rest_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), null, $1, $3, null, $4);
                }
                | f_optarg ',' f_rest_arg ',' f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), null, $1, $3, $5, $6);
                }
                | f_optarg opt_args_tail {
                    $$ = support.new_args($1.getLine(), null, $1, null, null, $2);
                }
                | f_optarg ',' f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), null, $1, null, $3, $4);
                }
                | f_rest_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), null, null, $1, null, $2);
                }
                | f_rest_arg ',' f_arg opt_args_tail {
                    $$ = support.new_args($1.getLine(), null, null, $1, $3, $4);
                }
                | args_tail {
                    $$ = support.new_args($1.getLine(), null, null, null, null, $1);
                }
                | /* none */ {
                    $$ = support.new_args(lexer.getRubySourceline(), null, null, null, null, (ArgsTailHolder) null);
                }

// [!null] - ByteList
args_forward    : tBDOT3 {
                    $$ = FWD_KWREST;
                }

f_bad_arg       : tCONSTANT {
                    support.yyerror("formal argument cannot be a constant");
                }
                | tIVAR {
                    support.yyerror("formal argument cannot be an instance variable");
                }
                | tGVAR {
                    support.yyerror("formal argument cannot be a global variable");
                }
                | tCVAR {
                    support.yyerror("formal argument cannot be a class variable");
                }

// ByteList:f_norm_arg [!null]
f_norm_arg      : f_bad_arg {
                    $$ = $1; // Not really reached
                }
                | tIDENTIFIER {
                    $$ = support.formal_argument($1);
                    support.ordinalMaxNumParam();
                }

f_arg_asgn      : f_norm_arg {
                    lexer.setCurrentArg($1);
                    $$ = support.arg_var($1);
                }

f_arg_item      : f_arg_asgn {
                    lexer.setCurrentArg(null);
                    $$ = $1;
                }
                | tLPAREN f_margs rparen {
                    $$ = $2;
                }

// [!null]
f_arg           : f_arg_item {
                    $$ = new ArrayNode(lexer.getRubySourceline(), $1);
                }
                | f_arg ',' f_arg_item {
                    $1.add($3);
                    $$ = $1;
                }

f_label 	: tLABEL {
                    support.arg_var(support.formal_argument($1));
                    lexer.setCurrentArg($1);
                    support.ordinalMaxNumParam();
                    lexer.getLexContext().in_argdef = false;
                    $$ = $1;
                }

// KeywordArgNode - [!null]
f_kw            : f_label arg_value {
                    lexer.setCurrentArg(null);
                    lexer.getLexContext().in_argdef = true;
                    $$ = new KeywordArgNode($2.getLine(), support.assignableKeyword($1, $2));
                }
                | f_label {
                    lexer.setCurrentArg(null);
                    lexer.getLexContext().in_argdef = true;
                    $$ = new KeywordArgNode(lexer.getRubySourceline(), support.assignableKeyword($1, new RequiredKeywordArgumentValueNode()));
                }

f_block_kw      : f_label primary_value {
                    lexer.getLexContext().in_argdef = true;
                    $$ = new KeywordArgNode(support.getPosition($2), support.assignableKeyword($1, $2));
                }
                | f_label {
                    lexer.getLexContext().in_argdef = true;
                    $$ = new KeywordArgNode(lexer.getRubySourceline(), support.assignableKeyword($1, new RequiredKeywordArgumentValueNode()));
                }
             

f_block_kwarg   : f_block_kw {
                    $$ = new ArrayNode($1.getLine(), $1);
                }
                | f_block_kwarg ',' f_block_kw {
                    $$ = $1.add($3);
                }

// ListNode - [!null]
f_kwarg         : f_kw {
                    $$ = new ArrayNode($1.getLine(), $1);
                }
                | f_kwarg ',' f_kw {
                    $$ = $1.add($3);
                }

kwrest_mark     : tPOW {
                    $$ = $1;
                }
                | tDSTAR {
                    $$ = $1;
                }

f_no_kwarg      : kwrest_mark keyword_nil {
                    $$ = $2;
                }

f_kwrest        : kwrest_mark tIDENTIFIER {
                    support.shadowing_lvar($2);
                    $$ = $2;
                }
                | kwrest_mark {
                    $$ = support.INTERNAL_ID;
                }

f_opt           : f_arg_asgn f_eq arg_value {
                    lexer.setCurrentArg(null);
                    lexer.getLexContext().in_argdef = true;
                    $$ = new OptArgNode(support.getPosition($3), support.assignableLabelOrIdentifier($1.getName().getBytes(), $3));
                }

f_block_opt     : f_arg_asgn f_eq primary_value {
                    lexer.getLexContext().in_argdef = true;
                    lexer.setCurrentArg(null);
                    $$ = new OptArgNode(support.getPosition($3), support.assignableLabelOrIdentifier($1.getName().getBytes(), $3));
                }

f_block_optarg  : f_block_opt {
                    $$ = new BlockNode($1.getLine()).add($1);
                }
                | f_block_optarg ',' f_block_opt {
                    $$ = support.appendToBlock($1, $3);
                }

f_optarg        : f_opt {
                    $$ = new BlockNode($1.getLine()).add($1);
                }
                | f_optarg ',' f_opt {
                    $$ = support.appendToBlock($1, $3);
                }

restarg_mark    : '*' {
                    $$ = STAR;
                }
                | tSTAR {
                    $$ = $1;
                }

// [!null]
f_rest_arg      : restarg_mark tIDENTIFIER {
                    if (!support.is_local_id($2)) {
                        support.yyerror("rest argument must be local variable");
                    }
                    
                    $$ = new RestArgNode(support.arg_var(support.shadowing_lvar($2)));
                }
                | restarg_mark {
  // FIXME: bytelist_love: somewhat silly to remake the empty bytelist over and over but this type should change (using null vs "" is a strange distinction).
  $$ = new UnnamedRestArgNode(lexer.getRubySourceline(), support.symbolID(CommonByteLists.EMPTY), support.getCurrentScope().addVariable("*"));
                }

// [!null]
blkarg_mark     : '&' {
                    $$ = AMPERSAND;
                }
                | tAMPER {
                    $$ = $1;
                }

// f_block_arg - Block argument def for function (foo(&block)) [!null]
f_block_arg     : blkarg_mark tIDENTIFIER {
                    if (!support.is_local_id($2)) {
                        support.yyerror("block argument must be local variable");
                    }
                    
                    $$ = new BlockArgNode(support.arg_var(support.shadowing_lvar($2)));
                }
                | blkarg_mark {
                    $$ = new BlockArgNode(support.arg_var(support.shadowing_lvar(FWD_BLOCK)));
                }


opt_f_block_arg : ',' f_block_arg {
                    $$ = $2;
                }
                | /* none */ {
                    $$ = null;
                }

singleton       : var_ref {
                    support.value_expr(lexer, $1);
                    $$ = $1;
                }
                | '(' {
                    lexer.setState(EXPR_BEG);
                } expr rparen {
                    if ($3 == null) {
                        support.yyerror("can't define single method for ().");
                    } else if ($3 instanceof ILiteralNode) {
                        support.yyerror("can't define single method for literals.");
                    }
                    support.value_expr(lexer, $3);
                    $$ = $3;
                }

// HashNode: [!null]
assoc_list      : none {
                    $$ = new HashNode(lexer.getRubySourceline());
                }
                | assocs trailer {
                    $$ = support.remove_duplicate_keys($1);
                }

// [!null]
assocs          : assoc {
                    $$ = new HashNode(lexer.getRubySourceline(), $1);
                }
                | assocs ',' assoc {
                    $$ = $1.add($3);
                }

// Cons: [!null]
assoc           : arg_value tASSOC arg_value {
                    $$ = support.createKeyValue($1, $3);
                }
                | tLABEL arg_value {
                    Node label = support.asSymbol(support.getPosition($2), $1);
                    $$ = support.createKeyValue(label, $2);
                }
                | tLABEL {
                    Node label = support.asSymbol(lexer.tokline, $1);
                    Node var = support.gettable($1);
                    if (var == null) var = new BeginNode(lexer.tokline, NilImplicitNode.NIL);
                    $$ = support.createKeyValue(label, var);
                }
 
                | tSTRING_BEG string_contents tLABEL_END arg_value {
                    if ($2 instanceof StrNode) {
                        DStrNode dnode = new DStrNode(support.getPosition($2), lexer.getEncoding());
                        dnode.add($2);
                        $$ = support.createKeyValue(new DSymbolNode(support.getPosition($2), dnode), $4);
                    } else if ($2 instanceof DStrNode) {
                        $$ = support.createKeyValue(new DSymbolNode(support.getPosition($2), $<DStrNode>2), $4);
                    } else {
                        support.compile_error("Uknown type for assoc in strings: " + $2);
                    }

                }
                | tDSTAR arg_value {
                    $$ = support.createKeyValue(null, $2);
                }

operation       : tIDENTIFIER {
                    $$ = $1;
                }
                | tCONSTANT {
                    $$ = $1;
                }
                | tFID {
                    $$ = $1;
                }
operation2      : tIDENTIFIER  {
                    $$ = $1;
                }
                | tCONSTANT {
                    $$ = $1;
                }
                | tFID {
                    $$ = $1;
                }
                | op {
                    $$ = $1;
                }
                    
operation3      : tIDENTIFIER {
                    $$ = $1;
                }
                | tFID {
                    $$ = $1;
                }
                | op {
                    $$ = $1;
                }
                    
dot_or_colon    : '.' {
                    $$ = DOT;
                }
                | tCOLON2 {
                    $$ = $1;
                }

call_op 	: '.' {
                    $$ = DOT;
                }
                | tANDDOT {
                    $$ = $1;
                }

call_op2        : call_op
                | tCOLON2 {
                    $$ = $1;
                }
  
opt_terms       : /* none */ | terms
opt_nl          : /* none */ | '\n'
rparen          : opt_nl ')' {
                    $$ = RPAREN;
                }
rbracket        : opt_nl ']' {
                    $$ = RBRACKET;
                }
rbrace          : opt_nl '}' {
                    $$ = RCURLY;
                }
trailer         : /* none */ | '\n' | ','

term            : ';'
                | '\n'

terms           : term
                | terms ';'

none            : /* none */ {
                      $$ = null;
                }

none_block_pass : /* none */ {  
                  $$ = null;
                }

%%

    /** The parse method use an lexer stream and parse it to an AST node 
     * structure
     */
    public RubyParserResult parse(ParserConfiguration configuration) throws IOException {
        support.reset();
        support.setConfiguration(configuration);
        support.setResult(new RubyParserResult());
        
        yyparse(lexer, configuration.isDebug() ? new YYDebug() : null);
        
        return support.getResult();
    }
}
