
%% 
% Must account for:
% 
% -Antenna Efficiency Losses: Rx and Tx (~4 dB)
% -Antenna Mismatch Losses: Reflection from Transmitter/Receiver to
%   Antennas, (~1dB)
% -Transmission Coupling Loss (~2.5 dB): For antennas on the surface of the material,
%   the transmission Loss is:
%
%    Lt1 = -20log10(4*ZmZa/(|Zm+Za|^2)
%
%   where Za = char. impedance of air (377 ohms), Zm = characteristic
%   impedance of material:

%    Zm = (sqrt(u0*ur/e0*er))*(1/(1+tan(del)^2)^4)*(cos(del/2)+jsin(del/2))
% 
%    where del is the skin depth. Typically Zm = 125 ohms for earth materials.
% -Retransmission Coupling Loss (~2.5 dB) : retransmission from material to air
%     Lt2 = -20log10(4*ZmZa/(|Zm+Za|^2)
% -Antenna Spreading Losses: 
%       Ls = -10log10(G_tx*A_rx*rcs/((4*pi*R^2)^2))
%   where G_tx = tx antenna gain, A_rx = rx antenna aperture, R = range, 
%   and rcs = radar cross section (~1m^2). 
%   Note that A = G*lambda^2/4*pi
%
%   Corrections for other scatterers:
%         point scatterer : 1/R^4
%         line reflector : 1/R^3
%         planar reflector : 1/R^2

% -Attenuation Loss of Material
% 
%     La = 2*[20*log10(exp(atten_const*R))]
% 
% -Target Scattering Loss: for an interface between the material and a
% plane
%     Lsc = 20*log10(1-|(Z1-Z2)/(Z1+Z2)|)+20log(rcs)
%  where Z1 = char. impedance of 1st layer of underground material and 
%  Z2 = char. impedance of 2nd layer.
%  RCS for a flat plate: rcs = 4*pi*A^2/lambda^2 where A = plate area
% 
% Source: Ground Penetrating Radar, Volume 1 By David J. Daniels

R_tx = 10; R_rx = 10;
%R_tx = linspace(1,30,100); R_rx = linspace(1,30,100);

f_off = 60.00125e6; BW = 46.08e6; chirpT = 14.583e-6;
fc = BW/2 + f_off;
%fc = linspace(f_off,BW+f_off,100);

VWC = .2; 
VWC = linspace(.05,.3,100); 

er_a = 1; er_w = 81; er_s = 4; 
s_p = .5; % s_p = 1-(density of dry soil/density of water)
e0 = 8.85e-12; u0 = pi*4e-7; kboltz = 1.38e-23;
er_a = 1; er_w = 81; er_s = 4; 
cond_e = .001*(22*VWC).^(2); % custom fit to conductivity vs. moisture data
%cond_e = 1e-2;

w = 2*pi*fc;
er = ((1-s_p)*er_s^.5+(s_p-VWC).*er_a^.5+VWC*er_w^.5).^2;
loss_m = 0; loss_e = cond_e./(w*er*e0);

prop_const = sqrt((0+1i*w*u0).*(cond_e+1i*w.*er*e0));
atten_const = w*sqrt(er*e0*u0).*sqrt(.5*(sqrt(1+(loss_e).^2)-1));
phase_const = w*sqrt(er*e0*u0).*sqrt(.5*(sqrt(1+(loss_e).^2)+1));

lambda = 2*pi./phase_const;
v = w./phase_const;

linkbudget = struct('freq',{},'wavelength',{},'velocity',{},'prop_const',{},'rel_perm',{},'spread_loss',{},'freq_loss',{},'atten_loss',{},'total_loss',{});
linkbudget(1).wavelength = lambda;
linkbudget.freq = fc;
linkbudget.velocity = v;
linkbudget.prop_const = prop_const;
linkbudget.rel_perm = er;
linkbudget.cond_e = cond_e;

linkbudget.spread_loss = [10*log10(4*pi*R_tx.^2);10*log10(4*pi*R_rx.^2)];
linkbudget.spread_loss = [linkbudget.spread_loss; sum(linkbudget.spread_loss(1:2,:))];
linkbudget.freq_loss = 10*log10(4*pi./(lambda.^2));
linkbudget.atten_loss = [20*log10(exp(atten_const*R_tx));20*log10(exp(atten_const*R_rx))];
linkbudget.atten_loss = [linkbudget.atten_loss;sum(linkbudget.atten_loss(1:2,:))];
linkbudget.total_loss = linkbudget.spread_loss(3,:)+linkbudget.freq_loss+linkbudget.atten_loss(3,:);
linkbudget


pin_dbm = -15;
Gtx_db = 73.6;
Grx_db = 79.8;
NFtx_db = 7.002;
NFrx_db = .7843;
Gant_db = 22;
T0 = 290;
rcs = 1;

Ptx = .001*(10^(.1*(pin_dbm+Gtx_db)));
Gant_tx = 10^(.1*Gant_db);
Gant_rx = Gant_tx;

Prx = (Ptx*Gant_tx*Gant_rx*rcs*lambda.^2)./(((4*pi)^3)*(R_tx.^4).*exp(2*atten_const.*R_tx).*exp(2*atten_const.*R_rx));
SNR = Prx./(kboltz*T0*BW);

Prx_dbm = 10*log10(1000*Prx);
SNR_db = 10*log10(SNR);

if(numel(R_tx) > 1)
    figure; hold on; 
    plot(R_tx,linkbudget.atten_loss(1,:)); plot(R_rx,linkbudget.atten_loss(2,:)); 
    plot(R_tx,linkbudget.atten_loss(3,:)); plot(R_tx,linkbudget.total_loss(1,:)); 
    xlabel('TX Range (m)'); ylabel('Attenuation Loss (dB)'); legend('TX Atten Loss','RX Atten Loss','Total Atten Loss','Total Loss');
    title(sprintf('Rng v. Attenuation. fc = %f Mhz',fc/1e6));
    
    figure; hold on; 
    plot(R_tx,linkbudget.spread_loss(1,:)); plot(R_rx,linkbudget.spread_loss(2,:)); 
    plot(R_tx,linkbudget.spread_loss(3,:)); plot(R_tx,linkbudget.total_loss(1,:));
    xlabel('TX Range (m)'); ylabel('Spreading Loss (dB)'); 
    legend('TX Spread Loss','RX Spread Loss','Total Spread Loss','Total Loss');
    title(sprintf('Rng v. Spreading. fc = %f Mhz',fc/1e6));
    
    figure; hold on; plot(R_tx,Prx_dbm);plot(R_tx,SNR_db); legend('P RX [dBm]','SNR[dB]');
    xlabel('Range (m)'); ylabel('dBm/ dB'); grid on; axis tight;
    title(sprintf('Received Signal vs. Rng. fc = %f Mhz',fc/1e6));
end

if(numel(fc)>1)
    figure; hold on;
    plot(fc/1e6,linkbudget.total_loss,'k');
    [a h1 h2] = plotyy(fc/1e6,linkbudget.atten_loss(3,:),fc/1e6,atten_const);  
    xlabel('signal freq (MHz)'); 
    ylabel(a(1),'Attenuation Loss (dB)');ylabel(a(2),'Attenuation Const (Np/m)');
    title(sprintf('Freq. vs Attenuation. R tx=%i m, R rx=%i m',R_tx(1),R_rx(1)));
    legend('Total Loss','Atten. Loss','Atten Const');
    
    figure; hold on; plot(fc/1e6,Prx_dbm);plot(fc/1e6,SNR_db); legend('P RX [dBm]','SNR[dB]');
    xlabel('Freq (MHz)'); ylabel('dBm/ dB'); grid on; axis tight;
    title(sprintf('Received Signal. vs Freq. R tx=%i m, R rx=%i m',R_tx(1),R_rx(1)));
end

if (numel(VWC)>1)
    figure; hold on;
    plot(VWC,linkbudget.total_loss,'k');
    [a h1 h2] = plotyy(VWC,linkbudget.atten_loss(3,:),VWC,cond_e);  
    L1 = get(a(1),'YLim');
    set(a(1),'YTick',linspace(L1(1),L1(2),13));
    L2 = get(a(2),'YLim');
    set(a(2),'YTick',linspace(L2(1),L2(2),13));
    ylabel(a(1),'Loss (dB)');
    ylabel(a(2),'conductivity (S/m)');
    xlabel('Vol. Water Content'); grid on;
    title(sprintf('Attenuation Loss and Conductivity. R tx=%i m, R rx=%i m, fc=%f Mhz',R_tx(1),R_rx(1),fc/1e6));
    legend('Total Loss','Attenuation Loss','Conductivity');
    
    figure;
    semilogy(VWC,cond_e); grid on; title('Conductivity vs. VMC');
    xlabel('Vol. Water Content'); ylabel('Conductivity S/m');
    title(sprintf('VMC vs Conductivity. R tx=%i m, R rx=%i m, fc=%f Mhz',R_tx(1),R_rx(1),fc/1e6));
    
    figure; hold on; plot(VWC,Prx_dbm);plot(VWC,SNR_db); legend('P RX [dBm]','SNR[dB]');
     xlabel('Vol. Water Content'); ylabel('dBm/ dB');grid on; axis tight;
     title(sprintf('Received Signal vs. VMC. R tx=%i m, R rx=%i m, fc=%f Mhz',R_tx(1),R_rx(1),fc/1e6));
end