function mag = magest(z,alpha,beta)
    mag = alpha*max(abs(real(z(:))),abs(imag(z(:))))+beta*min(abs(real(z(:))),abs(imag(z(:))));
end