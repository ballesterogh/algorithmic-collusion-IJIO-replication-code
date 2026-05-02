#####################################################
## FIGURE 1: average market price upon convergence ##
#####################################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_dir = joinpath(root_dir, "figures_tables");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_dir);

# load packages
using Pkg
required_packages = ["Plots", "Statistics", "LinearAlgebra", "Serialization","JLD2","Revise"]
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


price = game.P[actions];
size(price)
price_market = minimum(price,dims=2);
price_market = reshape(price_market, game.tstable, game.S, game.dim_rho, game.dim_delta);
price_market_average = mean(price_market,dims=1);
price_market_average = reshape(price_market_average ,game.S, game.dim_rho, game.dim_delta);
r=1;
mean(price_market_average[:,r,d])
r=2;
mean(price_market_average[:,r,d])

price_market_mean_all = zeros(Float32, game.S, game.dim_rho, game.dim_delta);
for d=1:game.dim_delta
    for r=1:game.dim_rho
        for s=1:game.S
            price_market_mean_all[s,r,d]=mean(price_market[:,s,r,d]);
        end
    end
end

bin_centers = 0.2:0.154/20:.6
bin_edges = [(bin_centers[i] + bin_centers[i-1]) / 2 for i in 2:length(bin_centers)]
bin_edges = [0.2; bin_edges; 0.6]  
r=1;
histogram(price_market_mean_all[:,r,d], bins=bin_edges, normalize=:probability, xlabel="Prices", ylabel="Frequency",alpha=0.8,label="ρ = $(game.rho[r])")
r=2;
histogram!(price_market_mean_all[:,r,d], bins=bin_edges,xticks=collect(.2:.05:.6), normalize=:probability, xlabel="Prices", ylabel="Frequency",alpha=0.8,label="ρ = $(game.rho[r])")
vline!([(game.p_monopoly[1]+game.p_monopoly[2])/2],color="black",linewidth=2, linestyle=:solid,label="")
vline!([0.282],color="black",linewidth=2, linestyle=:solid,label="",xlim=(0.25,0.65)) 
y_max = Plots.ylims()[2];
y_min = Plots.ylims()[1];
annotate!((game.p_monopoly[1]+game.p_monopoly[2])/2-.01, 0.75*y_max, text("Collusive", color=:black, 10,rotation=90))
annotate!(.282-.01, 0.75*y_max, text("Competitive MPE", color=:black, 10,rotation=90),grid=false,xlim=(.14,.66),legend=:topright)
savefig("figure_1.pdf")