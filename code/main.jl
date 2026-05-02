# set working directory

root_dir ="/Users/gonzaloballestero/Desktop/Phd Economics/Research/Projects/Algorithmic Collusion/code_IJIO/"

root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
data_dir = joinpath(root_dir, "data_simulation");
cd(code_dir);


# load packages
using Pkg
required_packages = ["JLD2","Revise","FileIO"]
for pkg in required_packages
    try
        @eval using $(Symbol(pkg))
    catch
        println("Installing missing package: $pkg")
        Pkg.add(pkg)
        @eval using $(Symbol(pkg))
    end
end

# 1. DETERMINISTIC MARGINAL COSTS  (no-uncertainty benchmark) 
Revise.revise()
include("init_deterministic.jl"); include("qlearning_deterministic.jl")

# 1.1. Deterministic low marginal cost (i.e., fix c=0)
c = 0; k = 12;
game = init_deterministic.init_game(c, k); # Initialize the game 
Q_matrix, profits, actions, t_final,bf = qlearning_deterministic.simulate_game(game); # Simulate the game
output_path = joinpath(data_dir, "outcomes_deterministic_cL.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; # Save simlulation outcomes


# 1.2. Deterministic high marginal cost (i.e., fix c=1/6)
c = 1/6; k = 12;
game = init_deterministic.init_game(c, k); 
Q_matrix, profits, actions, t_final, bf = qlearning_deterministic.simulate_game(game); 
output_path = joinpath(data_dir, "outcomes_deterministic_cH.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# 2. STOCHASTIC MARGINAL COSTS 
Revise.revise()
include("init_stochastic.jl"); include("qlearning_stochastic.jl");

cH = [1/6]; k = 12; delta=[0.95]; rho=[0.5, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho); 
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# ROBUSTNESS 

# 1. DISCOUNT FACTOR
# i. Bernoulli
cH = [1/6]; k = 12; 
delta = [0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95];
rho=[0.5];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_discount_bernoulli.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# ii. Markov
rho=[0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_discount_markov.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# 2.1 ACTION SET
cH = [1/6]; k = 24; delta=[0.95]; rho=[0.5, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_action_24.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# 2.2 ACTION SET
cH = [1/6]; k = 48; delta=[0.95]; rho=[0.5, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_action_48.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# 2.3 ACTION SET
cH = [1/6]; k = 108; delta=[0.95]; rho=[0.5, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_action_108.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 


# 3. LARGE COST SHOCKS
cH = [1/3]; k = 12; delta=[0.95]; rho=[0.5, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_cost_shock.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 

# 4. HIGHER UNCERTAINTY
cH = [1/6, 1/3]; k = 12; delta=[0.95]; rho=[1/3, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic.simulate_game(game);
output_path = joinpath(data_dir, "outcomes_stochastic_uncertainty.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 


# 5. CONDITIONING ON OWN PAST PRICE 
Revise.revise();
include("qlearning_stochastic_own_price.jl");
cH = [1/6]; k = 12; delta=[0.95]; rho=[0.5, 0.9];
game = init_stochastic.init_game(cH, k, delta, rho);
Q_matrix, profits, actions, cost, t_final, bf = qlearning_stochastic_own_price.simulate_game_own_price(game);
output_path = joinpath(data_dir, "outcomes_stochastic_own_price.jld2");
@save output_path game Q_matrix profits actions cost t_final bf; 
