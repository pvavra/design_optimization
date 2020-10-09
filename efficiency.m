function eff = efficiency(X,C)

eff = 1/trace(C*X'*X*C');

end