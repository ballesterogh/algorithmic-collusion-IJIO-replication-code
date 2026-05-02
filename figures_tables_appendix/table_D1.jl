
###########################################################
## TABLE D.1: onditioning on own past price - robustness ##
###########################################################

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
include("compute_profit_normalized.jl") 
@load joinpath(data_dir, "outcomes_stochastic_own_price.jld2") game Q_matrix profits actions cost t_final bf;

π_bar_comp = 0.059; 
π_bar_monop = 0.5 * (game.profit_monopoly[1]/2) + 0.5 * (game.profit_monopoly[2]/2);

Δ, Δ_random = compute_profit_normalized(game, profits, π_bar_comp, π_bar_monop);


V0_matrix = zeros(Float32, game.n, game.dim_A, game.dim_A, game.dim_A, game.dim_C, game.S, game.dim_rho, game.dim_delta);
epsilon =  10^-6;  # Convergence threshold

    for d=1:game.dim_delta
        for r=1:game.dim_rho
                for s=1:game.S
                    for n=1:game.n
                        rival = n == 1 ? 2 : 1
                        dif = 1.0; 
                        t=1;
                        V0 = zeros(Float32, game.dim_A, game.dim_A, game.dim_C);
                        V_new = zeros(Float32, game.dim_A, game.dim_A, game.dim_C);
                        W = zeros(Float32, game.dim_A, game.dim_A, game.dim_C);
                        V = zeros(Float32, game.dim_A, game.dim_A, game.dim_A, game.dim_C);
                        
                        while dif>epsilon
                                for c_current=1:game.dim_C
                                    for aj=1:game.dim_A
                                        for ai=1:game.dim_A
                                            for ai_previous=1:game.dim_A
                                                    pi_current = game.PI[1, ai, aj, c_current]; 
                                                    if c_current==1
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,aj,ai,1,c_current,s,r,d],1] + (1-game.rho[r])*game.PI[1, ai, bf[rival,aj,ai,2,c_current,s,r,d],2];    
                                                        EV = game.rho[r]*V0[ai_previous,bf[rival,aj,ai,1,c_current,s,r,d],1] + (1-game.rho[r])*V0[ai_previous,bf[rival,aj,ai,2,c_current,s,r,d],2];    
                                                    else
                                                        Epi = game.rho[r]*game.PI[1, ai, bf[rival,aj,ai,2,c_current,s,r,d],2] + (1-game.rho[r])*game.PI[1, ai, bf[rival,aj,ai,1,c_current,s,r,d],1];    
                                                        EV = game.rho[r]*V0[ai_previous,bf[rival,aj,ai,2,c_current,s,r,d],2] + (1-game.rho[r])*V0[ai_previous,bf[rival,aj,ai,1,c_current,s,r,d],1];    
                                                    end
            
                                                    W[ai,ai_previous,c_current] = Float32((game.delta[d] * Epi + game.delta[d]^2 * EV));
                                                    V[ai, ai_previous, aj, c_current] = pi_current + W[ai,ai_previous,c_current];
                                                    
                                                    V_new[ai_previous, aj,c_current]=maximum(V[:, ai_previous, aj, c_current]);
                                            end 
                                        end
                                    end
                                end
                                dif = maximum(abs.(V_new-V0))
                                V0 .= V_new 
                                t=t+1;
                        end
                        V0_matrix[n,:,:,:,:, s,r,d] = V; 
                    end
                end
        end
    end
    
    
    bf_optimal = zeros(Int8, game.n, game.dim_A, game.dim_A, game.dim_C, game.S, game.dim_rho, game.dim_delta);
    for d=1:game.dim_delta
        for r=1:game.dim_rho
                for s=1:game.S
                    for n=1:game.n
                        for c_current=1:2
                            for aj=1:game.dim_A
                                for ai_previous=1:game.dim_A
                                    bf_optimal[n,ai_previous, aj,c_current,s,r,d]=argmax(V0_matrix[n, :, ai_previous, aj, c_current,s,r,d]);
                                end    
                            end   
                        end
                    end
                end
        end
    end
    
    optimality_matrix = zeros(Int8, game.n, game.S, game.dim_rho, game.dim_delta);
    Q_loss_path = zeros(Float32, game.n, game.S, game.dim_rho, game.dim_delta);
    Gamma = zeros(Float32, game.n, game.S, game.dim_rho, game.dim_delta);
    for d=1:game.dim_delta
        for r=1:game.dim_rho
            for s=1:game.S
                for n=1:game.n
                    rival = n == 1 ? 2 : 1
                    if n==1
                        state=[actions[end-2,n,s,r,d], actions[end-1,rival,s,r,d], cost[end-1,s,r,d],cost[end-2,s,r,d]];
                        p_own = actions[end-1,n,s,r,d];
                    else
                        state=[actions[end-1,n,s,r,d],actions[end,rival,s,r,d], cost[end,s,r,d], cost[end-1,s,r,d]];
                        p_own = actions[end,n,s,r,d];
                    end
                    simulated = bf[n,state[1],state[2],state[3],state[4],s,r,d];
                    theoretical = bf_optimal[n,state[1],state[2],state[3],s,r,d];
                    optimality_matrix[n,s,r,d]= simulated == theoretical ? 1 : 0;
                    Gamma[n,s,r,d] =  Float32.(Q_matrix[n,state[1],state[2],state[3],state[4],p_own,s,r,d] / maximum(V0_matrix[n,:,state[1],state[2],state[3],s,r,d]))[1];
                    Q_loss_path[n,s,r,d] =  Float32.((maximum(V0_matrix[n,:,state[1],state[2],state[3],s,r,d])-Q_matrix[n,state[1],state[2],state[3],state[4],p_own,s,r,d][1]) / maximum(V0_matrix[n,:,state[1],state[2],state[3],s,r,d]))[1];
                end
            end
        end
    end

    Q_loss_all = zeros(Float32, game.n, game.dim_A, game.dim_A, game.dim_C, game.dim_C, game.dim_A, game.S, game.dim_rho, game.dim_delta);
    for d=1:game.dim_delta
        for r=1:game.dim_rho
            for n=1:game.n
                for s=1:game.S
                    for aj=1:game.dim_A
                        for ai_previous=1:game.dim_A
                            for c=1:game.dim_C
                                for ai=1:game.dim_A
                                    Q_loss_all[n,ai_previous, aj, c, 1, ai,s,r,d] = (V0_matrix[n,ai,ai_previous,aj,c,s,r,d]-Q_matrix[n,ai_previous,aj,c,1,ai,s,r,d])/V0_matrix[n,ai,ai_previous,aj,c,s,r,d];
                                    Q_loss_all[n,ai_previous, aj, c, 2, ai,s,r,d] = (V0_matrix[n,ai,ai_previous,aj,c,s,r,d]-Q_matrix[n,ai_previous,aj,c,2,ai,s,r,d])/V0_matrix[n,ai,ai_previous,aj,c,s,r,d];
                                end
                            end
                        end    
                    end
                end
            end
        end
    end


    Γ = mean(Gamma, dims=1);
    Γ = reshape(Γ,game.S,game.dim_rho,game.dim_delta);
    nash =  sum(optimality_matrix,dims=1).==2;
    nash = reshape(nash,game.S,game.dim_rho,game.dim_delta);
    Q_loss = mean(Q_loss_path,dims=1);
    Q_loss = reshape(Q_loss,game.S,game.dim_rho,game.dim_delta);
    Q1_loss_all = mean(Q_loss_all,dims=1:6);
    Q1_loss_all = reshape(Q1_loss_all,game.S, game.dim_rho, game.dim_delta);


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

table=Array{Any}(undef, 9, game.dim_rho);

d=1;
    for r=1:game.dim_rho
        table[1,r] = t_conv[r,d];
        table[2,r] = price_market_mean[r,d]
        table[3,r] = mean(Δ[:,r,d]);
        table[4,r] = std(Δ[:,r,d]);
        table[5,r] = mean(nash[:,r,d]);
        table[6,r] = mean(Q_loss[:,r,d]);
        table[7,r] = std(Q_loss[:,r,d]);
        table[8,r] = mean(Q1_loss_all[:,r,d]);
        table[9,r] = std(Q1_loss_all[:,r,d]);
    end


        # --- Labels ---
row_labels = [
    "Number of iterations until convergence (in millions)",
    "Average market price",
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

for i in 1:9
    push!(output_lines,
        @sprintf("%-45s %15.3f %15.3f", row_labels[i], table[i,1], table[i,2])
    )
end

writedlm("table_D1.txt", output_lines)
