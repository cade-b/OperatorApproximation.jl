function *(D::Derivative,domain::Fourier)
    if D.order == 1
        range = domain
        dom = domain.GD.D
        ConcreteLazyOperator(domain,range,BasicBandedOperator(BI,0,0, (i,j) -> i == j ? 2im*pi*j/(dom.b-dom.a) : 0im ))
    else
        Derivative(D.order-1)*(Derivative(1)*domain)
    end
end