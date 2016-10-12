
nsamples = 4096;
Fs = 245.76e6;
chirpBW = 30.72e6
chirpT = nsamples/Fs %33.333e-6

nadc_new = (Fs/chirpBW - 1)*nsamples


