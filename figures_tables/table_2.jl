#########################################
## Table 2: unilateral price deviation ##
#########################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_dir = joinpath(root_dir, "figures_tables");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_dir);

# load packages
using Pkg
required_packages = ["Plots", "StatsPlots", "Statistics", "DelimitedFiles","Serialization", "Printf","JLD2","Revise","Measures"]
for pkg in required_packages
    try
        @eval using $(Symbol(pkg))
    catch
        println("Installing missing package: $pkg")
        Pkg.add(pkg)
        @eval using $(Symbol(pkg))
    end
end


# load data 
include(joinpath(code_dir, "init_stochastic.jl"));
@load joinpath(data_dir, "outcomes_stochastic.jld2") game Q_matrix profits actions cost t_final bf;



Revise.revise()
include("price_deviation_analysis.jl")
T=20;
table2, price_serie_mean, p_serie_mean, p_diff = price_deviation_analysis(game, bf, T, "price_deviation");


# --- Labels ---
row_labels = [
    "Relative price change by the nondeviating agent in period τ = 2",
    "Average percentage gain from the deviation in terms of discounted profits",
    "Length of punishment"
]

col_labels = ["Low-cost state", "High-cost state"]


output_lines = String[]

push!(output_lines, "Panel A: Bernoulli (ρ = 0.5)")
for i in 1:3
    push!(output_lines,
        @sprintf("%-75s %8.3f %8.3f", row_labels[i], table2[i,1,1], table2[i,2,1])
    )
end
push!(output_lines, "")
push!(output_lines, "Panel B: Markov (ρ = 0.9)")
for i in 1:3
    push!(output_lines,
        @sprintf("%-75s %8.3f %8.3f", row_labels[i], table2[i,1,2], table2[i,2,2])
    )
end

header = @sprintf("%-75s %15s %15s", "", col_labels[1], col_labels[2])
final_text = [header; repeat(["─"^105], 1); output_lines...]

writedlm("table_2.txt", final_text)