using Jugsaw
using Jugsaw.JugsawIR
using Jugsaw.Universe
using JSON

using GenericTensorNetworks
using GenericTensorNetworks: AbstractProperty
import Graphs
using Random



types = JSON.parse(String(read(joinpath(@__DIR__, "method_table.json"))))
demos = JSON.parse(String(read(joinpath(@__DIR__, "demo.json"))))