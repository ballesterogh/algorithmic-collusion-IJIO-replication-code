###############################
## FIGURE 2: Price deviation ##
###############################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_dir = joinpath(root_dir, "figures_tables");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_dir);


# load packages
using Pkg
required_packages = ["Random", "Plots", "StatsPlots", "Statistics", "DelimitedFiles","LinearAlgebra", "NaNStatistics","Serialization","JLD2","Revise","Measures"]
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
Revise.revise()
include(joinpath(code_dir, "init_stochastic.jl"));
@load joinpath(data_dir, "outcomes_stochastic.jld2") game Q_matrix profits actions cost t_final bf;

include("price_deviation_analysis.jl") 
T=20;
table, price_serie_mean, p_serie_mean, p_diff = price_deviation_analysis(game, bf, T, "price_deviation")

X = Array{Any}(undef, game.dim_C, game.dim_rho);
tt=["Low cost" "High cost";"Low cost" "High cost"];
default_blue = palette(:auto)[1];
default_red = palette(:auto)[2];

for c=1:game.dim_C
    for r=1:game.dim_rho
        X[c,r]=scatter(collect(1:2:T), price_serie_mean[1,1:2:T,c,r],label="",markersize=5,title=tt[r,c]) #deviating agent
        scatter!(collect(2:2:T), price_serie_mean[2,2:2:T,c,r],ylim=(-.2,.1),label="",yticks=(round.(collect(-3/game.k : 1/game.k : 3/game.k), digits=2)),markersize=5) #deviating agent
        plot!(collect(1:1:T), p_serie_mean[:,c,r], label="",linestyle = :dashdot,  color= :black, grid = false,xlabel="Time", ylabel="Price change",fillalpha=.2,xlim=(0.5,13.5),xticks=collect(1:1:10),linewidth=2)
        hline!([0], linestyle = :solid,  color= :black, label = "",xticks = (1:13, -1:11))
        vline!([3], linestyle = :dash,  color= :black, label = "")
    end
end


title1 = plot(title = "(a) Bernoulli (ρ = $(game.rho[1]))", grid = false, showaxis = false, bottom_margin = -50Plots.px)
title2 = plot(title = "(b) Markov (ρ = $(game.rho[2]))", grid = false, showaxis = false, bottom_margin = -50Plots.px)
title3 = plot(title = "", grid = false, showaxis = false, bottom_margin = -80Plots.px)
plot(title1, X[1,1], X[2,1], title3, title2, X[1,2], X[2,2], layout = @layout([A{0.02h}; [B C]; D{0.1h}; E{0.02h}; [F G]]), grid = false,margin=3mm)
plot!(size=(800,600))
savefig("figure_2.pdf")

