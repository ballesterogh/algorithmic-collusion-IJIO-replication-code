function cost_shock_analysis(game, bf, T)
    d=1;

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
        
        p_treshold_up = game.P[end];
        p_treshold_low = game.P[1];
        Z=c*ones(Int64, T+2);
        shock=setdiff([1,2],c)[1];
        Z[3]=shock;
    
        for s=1:game.S
            prices_unique = sort(unique(price[1,51:end,s]));
            actions_unique = indexin(prices_unique, game.P);
            prices_unique_rival = sort(unique(price[2,51:end,s]));
            actions_unique_rival = indexin(prices_unique_rival, game.P);

            prices_valid = filter(y -> y < p_treshold_up && y > p_treshold_low, prices_unique)
            actions_valid = indexin(prices_valid, game.P);
            K = length(prices_valid);
            price_k = zeros(Float32, game.n, T, K);
            price_k_nodev = zeros(Float32, game.n, T, K);
            a=zeros(Int64,game.n,T);
            a_nodev=zeros(Int64,game.n,T);
            top_cylce = [maximum(actions_unique), maximum(actions_unique_rival)];
            bottom_cylce = [minimum(actions_unique), minimum(actions_unique_rival)];

            if K>=1
                for k=1:K
                    a0=zeros(Int64,game.n;);
                    a0_nodev=zeros(Int64,game.n;);
                    q=findall(bf[1,:,c,c,s,r,d].==actions_valid[k]);
                    idx = indexin(intersect(q,actions_unique_rival),actions_unique_rival);
                    a0[2]=actions_unique_rival[idx][1];
                    a0_nodev[2]=a0[2]
                    
                    for t=1:T
                        if isodd(t) 
                            a[2,t]=a0[2];   
                            a[1,t]=bf[1,a[2,t],Z[t+2],Z[t+1],s,r,d];
    
                            a_nodev[2,t]=a0_nodev[2];   
                            a_nodev[1,t]=bf[1,a_nodev[2,t],c,c,s,r,d];
                        else
                            a[1,t]=a0[1];   
                            a[2,t]=bf[2,a[1,t],Z[t+2],Z[t+1],s,r,d];
    
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
                    price_k[:,:,k]
                    price_k_nodev[:,:,k]
                    price_k[:,:,k].-price_k_nodev[:,:,k]
    
                            #x = [findfirst(a[1,1:end].>=(top_cylce[1])),findfirst(a[2,2:end].>=(top_cylce[2]))];
                            #x = [findfirst(a[1,2:end].>=(a[1,1]+2)),findfirst(a[2,2:end].>=(a[1,1]+2))];
                            x = [
                                findfirst(a[1, 3:end] .>= top_cylce[1]),
                                findfirst(a[2, 2:end] .>= top_cylce[2]),
                                findfirst(a[1, 3:end] .<= bottom_cylce[1]), 
                                findfirst(a[2, 2:end] .<= bottom_cylce[2])
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

    
      price_serie_mean[:,:,c,r] = mean(p_diff[:,:,:,c,r], dims=3)

    
    
    for t=1:T
        if isodd(t)
            p_serie_mean[t,c,r]=price_serie_mean[1,t,c,r];
        else
            p_serie_mean[t,c,r]=price_serie_mean[2,t,c,r];
        end
    end
    
     
    end
    end

    
    
    return price_serie_mean, p_serie_mean,p_diff
end
