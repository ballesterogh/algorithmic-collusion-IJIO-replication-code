#####################################
## TABLE 1: Descriptive statistics ##
#####################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_dir = joinpath(root_dir, "figures_tables");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_dir);

# load packages
using Pkg
required_packages = ["Plots", "Statistics", "LinearAlgebra","Serialization", "Printf", "DelimitedFiles", "NaNStatistics","JLD2","Revise"]


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


include("pricing_classification.jl");
focal_single_idx, focal_alternate_idx, partial_idx, cycle_idx, focal_high_idx, focal_low_idx = pricing_classification(game, bf);

price = game.P[actions];
price_market = minimum(price,dims=2);
price_market = reshape(price_market, game.tstable, game.S, game.dim_rho, game.dim_delta);
price_market_average = mean(price_market,dims=1);
price_market_average = reshape(price_market_average ,game.S, game.dim_rho, game.dim_delta);


include("compute_profit_normalized.jl") 

π_bar_comp = 0.059; 
π_bar_monop = 0.5 * (game.profit_monopoly[1]/2) + 0.5 * (game.profit_monopoly[2]/2);

Δ, Δ_random = compute_profit_normalized(game, profits, π_bar_comp, π_bar_monop);


include("compute_nash_optimality.jl") 
epsilon =  10^-8;  # Convergence threshold
nash, Q_loss_on_path, Q_loss_all, Γ = compute_nash_optimality(game, epsilon, actions, cost, Q_matrix, bf);


#TABLE 1
table1A = zeros(Float32, 9, 5);
table1B = zeros(Float32, 9, 5);

r=1; d=1;
# Frequency
table1A[1,1]=mean(focal_single_idx[:,r,d]);
table1A[1,2]=mean(focal_alternate_idx[:,r,d]);
table1A[1,3]=mean(partial_idx[:,r,d]);
table1A[1,4]=mean(cycle_idx[:,r,d]);
table1A[1,5]=mean(focal_single_idx[:,r,d]+focal_alternate_idx[:,r,d]+partial_idx[:,r,d]+cycle_idx[:,r,d]);
# Average market price
table1A[2,1]=mean(price_market_average[focal_single_idx[:,r,d],r,d]);
table1A[2,2]=mean(price_market_average[focal_alternate_idx[:,r,d],r,d]);
table1A[2,3]=mean(price_market_average[partial_idx[:,r,d],r,d]);
table1A[2,4]=mean(price_market_average[cycle_idx[:,r,d],r,d]);
table1A[2,5]=mean(price_market_average[:,r,d]);
# Average Profits (normalized)
table1A[3,1]=mean(Δ[focal_single_idx[:,r,d],r,d]);
table1A[3,2]=mean(Δ[focal_alternate_idx[:,r,d],r,d]);
table1A[3,3]=mean(Δ[partial_idx[:,r,d],r,d]);
table1A[3,4]=mean(Δ[cycle_idx[:,r,d],r,d]);
table1A[3,5]=mean(Δ[:,r,d]);
# std Profits (normalized)
table1A[4,1]=std(Δ[focal_single_idx[:,r,d],r,d]);
table1A[4,2]=std(Δ[focal_alternate_idx[:,r,d],r,d]);
table1A[4,3]=std(Δ[partial_idx[:,r,d],r,d]);
table1A[4,4]=std(Δ[cycle_idx[:,r,d],r,d]);
table1A[4,5]=std(Δ[:,r,d]);
# Nash equilibrium 
table1A[5,1]=mean(nash[focal_single_idx[:,r,d],r,d]);
table1A[5,2]=mean(nash[focal_alternate_idx[:,r,d],r,d]);
table1A[5,3]=mean(nash[partial_idx[:,r,d],r,d]);
table1A[5,4]=mean(nash[cycle_idx[:,r,d],r,d]);
table1A[5,5]=mean(nash[:,r,d]);
# Average Q-loss (on path)
table1A[6,1]=mean(Q_loss_on_path[focal_single_idx[:,r,d],r,d]);
table1A[6,2]=mean(Q_loss_on_path[focal_alternate_idx[:,r,d],r,d]);
table1A[6,3]=mean(Q_loss_on_path[partial_idx[:,r,d],r,d]);
table1A[6,4]=mean(Q_loss_on_path[cycle_idx[:,r,d],r,d]);
table1A[6,5]=mean(Q_loss_on_path[:,r,d]);
# std Q-loss (on path)
table1A[7,1]=std(Q_loss_on_path[focal_single_idx[:,r,d],r,d]);
table1A[7,2]=std(Q_loss_on_path[focal_alternate_idx[:,r,d],r,d]);
table1A[7,3]=std(Q_loss_on_path[partial_idx[:,r,d],r,d]);
table1A[7,4]=std(Q_loss_on_path[cycle_idx[:,r,d],r,d]);
table1A[7,5]=std(Q_loss_on_path[:,r,d]);
# Average Q-loss (all states)
table1A[8,1]=mean(Q_loss_all[focal_single_idx[:,r,d],r,d]);
table1A[8,2]=mean(Q_loss_all[focal_alternate_idx[:,r,d],r,d]);
table1A[8,3]=mean(Q_loss_all[partial_idx[:,r,d],r,d]);
table1A[8,4]=mean(Q_loss_all[cycle_idx[:,r,d],r,d]);
table1A[8,5]=mean(Q_loss_all[:,r,d]);
# std Q-loss (all states)
table1A[9,1]=std(Q_loss_all[focal_single_idx[:,r,d],r,d]);
table1A[9,2]=std(Q_loss_all[focal_alternate_idx[:,r,d],r,d]);
table1A[9,3]=std(Q_loss_all[partial_idx[:,r,d],r,d]);
table1A[9,4]=std(Q_loss_all[cycle_idx[:,r,d],r,d]);
table1A[9,5]=std(Q_loss_all[:,r,d]);

