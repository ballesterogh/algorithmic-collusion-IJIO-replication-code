#######################################################################
## FIGURE 4: Normalized profits as a function of the discount factor ##
#######################################################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_dir = joinpath(root_dir, "figures_tables");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_dir);

# load packages
using Pkg
required_packages = ["Random", "Plots", "StatsPlots", "Statistics", "DelimitedFiles","LinearAlgebra", "NaNStatistics","Serialization", "Printf","JLD2","Revise","Measures","LaTeXStrings"]
for pkg in required_packages
    try
        @eval using $(Symbol(pkg))
    catch
        println("Installing missing package: $pkg")
        Pkg.add(pkg)
        @eval using $(Symbol(pkg))
    end
end

Revise.revise()
include(joinpath(code_dir, "init_stochastic.jl"));

include("compute_profit_normalized.jl");

π_bar_comp = 0.059; 
π_bar_monop = 0.5 * (game.profit_monopoly[1]/2) + 0.5 * (game.profit_monopoly[2]/2);

# i. Bernoulli
@load joinpath(data_dir, "outcomes_stochastic_discount_bernoulli.jld2") game Q_matrix profits actions cost t_final bf;
Δ_bernoulli, Δ_random = compute_profit_normalized(game, profits, π_bar_comp, π_bar_monop);
Δ_bernoulli = reshape(Δ_bernoulli, game.S, game.dim_delta);
Δ_bernoulli_mean = mean(Δ_bernoulli,dims=1);


# ii. Markov
@load joinpath(data_dir, "outcomes_stochastic_discount_markov.jld2") game Q_matrix profits actions cost t_final bf;
Δ_markov, Δ_random = compute_profit_normalized(game, profits, π_bar_comp, π_bar_monop);
Δ_markov_mean = mean(Δ_markov,dims=1);
Δ_markov_mean = reshape(Δ_markov_mean, 1, game.dim_delta);

# Plot
default_blue = palette(:auto)[1];
default_red = palette(:auto)[2];

Delta_static_nash = (mean(game.profit_nash./2) -π_bar_comp)./(π_bar_monop.-π_bar_comp); 
# The static Nash outcome is defined as a situation in which both algorithms set their prices at one increment above the marginal cost. 
# The competitive MPE and joint-profit maximizing benchmark are defined as in Section 4.

plot(vec(game.delta), vec(Δ_bernoulli_mean), linestyle=:solid, linewidth=1.5, color=default_blue, label="ρ=0.5")
scatter!(vec(game.delta), vec(Δ_bernoulli_mean),label="",markersize=4,color=default_blue,xlabel="Discount factor", ylabel= "Normalized profits " * L"\Delta")
plot!(vec(game.delta), vec(Δ_markov_mean), linestyle=:solid, linewidth=1.5, color=default_red, label="ρ=0.9", size=(500,300),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6, legend=(0.12, 0.9))
scatter!(vec(game.delta), vec(Δ_markov_mean),label="",ylim=(-0.7,1.05),xlim=(-0.05,1.05),markersize=4,color=default_red,xlabel="Discount factor", ylabel= "Normalized profits " * L"\Delta",xticks=collect(0:0.1:1),yticks=collect(-1:0.25:1))
hline!([Delta_static_nash],label="",linestyle=:dash, linewidth=1, color=:black,grid=false)
hline!([0],label="",linestyle=:dash, linewidth=1, color=:black)
hline!([1],label="",linestyle=:dash, linewidth=1, color=:black)
annotate!(1, 0-.05, text("Competitive MPE", :black, 8, halign=:right))
annotate!(1, Delta_static_nash-0.05, text("Static Nash", :black, 8, halign=:right))
annotate!(1, 1-.05, text("Joint-Profit Maximizing", :black, 8, halign=:right))
savefig("figure_4.pdf")



