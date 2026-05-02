function price_deviation_analysis(game, bf, T, mode)
    d=1;
    @assert mode in ["price_deviation", "price_hike"] "mode must be 'price_deviation' or 'price_hike'"

    # Selección de desviación segun 'mode'
    dev = mode == "price_deviation" ? 1 : -1
    p_threshold = mode == "price_deviation" ? game.P[5] : game.P[end-1]

    #En estado de costo bajo, consideras desviaciones desde p>=P[5]
    # dev=1; p_treshold = game.P[5]; #for price deviation
    # dev=-1;  p_treshold = game.P[end-1]; #for price hikes

    
    table2=Array{Any}(undef, 3, game.dim_C, game.dim_rho);
    price_serie_mean = Array{Float32}(undef, game.n, T+2, game.dim_C, game.dim_rho)
    p_serie_mean     = Array{Float32}(undef, T, game.dim_C, game.dim_rho)
    p_diff = Array{Float32}(undef, game.n, T+2, game.S, game.dim_C, game.dim_rho)
    


    for c=1:game.dim_C
        for r=1:game.dim_rho
            T_sim=100;
            a=zeros(Int64,game.n,T_sim,game.S);
            price=zeros(Float32,game.n,T_sim,game.S);
            for s=1:game.S
                Random.seed!(s);
                a0=zeros(Int64, game.n);
                a0[1] = rand(unique(bf[1,:,c,c,s,r,d]));
                a0[2] = bf[2,a0[1],c,c,s,r,d];
                for t=1:T_sim
                    if isodd(t) 
                        a[2,t,s]=a0[2];   
                        a[1,t,s]=bf[1,a[2,t,s],c,c,s,r,d];
                    else
                        a[1,t,s]=a0[1];   
                        a[2,t,s]=bf[2,a[1,t,s],c,c,s,r,d];
                    end
                    price[1,t,s] = game.P[a[1,t,s]];
                    price[2,t,s] = game.P[a[2,t,s]];
                    a0=[a[1,t,s], a[2,t,s]];
                end
            end
    
    
        price_serie=zeros(Float32,game.n,T,game.S);
        price_serie_nodev=zeros(Float32,game.n,T,game.S);
    
        for s=1:game.S
            prices_unique = sort(unique(price[1,51:end,s]));
            actions_unique = indexin(prices_unique, game.P);
            prices_unique_rival = sort(unique(price[2,51:end,s]));
            actions_unique_rival = indexin(prices_unique_rival, game.P);
            #prices_above = filter(y -> y >= p_treshold, prices_unique) #for price deviation
            #prices_above = filter(y -> y <= p_treshold, prices_unique) #for price hikes

            prices_above = mode == "price_deviation" ?
               filter(y -> y >= p_threshold, prices_unique) :
               filter(y -> y <= p_threshold, prices_unique)

            actions_above = indexin(prices_above, game.P);
            K = length(prices_above);
            price_k = zeros(Float32, game.n, T, K);
            price_k_nodev = zeros(Float32, game.n, T, K);
            a=zeros(Int64,game.n,T);
            a_nodev=zeros(Int64,game.n,T);
            top_cylce = [maximum(actions_unique), maximum(actions_unique_rival)];
            if K>=1
                for k=1:K
                    a0=zeros(Int64,game.n;);
                    a0_nodev=zeros(Int64,game.n;);
                    #que accion del jugador 2 genera que 1 juege actions_above[k]??
                    q=findall(bf[1,:,c,c,s,r,d].==actions_above[k]);
                    idx = indexin(intersect(q,actions_unique_rival),actions_unique_rival);
                    a0[2]=actions_unique_rival[idx][1];
                    a0_nodev[2]=a0[2]
                    
                    for t=1:T
                        if isodd(t) && t==1
                            a[2,t]=a0[2];   
                            a[1,t]=bf[1,a[2,t],c,c,s,r,d]-dev;
    
                            a_nodev[2,t]=a0_nodev[2];   
                            a_nodev[1,t]=bf[1,a_nodev[2,t],c,c,s,r,d];
                        elseif isodd(t) && t!==1
                            a[2,t]=a0[2];   
                            a[1,t]=bf[1,a[2,t],c,c,s,r,d];
    
                            a_nodev[2,t]=a0_nodev[2];   
                            a_nodev[1,t]=bf[1,a_nodev[2,t],c,c,s,r,d];
                        else
                            a[1,t]=a0[1];   
                            a[2,t]=bf[2,a[1,t],c,c,s,r,d];
    
                            a_nodev[1,t]=a0_nodev[1];   
                            a_nodev[2,t]=bf[2,a_nodev[1,t],c,c,s,r,d];
                        end
                        price_k_nodev[1,t,k] = game.P[a_nodev[1,t]];
                        price_k_nodev[2,t,k] = game.P[a_nodev[2,t]];
                        price_k[1,t,k] = game.P[a[1,t]];
                        price_k[2,t,k] = game.P[a[2,t]];
    
                        a0=[a[1,t], a[2,t]];
                        a0_nodev=[a_nodev[1,t], a_nodev[2,t]];
                    end
                    #analysis
                    price_k[:,:,1]
                    price_k_nodev[:,:,1]
                    price_k[:,:,1].-price_k_nodev[:,:,1]
    
                            #x = [findfirst(a[1,1:end].>=(top_cylce[1])),findfirst(a[2,2:end].>=(top_cylce[2]))];
                            #x = [findfirst(a[1,2:end].>=(a[1,1]+2)),findfirst(a[2,2:end].>=(a[1,1]+2))];
                            x = [
                            findfirst(a[1, 3:end] .>= top_cylce[1]),
                            findfirst(a[2, 2:end] .>= top_cylce[2]),
                            findfirst(a[1, 3:end] .>= (a[1, 1] .+ 2)), 
                            findfirst(a[2, 2:end] .>= a[1, 1].+ 2)
                            ]
                            if x[1]!==nothing
                                x[1]=x[1]+2;
                            end
                            if x[2]!==nothing
                                x[2]=x[2]+1;
                            end
                            if x[3]!==nothing
                                x[3]=x[3]+2;
                            end
                            if x[4]!==nothing
                                x[4]=x[4]+1;
                            end
                        y = filter(!isnothing, x);
                        if isempty(y)==0 
                            t_pos = minimum(y);
                            restarting_firm = indexin(t_pos,x)[1]; #firm 1 or 2 restart the cycle
                            if isodd(restarting_firm)
                                price_k[1,t_pos:end,k] = price_k_nodev[1,t_pos:end,k];
                                price_k[2,t_pos+1:end,k] = price_k_nodev[2,t_pos+1:end,k];
                            else
                                price_k[1,t_pos+1:end,k] = price_k_nodev[1,t_pos+1:end,k];
                                price_k[2,t_pos:end,k] = price_k_nodev[2,t_pos:end,k];
                            end
                        end
                        price_k[:,:,1].-price_k_nodev[:,:,1]
                end
                price_serie[1,:,s] = mean(price_k[1,:,:],dims=[2,3]);
                price_serie[2,:,s] = mean(price_k[2,:,:],dims=[2,3]);
    
                price_serie_nodev[1,:,s] = mean(price_k_nodev[1,:,:],dims=[2,3]);
                price_serie_nodev[2,:,s] = mean(price_k_nodev[2,:,:],dims=[2,3]);
            end
        end
    
    p_diff_w = price_serie.-price_serie_nodev;
    p_diff[:,:, :, c, r] = cat(zeros(Float32, game.n, 2, game.S), p_diff_w; dims=2)

    
    #idx = findall(s -> p_diff[1,3,s,c,r] < 0, 1:game.S) # for prices deviation
    #idx = findall(s -> p_diff[1,3,s,c,r] > 0, 1:game.S); # for prices hikes
    
    idx = mode == "price_deviation" ?
      findall(s -> p_diff[1,3,s,c,r] < 0, 1:game.S) :
      findall(s -> p_diff[1,3,s,c,r] > 0, 1:game.S)
    
      price_serie_mean[:,:,c,r] = mean(p_diff[:,:,:,c,r][:,:,idx], dims=3)

    
    #table2[1,c,r] = nanmean(price_serie[2,2,idx].-price_serie[1,1,idx]); # absolute price change
    table2[1,c,r] = nanmean((price_serie[2,2,idx].-price_serie[1,1,idx])./price_serie[1,1,idx]); # relative`` price change
    
    # Length of punishment
    length_punishment=zeros(Int64, game.S);
    for s=1:game.S
        t_index = findfirst(t -> all(p_diff_w[:, t, s] .== 0), 1:T);
        length_punishment[s] = t_index === nothing ? 0 : t_index;
    end
    table2[3,c,r] = mean(length_punishment.-1);
    
    
    
    
    disc = [game.delta[d]^i for i in 0:T-1];
    profits_serie = zeros(Float32, game.n, T, game.S);
    profits_serie_disc = zeros(Float32, game.n, T, game.S);
    for s=1:game.S
        for t=1:T
            if price_serie[1,t,s] < price_serie[1,t,s]
                d1 = 1 - price_serie[1,t,s];
                d2 = 0;
            elseif price_serie[1,t,s] > price_serie[1,t,s]
                d1 = 0;
                d2 = 1 - price_serie[2,t,s];
            else
                d1 = (1 - price_serie[1,t,s])/2;
                d2 = (1 - price_serie[2,t,s])/2;
            end
        profits_serie[:,t,s] = [(price_serie[1,t,s]-game.C[c])*d1, (price_serie[2,t,s]-game.C[c])*d2];
        end
        profits_serie_disc[:,:,s] = profits_serie[:,:,s].* disc';
    end
    
    
    
    profits_serie_nodev = zeros(Float32, game.n, T, game.S);
    profits_serie_nodev_disc = zeros(Float32, game.n, T, game.S);
    for s=1:game.S
        for t=1:T
        if price_serie_nodev[1,t,s] < price_serie_nodev[1,t,s]
            d1 = 1 - price_serie_nodev[1,t,s];
            d2 = 0;
        elseif price_serie_nodev[1,t,s] > price_serie_nodev[1,t,s]
            d1 = 0;
            d2 = 1 - price_serie_nodev[2,t,s];
        else
            d1 = (1 - price_serie_nodev[1,t,s])/2;
            d2 = (1 - price_serie_nodev[2,t,s])/2;
        end
        profits_serie_nodev[:,t,s] = [(price_serie_nodev[1,t,s]-game.C[c])*d1, (price_serie_nodev[2,t,s]-game.C[c])*d2];
        end
        profits_serie_nodev_disc[:,:,s] = profits_serie_nodev[:,:,s].* disc';
    end
    
    gain_dev=zeros(Float32, game.S);
    for s=1:game.S
        a=mean(profits_serie_disc[:,1:length_punishment[s],s],dims=2);
        b=mean(profits_serie_nodev_disc[:,1:length_punishment[s],s],dims=2);
        gain_dev[s] = (mean(a)[1] - mean(b)[1]) - mean(b)[1];
    end
    
    # Average percentage gain from the deviation in terms of discounted profits
    table2[2,c,r] = nanmean(gain_dev)
    
    
    
    for t=1:T
        
        if isodd(t)
            p_serie_mean[t,c,r]=price_serie_mean[1,t,c,r];
    
        else
            p_serie_mean[t,c,r]=price_serie_mean[2,t,c,r];
    
        end
    end
    
     
    end
    end

    table2=round.(table2, digits=3);
    
    return table2, price_serie_mean, p_serie_mean,p_diff
end
