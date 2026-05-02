######################################################
## FIGURE B.2: empirical distribution of cost state ##
######################################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);

# load packages
using Pkg
required_packages = ["Plots", "Statistics","Serialization","JLD2","Revise","Measures"]
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


prob_cost_low = zeros(Float32, game.S, game.dim_rho, game.dim_delta);
for d=1:game.dim_delta
    for r=1:game.dim_rho
        for s=1:game.S
            prob_cost_low[s,r,d] = mean(cost[:,s,r,d] .== 1);
        end
    end
end

bin_width = 0.001;
centers = 0.485:0.001:0.515;
edges = vcat(centers .- bin_width/2, maximum(centers) + bin_width/2);

r=1;
histogram(prob_cost_low[:,r,d],alpha=.8,bins=edges, xticks=collect(0.49:0.01:0.51), normalize=:probability, ylabel="Frequency",label="ρ = $(game.rho[r])",linewidth=1)
r=2;
histogram!(prob_cost_low[:,r,d],alpha=.8,bins=edges, normalize=:probability, ylabel="Frequency",label="ρ = $(game.rho[r])",linewidth=1)
vline!([0.5],label="",linestyle=:solid, linewidth=1.5,color=:black,ylim=(0,0.28))
plot!(xlabel="Fraction of periods in the low-cost state", grid = false,size=(500,300),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6)
savefig("figure_B2.pdf")