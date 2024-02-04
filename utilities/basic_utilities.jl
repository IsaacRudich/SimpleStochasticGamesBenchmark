"""
    eps_equals(a::T, b::U; eps::V = .0000000001)where{T,U,V <: Real}

Returns true if a and b are within eps of each other

# Arguments
- `a::T`: a number to compare 
- `b::U`: a number to compare 
- `eps::V`: the allowable gap between a and b
"""
function eps_equals(a::T, b::U; eps::V = .0000000001)where{T,U,V <: Real}
    if abs(a-b) < eps
        return true
    else
        return false
    end
end