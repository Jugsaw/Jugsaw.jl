# Please check Jugsaw documentation: TBD
using Jugsaw

const modules = Dict{Symbol, Module}()

"""
Evaluate a Julia expression just like a Julia REPL.

To avoid context conflict, you can feed the same module name.
"""
function eval(ex::String; module_name::Symbol)
    if haskey(modules, module_name)
        mod = modules[module_name]
    else
        mod = @eval module $module_name end
        modules[module_name] = mod
    end
    return string(Core.eval(mod, Meta.parse(ex)))
end

function delete_workspace(module_name::Symbol)
    if haskey(modules, module_name)
        delete!(modules, module_name)
        return true
    else
        return false
    end
end

# create an application
@register REPL begin
    # register by demo
    eval("3^2"; module_name=:default) == "9"
    delete_workspace(:none) == false
end

