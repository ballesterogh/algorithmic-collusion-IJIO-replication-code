function compute_profit_normalized(game, profits, π_bar_comp, π_bar_monop)
    
    Δ = zeros(Float64, game.S, game.dim_rho, game.dim_delta);
    Δ_random = 0;

    π_bar = zeros(Float64, game.S, game.dim_rho, game.dim_delta);

    for d=1:game.dim_delta
        for r=1:game.dim_rho
            for s=1:game.S
                π_bar[s,r,d] = mean(profits[:,:,s,r,d]);
                Δ[s,r,d] = (π_bar[s,r,d]-π_bar_comp)/(π_bar_monop.-π_bar_comp);
            end
        end
    end

    
    π_random = mean(game.PI);
    Δ_random = (π_random-π_bar_comp)/(π_bar_monop-π_bar_comp);

    return Δ, Δ_random
end
