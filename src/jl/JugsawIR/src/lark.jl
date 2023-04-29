const jp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="object")
parse5(str::String) = Lerche.parse(jp, str)

function parse5(demo, str::String)
    tree = parse5(str)
    fromtree(tree, demo)
end

#const jtp = Lark(read(joinpath(@__DIR__, "jugsawir.lark"), String),parser="lalr",lexer="contextual", start="type")

# mutable struct JugsawTransformer <: Transformer
#     const mod::Module
#     const demo
#     currentobj
# end

# @inline_rule object(jt::JugsawTransformer, item) = item
# @inline_rule type(jt::JugsawTransformer, item) = item
# @inline_rule typewithparams(jt::JugsawTransformer, item) = str2type(jt.mod, item)
# @inline_rule typewithoutparams(jt::JugsawTransformer, item) = str2type(jt.mod, item)
# @inline typename(jt::JugsawTransformer, items) = (".".join(items[1:end-1]), items[-1])
# @inline_rule funcname(jt::JugsawTransformer, modname, funcname) = (modname, funcname)
# @inline_rule var(jt::JugsawTransformer, item) = String(item)
# @inline_rule typeparam(jt::JugsawTransformer, item) = item
# # primitive types
# #@inline_rule symbol(jt::JugsawTransformer, items) = Symbol(items[0])
# #@inline_rule tuple(jt::JugsawTransformer, items)
#         #if items[0] == None
#             #return ()
#         #return tuple(items)
# @inline genericobj(jt::JugsawTransformer, items) = begin
#     d = dict(items)
#     values = d["values"]
#     fields = fieldnames(jt.demo)
#     # fallback
#     vals = Any[isdefined(jt.demo, fn) ? fromdict(m, T.types[i], values[i]) for i=1:length(fields)]
#     #generic_customized_parsetype(m, T, Tuple(values))
#     Core.eval(m, Expr(:new, T, Any[:($vals[$i]) for i=1:length(vals)]...))
# end
# @inline_rule pair(jt::JugsawTransformer, a, b) = a => b
# @inline_rule list(jt::JugsawTransformer, item) = item
# @inline_rule string(jt::JugsawTransformer, item) = item[2:end-1]
# @inline_rule float(jt::JugsawTransformer, item) = Float64(item)
# @inline_rule integer(jt::JugsawTransformer, item) = Int64(item)
# @inline_rule bool(jt::JugsawTransformer, item) = Bool(item)
# @inline_rule true(jt::JugsawTransformer, items) = true
# @inline_rule false(jt::JugsawTransformer, items) = false
# @inline_rule null(jt::JugsawTransformer, items) = nothing

# # string as type and type to string
# function str2type(m::Module, str::String)
#     ex = Meta.parse(str)
#     @match ex begin
#         :($mod.$name{$(paras...)}) || :($mod.$name) ||
#             ::Symbol || :($name{$(paras...)}) => Core.eval(m, ex)
#         _ => Any
#     end
# end