table1A=round.(table1A,digits=3)

r=2;

# Frequency
table1B[1,1]=mean(focal_single_idx[:,r,d]);
table1B[1,2]=mean(focal_alternate_idx[:,r,d]);
table1B[1,3]=mean(partial_idx[:,r,d]);
table1B[1,4]=mean(cycle_idx[:,r,d]);
table1B[1,5]=mean(focal_single_idx[:,r,d]+focal_alternate_idx[:,r,d]+partial_idx[:,r,d]+cycle_idx[:,r,d]);
# Average market price
table1B[2,1]=mean(price_market_average[focal_single_idx[:,r,d],r,d]);
table1B[2,2]=mean(price_market_average[focal_alternate_idx[:,r,d],r,d]);
table1B[2,3]=mean(price_market_average[partial_idx[:,r,d],r,d]);
table1B[2,4]=mean(price_market_average[cycle_idx[:,r,d],r,d]);
table1B[2,5]=mean(price_market_average[:,r,d]);
# Average Profits (normalized)
table1B[3,1]=mean(Δ[focal_single_idx[:,r,d],r,d]);
table1B[3,2]=mean(Δ[focal_alternate_idx[:,r,d],r,d]);
table1B[3,3]=mean(Δ[partial_idx[:,r,d],r,d]);
table1B[3,4]=mean(Δ[cycle_idx[:,r,d],r,d]);
table1B[3,5]=mean(Δ[:,r,d]);
# std Profits (normalized)
table1B[4,1]=std(Δ[focal_single_idx[:,r,d],r,d]);
table1B[4,2]=std(Δ[focal_alternate_idx[:,r,d],r,d]);
table1B[4,3]=std(Δ[partial_idx[:,r,d],r,d]);
table1B[4,4]=std(Δ[cycle_idx[:,r,d],r,d]);
table1B[4,5]=std(Δ[:,r,d]);
# Nash equilibrium 
table1B[5,1]=mean(nash[focal_single_idx[:,r,d],r,d]);
table1B[5,2]=mean(nash[focal_alternate_idx[:,r,d],r,d]);
table1B[5,3]=mean(nash[partial_idx[:,r,d],r,d]);
table1B[5,4]=mean(nash[cycle_idx[:,r,d],r,d]);
table1B[5,5]=mean(nash[:,r,d]);
# Average Q-loss (on path)
table1B[6,1]=mean(Q_loss_on_path[focal_single_idx[:,r,d],r,d]);
table1B[6,2]=mean(Q_loss_on_path[focal_alternate_idx[:,r,d],r,d]);
table1B[6,3]=mean(Q_loss_on_path[partial_idx[:,r,d],r,d]);
table1B[6,4]=mean(Q_loss_on_path[cycle_idx[:,r,d],r,d]);
table1B[6,5]=mean(Q_loss_on_path[:,r,d]);
# std Q-loss (on path)
table1B[7,1]=std(Q_loss_on_path[focal_single_idx[:,r,d],r,d]);
table1B[7,2]=std(Q_loss_on_path[focal_alternate_idx[:,r,d],r,d]);
table1B[7,3]=std(Q_loss_on_path[partial_idx[:,r,d],r,d]);
table1B[7,4]=std(Q_loss_on_path[cycle_idx[:,r,d],r,d]);
table1B[7,5]=std(Q_loss_on_path[:,r,d]);
# Average Q-loss (all states)
table1B[8,1]=mean(Q_loss_all[focal_single_idx[:,r,d],r,d]);
table1B[8,2]=mean(Q_loss_all[focal_alternate_idx[:,r,d],r,d]);
table1B[8,3]=mean(Q_loss_all[partial_idx[:,r,d],r,d]);
table1B[8,4]=mean(Q_loss_all[cycle_idx[:,r,d],r,d]);
table1B[8,5]=mean(Q_loss_all[:,r,d]);
# std Q-loss (all states)
table1B[9,1]=std(Q_loss_all[focal_single_idx[:,r,d],r,d]);
table1B[9,2]=std(Q_loss_all[focal_alternate_idx[:,r,d],r,d]);
table1B[9,3]=std(Q_loss_all[partial_idx[:,r,d],r,d]);
table1B[9,4]=std(Q_loss_all[cycle_idx[:,r,d],r,d]);
table1B[9,5]=std(Q_loss_all[:,r,d]);


