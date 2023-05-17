struct TypeTooAbstract <: Exception
    type
end
function Base.showerror(io::IO, e::TypeTooAbstract, trace)
    print(io, "Type is too abstract, expect a more concrete one in a demo, got: $(e.type)")
end
