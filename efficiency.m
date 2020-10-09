function eff = efficiency(X,C)

eff = 1/trace(C*spm_inv(X'*X)*C');

end