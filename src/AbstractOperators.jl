abstract type Operator end

abstract type AbstractOperator <: Operator end

struct ProductOfAbstractOperators{T} <: AbstractOperator where T
    Ops::Vector{T}
end

struct SumOfAbstractOperators{T} <: AbstractOperator where T
    Ops::Vector{T}
    c::Vector
end

function *(c::Number,L::Operator)
    SumOfAbstractOperators([L],[c])
end

function -(L::Operator)
    (-1)*L
end

function +(Op1::AbstractOperator,Op2::AbstractOperator)
    SumOfAbstractOperators([Op1;Op2],[1;1])
end

function -(Op1::AbstractOperator,Op2::AbstractOperator)
    SumOfAbstractOperators([Op1;Op2],[1;-1])
end

function +(S1::SumOfAbstractOperators{T1},S2::SumOfAbstractOperators{T2}) where {T1 <: AbstractOperator, T2 <:AbstractOperator}
    SumOfAbstractOperators(vcat(S1.Ops,S2.Ops),vcat(S1.c,S2.c))
end

function +(S1::AbstractOperator,S2::SumOfAbstractOperators{T2}) where {T2 <:AbstractOperator}
    (1*S1) + S2
end

function +(S2::SumOfAbstractOperators{T2},S1::AbstractOperator) where {T2 <:AbstractOperator}
    S2 + (1*S1)
end

struct Derivative <: AbstractOperator
    order::Integer
end

struct Evaluation <: AbstractOperator end

struct Multiplication <: AbstractOperator
    f::Function
end

struct CollocatedOperator <: AbstractOperator
   Op::AbstractOperator
end

struct CollocatedMultiplication <: AbstractOperator
    f::Function
end

struct Projector <: AbstractOperator
    N::Integer
end

struct LeftBoundaryFunctional <: AbstractOperator end

struct RightBoundaryFunctional <: AbstractOperator end

struct BoundaryFunctional <: AbstractOperator
    A::Matrix
    B::Matrix
end

Derivative() = Derivative(1)

function *(D1::Derivative,D2::Derivative)
    Derivative(D1.order + D2.order)
end

function *(E::Evaluation,Op::ProductOfAbstractOperators)
    if typeof(Op.Ops[1]) <: Multiplication
        PoO = ProductOfAbstractOperators(Op.Ops[2:end])
        CollocatedMultiplication(Op.Ops[1].f)*(E*PoO)
    else
        CollocatedOperator(Op,E.GD)
    end
end

function *(E::Evaluation,Op::AbstractOperator)
    CollocatedOperator(Op)
end

function *(M::AbstractOperator,Op2::AbstractOperator)
    ProductOfAbstractOperators([M;Op2])
end

function *(M::Multiplication,Op::CollocatedOperator)
    ProductOfAbstractOperators([CollocatedMultiplication(M.f);Op])
end

function *(Op1::CollocatedOperator,Op2::AbstractOperator)
    CollocatedOperator(Op1.Op*Op2)
end

function *(E::Evaluation,M::Multiplication)
    ProductOfAbstractOperators([CollocatedMultiplication(M.f);E])  # Note that this is an approximation.
end

function *(M::Multiplication,E::Evaluation)
    ProductOfAbstractOperators([CollocatedMultiplication(M.f);E])  # Note that this is an approximation.
end

function *(P::ProductOfAbstractOperators,Op::AbstractOperator)
    ProductOfAbstractOperators(vcat(P.Ops,[Op]))
end

function *(Op::ProductOfAbstractOperators,sp::Basis)
    p = Op.Ops[end]*sp
    for i = length(Op.Ops)-1:-1:1
        p = Op.Ops[i]*p
    end
    p
end

function *(Op::SumOfAbstractOperators,sp::Basis)
    ops = [op*sp for op in Op.Ops]
    SumOfConcreteOperators(ops[1].domain,ops[1].range,ops ,Op.c)
end


