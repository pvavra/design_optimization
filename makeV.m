function V = makeV(rho,n)

% create cross-correlations using rho
xc = zeros(1,n);
xc(1) = [1];
for i=2:(n)
    xc(i) = rho^(i-1); 
    if xc(i) < 0.00001 % tolerance - stop after this
        break;
    end
end

	% figure;plot(xc)
	
	% taper data; see Chatfield, 'Analysis of time series', p. 148
	% this is not applied, as it is in the book, to the actual timeseries. ?
	sizexc = size(xc,2);
	num = round(sizexc * .05); 			% taper about 5% of values.
	txc = xc;
	for i = sizexc - num : sizexc
		txc(i) = (sizexc - i)*xc(i) / (num+1);
	end
	txc(sizexc+1:n) = 0;
	V = toeplitz(txc);
    if size(V,1) > n
        V = V(1:n,1:n);
    end
	%figure;plot(xc)
	%hold on; plot(txc,'r')
	
% % 	Old method without using the toeplitz function, on original xc.
% 	myones = ones(n,1);
% 	V = diag(myones);
% 	for i = 2:size(xc,2)
% 		d = myones((i:end),1) .* xc(i);
% 		V = V + diag(d,i-1) + diag(d,-(i-1));
% 	end
% 	
	% increase taper if matrix is still not positive definite
	test = eig(V);
	if test(1) < 0, warning('	V matrix is not positive definite!'),
		disp('		Increasing taper to stabilize variance.')
		while test(1) < 0
			num = num + 1;
			txc = xc;									% new tapered xc
			for i = sizexc - num : sizexc				% taper
				txc(i) = (sizexc - i)*xc(i) / (num+1);
			end
			txc(sizexc+1:n) = 0;						% fill in with zeros
			V = toeplitz(txc);							% make V
			test = eig(V);								% test V
            if num+1 == sizexc, disp('Taper failed...not a valid V matrix.'), break, end
		end
		disp(['		Tapered ' num2str(num) ' values from xc, which equals ' num2str(num*100/sizexc) ' % of the values.'])
	end
%     
    out1 = V;
%     out2 = txc;
    

end
