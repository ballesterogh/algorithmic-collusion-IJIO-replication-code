####################################################################################
## FIGURE D1: Freq of Nash equilibria and Q-loss as a function of discount factor ##
####################################################################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);

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

include("compute_nash_optimality.jl") ;
epsilon =  10^-8;  # Convergence threshold

# i. Bernoulli
@load joinpath(data_dir, "outcomes_stochastic_discount_bernoulli.jld2") game Q_matrix profits actions cost t_final bf;
nash_bernoulli, Q_loss_on_path_bernoulli, Q_loss_all_bernoulli, Γ_bernoulli = compute_nash_optimality(game, epsilon, actions, cost, Q_matrix, bf);
nash_bernoulli = reshape(nash_bernoulli, game.S, game.dim_delta);
nash_bernoulli_mean = mean(nash_bernoulli,dims=1);
Q_loss_on_path_bernoulli = reshape(Q_loss_on_path_bernoulli, game.S, game.dim_delta);
Q_loss_on_path_bernoulli_mean = mean(Q_loss_on_path_bernoulli,dims=1);
Q_loss_all_bernoulli = reshape(Q_loss_all_bernoulli, game.S, game.dim_delta);
Q_loss_all_bernoulli_mean = mean(Q_loss_all_bernoulli,dims=1);

# ii. Markov
@load joinpath(data_dir, "outcomes_stochastic_discount_markov.jld2") game Q_matrix profits actions cost t_final bf;
nash_markov, Q_loss_on_path_markov, Q_loss_all_markov, Γ_markov = compute_nash_optimality(game, epsilon, actions, cost, Q_matrix, bf);
nash_markov = reshape(nash_markov, game.S, game.dim_delta);
nash_markov_mean = mean(nash_markov,dims=1);
Q_loss_on_path_markov = reshape(Q_loss_on_path_markov, game.S, game.dim_delta);
Q_loss_on_path_markov_mean = mean(Q_loss_on_path_markov,dims=1);
Q_loss_all_markov = reshape(Q_loss_all_markov, game.S, game.dim_delta);
Q_loss_all_markov_mean = mean(Q_loss_all_markov,dims=1);




# Plot
default_blue = palette(:auto)[1];
default_red = palette(:auto)[2];

p1=plot(vec(game.delta), vec(nash_bernoulli_mean), linestyle=:solid, linewidth=1.5, color=default_blue, label="ρ=0.5");
scatter!(vec(game.delta), vec(nash_bernoulli_mean),label="",markersize=4,color=default_blue,xlabel="Discount factor", ylabel="Nash Equilibria")
plot!(vec(game.delta), vec(nash_markov_mean), linestyle=:solid, linewidth=1.5, color=default_red, label="ρ=0.9", size=(500,300),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6)
scatter!(vec(game.delta), vec(nash_markov_mean),label="",ylim=(-0.05,1.05),xlim=(-0.05,1.05),markersize=4,color=default_red,xticks=collect(0:0.1:1),yticks=collect(-1:0.25:1),grid=false,legend=:bottomleft,size=(500,300))

y_upper = maximum([Q_loss_on_path_markov_mean;Q_loss_on_path_bernoulli_mean]);
y_lower = minimum([Q_loss_on_path_markov_mean;Q_loss_on_path_bernoulli_mean]);
p2=plot(vec(game.delta), vec(Q_loss_on_path_bernoulli_mean), linestyle=:solid, linewidth=1.5, color=default_blue, label="ρ=0.5");
scatter!(vec(game.delta),vec(Q_loss_on_path_bernoulli_mean),label="",markersize=4,color=default_blue,xlabel="Discount factor", ylabel="Q-loss (on path)");
plot!(vec(game.delta), vec(Q_loss_on_path_markov_mean), linestyle=:solid, linewidth=1.5, color=default_red, label="ρ=0.9", size=(500,300),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6);
scatter!(vec(game.delta),vec(Q_loss_on_path_markov_mean),label="",ylim=(-0.01,0.15),xlim=(-0.05,1.05),markersize=4,color=default_red,xticks=collect(0:0.1:1),yticks=collect(0:0.02:0.15),grid=false);

plot(p1, p2, layout=(1, 2),size=(600,200))

savefig("figure_D1.pdf")





