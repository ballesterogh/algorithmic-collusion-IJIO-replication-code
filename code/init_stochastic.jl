# Model of algorithms and competition

module init_stochastic

    export init_game

    using Pkg

    required_packages = ["Parameters", "Statistics", "Combinatorics", "NLsolve", "StructTypes"]

    for pkg in required_packages
        try
            @eval using $(Symbol(pkg))
        catch
            println("Installing missing package: $pkg")
            Pkg.add(pkg)
            @eval using $(Symbol(pkg))
        end
    end
    
    # Model properties
    @with_kw mutable struct model
        # Default Properties
        cH::Vector{Float32}                     # High marginal cost
        delta::Vector{Float32}                  # Discount factor
        rho::Vector{Float32}                    # Transition probability
        k::Int8                                 # Dimension of the price grid
        n::Int8 = 2                             # Number of firms
        alpha::Float32 = 0.15                   # Learning parameter
        beta::Float32 = 4e-6                    # Learning parameter
        
        cL::Float32 = 0.0                       # Low marginal cost
        S::Int64 = 1000                         # Number of simulations
        tstable::Int64 = 1e5                    # Number of iterations needed for stability
        tmax::Int64 = 1e7                       # Maximum number of iterations
        
        # Derived Properties
        A::Array{Int8,1} = zeros(1)             # Action space
        P::Array{Float32,1} = zeros(1)          # Price space
        C::Array{Float32,1} = zeros(1)          # Cost space   
        dim_A::Int64 = 0                        # dimension action space
        dim_C::Int64 = 0                        # dimension cost space   
        dim_delta::Int64 = 0                    # dimension discount factor   
        dim_rho::Int64 = 0                      # dimension transition probability   
        p_nash::Vector{Float32} = Vector{Float32}()
        p_monopoly::Vector{Float32} = Vector{Float32}()
        profit_nash::Vector{Float32} = Vector{Float32}()
        profit_monopoly::Vector{Float32} = Vector{Float32}()
        demand::Array{Float32, 3} = zeros(1,1,1)
        PI::Array{Float32, 4} = zeros(1,1,1,1)
        
    end

    # Save struct type
    StructTypes.StructType(::Type{model}) = StructTypes.Mutable()

    function dimension(game::model)::Tuple{Int64, Int64}
        dim_delta = length(game.delta);
        dim_rho = length(game.rho);
        return dim_delta, dim_rho
    end
    
    function compute_p_nash_monopoly(game::model)::Tuple{Array{Float32,1}, Array{Float32,1}, Array{Float32,1}, Array{Float32,1}}
        # Computes competitive and monopoly prices
        p_nash = vcat(game.cL, game.cH) .+ 1/game.k
        p_monopoly = vcat( (1 .+ game.cL) ./ 2, (1 .+ game.cH) ./ 2 )
        profit_monopoly = (1 .- p_monopoly) .* (p_monopoly .- vcat(game.cL, game.cH))
        profit_nash = (1 .- p_nash) .* (p_nash .- vcat(game.cL, game.cH))
        return p_nash, p_monopoly, profit_nash, profit_monopoly
    end

    function init_actions(game::model)::Tuple{Vector{Float32}, Vector{Int8},Vector{Float32},Int64, Int64}
        # Get action space of the firms
        P = collect(0:1/game.k:1)
        A = collect(1:1:length(P))
        # Get cost space
        C = [game.cL; game.cH]
        
        dim_A = length(A);
        dim_C = length(C);
        return P, A, C, dim_A, dim_C
    end

    
    function demand_compute(game::model)::Array{Float32, 3}
        dim_A = length(game.A)
        demand = zeros(Float32, game.n, dim_A, dim_A)
    
        for i in 1:dim_A
            for j in 1:dim_A
                p_i = game.P[game.A[i]]  
                p_j = game.P[game.A[j]]  
    
                if p_i < p_j
                    demand[1, i, j] = 1 - p_i  
                    demand[2, i, j] = 0        
    
                elseif p_j < p_i
                    demand[1, i, j] = 0       
                    demand[2, i, j] = 1 - p_j  
    
                else
                    demand[1, i, j] = (1 - p_i) / 2  
                    demand[2, i, j] = (1 - p_j) / 2  
                end
            end
        end
        
        return demand
    end

   
    function init_PI(game::model)::Array{Float32,4}
        # Initialize Profits (k^n x n)
        dim_A = length(game.A)
        C = [game.cL; game.cH]
        dim_C=length(C)
        PI = zeros(game.n, dim_A, dim_A,dim_C);
        
        for c=1:dim_C 
            for i=1:dim_A
                for j=1:dim_A
                    d = demand_compute(game);
                    p_i = game.P[i]  
                    p_j = game.P[j]  
                    
                    profit_i = (p_i-C[c])*d[1, i, j]
                    profit_j = (p_j-C[c])*d[2, i, j] 

                    PI[:,i, j,c] = [profit_i, profit_j];
                end
            end
        end
        return PI
    end
   
    # Initializes the game
        function init_game(cH, k, delta, rho)::model
            game = model(cH=cH, k=k, delta=delta, rho=rho)
            game.dim_delta, game.dim_rho = dimension(game)
            game.p_nash, game.p_monopoly, game.profit_nash, game.profit_monopoly = compute_p_nash_monopoly(game)
            game.P, game.A, game.C, game.dim_A, game.dim_C = init_actions(game)
            game.demand = demand_compute(game)
            game.PI = init_PI(game)
            return game
        end
end
