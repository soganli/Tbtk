%%
N = 31;
CoefLength     = 16;
FractionLength = 17;
Fpass = 0.1;
Fstop = 0.3;
Wpass = 1;
Wstop = 1;

Hd = filterDesign(N-1,Fpass,Fstop,Wpass,Wstop);
set(Hd, 'Arithmetic', 'fixed', ...
    'CoeffWordLength', CoefLength, ...
    'CoeffAutoScale', false, ...
    'NumFracLength', FractionLength, ...
    'Signed',         true, ...
    'FilterInternals',  'FullPrecision');
denormalize(Hd);
%coewrite(Hd,10,'firCoefficients');

coefFile = fopen('firCoefficients.mem' , 'w');

filter_data     = fi((Hd.Numerator)' , 1 , CoefLength , FractionLength);
data_bin = (filter_data.bin);
data_dec = str2num(filter_data.sdec);
for i = 1:N
    fprintf(coefFile, '%s\n',  data_dec(i,:));
end
fclose(coefFile);


%%Signal Generator.................................................
Fs = 260e6;
Fc = 8.3e6;
SampleNumber = 2^14;
t  = 0:(1/Fs):(SampleNumber-1)/Fs;
sig = exp(2*pi*1i*Fc*t);

sig_fi = fi(real(sig)*0.4 , 1 , 16 , 15);

dataFile = fopen('s_axis_data_tdata.txt' , 'w');

data     = str2num(sig_fi.sdec);
for i = 1:SampleNumber
    fprintf(dataFile, '%d\n',  data(i));
end
fclose(dataFile);





%%Filter Section...........................................................

data_filtered_conv = conv(data' , data_dec,'full');

data_buffer = zeros(N,1);
data_sum    = zeros(SampleNumber,1);
for i = 1:SampleNumber
    data_buffer(2:N) = data_buffer(1:N-1);    
    data_buffer(1)=data(i);
    mult_buffer     = data_buffer.*data_dec;
    data_sum(i)     = sum(mult_buffer);
end


plot(data_filtered_conv); hold on;
plot(data_sum, 'o'); hold off;







