function eps_equals(a::T, b::U; eps::Float64 = .0000000001)where{T,U <: Real}
    if abs(a-b) < eps
        return true
    else
        return false
    end
end