table1B=round.(table1B,digits=3);


# Impact of cost uncertainty on Collusion
include("init_deterministic.jl")
@load "outcomes_deterministic_cL.jld2" game Q_matrix profits actions cost t_final bf;
π_C_cL=0.070; π_M_cL=game.profit_monopoly/2;
Δ_cL = (mean(profits)-π_C_cL)/(π_M_cL-π_C_cL)


@load "outcomes_deterministic_cH.jld2" game Q_matrix profits actions cost t_final bf;
π_C_cH=0.047; π_M_cH=game.profit_monopoly/2;
Δ_cH = (mean(profits)-π_C_cH)/(π_M_cH-π_C_cH)

Δ_deterministic = (Δ_cL+Δ_cH)/2;

row_labels = [
    "Frequency",
    "Average market price",
    "Average normalized profit",
    "Standard deviation normalized profit",
    "Frequency of Nash equilibria",
    "Average Q-loss (on path)",
    "Standard deviation Q-loss (on path)",
    "Average Q-loss (all states)",
    "Standard deviation Q-loss (all states)"
]

col_labels = ["Focal single", "Alternating focal", "Partial focal", "Cycle", "All"]


function write_table_txt(filename, panel_title, table, col_labels, row_labels; note=nothing)
    output_lines = String[]

    push!(output_lines, panel_title)
    push!(output_lines, @sprintf("%-45s %15s %15s %15s %15s %15s",
        "", col_labels[1], col_labels[2], col_labels[3], col_labels[4], col_labels[5]))
        push!(output_lines, repeat("─", 120))

    for i in 1:length(row_labels)
        push!(output_lines,
            @sprintf("%-45s %15.3f %15.3f %15.3f %15.3f %15.3f",
                     row_labels[i], table[i,1], table[i,2], table[i,3], table[i,4], table[i,5])
        )
    end

    if note !== nothing
        push!(output_lines, "")
        push!(output_lines, "Note:")
        push!(output_lines, note)
    end

    writedlm(filename, output_lines)
end


write_table_txt("table_1A.txt", "Panel A: Bernoulli (ρ = 0.5)", table1A, col_labels, row_labels; note = "Normalized profits under random pricing = $(round.(Δ_random, digits=3))")
write_table_txt("table_1B.txt", "Panel B: Markov (ρ = 0.9)", table1B, col_labels, row_labels; note = "Normalized profits under random pricing = $(round.(Δ_random, digits=3))")


    
