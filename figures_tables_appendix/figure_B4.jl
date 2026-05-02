##############################################################################
## FIGURE B.4: Distribution of changes in market price and length of cycles ##
##############################################################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);

# load packages
using Pkg
required_packages = ["Plots", "Statistics", "LinearAlgebra","Serialization","JLD2","Revise","Measures","JLD2","Revise"]
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
include("pricing_classification.jl");
focal_single_idx, focal_alternate_idx, partial_idx, cycle_idx, focal_high_idx, focal_low_idx = pricing_classification(game, bf);

price = game.P[actions];
price_market = minimum(price,dims=2);
price_market = reshape(price_market, game.tstable, game.S, game.dim_rho, game.dim_delta);


# PLOT: DISTRIBUTION OF CHANGES IN MARKET PRICE AND LENGTH OF CYCLES
price_market_change = zeros(Float32, game.tstable-1,game.S, game.dim_rho, game.dim_delta);
for d=1:game.dim_delta
    for r=1:game.dim_rho
        for s=1:game.S
            for t=1:game.tstable-1
                price_market_change[t,s,r,d]=price_market[t+1,s,r,d]-price_market[t,s,r,d];
            end
        end
    end
end

resetting=zeros(Int32,game.tstable-1,game.S,game.dim_rho,game.dim_delta);
for d=1:game.dim_delta
    for r=1:game.dim_rho
        for s=1:game.S
            positive_changes = price_market_change[:,s,r,d][price_market_change[:,s,r,d] .> 0]
            median_positive = median(positive_changes)
            resetting[:,s,r,d] = price_market_change[:,s,r,d].>=median_positive;
        end
    end
end

cycle_period=zeros(Float32,game.S,game.dim_rho, game.dim_delta);
for d=1:game.dim_delta
    for r=1:game.dim_rho
        idx=findall(cycle_idx[:,r,d].==1);
        for s=1:length(idx)
            z=idx[s];    
            counts = Int[]  # Array to store counts
            count = 0       # Counter for consecutive zeros
            # Loop through the vector
            for val in resetting[:,z,r,d]
                if val == 0
                    count += 1  # Increment count for zeros
                else
                    push!(counts, count)  # Store the count when a 1 is encountered
                    count = 0  # Reset the count
                end
            end

            # Add any remaining counts if the vector ends with zeros
            if count > 0
                push!(counts, count)
            end
            cycle_period[s,r,d]=mean(counts)
        end
    end
end



# HISTOGRAM CYCLES
bin_edges = 0.5:1:15.5  # Bin edges for centers 1 to 15
bin_centers = 1:15      # Integer centers
r=1; d=1;
idx=findall(cycle_idx[:,r,d].==1);
p1=histogram(cycle_period[1:length(idx),r,d],alpha=.8,bins=bin_edges, xticks=bin_centers[2:2:end],normalize=:probability,label="ρ = $(game.rho[r])")
cH=1; r=2;
idx=findall(cycle_idx[:,r,d].==1);
histogram!(cycle_period[1:length(idx),r,d],alpha=.8,bins=bin_edges,normalize=:probability,label="ρ = $(game.rho[r])")
plot!(xlabel="Length of cycles", grid = false,size=(700,500),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6,ylabel="Frequency")

bin_centers = -10/game.k:1/game.k:10/game.k     # bin centers
bin_edges = [(bin_centers[i] + bin_centers[i+1]) / 2 for i in 1:length(bin_centers)-1]
bin_edges = [bin_centers[1] - (bin_centers[2] - bin_centers[1])/2; bin_edges; bin_centers[end] + (bin_centers[end] - bin_centers[end-1])/2]
x_ticks=round.(bin_centers,digits=2);
cH=1; r=1;
idx=findall(cycle_idx[:,r,d].==1);
p2=histogram(reshape(price_market_change[end-1000:end,idx,r,d],1001*length(idx)),normalize=:probability,bins=bin_edges, xticks=x_ticks[1:4:end],alpha=.8,label="ρ = $(game.rho[r])")
cH=1; r=2;
idx=findall(cycle_idx[:,r,d].==1);
histogram!(reshape(price_market_change[end-1000:end,idx,r,d],1001*length(idx)),normalize=:probability,bins=bin_edges,alpha=.8,label="ρ = $(game.rho[r])")
plot!(xlabel="Changes in market price", grid = false,size=(700,500),xlabelfontsize=8,ylabelfontsize=8, xtickfontsize=6,ytickfontsize=6,ylabel="Frequency")

plot(p2, p1, layout=(1, 2), grid = false,size=(600,300))
savefig("figure_B4.pdf")

