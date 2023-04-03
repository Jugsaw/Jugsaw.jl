struct JugsawFunctionCall{F, argsT<:Tuple, kwargsT<:NamedTuple}
    fname::F
    args::argsT
    kwargs::kwargsT
end
