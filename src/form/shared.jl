#
# Shared Formulation Definitions
#################################
#
# This is the home of functions that are shared across multiple branches
# of the type hierarchy.  Hence all function in this file should be over 
# union types.
#
# The types defined in this file should not be exported because they exist 
# only to prevent code replication
#
# Note that Union types are discouraged in Julia, 
# https://docs.julialang.org/en/release-0.6/manual/style-guide/#Avoid-strange-type-Unions-1
# and should be used with discretion.
#
# If you are about to add a union type,
# first double check if a different type hierarchy can resolve the issue
# instead.
#

AbstractWRForms = Union{AbstractACTForm, AbstractWRForm}
AbstractPForms = Union{AbstractACPForm, AbstractACTForm, AbstractDCPForm}

"`t[ref_bus] == 0`"
function constraint_theta_ref{T <: AbstractPForms}(pm::GenericPowerModel{T}, ref_bus::Int)
    @constraint(pm.model, pm.var[:va][ref_bus] == 0)
end

"""
```
t[f_bus] - t[t_bus] <= angmax
t[f_bus] - t[t_bus] >= angmin
```
"""
function constraint_voltage_angle_difference{T <: AbstractPForms}(pm::GenericPowerModel{T}, f_bus, t_bus, angmin, angmax)
    va_fr = pm.var[:va][f_bus]
    va_to = pm.var[:va][t_bus]

    @constraint(pm.model, va_fr - va_to <= angmax)
    @constraint(pm.model, va_fr - va_to >= angmin)
end


function constraint_voltage_magnitude_setpoint{T <: AbstractWRForms}(pm::GenericPowerModel{T}, i, vm, epsilon)
    w = pm.var[:w][i]

    if epsilon == 0.0
        @constraint(pm.model, w == vm^2)
    else
        @assert epsilon > 0.0
        @constraint(pm.model, w <= (vm + epsilon)^2)
        @constraint(pm.model, w >= (vm - epsilon)^2)
    end
end


"""
enforces pv-like buses on both sides of a dcline
"""
function constraint_voltage_dcline_setpoint{T <: AbstractWRForms}(pm::GenericPowerModel{T}, f_bus, t_bus, vf, vt, epsilon)
    w_fr = pm.var[:w][f_bus]
    w_to = pm.var[:w][t_bus]
    if epsilon == 0.0
        @constraint(pm.model, w_fr == vf^2)
        @constraint(pm.model, w_to == vt^2)
    else
        @constraint(pm.model, w_fr <= (vf + epsilon)^2)
        @constraint(pm.model, w_fr >= (vf - epsilon)^2)
        @constraint(pm.model, w_to <= (vt + epsilon)^2)
        @constraint(pm.model, w_to >= (vt - epsilon)^2)
    end
end


"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w[i]
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w[i]
```
"""
function constraint_kcl_shunt{T <: AbstractWRForms}(pm::GenericPowerModel{T}, i, bus_arcs, bus_arcs_dc, bus_gens, pd, qd, gs, bs)
    w = pm.var[:w][i]
    p = pm.var[:p]
    q = pm.var[:q]
    pg = pm.var[:pg]
    qg = pm.var[:qg]
    p_dc = pm.var[:p_dc]
    q_dc = pm.var[:q_dc]

    @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w)
    @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w)
end


"""
```
sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w[i]
sum(q[a] for a in bus_arcs) + sum(q_ne[a] for a in bus_arcs_ne) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w[i]
```
"""
function constraint_kcl_shunt_ne{T <: AbstractWRForms}(pm::GenericPowerModel{T}, i, bus_arcs, bus_arcs_dc, bus_arcs_ne, bus_gens, pd, qd, gs, bs)
    w = pm.var[:w][i]
    p = pm.var[:p]
    q = pm.var[:q]
    p_ne = pm.var[:p_ne]
    q_ne = pm.var[:q_ne]
    pg = pm.var[:pg]
    qg = pm.var[:qg]
    p_dc = pm.var[:p_dc]
    q_dc = pm.var[:q_dc]

    @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) - pd - gs*w)
    @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(q_ne[a] for a in bus_arcs_ne) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) - qd + bs*w)
end


"""
Creates Ohms constraints (yt post fix indicates that Y and T values are in rectangular form)
"""
function constraint_ohms_yt_from{T <: AbstractWRForms}(pm::GenericPowerModel{T}, f_bus, t_bus, f_idx, t_idx, g, b, c, tr, ti, tm)
    p_fr = pm.var[:p][f_idx]
    q_fr = pm.var[:q][f_idx]
    w_fr = pm.var[:w][f_bus]
    wr = pm.var[:wr][(f_bus, t_bus)]
    wi = pm.var[:wi][(f_bus, t_bus)]

    @constraint(pm.model, p_fr == g/tm*w_fr + (-g*tr+b*ti)/tm*(wr) + (-b*tr-g*ti)/tm*( wi) )
    @constraint(pm.model, q_fr == -(b+c/2)/tm*w_fr - (-b*tr-g*ti)/tm*(wr) + (-g*tr+b*ti)/tm*( wi) )
end


"""
Creates Ohms constraints (yt post fix indicates that Y and T values are in rectangular form)
"""
function constraint_ohms_yt_to{T <: AbstractWRForms}(pm::GenericPowerModel{T}, f_bus, t_bus, f_idx, t_idx, g, b, c, tr, ti, tm)
    q_to = pm.var[:q][t_idx]
    p_to = pm.var[:p][t_idx]
    w_to = pm.var[:w][t_bus]
    wr = pm.var[:wr][(f_bus, t_bus)]
    wi = pm.var[:wi][(f_bus, t_bus)]

    @constraint(pm.model, p_to == g*w_to + (-g*tr-b*ti)/tm*(wr) + (-b*tr+g*ti)/tm*(-wi) )
    @constraint(pm.model, q_to == -(b+c/2)*w_to - (-b*tr+g*ti)/tm*(wr) + (-g*tr-b*ti)/tm*(-wi) )
end

