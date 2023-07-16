# Please check Jugsaw documentation: TBD
using Jugsaw
using TensorInference: TensorNetworkModel, MMAPModel, TreeSA, read_instance_from_string, set_evidence!, set_query!
import TensorInference

"""
Compute the probability.

### Arguments
* The only positional argument is a string with the UAI format. The UAI format is specified at [https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats](https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats)

### Keyword Arguments
* `evidence` is a dictionary with the observed variable-value pairs.
* `optimize_level` is an integer to specify the level of effort to optimize the tensor network contraction order.
"""
function probability(uai::String; evidence::Dict, optimize_level::Int)
    instance = read_instance_from_string(uai)
    set_evidence!(instance, evidence...)
    optimizer = TreeSA(ntrials=2, niters=optimize_level, βs=0.1:0.1:100)
    tn = TensorNetworkModel(instance; optimizer)
    return TensorInference.probability(tn)[]
end

"""
Compute the marginal probabilities for each variable.

### Arguments
* The only positional argument is a string with the UAI format. The UAI format is specified at [https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats](https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats)

### Keyword Arguments
* `evidence` is a dictionary with the observed variable-value pairs.
* `optimize_level` is an integer to specify the level of effort to optimize the tensor network contraction order.
"""
function marginals(uai::String; evidence::Dict, optimize_level::Int)
    instance = read_instance_from_string(uai)
    set_evidence!(instance, evidence...)
    optimizer = TreeSA(ntrials=2, niters=optimize_level, βs=0.1:0.1:100)
    tn = TensorNetworkModel(instance; optimizer)
    return TensorInference.marginals(tn)
end

"""
Find the most probable configuration and its probability.

### Arguments
* The only positional argument is a string with the UAI format. The UAI format is specified at [https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats](https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats)

### Keyword Arguments
* `evidence` is a dictionary with the observed variable-value pairs.
* `queryvars` is a vector for specifying the query variables (those not marginalized in the MMAP task definition).
* `optimize_level` is an integer to specify the level of effort to optimize the tensor network contraction order.
"""
function most_probable_config(uai; evidence::Dict, queryvars, optimize_level::Int)
    instance = read_instance_from_string(uai)
    set_evidence!(instance, evidence...)
    set_query!(instance, queryvars)
    optimizer = TreeSA(ntrials=2, niters=optimize_level, βs=0.1:0.1:100)
    tn = MMAPModel(instance; optimizer)
    logp, solution = TensorInference.most_probable_config(tn)
    return (; probability=exp(logp), configuration=solution)
end

"""
Sample from the probability model.

### Arguments
* The only positional argument is a string with the UAI format. The UAI format is specified at [https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats](https://tensorbfs.github.io/TensorInference.jl/dev/uai-file-formats/#UAI-file-formats)

### Keyword Arguments
* `evidence` is a dictionary with the observed variable-value pairs.
* `num_sample` is the number of samples to return.
* `optimize_level` is an integer to specify the level of effort to optimize the tensor network contraction order.
"""
function sample(uai::String; evidence::Dict, num_sample, optimize_level::Int)
    instance = read_instance_from_string(uai)
    set_evidence!(instance, evidence...)
    optimizer = TreeSA(ntrials=2, niters=optimize_level, βs=0.1:0.1:100)
    tnet = TensorNetworkModel(instance; optimizer)
    return TensorInference.sample(tnet, num_sample)
end

const uai_demo_input = """MARKOV
8
 2 2 2 2 2 2 2 2
8
 1 0
 2 1 0
 1 2
 2 3 2
 2 4 2
 3 5 3 1
 2 6 5
 3 7 5 4

2
 0.01
 0.99

4
 0.05 0.01
 0.95 0.99

2
 0.5
 0.5

4
 0.1 0.01
 0.9 0.99

4
 0.6 0.3
 0.4 0.7 

8
 1 1 1 0
 0 0 0 1

4
 0.98 0.05
 0.02 0.95

8
 0.9 0.7 0.8 0.1
 0.1 0.3 0.2 0.9
"""

@register inference begin
    # register by demo
    probability(uai_demo_input; evidence=Dict(7=>1), optimize_level=5)
    marginals(uai_demo_input; evidence=Dict(7=>1), optimize_level=5)
    most_probable_config(uai_demo_input; evidence=Dict(7=>1), queryvars=setdiff(1:8, 7), optimize_level=5)
    sample(uai_demo_input; evidence=Dict(7=>1), num_sample=3, optimize_level=5)
end
