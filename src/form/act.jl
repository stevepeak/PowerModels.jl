### w-theta form of the non-convex AC equations

export 
    ACTPowerModel, StandardACTForm

""
@compat abstract type AbstractACTForm <: AbstractPowerFormulation end

""
@compat abstract type StandardACTForm <: AbstractACTForm end

""
const ACTPowerModel = GenericPowerModel{StandardACTForm}

"default AC constructor"
ACTPowerModel(data::Dict{String,Any}; kwargs...) = 
    GenericPowerModel(data, StandardACTForm; kwargs...)

""
function variable_voltage{T <: AbstractACTForm}(pm::GenericPowerModel{T}, n::Int=0; kwargs...)
    variable_phase_angle(pm, n; kwargs...)
    variable_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_voltage_product(pm, n; kwargs...)
end

function constraint_voltage{T <: StandardACTForm}(pm::GenericPowerModel{T}, n::Int=0)
    t = pm.var[:nw][n][:t]
    w = pm.var[:nw][n][:w]
    wr = pm.var[:nw][n][:wr]
    wi = pm.var[:nw][n][:wi]

    for (i,j) in keys(pm.ref[:nw][n][:buspairs])
        @NLconstraint(pm.model, wr[(i,j)]^2 + wi[(i,j)]^2 == w[i]*w[j])
        @NLconstraint(pm.model, wi[(i,j)]/wr[(i,j)] == tan(t[i] - t[j]))
    end
end


""
function add_bus_voltage_setpoint{T <: AbstractACTForm}(sol, pm::GenericPowerModel{T}, n::String)
    add_setpoint(sol, pm, n, "bus", "bus_i", "vm", :w; scale = (x,item) -> sqrt(x))
    add_setpoint(sol, pm, n, "bus", "bus_i", "va", :t)
end
