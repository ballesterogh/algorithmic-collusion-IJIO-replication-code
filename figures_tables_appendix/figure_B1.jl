###########################################
## FIGURE B.1: iterations to convergence ##
###########################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);

# load packages
using Pkg
required_packages = ["Plots", "Statistics", "LinearAlgebra","JLD2","Revise","Measures"]
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


size(t_final)
bin_width = 0.1;
centers = 1:0.1:4;
edges = vcat(centers .- bin_width/2, maximum(centers) + bin_width/2);

r=1; d=1;
histogram(t_final[:,r,d]./10^6, bins=edges, normalize=:probability, ylabel="Frequency",label="ρ = $(game.rho[r])",alpha=0.8,linewidth=1)
r=2;
histogram!(t_final[:,r,d]./10^6, bins=edges, xticks=[1,1.5,2,2.5,3,3.5,4.0], normalize=:probability, ylabel="Frequency",label="ρ =  $(game.rho[r])",alpha=0.8,linewidth=1)
plot!(xlabel="Number of Iterations (in millions)", grid = false,size=(300,200),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6)
savefig("figure_B1.pdf")

r=1;
mean(t_final[:,r,d])/10^6
r=2;
mean(t_final[:,r,d])/10^6