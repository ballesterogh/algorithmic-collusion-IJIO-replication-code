##################################
## FIGURE B.3: Pricing dynamics ##
##################################

# set working directory
root_dir = ".../code_IJIO/";
code_dir = joinpath(root_dir, "code");
figure_table_appendix_dir = joinpath(root_dir, "figures_tables_appendix");
data_dir = joinpath(root_dir, "data_simulation");

cd(figure_table_appendix_dir);

# load packages
using Pkg
required_packages = ["Plots", "Statistics", "LinearAlgebra","Serialization","JLD2","Revise","Measures"]
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
P = Array{Any}(undef, 3);

# PLOT PRICING DYNAMICS 
y_ticks=(round.(collect(0 : 1/game.k : 1), digits=2));
r=2; d=1;
T=40;
# ALTERNATING FOCAL
idx=findall(focal_alternate_idx[:,r,d].==1);
w=11;
price_serie = zeros(Float32, T+2);
for t=1:T+2
    if isodd(t)
        price_serie[t]= price[end-T-2+t,1,idx[w],r,d];
    else
        price_serie[t]=price[end-T-2+t,2,idx[w],r,d];
    end
end
P[1]=scatter(collect(1:2:T+2),price[end-T-1:2:end,1,idx[w],r,d],ylim=(-0.1,1.1),label="Firm 1",markersize=5)
scatter!(collect(2:2:T+2),price[end-T:2:end,2,idx[w],r,d],label="Firm 2",markersize=5)
plot!(price_serie,yticks=y_ticks[1:2:end],linestyle = :dashdot,  color= :black,label="",xlabel="", ylabel="Prices",linewidth=2,xticks=false)
plot!(game.C[cost[end-T:end,idx[w],r,d]],grid=false,linestyle = :solid,  color= :black,linewidth=2,label="Cost",title="(a) Alternating focal")

# PARTIAL FOCAL
idx=findall(focal_high_idx[:,r,d].==1);
w=11
price_serie = zeros(Float32, T+2);
for t=1:T+2
    if isodd(t)
        price_serie[t]= price[end-T-2+t,1,idx[w],r,d];
    else
        price_serie[t]=price[end-T-2+t,2,idx[w],r,d];
    end
end
P[2]=scatter(collect(1:2:T+2),price[end-T-1:2:end,1,idx[w],r,d],ylim=(-0.1,1.1),label="",markersize=5)
scatter!(collect(2:2:T+2),price[end-T:2:end,2,idx[w],r,d],label="",markersize=5)
plot!(price_serie,yticks=y_ticks[1:2:end],linestyle = :dashdot,  color= :black,label="",xlabel="", ylabel="Prices",linewidth=2,xticks=false)
plot!(game.C[cost[end-T:end,idx[w],r,d]],grid=false,linestyle = :solid,  color= :black,linewidth=2,label="",title="(b) Partial focal")

# CYCLE
idx=findall(cycle_idx[:,r,d].==1);
price_serie = zeros(Float32, T+2);
x=2;
for t=1:T+2
    if isodd(t)
        price_serie[t]= price[end-T-2+t,1,idx[x],r,d];
    else
        price_serie[t]=price[end-T-2+t,2,idx[x],r,d];
    end
end
P[3]=scatter(collect(1:2:T+2),price[end-T-1:2:end,1,idx[x],r,d],ylim=(-0.1,1.1),label="",markersize=5)
scatter!(collect(2:2:T+2),price[end-T:2:end,2,idx[x],r,d],label="",markersize=5)
plot!(price_serie,yticks=y_ticks[1:2:end],linestyle = :dashdot,  color= :black,label="",xlabel="Time", ylabel="Prices",linewidth=2,xticks=false)
plot!(game.C[cost[end-T:end,idx[x],r,d]],grid=false,linestyle = :solid,  color= :black,linewidth=2,label="",title="(c) Cycle")

plot(P[1],P[2],P[3], layout=(3, 1),legend=false)

savefig("figure_B3.pdf")
