#########################################
## FIGURE C.1: Price deviation boxplot ##
#########################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);

# load packages
using Pkg
required_packages = ["Plots", "StatsPlots", "Statistics", "DelimitedFiles","JLD2","Revise","Measures","Random","NaNStatistics"]
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
table, price_serie_mean, p_serie_mean, p_diff = price_deviation_analysis(game, bf, T, "price_deviation")


Y = Array{Any}(undef, game.dim_C, game.dim_rho);
tt=["Low cost" "High cost";"Low cost" "High cost"];
default_blue = palette(:auto)[1];
default_red = palette(:auto)[2];

for c=1:game.dim_C
    for r=1:game.dim_rho
        Y[c,r]=boxplot(collect(1:2:T-7)',p_diff[1,1:2:T-7,:,c,r]',fillcolor=default_blue,markeralpha=0,legend=false,ylim=(-0.5,0.1),linewidth=2,title=tt[r,c],xticks = (1:15, -2:12),xlim=(1,13),linecolor=:black,xlabel="Time", ylabel="Price change")
        boxplot!(collect(2:2:T)',p_diff[2,2:2:T,:,c,r]',fillcolor=default_red,markeralpha=0,legend=false,grid=false,yticks=(round.(collect(-6/game.k : 1/game.k : 3/game.k), digits=2)),linewidth=2,xticks = (1:13, -1:11),xlim=(1,13),linecolor=:black,xlabel="Time", ylabel="Price change")
    end
end

title1 = plot(title = "(a) Bernoulli (ρ = $(game.rho[1]))", grid = false, showaxis = false, bottom_margin = -40Plots.px)
title2 = plot(title = "(b) Markov (ρ = $(game.rho[2]))", grid = false, showaxis = false, bottom_margin = -40Plots.px)
title3 = plot(title = "", grid = false, showaxis = false, bottom_margin = -50Plots.px)
combined_plot=plot(title1, Y[1,1], Y[2,1], title3, title2, Y[1,2], Y[2,2], layout = @layout([A{0.02h}; [B C]; D{0.1h}; E{0.02h}; [F G]]), grid = false,margin=3mm)
plot!(combined_plot, size=(800, 600), xlim=(1, 13))
savefig("figure_C1.pdf")
