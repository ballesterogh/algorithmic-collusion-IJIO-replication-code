###################################
## TABLE D.4: large cost shocks ###
###################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);


# load packages
using Pkg
required_packages = ["Random", "Plots", "StatsPlots", "Statistics", "DelimitedFiles","LinearAlgebra", "NaNStatistics","Serialization", "Printf","JLD2","Revise","Measures"]
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
@load joinpath(data_dir, "outcomes_stochastic_cost_shock.jld2") game Q_matrix profits actions cost t_final bf;


include("compute_profit_normalized.jl") 

π_bar_comp = 0.045; 
π_bar_monop = 0.5 * (game.profit_monopoly[1]/2) + 0.5 * (game.profit_monopoly[2]/2);

Δ, Δ_random = compute_profit_normalized(game, profits, π_bar_comp, π_bar_monop);


include("compute_nash_optimality.jl") 
epsilon = 0.00001;  # Convergence threshold
nash, Q_loss_on_path, Q_loss_all, Γ = compute_nash_optimality(game, epsilon, actions, cost, Q_matrix, bf);

# Number of iterations until convergence
t_conv = zeros(game.dim_rho,game.dim_delta);
for d=1:game.dim_delta 
    for r=1:game.dim_rho
        t_conv[r,d]=mean(t_final[:,r,d])/10^6;
    end
end

# Market price
price = game.P[actions];
price_market = minimum(price,dims=2);
price_market = reshape(price_market, game.tstable, game.S, game.dim_rho, game.dim_delta);
price_market_average = mean(price_market,dims=1);
price_market_average = reshape(price_market_average ,game.S, game.dim_rho, game.dim_delta);

price_market_mean = zeros(game.dim_rho, game.dim_delta)
for d=1:game.dim_delta 
    for r=1:game.dim_rho
        price_market_mean[r,d]=mean(price_market_average[:,r,d]);
    end
end



table=Array{Any}(undef, 7, game.dim_rho);

d=1;
    for r=1:game.dim_rho
        table[1,r] = mean(Δ[:,r,d]);
        table[2,r] = std(Δ[:,r,d]);
        table[3,r] = mean(nash[:,r,d]);
        table[4,r] = mean(Q_loss_on_path[:,r,d]);
        table[5,r] = std(Q_loss_on_path[:,r,d]);
        table[6,r] = mean(Q_loss_all[:,r,d]);
        table[7,r] = std(Q_loss_all[:,r,d]);
    end



    # --- Labels ---
row_labels = [
    "Average normalized profit",
    "Standard deviation normalized profits",
    "Frequency of Nash equilibria",
    "Average Q-loss (on path)",
    "Standard deviation Q-loss (on path)",
    "Average Q-loss (all states)",
    "Standard deviation Q-loss (all states)"
]

col_labels = ["Bernoulli (ρ = 0.5)", "Markov (ρ = 0.9)"]


output_lines = String[]

push!(output_lines, @sprintf("%-45s %15s %15s", "", col_labels[1], col_labels[2]))
push!(output_lines, "─"^80)

for i in 1:7
    push!(output_lines,
        @sprintf("%-45s %15.3f %15.3f", row_labels[i], table[i,1], table[i,2])
    )
end

# --- Add note ---
push!(output_lines, "")
push!(output_lines, "Note: Normalized profits under random pricing = $(round(Δ_random, digits=3))")

r=1; d=1;
push!(output_lines, "Note: Average number of iterations until converge for Bernoulli (ρ = 0.5) in millions = $(round(t_conv[r,d], digits=3))")
push!(output_lines, "Note: Average market price for Bernoulli (ρ = 0.5) = $(round(price_market_mean[r,d], digits=3))")

r=2;
push!(output_lines, "Note: Average number of iterations until converge for Markov (ρ = 0.9) in millions = $(round(t_conv[r,d], digits=3))")
push!(output_lines, "Note: Average market price for Markov (ρ = 0.9) = $(round(price_market_mean[r,d], digits=3))")

writedlm("table_D4.txt", output_lines)

