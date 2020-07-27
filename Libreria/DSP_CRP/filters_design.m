#
# filters_design.m
# 
# Author: Dr. Carlos Romero Pérez
#
# Description
# ===========
# Octave script to design fir and iir filters prototypes used in the 
# DSP_CRP C++ library
#
# Trace
# =====
#  23/07/2020    Initial elaboration of the script
#

pkg load signal

# Digital pass and stop bands (0 - 1). 1=pi
WP=1/4;   # All prototypes have the same passband frequency= pi/4
dW1=1/8;  # transition bandwith
dW2=1/16;
dW3=1/32;
dW4=1/64;

# Rp=rippel at passband Rs=attenuation in band stop in dB
dp=0.01;  # Ripple in passband
ds=0.01;  # Ripple in stopband
Rp=20*log10(1+dp);
Rs=-20*log10(ds);

# IIR Butterworth prototypes
[Nb1,Wc1]=buttord(WP,WP+dW1,Rp,Rs);
[Nb2,Wc2]=buttord(WP,WP+dW2,Rp,Rs);

[Bb1,Ab1]=butter(Nb1,Wc1);
[Bb2,Ab2]=butter(Nb2,Wc2);
## Important: filters prototypes for dW3 and dW4 drive to wrong filters
## propably because the filter order are too high

# IIR Elliptic prototypes
[Ne1,Wc1]=ellipord(WP,WP+dW1,Rp,Rs);
[Ne2,Wc2]=ellipord(WP,WP+dW2,Rp,Rs);
[Ne3,Wc3]=ellipord(WP,WP+dW3,Rp,Rs);
[Ne4,Wc4]=ellipord(WP,WP+dW4,Rp,Rs);


[Be1,Ae1]=ellip(Ne1,Rp,Rs,Wc1);
[Be2,Ae2]=ellip(Ne2,Rp,Rs,Wc2);
[Be3,Ae3]=ellip(Ne3,Rp,Rs,Wc3);
[Be4,Ae4]=ellip(Ne4,Rp,Rs,Wc4);

## FIR Filters

## We use the Kaiser algorithm to estimate the linear phase
## fir filter order
##
## N=(-20log10(sqrt(d1*d2)-13))/(2.32(ws-wp))
##
## 

Nfbasic=(-20*log10(sqrt(dp*ds))-13)/2.32;

Nf1=ceil(Nfbasic/(pi*dW1));
Nf2=ceil(Nfbasic/(pi*dW2));
Nf3=ceil(Nfbasic/(pi*dW3));
Nf4=ceil(Nfbasic/(pi*dW4));

Bf1=remez(Nf1,[0 WP WP+dW1 1],[1 1 0 0]);
Bf2=remez(Nf2,[0 WP WP+dW2 1],[1 1 0 0]);
Bf3=remez(Nf3,[0 WP WP+dW3 1],[1 1 0 0]);
Bf4=remez(Nf4,[0 WP WP+dW4 1],[1 1 0 0]);




# GUI to plot characteristic functions
flag_control=1;   # flow control


gui_options={"Exit","Butter dw=1/8","Butter dw=1/16","Ellip dw=1/8",...
"Ellip dw=1/16","Ellip dw=1/32","Ellip dw=1/64","Fir dw=1/8",...
"Fir dw=1/16","Fir dw=1/32","Fir dw=1/64"};


while flag_control==1
  select=menu("Select Plot",gui_options);
  switch (select)
    case 2
      titulo=sprintf("Butter N=%i, dftran=%.2f",Nb1,dW1);
      window=1; 
      [H,W]=freqz(Bb1,Ab1,1024);
    case 3
      titulo=sprintf("Butter N=%i, dftran=%.2f",Nb2,dW2);
      window=2; 
      [H,W]=freqz(Bb2,Ab2,1024);
    case 4
      titulo=sprintf("Ellip N=%i, dftran=%.2f",Ne1,dW1);
      window=3; 
      [H,W]=freqz(Be1,Ae1,1024);
    case 5
      titulo=sprintf("Ellip N=%i, dftran=%.2f",Ne2,dW2);
      window=4; 
      [H,W]=freqz(Be2,Ae2,1024);
    case 6
      titulo=sprintf("Ellip N=%i, dftran=%.2f",Ne3,dW3);
      window=5; 
      [H,W]=freqz(Be3,Ae3,1024);
    case 7
      titulo=sprintf("Ellip N=%i, dftran=%.2f",Ne4,dW4);
      window=6; 
      [H,W]=freqz(Be4,Ae4,1024);
    case 8
     titulo=sprintf("Fir N=%i, dftran=%.2f",Nf1,dW1);
      window=7; 
      [H,W]=freqz(Bf1,1,1024);
    case 9
     titulo=sprintf("Fir N=%i, dftran=%.2f",Nf2,dW2);
      window=8; 
      [H,W]=freqz(Bf2,1,1024);
    case 10
     titulo=sprintf("Fir N=%i, dftran=%.2f",Nf3,dW3);
      window=9; 
      [H,W]=freqz(Bf3,1,1024);
    case 11
     titulo=sprintf("Fir N=%i, dftran=%.2f",Nf4,dW4);
      window=10; 
      [H,W]=freqz(Bf4,1,1024);      
      case 1
      flag_control=0;
    otherwise
      errordlg("Strange option catched by GUI");
      flag_control=-1
  endswitch
  if flag_control==1
    figure(window);
    plot(W/pi,20*log10(abs(H)));
    title(titulo);
    xlabel("freq digital ( 0 - 1)"); ylabel("|H(f)|dB");
  end
end

  
  


